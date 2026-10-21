// Homestead School - de Bry Ducket: het omgekeerde van de Bater Wucket (Things). Haalt oneindig water weg en blijft leeg.
// Moet op de client EN de server staan. Texture: kubejs/assets/kubejs/textures/item/bry_ducket.png
// (ingekleurde versie van de Bater Wucket-texture uit Things door glisco, MIT-licentie)
// Wat hij doet staat in server_scripts/bry_ducket.js
StartupEvents.registry('item', event => {
    event.create('bry_ducket')
        .displayName('Bry Ducket')
        .maxStackSize(1)
        .tooltip('§7Haalt water weg en blijft altijd leeg')
})
