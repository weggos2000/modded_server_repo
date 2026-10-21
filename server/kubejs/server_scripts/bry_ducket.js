// Homestead School - de Bry Ducket (kubejs:bry_ducket), het omgekeerde van de Bater Wucket: haalt water weg, blijft leeg.
//  - waterbron      -> weg (zoals een emmer, maar de Bry Ducket blijft leeg)
//  - waterlogged blok -> droog
//  - ketel met water  -> lege ketel
//  - AlcoCraft+-keg   -> -10 water (alleen zonder bier erin)
// Het item zelf wordt geregistreerd in startup_scripts/bry_ducket.js (client + server).

const BRY_REACH = 5

function bryPlaySound(event, b, sound) {
    event.server.runCommandSilent(`execute in ${event.level.dimension} run playsound ${sound} block @a ${b.x + 0.5} ${b.y + 0.5} ${b.z + 0.5}`)
}

// Eerste blok in de kijkrichting met water dat we weg kunnen halen. Gaat door lucht, gras en stromend water
// (zoals een emmer), stopt bij het eerste vaste blok.
function bryFindWater(player, level) {
    const eye = player.getEyePosition()
    const look = player.getLookAngle()
    let last = ''
    for (let d = 0; d <= BRY_REACH; d += 0.1) {
        const x = Math.floor(eye.x() + look.x() * d)
        const y = Math.floor(eye.y() + look.y() * d)
        const z = Math.floor(eye.z() + look.z() * d)
        const key = `${x},${y},${z}`
        if (key === last) continue
        last = key

        const b = level.getBlock(x, y, z)
        const props = b.properties
        if (b.id === 'minecraft:water') {
            if (String(props.level) === '0') return { block: b, kind: 'source' }
            continue   // stromend water: erdoor kijken
        }
        if (String(props.waterlogged) === 'true') return { block: b, kind: 'waterlogged' }
        if (b.id === 'minecraft:water_cauldron') return { block: b, kind: 'cauldron' }
        if (!b.blockState.getCollisionShape(level, b.pos).isEmpty()) return null
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
        Object.keys(b.properties).forEach(k => { props[k] = String(b.properties[k]) })
        props.waterlogged = 'false'
        b.set(b.id, props)
    } else {
        b.set('minecraft:cauldron')
    }
    bryPlaySound(event, b, 'minecraft:item.bucket.fill')
    player.swing(event.hand, true)
    event.cancel()
})

// De keg opent anders zijn GUI, dus die apart (zelfde aanpak als bater_wucket_keg.js)
BlockEvents.rightClicked('alcocraftplus:keg', event => {
    if (event.item.id !== 'kubejs:bry_ducket') return

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
