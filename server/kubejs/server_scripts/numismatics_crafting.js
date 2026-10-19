// Homestead School - craftbare Numismatics-munten
// Zoals de Forge-mod "Create: Numismatics Crafting" (bestaat niet voor Fabric):
//   1. Mechanical Press boven een Basin (Create Compacting)  -> unpolished munt
//   2. Wassen met een Encased Fan door water (Create Splashing) -> echte munt
// De unpolished items komen uit kubejs/startup_scripts/numismatics_unpolished.js
ServerEvents.recipes(event => {
    const coin = (name, ingredients) => {
        event.custom({
            type: 'create:compacting',
            ingredients: ingredients,
            results: [{ item: `kubejs:unpolished_${name}`, count: 1 }]
        }).id(`homestead_school:numismatics/press_${name}`)

        event.custom({
            type: 'create:splashing',
            ingredients: [{ item: `kubejs:unpolished_${name}` }],
            results: [{ item: `numismatics:${name}`, count: 1 }]
        }).id(`homestead_school:numismatics/polish_${name}`)
    }

    coin('spur',     [{ tag: 'c:copper_nuggets' },       { item: 'create:cogwheel' }])
    coin('bevel',    [{ item: 'create:crushed_raw_zinc' }, { item: 'create:cogwheel' }])
    coin('sprocket', [{ tag: 'c:iron_plates' },          { item: 'create:large_cogwheel' }])
    coin('cog',      [{ item: 'create:large_cogwheel' }, { tag: 'c:brass_ingots' }])
    coin('crown',    [{ item: 'create:large_cogwheel' }, { item: 'minecraft:gold_block' }])
    coin('sun',      [{ item: 'create:large_cogwheel' }, { item: 'numismatics:crown' }, { item: 'createdeco:netherite_sheet' }])
})
