// Mythic Upgrades heeft zelf geen uitleg in de tooltip; hier staan de officiële beschrijvingen
// (Modrinth-pagina van Mythic Upgrades) bij wapens/tools, armor en ingots.

const MYTHIC_TOOLS = 'sword|axe|pickaxe|shovel|hoe'
const MYTHIC_ARMOR = 'helmet|chestplate|leggings|boots'

const MYTHIC_INFO = {
  ruby: {
    tool: 'Ruby tools steal life on hits and regenerate health on uses.',
    armor: 'Blood Thirst: gathers the blood from the environment and heals you.'
  },
  topaz: {
    tool: 'Topaz tools create topaz waves on third interactions.',
    armor: 'Topaz Reaction: creates damage waves as reactions when you get hit.'
  },
  citrine: {
    tool: 'Citrine tools make charged enemies summon lightning bolts upon their death.',
    armor: 'Static Field: creates a sphere field around you and always damages entities around you.'
  },
  peridot: {
    tool: 'Peridot tools apply a lethal incubation on enemies, releasing a wave of poison upon their death.',
    armor: 'Miasma: creates poison waves regularly.'
  },
  jade: {
    tool: 'Jade tools permanently grant Jade Aura whenever you interact.',
    armor: 'Jade Aura: increased speed and jump boost, and leaves behind jade aura traces.'
  },
  aquamarine: {
    tool: 'Aquamarine tools freeze enemies on hits and create freezing waves upon their death.',
    armor: 'Ice Shield: freezes enemies that attack you.'
  },
  sapphire: {
    tool: "Sapphire tools deal additional damage based on enemies' maximum health.",
    armor: 'Damage Deflection: deflects a certain percentage of the damage you take back to your opponent.'
  },
  ametrine: {
    tool: 'Ametrine tools levitate enemies on hits.',
    armor: 'Arcane Aura: creates levitation waves when you get hit.'
  }
}

ItemEvents.tooltip(event => {
  Object.keys(MYTHIC_INFO).forEach(gem => {
    const info = MYTHIC_INFO[gem]
    event.add(new RegExp(`^mythicupgrades:${gem}_(${MYTHIC_TOOLS})$`), Text.gold(info.tool))
    event.add(new RegExp(`^mythicupgrades:${gem}_(${MYTHIC_ARMOR})$`), [
      Text.gold(info.armor),
      Text.gray('More pieces of the same gem = stronger effect.')
    ])
    event.add(`mythicupgrades:${gem}_ingot`, [
      Text.gray('Upgrades netherite gear with a Mythic Upgrade Smithing Template.'),
      Text.gold(`Tools: ${info.tool}`),
      Text.gold(`Armor: ${info.armor}`)
    ])
  })
  event.add('mythicupgrades:necoium_ingot', Text.gray('Necoium is the main material to craft all mythic items.'))
})
