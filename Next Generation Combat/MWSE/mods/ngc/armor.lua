local this = {
    playerArmorClass = nil,
    npcArmorClasses = {},
    shieldBonusRefs = {},
}

local common = require("ngc.common")

local nextTimestamp
local timestampOffset = 3 / 100 -- every 3 seconds
local lastPosition

local function getClassOfArmor(target)
    local heavyPieces = 0
    local mediumPieces = 0
    local lightPieces = 0

    for _, slot in pairs(tes3.armorSlot) do
        local equippedSlot = tes3.getEquippedItem({ actor = target, objectType = tes3.objectType.armor, slot = slot })
        if equippedSlot then
            if equippedSlot.object.weightClass == 0 then
                lightPieces = lightPieces + 1
            elseif equippedSlot.object.weightClass == 1 then
                mediumPieces = mediumPieces + 1
            elseif equippedSlot.object.weightClass == 2 then
                heavyPieces = heavyPieces + 1
            end
        end
    end

    if heavyPieces >= common.config.armorPerks.armorMinPieces then
        return "heavy"
    elseif mediumPieces >= common.config.armorPerks.armorMinPieces then
        return "medium"
    elseif lightPieces >= common.config.armorPerks.armorMinPieces then
        return "light"
    elseif lightPieces == 0 and mediumPieces == 0 and heavyPieces == 0 then
        return "unarmored"
    else
        return
    end
end

function this.determinePlayerArmorClass(e)
    this.playerArmorClass = getClassOfArmor(tes3.player)
end

function this.determineNPCArmorClasses(e)
    this.npcArmorClasses[e.reference.id] = getClassOfArmor(e.reference)
end

function this.simulate(e)
    if nextTimestamp == nil then
        lastPosition = tes3.mobilePlayer.position:copy()
        nextTimestamp = e.timestamp + timestampOffset
        return
    end
    if e.timestamp > nextTimestamp then
        local distanceFromLastVector = tes3.mobilePlayer.position:distance(lastPosition)
        if (tes3.mobilePlayer.isRunning and distanceFromLastVector > 600) then
            this.playerArmorClass = getClassOfArmor(tes3.player)
            if common.config.showDebugMessages then
                tes3.messageBox(this.playerArmorClass)
            end
            local skillId

            if this.playerArmorClass == "heavy" then
                local armorSkill = tes3.mobilePlayer.heavyArmor.current
                if armorSkill >= common.config.armorPerks.apprenticeSkillMin then
                    skillId = tes3.skill.heavyArmor
                end
            elseif this.playerArmorClass == "medium" then
                local armorSkill = tes3.mobilePlayer.mediumArmor.current
                if armorSkill >= common.config.armorPerks.apprenticeSkillMin then
                    skillId = tes3.skill.mediumArmor
                end
            elseif this.playerArmorClass == "light" then
                local armorSkill = tes3.mobilePlayer.lightArmor.current
                if armorSkill >= common.config.armorPerks.apprenticeSkillMin then
                    skillId = tes3.skill.lightArmor
                end
            elseif this.playerArmorClass == "unarmored" then
                local armorSkill = tes3.mobilePlayer.unarmored.current
                if armorSkill >= common.config.armorPerks.apprenticeSkillMin then
                    skillId = tes3.skill.unarmored
                end
            end

            if skillId then
                tes3.mobilePlayer:exerciseSkill(skillId, 0.05)
                if common.config.showDebugMessages then
                    tes3.messageBox("Triggering experience for: " .. this.playerArmorClass)
                end
            end
        end

        lastPosition = tes3.mobilePlayer.position:copy()
        nextTimestamp = e.timestamp + timestampOffset
    end
end

local function unarmoredShieldBonus(armorSkill)
    if armorSkill >= common.config.armorPerks.journeymanSkillMin then
        return common.config.armorPerks.unarmoredShieldBonusMod
    end
end

function this.unarmoredShieldBonusCalc(e)
    if e.effectId == tes3.effect.shield then
        local uid = e.sourceInstance.serialNumber
        if this.shieldBonusRefs[uid] == nil and e.effectInstance.timeActive > 0 then
            this.shieldBonusRefs[uid] = true
            if e.target == tes3.player then
                this.playerArmorClass = getClassOfArmor(tes3.player)
                if common.config.showDebugMessages then
                    tes3.messageBox(this.playerArmorClass)
                end
                if this.playerArmorClass == "unarmored" then
                    local armorSkill = tes3.mobilePlayer.unarmored.current
                    local unarmoredShieldMod = unarmoredShieldBonus(armorSkill)
                    if unarmoredShieldMod then
                        e.effectInstance.magnitude = e.effectInstance.magnitude * (1 + unarmoredShieldMod)
                    end
                end
            else
                if this.npcArmorClasses[e.target.id] then
                    if this.npcArmorClasses[e.target.id] == "unarmored" then
                        local armorSkill = tes3.mobilePlayer.unarmored.current
                        if armorSkill then
                            local unarmoredShieldMod = unarmoredShieldBonus(armorSkill)
                            if unarmoredShieldMod then
                                e.effectInstance.magnitude = e.effectInstance.magnitude * (1 + unarmoredShieldMod)
                            end
                        end
                    end
                end
            end
        end
        if this.shieldBonusRefs[uid] and e.sourceInstance.state == 6 then
            -- clean up on expired state
            this.shieldBonusRefs[uid] = nil
        end
    end
end

return this