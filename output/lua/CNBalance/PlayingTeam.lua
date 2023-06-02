local oldGetIsResearchRelevant = debug.getupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant")

local relevantResearchIds
local function extGetIsResearchRelevant(techId)

    if not relevantResearchIds then
        relevantResearchIds = {}
        
        relevantResearchIds[kTechId.StandardSupply] = 1
        relevantResearchIds[kTechId.LightMachineGunUpgrade] = 2
        relevantResearchIds[kTechId.DragonBreath] = 2
        relevantResearchIds[kTechId.CannonTech] = 2
        
        relevantResearchIds[kTechId.ExplosiveSupply] = 1
        relevantResearchIds[kTechId.MinesUpgrade] = 2
        --relevantResearchIds[kTechId.GrenadeLauncherDetectionShot] = 2
        --relevantResearchIds[kTechId.GrenadeLauncherAllyBlast] = 2
        relevantResearchIds[kTechId.GrenadeLauncherUpgrade] = 2
        relevantResearchIds[kTechId.MACEMPBlast] = 2
        relevantResearchIds[kTechId.PoweredExtractorTech] = 2

        relevantResearchIds[kTechId.ArmorSupply] = 1
        relevantResearchIds[kTechId.LifeSustain] = 2
        relevantResearchIds[kTechId.ArmorRegen] = 2
        relevantResearchIds[kTechId.CombatBuilderTech] = 2
        
        relevantResearchIds[kTechId.Devour] = 1
        relevantResearchIds[kTechId.ShiftTunnel] = 1
        
        relevantResearchIds[kTechId.XenocideFuel] = 1
    end

    local relevant = relevantResearchIds[techId]
    if relevant ~= nil then
        return relevant
    end

    return oldGetIsResearchRelevant(techId)
end
debug.setupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant", extGetIsResearchRelevant)