// Homestead School - de Bater Wucket (Things, oneindige emmer water) werkt ook op de AlcoCraft+-keg.
// De keg accepteert hardgecodeerd alleen een gewone emmer water. Dit doet hetzelfde als die emmer
// (+10 water, alleen als de keg op 30 of minder staat en er geen bier in zit), maar de Bater Wucket blijft vol.
BlockEvents.rightClicked('alcocraftplus:keg', event => {
    if (event.item.id !== 'things:bater_wucket') return

    const keg = event.block.entity
    if (!keg) return

    // zelfde voorwaarden als de keg zelf voor een emmer water
    if (keg.waterLevel > keg.maxWaterLevel - 10 || keg.beerLevel !== 0) {
        event.cancel()   // niet de GUI openen, gewoon niets doen (keg vol of bier erin)
        return
    }

    keg.waterLevel += 10
    keg.setChanged()

    const level = event.level
    const pos = event.block.pos
    level.playSound(null, pos, 'minecraft:item.bucket.empty', 'blocks', 1.0, 1.0)
    level.sendBlockUpdated(pos, event.block.blockState, event.block.blockState, 3)

    event.cancel()
})
