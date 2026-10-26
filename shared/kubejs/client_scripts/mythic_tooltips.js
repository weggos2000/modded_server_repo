// Mythic Upgrades heeft zelf geen uitleg in de tooltip; hier staat per edelsteen wat wapens/tools en armor doen.
// Waarden komen uit config/mythicupgrades.json op de server. Armor: hoe meer stukken van dezelfde steen, hoe sterker.

const MYTHIC_TOOLS = 'sword|axe|pickaxe|shovel|hoe'
const MYTHIC_ARMOR = 'helmet|chestplate|leggings|boots'

const MYTHIC_INFO = {
  ruby:       { tool: 'Haste: je mijnt sneller',                              armor: 'Spelunker: je ziet ertsen door muren' },
  sapphire:   { tool: 'Extra schade als % van het leven van je doelwit',      armor: 'Damage Deflection: kaatst schade terug' },
  topaz:      { tool: 'Zet je doelwit in brand',                              armor: 'Item Mastery + Topaz Reaction (schokken)' },
  aquamarine: { tool: 'Bevriest je doelwit even',                             armor: 'Ice Shield: beschermend ijsschild' },
  peridot:    { tool: 'Vergiftigt je doelwit',                                armor: 'Giftige thorns: aanvallers worden vergiftigd' },
  ametrine:   { tool: 'Laat je doelwit zweven, soms teleporteert het weg',    armor: 'Arcane Aura: vijanden rond jou gaan zweven' },
  jade:       { tool: 'Laat je doelwit wegstuiteren',                         armor: 'Speed en Jump Boost' },
  citrine:    { tool: 'Kettingbliksem: raakt ook vijanden in de buurt',       armor: 'Static Field: elektrisch veld, trekt bliksem aan' }
}

ItemEvents.tooltip(event => {
  Object.keys(MYTHIC_INFO).forEach(gem => {
    const info = MYTHIC_INFO[gem]
    event.add(new RegExp(`^mythicupgrades:${gem}_(${MYTHIC_TOOLS})$`), Text.gold(`✦ ${info.tool}`))
    event.add(new RegExp(`^mythicupgrades:${gem}_(${MYTHIC_ARMOR})$`), [
      Text.gold(`✦ ${info.armor}`),
      Text.gray('Meer stukken van dezelfde steen = sterker effect')
    ])
    event.add(`mythicupgrades:${gem}_ingot`, Text.gray(`Upgrade netherite met een Smithing Template. Wapens: ${info.tool.toLowerCase()}. Armor: ${info.armor.toLowerCase()}.`))
  })
  event.add('mythicupgrades:necoium_carrot', Text.gold('✦ Necoium Share: deelt je Mythic-effecten met spelers in de buurt'))
})
