// Homestead School - craftbare Numismatics-munten
// Zelfde ingrediënten als de Forge-mod "Create: Numismatics Crafting" (die bestaat niet voor Fabric),
// maar de pers (Mechanical Press boven een Basin = Create Compacting) geeft meteen de munt.
ServerEvents.recipes(event => {
    const coin = (name, ingredients) => {
        event.custom({
            type: 'create:compacting',
            ingredients: ingredients,
            results: [{ item: `numismatics:${name}`, count: 1 }]
        }).id(`homestead_school:numismatics/${name}`)
    }

    coin('spur',     [{ tag: 'c:copper_nuggets' },       { item: 'create:cogwheel' }])
    coin('bevel',    [{ item: 'create:crushed_raw_zinc' }, { item: 'create:cogwheel' }])
    coin('sprocket', [{ tag: 'c:iron_plates' },          { item: 'create:large_cogwheel' }])
    coin('cog',      [{ item: 'create:large_cogwheel' }, { tag: 'c:brass_ingots' }])
    coin('crown',    [{ item: 'create:large_cogwheel' }, { item: 'minecraft:gold_block' }])
    coin('sun',      [{ item: 'create:large_cogwheel' }, { item: 'numismatics:crown' }, { item: 'createdeco:netherite_sheet' }])
})
