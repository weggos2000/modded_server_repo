// Homestead School - commando's van FTB Essentials beperken.
// FTB Essentials kan een commando alleen voor iedereen aan/uit zetten (rechten per speler kan pas met FTB Ranks),
// dus hier blokkeren we ze. De console en command blocks mogen alles.
//   OP_ONLY_COMMANDS:  alleen OPs
//   DISABLED_COMMANDS: niemand (homes staan ook uit in world/serverconfig/ftbessentials.snbt, home.enabled = false;
//                      dat haalt ze pas na een herstart helemaal weg, dit script blokkeert ze meteen)
const OP_ONLY_COMMANDS = ['spawn', 'tpa', 'tpahere']
const DISABLED_COMMANDS = ['home', 'homes', 'sethome', 'delhome', 'listhomes']

ServerEvents.command(event => {
    const name = String(event.commandName)   // Java-string -> JS-string, anders werkt includes() niet
    const disabled = DISABLED_COMMANDS.includes(name)
    if (!disabled && !OP_ONLY_COMMANDS.includes(name)) return

    const player = event.parseResults.context.source.player
    if (!player) return
    if (disabled) {
        player.tell(Text.red(`/${name} staat uit op deze server.`))
    } else {
        if (player.isOp()) return
        player.tell(Text.red(`/${name} is alleen voor beheerders.`))
    }
    event.cancel()
})
