// Homestead School - de Bry Ducket (kubejs:bry_ducket), het omgekeerde van de Bater Wucket: haalt water weg, blijft leeg.
//  - waterbron      -> weg (zoals een emmer, maar de Bry Ducket blijft leeg)
//  - waterlogged blok -> droog
//  - ketel met water  -> lege ketel
//  - AlcoCraft+-keg   -> -10 water (alleen zonder bier erin)
// Het item zelf wordt geregistreerd in startup_scripts/bry_ducket.js (client + server).

// Let op: KubeJS op deze server remapt Minecraft-methodes naar yarn-namen, niet naar Mojang-namen
// (getYRot bestaat hier niet). Daarom vooral KubeJS' eigen functies: rayTrace, getBlock, properties, set, swing.
const BRY_REACH = 5

function bryPlaySound(event, b, sound) {
    event.server.runCommandSilent(`execute in ${event.level.dimension} run playsound ${sound} block @a ${b.x + 0.5} ${b.y + 0.5} ${b.z + 0.5}`)
}

function bryProp(b, key) {
    const v = b.properties.get(key)
    return v == null ? '' : String(v)
}

// b.id is een Java-string: eerst String() ervan maken, anders is === altijd false
function bryCheck(b) {
    const id = String(b.id)
    if (id === 'minecraft:water') return bryProp(b, 'level') === '0' ? 'source' : 'flowing'
    if (bryProp(b, 'waterlogged') === 'true') return 'waterlogged'
    if (id === 'minecraft:water_cauldron') return 'cauldron'
    return null
}

// Eerste blok in de kijkrichting met water dat we weg kunnen halen. Gaat door lucht, gras en stromend water
// (zoals een emmer) tot het eerste vaste blok dat rayTrace zonder water raakt.
function bryFindWater(player, level) {
    // meestal raakt de straal mét water meteen de bron
    const wray = player.rayTrace(BRY_REACH, true)
    if (wray && wray.block) {
        const kind = bryCheck(wray.block)
        if (kind && kind !== 'flowing') return { block: wray.block, kind: kind }
    }
    // stromend water ervoor? Dan stap voor stap verder kijken tot het eerste vaste blok
    const ray = player.rayTrace(BRY_REACH, false)
    if (!ray || ray.hit == null) return null
    const ex = player.x, ey = player.y + 1.62, ez = player.z   // ooghoogte van een staande speler
    const tx = ray.hitX, ty = ray.hitY, tz = ray.hitZ
    const len = Math.sqrt((tx - ex) ** 2 + (ty - ey) ** 2 + (tz - ez) ** 2)
    if (!(len > 0)) return null
    let last = ''
    for (let d = 0; d <= len + 0.05; d += 0.1) {
        const t = Math.min(d, len + 0.05) / len
        const x = Math.floor(ex + (tx - ex) * t)
        const y = Math.floor(ey + (ty - ey) * t)
        const z = Math.floor(ez + (tz - ez) * t)
        const key = `${x},${y},${z}`
        if (key === last) continue
        last = key
        const b = level.getBlock(x, y, z)
        const kind = bryCheck(b)
        if (kind && kind !== 'flowing') return { block: b, kind: kind }
    }
    return null
}

ItemEvents.rightClicked('kubejs:bry_ducket', event => {
    const { player, level } = event
    const hit = bryFindWater(player, level)
    if (!hit) return

    const b = hit.block
    if (hit.kind === 'source') {
        b.set('minecraft:air')
    } else if (hit.kind === 'waterlogged') {
        const props = {}
        b.properties.forEach((k, v) => { props[String(k)] = String(v) })
        props.waterlogged = 'false'
        b.set(String(b.id), props)
    } else {
        b.set('minecraft:cauldron')
    }
    bryPlaySound(event, b, 'minecraft:item.bucket.fill')
    player.swing(event.hand)
    event.cancel()
})

// De keg opent anders zijn GUI, dus die apart (zelfde aanpak als bater_wucket_keg.js)
BlockEvents.rightClicked('alcocraftplus:keg', event => {
    if (String(event.item.id) !== 'kubejs:bry_ducket') return   // id is een Java-string

    const keg = event.block.entity
    if (!keg) return
    event.cancel()   // nooit de GUI openen met de Bry Ducket in de hand
    if (keg.waterLevel <= 0 || keg.beerLevel !== 0) return   // leeg, of er zit bier in

    keg.waterLevel = Math.max(0, keg.waterLevel - 10)
    keg.setChanged()

    const b = event.block
    bryPlaySound(event, b, 'minecraft:item.bucket.fill')
    event.level.sendBlockUpdated(b.pos, b.blockState, b.blockState, 3)
})

// Recept: het omgekeerde van de Bater Wucket (3 emmers water) -> 3 lege emmers met een spons ertussen
ServerEvents.recipes(event => {
    event.shaped('kubejs:bry_ducket', [
        'BSB',
        ' B '
    ], {
        B: 'minecraft:bucket',
        S: 'minecraft:sponge'
    }).id('kubejs:bry_ducket')
})
