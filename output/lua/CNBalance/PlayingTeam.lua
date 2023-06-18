
local baseInitialized = PlayingTeam.Initialize
function PlayingTeam:Initialize(teamName, teamNumber)
    self.maxSupply = kStartSupply
    baseInitialized(self,teamName,teamNumber)
end

local baseOnInitialized = PlayingTeam.OnInitialized
function PlayingTeam:OnInitialized()
    self.maxSupply = kStartSupply
    baseOnInitialized(self)
end

function PlayingTeam:GetSupplyUsed()
    return Clamp(self.supplyUsed, 0, self:GetMaxSupply())
end

function PlayingTeam:GetMaxSupply()
    return self.maxSupply
end

function PlayingTeam:AddMaxSupply(supplyIncrease)
    self.maxSupply = self.maxSupply + supplyIncrease
end

function PlayingTeam:RemoveMaxSupply(supplyDecrease)
    self.maxSupply = self.maxSupply - supplyDecrease
end

function PlayingTeam:AddSupplyUsed(supplyUsed)
    self.supplyUsed = self.supplyUsed + supplyUsed
end

function PlayingTeam:RemoveSupplyUsed(supplyUsed)
    self.supplyUsed = self.supplyUsed - supplyUsed
end

local oldGetIsResearchRelevant = debug.getupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant")

local relevantResearchIds
local function extGetIsResearchRelevant(techId)

    if not relevantResearchIds then
        relevantResearchIds = {}

        relevantResearchIds[kTechId.GrenadeLauncherUpgrade] = 2
        
        relevantResearchIds[kTechId.StandardSupply] = 1
        relevantResearchIds[kTechId.LightMachineGunUpgrade] = 2
        relevantResearchIds[kTechId.DragonBreath] = 2
        relevantResearchIds[kTechId.CannonTech] = 2

        --relevantResearchIds[kTechId.ExplosiveSupply] = 1
        --relevantResearchIds[kTechId.GrenadeLauncherDetectionShot] = 2
        --relevantResearchIds[kTechId.GrenadeLauncherAllyBlast] = 2

        relevantResearchIds[kTechId.ElectronicSupply] = 1
        relevantResearchIds[kTechId.ElectronicStation] = 1
        relevantResearchIds[kTechId.MACEMPBlast] = 2
        relevantResearchIds[kTechId.PoweredExtractorTech] = 2

        relevantResearchIds[kTechId.ArmorSupply] = 1
        relevantResearchIds[kTechId.MinesUpgrade] = 2
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
