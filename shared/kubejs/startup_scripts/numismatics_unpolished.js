// Homestead School - "unpolished" Numismatics-munten (zoals Create: Numismatics Crafting, dat alleen voor Forge bestaat)
// Moet op de client EN de server staan. Textures: kubejs/assets/kubejs/textures/item/unpolished_<munt>.png
StartupEvents.registry('item', event => {
    const coins = [
        ['spur', 'Spur'],
        ['bevel', 'Bevel'],
        ['sprocket', 'Sprocket'],
        ['cog', 'Cog'],
        ['crown', 'Crown'],
        ['sun', 'Sun']
    ]
    coins.forEach(([id, name]) => {
        event.create(`unpolished_${id}`).displayName(`Unpolished ${name}`)
    })
})
