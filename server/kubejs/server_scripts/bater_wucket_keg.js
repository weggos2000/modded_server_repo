// Homestead School - de Bater Wucket (Things, oneindige emmer water) werkt ook op de AlcoCraft+-keg.
// De keg accepteert hardgecodeerd alleen een gewone emmer water. Dit doet hetzelfde als die emmer
// (+10 water, alleen als de keg op 30 of minder staat en er geen bier in zit), maar de Bater Wucket blijft vol.
BlockEvents.rightClicked('alcocraftplus:keg', event => {
    if (String(event.item.id) !== 'things:bater_wucket') return   // id is een Java-string

    const keg = event.block.entity
    if (!keg) return

    // zelfde voorwaarden als de keg zelf voor een emmer water
    if (keg.waterLevel > keg.maxWaterLevel - 10 || keg.beerLevel !== 0) {
        event.cancel()   // niet de GUI openen, gewoon niets doen (keg vol of bier erin)
        return
    }

    keg.waterLevel += 10
    keg.setChanged()

    const b = event.block
    // geluid via commando: level.playSound() is dubbelzinnig (meerdere Java-overloads) voor KubeJS
    event.server.runCommandSilent(`execute in ${event.level.dimension} run playsound minecraft:item.bucket.empty block @a ${b.x + 0.5} ${b.y + 0.5} ${b.z + 0.5}`)
    event.level.sendBlockUpdated(b.pos, b.blockState, b.blockState, 3)

    event.cancel()
})
