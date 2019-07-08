this = {
    config = {},
    currentlyExposed = {},
    currentlyBleeding = {},
}
local defaultConfig = {
    showMessages = true,
    showDamageNumbers = true,
    multistrikeStrikesNeeded = 3,
    multistrikeBonuseDamageMultiplier = 2,
    criticalStrikeMultiplier = 0.5,
    bleedMultiplier = 0.25,
    weaponTier1 = {
        weaponSkillMin = 25,
        criticalStrikeChance = 10,
        multistrikeDamageMultiplier = 0.1,
        bleedChance = 10,
    },
    weaponTier2 = {
        weaponSkillMin = 50,
        criticalStrikeChance = 20,
        multistrikeBonusChance = 5,
        multistrikeDamageMultiplier = 0.2,
        bleedChance = 20,
        maxBleedStack = 2,
    },
    weaponTier3 = {
        weaponSkillMin = 75,
        criticalStrikeChance = 30,
        multistrikeBonusChance = 10,
        multistrikeDamageMultiplier = 0.35,
        bleedChance = 30,
        maxBleedStack = 3,
    },
    weaponTier4 = {
        weaponSkillMin = 100,
        criticalStrikeChance = 30,
        multistrikeBonusChance = 20,
        multistrikeDamageMultiplier = 0.5,
        bleedChance = 30,
        maxBleedStack = 4,
    },
}

-- Loads the configuration file for use.
function this.loadConfig()
	this.config = defaultConfig

	local configJson = mwse.loadConfig("More Interesting Combat")
	if (configJson ~= nil) then
		this.config = configJson
	end

	mwse.log("[More Interesting Combat] Loaded configuration:")
	mwse.log(json.encode(this.config, { indent = true }))
end


return this