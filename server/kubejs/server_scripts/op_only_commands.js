// Homestead School - /spawn en /tpa (FTB Essentials) alleen voor OPs.
// FTB Essentials kan een commando alleen voor iedereen aan/uit zetten (rechten per speler kan pas met FTB Ranks),
// dus hier blokkeren we ze voor gewone spelers. De console en command blocks mogen alles.
const OP_ONLY_COMMANDS = ['spawn', 'tpa', 'tpahere']

ServerEvents.command(event => {
    const name = String(event.commandName)   // Java-string -> JS-string, anders werkt includes() niet
    if (!OP_ONLY_COMMANDS.includes(name)) return

    const player = event.parseResults.context.source.player
    if (!player || player.isOp()) return

    player.tell(Text.red(`/${name} is alleen voor beheerders.`))
    event.cancel()
})
