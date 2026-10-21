#!/usr/bin/env python3
"""
Homestead School - alles-in-een installer / updater (Linux en macOS)

Doet hetzelfde als install.ps1 op Windows:
  - Fabric voor Minecraft 1.20.1
  - een profiel/instance "Homestead School" (gewone Minecraft Launcher of Prism Launcher)
  - de Homestead 1.3.7-pack (configs, quests, resourcepacks, shaders), rechtstreeks van CurseForge
  - de mods + KubeJS-bestanden uit deze repo (exact gelijk aan de server)
  - de server in je serverlijst
  - normale of performance-modus (zelfde .homestead-map als op Windows)

Gebruik (zie README):
  curl -fsSL https://raw.githubusercontent.com/weggos2000/modded_server_repo/main/install.sh | bash

Opties (meestal niet nodig):
  --launcher official|prism|folder   launcher kiezen zonder menu
  --instance-path <map>              (bij "folder") de game-map van je instance
  --mode normal|performance          modus kiezen zonder menu
  --set-mode normal|performance      alleen snel wisselen van modus (geen download)
"""
import argparse
import datetime
import json
import os
import platform
import shutil
import struct
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
import zlib

REPO = 'weggos2000/modded_server_repo'
BRANCH = 'main'
INSTALLER_VERSION = 3   # verhogen bij elke wijziging aan de installers (ook in pack.json zetten)
UA = 'homestead-school-installer'

IS_MAC = platform.system() == 'Darwin'
HOME = os.path.expanduser('~')
TTY = sys.stdin.isatty()

if sys.stdout.isatty() and os.environ.get('TERM') != 'dumb':
    CYAN, YELLOW, GREEN, RED, RESET = '\033[36m', '\033[33m', '\033[32m', '\033[31m', '\033[0m'
else:
    CYAN = YELLOW = GREEN = RED = RESET = ''


def step(msg): print(f'{CYAN}==> {msg}{RESET}', flush=True)
def warn(msg): print(f'{YELLOW}    {msg}{RESET}', flush=True)
def good(msg): print(f'{GREEN}{msg}{RESET}', flush=True)


class Quit(Exception):
    def __init__(self, code): self.code = code


def ask(prompt, default=''):
    if not TTY:
        return default
    try:
        return input(prompt).strip()
    except EOFError:
        return default


def choose(prompt, options):
    while True:
        c = ask(prompt)
        if c in options:
            return c
        if not TTY:
            raise SystemExit('Geen terminal om een keuze te maken. Start de installer in een terminal.')


def wait_enter(msg):
    if TTY:
        ask(f'{msg} ')


# --- standaardpaden per systeem ----------------------------------------------
def app_support(name):
    return os.path.join(HOME, 'Library', 'Application Support', name)


def xdg(var, fallback):
    return os.environ.get(var) or os.path.join(HOME, fallback)


if IS_MAC:
    DEF_MINECRAFT = app_support('minecraft')
    DEF_PRISM = [app_support('PrismLauncher')]
    DEF_GAME = app_support('homestead-school')
    DEF_INSTALLS = os.path.join(app_support('HomesteadSchool'), 'installs.txt')
    DEF_WORK = os.path.join(HOME, 'Library', 'Caches', 'homestead-school')
else:
    DEF_MINECRAFT = os.path.join(HOME, '.minecraft')
    DEF_PRISM = [os.path.join(xdg('XDG_DATA_HOME', '.local/share'), 'PrismLauncher'),
                 os.path.join(HOME, '.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher')]   # Flatpak
    DEF_GAME = os.path.join(HOME, '.homestead-school')
    DEF_INSTALLS = os.path.join(xdg('XDG_DATA_HOME', '.local/share'), 'homestead-school', 'installs.txt')
    DEF_WORK = os.path.join(xdg('XDG_CACHE_HOME', '.cache'), 'homestead-school')   # niet /tmp: dat zit soms in RAM


# --- hulpjes ---------------------------------------------------------------
def download(url, dest, progress=False):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if shutil.which('curl'):
        cmd = ['curl', '-fL', '--retry', '3', '-A', UA, '-o', dest, url]
        cmd.insert(1, '--progress-bar' if progress and sys.stderr.isatty() else '-sS')
        subprocess.run(cmd, check=True)
    else:
        req = urllib.request.Request(url, headers={'User-Agent': UA})
        with urllib.request.urlopen(req) as r, open(dest, 'wb') as f:
            shutil.copyfileobj(r, f, 1 << 20)


def write_text(path, text):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def read_lines(path):
    if not os.path.isfile(path):
        return []
    with open(path, encoding='utf-8-sig', errors='replace') as f:
        return f.read().splitlines()


def total_ram_gb():
    try:
        if IS_MAC:
            return int(subprocess.run(['sysctl', '-n', 'hw.memsize'], capture_output=True, text=True).stdout) / 2**30
        for line in read_lines('/proc/meminfo'):
            if line.startswith('MemTotal:'):
                return int(line.split()[1]) / 2**20
    except Exception:
        pass
    return 8


def running(pattern):
    """Draait er een proces waarvan de commandoregel op pattern past (behalve dit script zelf)?"""
    if not shutil.which('pgrep'):
        return False
    r = subprocess.run(['pgrep', '-f', pattern], capture_output=True, text=True)
    mine = {os.getpid(), os.getppid()}
    return any(int(p) not in mine for p in r.stdout.split())


GAME_PROC = r'net\.fabricmc\.loader\.impl\.launch\.knot\.KnotClient|net\.minecraft\.client\.main\.Main'
LAUNCHER_PROC = r'(^|/)minecraft-launcher( |$)|Minecraft.app/Contents/MacOS/launcher'
PRISM_PROC = r'(^|/)prismlauncher( |$)'


def crc32_file(path):
    crc = 0
    with open(path, 'rb') as f:
        while True:
            b = f.read(1 << 20)
            if not b:
                return crc
            crc = zlib.crc32(b, crc)


# --- bron: de repo (als zip van GitHub, of een lokale map) ---------------------
class Source:
    """Leest bestanden uit de repo-zip zonder alles uit te pakken (scheelt 570 MB schrijven)."""

    def __init__(self, zip_path=None, folder=None):
        self.folder = folder
        self._cache = {}
        self.zip = zipfile.ZipFile(zip_path) if zip_path else None
        if self.zip:
            first = self.zip.namelist()[0]
            self.prefix = first.split('/')[0] + '/'

    def files(self, sub):
        """{relatief pad: (grootte, crc32 of None)} van alle bestanden onder sub/"""
        out = {}
        if self.zip:
            base = self.prefix + sub + '/'
            for i in self.zip.infolist():
                if i.filename.startswith(base) and not i.is_dir():
                    out[i.filename[len(base):]] = (i.file_size, i.CRC)
        else:
            base = os.path.join(self.folder, sub)
            for root, _, names in os.walk(base):
                for n in names:
                    p = os.path.join(root, n)
                    out[os.path.relpath(p, base).replace(os.sep, '/')] = (os.path.getsize(p), None)
        return out

    def crc(self, sub, rel):
        info = self.files_cache(sub)[rel]
        return info[1] if info[1] is not None else crc32_file(os.path.join(self.folder, sub, rel))

    def files_cache(self, sub):
        if sub not in self._cache:
            self._cache[sub] = self.files(sub)
        return self._cache[sub]

    def read(self, rel):
        if self.zip:
            return self.zip.read(self.prefix + rel)
        with open(os.path.join(self.folder, rel), 'rb') as f:
            return f.read()

    def copy(self, rel, dest):
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        tmp = dest + '.part'
        if self.zip:
            with self.zip.open(self.prefix + rel) as s, open(tmp, 'wb') as d:
                shutil.copyfileobj(s, d, 1 << 20)
        else:
            shutil.copyfile(os.path.join(self.folder, rel), tmp)
        os.replace(tmp, dest)


# --- performance-modus ---------------------------------------------------------
# Alles staat in <game>/.homestead (zelfde indeling als de Windows-installer):
#   mode.txt               normal / performance
#   remove.txt             mods die in performance-modus weg moeten
#   perf-mods/*.jar        extra FPS-mods voor performance-modus
#   perf-options.txt       lichtere grafische instellingen
#   disabled-mods/         hier staan de weggehaalde mods tijdens performance-modus
#   options-backup-*.txt   jouw eigen instellingen, om terug te zetten bij normaal
def state_dir(game): return os.path.join(game, '.homestead')


def current_mode(game):
    lines = read_lines(os.path.join(state_dir(game), 'mode.txt'))
    return lines[0].strip() if lines else 'normal'


def set_mode_marker(game, m):
    write_text(os.path.join(state_dir(game), 'mode.txt'), m)


def option_files(game):
    return [(os.path.join(game, 'options.txt'), 'options-backup-main.txt'),
            (os.path.join(game, 'config', 'defaultoptions', 'options.txt'), 'options-backup-default.txt')]


def jars(folder):
    return sorted(n for n in os.listdir(folder) if n.endswith('.jar')) if os.path.isdir(folder) else []


def restore_perf_mods(game):
    # mods uit performance-modus terugzetten en de extra FPS-mods weghalen
    st, mods = state_dir(game), os.path.join(game, 'mods')
    dis = os.path.join(st, 'disabled-mods')
    for n in jars(dis):
        os.replace(os.path.join(dis, n), os.path.join(mods, n))
    for n in jars(os.path.join(st, 'perf-mods')):
        p = os.path.join(mods, n)
        if os.path.exists(p):
            os.remove(p)


def apply_perf_mods(game):
    st, mods = state_dir(game), os.path.join(game, 'mods')
    dis = os.path.join(st, 'disabled-mods')
    os.makedirs(dis, exist_ok=True)
    n = 0
    for name in read_lines(os.path.join(st, 'remove.txt')):
        name = name.strip()
        if not name or name.startswith('#'):
            continue
        p = os.path.join(mods, name)
        if os.path.exists(p):
            os.replace(p, os.path.join(dis, name))
            n += 1
    perf = os.path.join(st, 'perf-mods')
    for j in jars(perf):
        shutil.copyfile(os.path.join(perf, j), os.path.join(mods, j))
    print(f'    {n} zware mods uitgezet, FPS-mods aangezet.')


def apply_perf_options(game):
    # lichtere instellingen zetten; eigen waarden eerst bewaren (alleen als er nog geen backup is)
    st = state_dir(game)
    patch = {}
    for l in read_lines(os.path.join(st, 'perf-options.txt')):
        if ':' in l and not l.startswith(':'):
            k, v = l.split(':', 1)
            patch[k] = v
    for path, backup_name in option_files(game):
        if not os.path.isfile(path):
            continue
        lines = read_lines(path)
        orig = []
        for key, val in patch.items():
            idx = next((i for i, l in enumerate(lines) if l.startswith(key + ':')), -1)
            if idx >= 0:
                orig.append(lines[idx])
                lines[idx] = f'{key}:{val}'
            else:
                orig.append(f'{key}:<absent>')
                lines.append(f'{key}:{val}')
        backup = os.path.join(st, backup_name)
        if not os.path.exists(backup):
            write_text(backup, '\n'.join(orig) + '\n')
        write_text(path, '\n'.join(lines) + '\n')


def restore_options(game):
    st = state_dir(game)
    default_backup = os.path.join(st, 'options-backup-default.txt')
    for path, backup_name in option_files(game):
        backup, delete = os.path.join(st, backup_name), True
        # options.txt bestond nog niet bij het aanzetten (Minecraft nog nooit gestart)? Dan de standaardwaarden gebruiken.
        if not os.path.exists(backup) and backup_name == 'options-backup-main.txt' and os.path.exists(default_backup):
            backup, delete = default_backup, False
        if not os.path.exists(backup) or not os.path.isfile(path):
            continue
        lines = read_lines(path)
        for b in read_lines(backup):
            if ':' not in b or b.startswith(':'):
                continue
            key, val = b.split(':', 1)
            lines = [l for l in lines if not l.startswith(key + ':')]
            if val != '<absent>':
                lines.append(b)
        write_text(path, '\n'.join(lines) + '\n')
        if delete:
            os.remove(backup)


def register_install(installs_file, game):
    games = [g for g in read_lines(installs_file) if g and os.path.isdir(g)]
    if game not in games:
        games.append(game)
    write_text(installs_file, '\n'.join(games) + '\n')


# --- servers.dat (minimale NBT: { servers: [ { name, ip } ] }) ---------------
def nbt_str(s):
    b = s.encode('utf-8')
    return struct.pack('>H', len(b)) + b


def servers_dat(name, ip):
    return (b'\x0a' + nbt_str('') +                       # root compound
            b'\x09' + nbt_str('servers') + b'\x0a' + struct.pack('>i', 1) +   # list met 1 compound
            b'\x08' + nbt_str('name') + nbt_str(name) +
            b'\x08' + nbt_str('ip') + nbt_str(ip) +
            b'\x00' +                                     # einde server-compound
            b'\x00')                                      # einde root


# --- modus wisselen zonder download ------------------------------------------
def switch_mode(args):
    games = [g for g in read_lines(args.installs_file) if g and os.path.isdir(state_dir(g))]
    if args.instance_path:
        games = [os.path.expanduser(args.instance_path)]
    if not games:
        warn('Homestead School is nog niet geinstalleerd. Draai eerst de installer.')
        raise Quit(1)
    game = games[0]
    if len(games) > 1:
        print('Welke installatie?')
        for i, g in enumerate(games, 1):
            print(f'  [{i}] {g}  ({current_mode(g)})')
        game = games[int(choose('Kies een nummer: ', [str(i) for i in range(1, len(games) + 1)])) - 1]
    if running(GAME_PROC):
        warn('Sluit Minecraft eerst af.')
        wait_enter('Druk op Enter als Minecraft dicht is')
    if current_mode(game) == args.set_mode:
        good(f"Performance-modus staat al {'AAN' if args.set_mode == 'performance' else 'UIT'} in {game}.")
        raise Quit(0)
    if args.set_mode == 'performance':
        step(f'Performance-modus aanzetten in {game} ...')
        apply_perf_mods(game)
        apply_perf_options(game)
    else:
        step(f'Terug naar normale modus in {game} ...')
        restore_perf_mods(game)
        restore_options(game)
        print('    Alle mods en je eigen instellingen staan terug.')
    set_mode_marker(game, args.set_mode)
    print()
    good('Klaar! Start Homestead School opnieuw in je launcher.')


def find_prism(args):
    if args.prism_dir:
        return args.prism_dir
    return next((p for p in DEF_PRISM if os.path.isdir(p)), None)


# --- de echte installatie ------------------------------------------------------
def install(args, work):
    # 1. Repo ophalen (mods, KubeJS-bestanden, pack.json)
    if args.source_dir:
        src = Source(folder=args.source_dir)
    elif args.repo_zip:
        src = Source(zip_path=args.repo_zip)
    else:
        step(f'Bestanden downloaden van github.com/{REPO} (ca. 570 MB, even geduld)...')
        zp = os.path.join(work, 'repo.zip')
        download(f'https://codeload.github.com/{REPO}/zip/refs/heads/{BRANCH}', zp, progress=True)
        src = Source(zip_path=zp)
    pack = json.loads(src.read('pack.json').decode('utf-8-sig'))
    fabric_id = f"fabric-loader-{pack['fabricLoader']}-{pack['minecraft']}"
    if int(pack.get('installerVersion', 0)) > INSTALLER_VERSION:
        warn('Er is een nieuwere installer. Haal hem opnieuw op via https://github.com/' + REPO)
        warn('(Deze versie gaat nu gewoon verder.)')

    # 2. Launcher kiezen
    launcher = args.launcher
    prism_dir = find_prism(args)
    if not launcher:
        if args.instance_path:
            launcher = 'folder'
        else:
            print('Welke launcher gebruik je?')
            print('  [1] Gewone Minecraft Launcher')
            print('  [2] Prism Launcher' + ('   (gevonden op deze computer)' if prism_dir else ''))
            print('  [3] Andere launcher (Modrinth App, ATLauncher, CurseForge, ...) - jij kiest de map')
            print('  [4] Lunar Client')
            c = choose('Kies 1, 2, 3 of 4: ', ['1', '2', '3', '4'])
            if c == '4':
                print()
                warn('Lunar Client kan geen modpacks laden (alleen zijn eigen mods), dus Homestead werkt daar niet.')
                warn('Je kan het wel in de gewone Minecraft Launcher zetten: daar log je in met hetzelfde Microsoft-account.')
                if not ask('Installeren in de gewone Minecraft Launcher? (j/n) ').lower().startswith(('j', 'y')):
                    print('Oke, er is niets geinstalleerd.')
                    raise Quit(0)
                c = '1'
            launcher = {'1': 'official', '2': 'prism', '3': 'folder'}[c]

    # RAM voor Minecraft: afhankelijk van hoeveel geheugen de computer heeft
    total = total_ram_gb()
    ram_mb = 8192 if total >= 15.5 else 6144 if total >= 11.5 else 4096
    if total < 11.5:
        warn(f'Je computer heeft maar ca. {round(total)} GB RAM. Homestead is zwaar; zet shaders uit als het hapert.')

    prism_instance = None
    if launcher == 'official':
        if not os.path.isfile(os.path.join(args.minecraft_dir, 'launcher_profiles.json')):
            warn('De Minecraft Launcher is nog niet (goed) geinstalleerd.')
            warn('Installeer hem via https://www.minecraft.net/download, start hem een keer, sluit hem en draai dit opnieuw.')
            raise Quit(1)
        if running(LAUNCHER_PROC):
            warn('Sluit eerst de Minecraft Launcher (anders overschrijft hij het nieuwe profiel).')
            wait_enter('Druk op Enter als de launcher dicht is')
        game = args.official_game_dir
    elif launcher == 'prism':
        if not prism_dir:
            warn('Prism Launcher niet gevonden (' + ' of '.join(DEF_PRISM) + ').')
            warn('Installeer Prism (https://prismlauncher.org), start hem een keer, sluit hem en draai dit opnieuw.')
            raise Quit(1)
        if running(PRISM_PROC):
            warn('Sluit eerst Prism Launcher.')
            wait_enter('Druk op Enter als Prism dicht is')
        # Prism kan een eigen instances-map ingesteld hebben
        inst_root = os.path.join(prism_dir, 'instances')
        for line in read_lines(os.path.join(prism_dir, 'prismlauncher.cfg')):
            if line.startswith('InstanceDir='):
                d = line[len('InstanceDir='):].strip()
                if d:
                    inst_root = d if os.path.isabs(d) else os.path.join(prism_dir, d)
                break
        prism_instance = os.path.join(inst_root, 'Homestead School')
        game = os.path.join(prism_instance, '.minecraft')
        if not os.path.isdir(game):
            game = os.path.join(prism_instance, 'minecraft')
    else:
        path = args.instance_path
        if not path:
            print()
            print(f"Maak in je launcher eerst een instance aan met Minecraft {pack['minecraft']} + Fabric {pack['fabricLoader']}.")
            path = ask("Plak het pad naar de game-map van die instance (de map waar 'mods' in staat of komt): ")
        game = os.path.expanduser(path.strip().strip('"\''))
        if os.path.basename(game.rstrip('/')) == 'mods':
            game = os.path.dirname(game.rstrip('/'))
        if not os.path.isdir(game):
            raise RuntimeError(f'Map bestaat niet: {game}')
    game = os.path.abspath(game)
    os.makedirs(game, exist_ok=True)
    step(f'Installeren in: {game}')

    # Modus kiezen (onthoudt de vorige keuze)
    prev_mode = current_mode(game)
    mode = args.mode
    if not mode:
        d = '2' if prev_mode == 'performance' else '1'
        print()
        print('Welke versie wil je?')
        print('  [1] Normaal       - alle effecten, voor een goede computer')
        print('  [2] Performance   - meer FPS, voor laptops (minder sfeer-effecten, lichtere instellingen)')
        print("  (Later wisselen kan met 'Performance aan' / 'Performance uit')")
        c = ask(f'Kies 1 of 2 [Enter = {d}]: ', d) or d
        mode = 'performance' if c == '2' else 'normal'

    # 3. Launcher instellen
    if launcher == 'official':
        step(f"Fabric {pack['fabricLoader']} voor Minecraft {pack['minecraft']} instellen...")
        ver_dir = os.path.join(args.minecraft_dir, 'versions', fabric_id)
        download(f"https://meta.fabricmc.net/v2/versions/loader/{pack['minecraft']}/{pack['fabricLoader']}/profile/json",
                 os.path.join(ver_dir, fabric_id + '.json'))
        now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')
        path = os.path.join(args.minecraft_dir, 'launcher_profiles.json')
        shutil.copyfile(path, path + '.homestead-backup')
        with open(path, encoding='utf-8-sig') as f:
            data = json.load(f)
        data.setdefault('profiles', {})['homestead-school'] = {
            'name': 'Homestead School', 'type': 'custom', 'created': now, 'lastUsed': now, 'icon': 'Grass',
            'lastVersionId': fabric_id, 'gameDir': game,
            'javaArgs': f'-Xmx{ram_mb}M -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200',
        }
        write_text(path, json.dumps(data, indent=2))
        print(f"    Profiel 'Homestead School' staat in de launcher ({round(ram_mb / 1024)} GB RAM).")
    elif launcher == 'prism':
        step("Prism-instance 'Homestead School' instellen...")
        mmc = {'formatVersion': 1, 'components': [
            {'uid': 'net.minecraft', 'version': pack['minecraft'], 'important': True},
            {'uid': 'net.fabricmc.intermediary', 'version': pack['minecraft'], 'dependencyOnly': True},
            {'uid': 'net.fabricmc.fabric-loader', 'version': pack['fabricLoader']},
        ]}
        write_text(os.path.join(prism_instance, 'mmc-pack.json'), json.dumps(mmc, indent=4))
        cfg = os.path.join(prism_instance, 'instance.cfg')
        if not os.path.exists(cfg):
            write_text(cfg, '\n'.join(['[General]', 'ConfigVersion=1.2', 'InstanceType=OneSix', 'name=Homestead School',
                                       'iconKey=default', 'OverrideMemory=true', f'MaxMemAlloc={ram_mb}',
                                       'MinMemAlloc=2048']) + '\n')
        print(f'    Instance staat in Prism ({round(ram_mb / 1024)} GB RAM).')

    # 4. Homestead-pack (configs, quests, resourcepacks, shaders)
    marker = os.path.join(game, '.homestead-pack')
    installed = (read_lines(marker) or [''])[0].strip()
    if installed != pack['packVersion']:
        step(f"Homestead {pack['packVersion']} ophalen van CurseForge (ca. 110 MB)...")
        pz = args.pack_zip
        if not pz:
            pz = os.path.join(work, 'homestead.zip')
            download(pack['packUrl'], pz, progress=True)
        step('Configs, quests, resourcepacks en shaders uitpakken...')
        with zipfile.ZipFile(pz) as z:
            for e in z.infolist():
                if e.is_dir() or not e.filename.startswith('overrides/'):
                    continue
                rel = e.filename[len('overrides/'):]
                if rel.startswith('mods/') or '..' in rel.split('/'):   # mods komen uit de repo
                    continue
                dst = os.path.join(game, *rel.split('/'))
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                with z.open(e) as s, open(dst, 'wb') as d:
                    shutil.copyfileobj(s, d, 1 << 20)
        write_text(marker, pack['packVersion'])
    else:
        step(f"Homestead {pack['packVersion']} staat er al (configs blijven zoals ze zijn).")

    for x in pack.get('extras', []):
        dst = os.path.join(game, x['dir'], x['file'])
        if os.path.exists(dst):
            continue
        print(f"    {x['dir']}/{x['file']} downloaden...")
        try:
            download(x['url'], dst)
        except Exception:
            if os.path.exists(dst):
                os.remove(dst)
            warn(f"Kon {x['file']} niet downloaden (niet erg, alleen een resource/shaderpack).")

    # 5. Mods synchroniseren
    # Eerst performance-wijzigingen aan de mods terugdraaien, dan synchroniseren, daarna de modus opnieuw toepassen.
    if prev_mode == 'performance':
        restore_perf_mods(game)
    st = state_dir(game)
    perf = src.files('performance')
    if perf:
        os.makedirs(st, exist_ok=True)
        src.copy('performance/remove.txt', os.path.join(st, 'remove.txt'))
        src.copy('performance/options.txt', os.path.join(st, 'perf-options.txt'))
        pm = os.path.join(st, 'perf-mods')
        shutil.rmtree(pm, ignore_errors=True)
        for rel in perf:
            if rel.startswith('mods/') and rel.endswith('.jar'):
                src.copy('performance/' + rel, os.path.join(pm, rel[len('mods/'):]))

    step('Mods synchroniseren...')
    mods_dir = os.path.join(game, 'mods')
    os.makedirs(mods_dir, exist_ok=True)
    backup_dir = os.path.join(game, 'mods-backup', datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
    want = {n: v for n, v in src.files_cache('mods').items() if n.endswith('.jar') and '/' not in n}
    have = jars(mods_dir)

    def backup(name):
        os.makedirs(backup_dir, exist_ok=True)
        os.replace(os.path.join(mods_dir, name), os.path.join(backup_dir, name))

    added = updated = removed = same = 0
    for n in have:
        if n not in want:
            backup(n)
            removed += 1
    for n, (size, _) in want.items():
        p = os.path.join(mods_dir, n)
        if os.path.exists(p):
            if os.path.getsize(p) == size and crc32_file(p) == src.crc('mods', n):
                same += 1
                continue
            backup(n)
            updated += 1
        else:
            added += 1
        src.copy('mods/' + n, p)

    # 6. Gedeelde bestanden (KubeJS-items + textures)
    for rel in src.files('shared'):
        if '..' not in rel.split('/'):
            src.copy('shared/' + rel, os.path.join(game, *rel.split('/')))

    # 6b. Modus toepassen
    if mode == 'performance':
        step('Performance-modus toepassen...')
        apply_perf_mods(game)
        if prev_mode != 'performance':   # eigen bijregelingen niet elke update overschrijven
            apply_perf_options(game)
    elif prev_mode == 'performance':
        step('Terug naar normale modus...')
        restore_options(game)
    set_mode_marker(game, mode)
    register_install(args.installs_file, game)

    # 7. Server in de serverlijst
    sd = os.path.join(game, 'servers.dat')
    if not os.path.exists(sd):
        with open(sd, 'wb') as f:
            f.write(servers_dat(pack['name'], pack['server']))
        print(f"    Server '{pack['name']}' toegevoegd aan je serverlijst.")

    # Klaar
    print()
    good('Klaar!')
    print(f'  Mods: {len(want)}  (nieuw {added}, bijgewerkt {updated}, ongewijzigd {same}, weggehaald {removed})')
    if removed + updated:
        print(f'  Oude mods staan in: {backup_dir}')
    if mode == 'performance':
        print("  Modus: PERFORMANCE (uitzetten: 'Performance uit')")
    else:
        print("  Modus: normaal (laptop? 'Performance aan')")
    print({'official': "  Open de Minecraft Launcher, kies het profiel 'Homestead School' en druk op Spelen.",
           'prism': "  Open Prism Launcher en start de instance 'Homestead School'.",
           'folder': f"  Start je instance (Minecraft {pack['minecraft']} + Fabric {pack['fabricLoader']})."}[launcher])
    print(f"  De eerste keer opstarten duurt een paar minuten. Join daarna '{pack['name']}' in Multiplayer.")


def main():
    p = argparse.ArgumentParser(description='Homestead School installer (Linux / macOS)')
    p.add_argument('legacy_path', nargs='?', help=argparse.SUPPRESS)   # oude install.sh: pad als eerste argument
    p.add_argument('--launcher', choices=['official', 'prism', 'folder'])
    p.add_argument('--instance-path')
    p.add_argument('--mode', choices=['normal', 'performance'])
    p.add_argument('--set-mode', choices=['normal', 'performance'])
    p.add_argument('--installs-file', default=DEF_INSTALLS)
    # --- voor testen / gevorderden ---
    p.add_argument('--minecraft-dir', default=DEF_MINECRAFT)
    p.add_argument('--prism-dir')
    p.add_argument('--official-game-dir', default=DEF_GAME)
    p.add_argument('--source-dir', help='lokale repo-map i.p.v. downloaden')
    p.add_argument('--repo-zip', help='lokale GitHub-zip van de repo i.p.v. downloaden')
    p.add_argument('--pack-zip', help='lokale Homestead-zip i.p.v. downloaden')
    p.add_argument('--work-dir', default=DEF_WORK)
    p.add_argument('--pause', action='store_true', help='op Enter wachten op het einde (dubbelklik-bestanden)')
    args = p.parse_args()
    if args.legacy_path and not args.instance_path:
        args.instance_path = args.legacy_path

    print()
    good('  Homestead School installer')
    print()
    code = 0
    work = None
    try:
        if args.set_mode:
            switch_mode(args)
        else:
            os.makedirs(args.work_dir, exist_ok=True)
            work = tempfile.mkdtemp(prefix='run-', dir=args.work_dir)
            install(args, work)
    except Quit as q:
        code = q.code
    except KeyboardInterrupt:
        print()
        warn('Gestopt.')
        code = 130
    except Exception as e:
        print()
        print(f'{RED}Er ging iets mis: {e}{RESET}')
        print('Maak een screenshot van dit venster en stuur het naar de beheerder.')
        code = 1
    finally:
        if work:
            shutil.rmtree(work, ignore_errors=True)
    if args.pause:
        wait_enter('\nDruk op Enter om af te sluiten')
    return code


if __name__ == '__main__':
    sys.exit(main())
