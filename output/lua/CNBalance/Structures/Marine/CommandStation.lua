Script.Load("lua/BiomassHealthMixin.lua")


local baseOnCreate = CommandStation.OnCreate
function CommandStation:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function CommandStation:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kCommandStationHealthPerPlayerAdd * extraPlayers
end

Script.Load("lua/CNBalance/Mixin/SupplyProviderMixin.lua")
local baseOnInitialized = CommandStation.OnInitialized
function CommandStation:OnInitialized()
    baseOnInitialized(self)
    if Server then
        InitMixin(self, SupplyProviderMixin)
    end
end

CommandStation.kUpgradeType = {
    kTechId.StandardSupply,kTechId.ExplosiveSupply,kTechId.ArmorSupply,kTechId.ElectronicSupply
}
CommandStation.kUpgradeToTargetType =
{
    [kTechId.StandardSupply] = kTechId.StandardStation,
    [kTechId.ExplosiveSupply] = kTechId.ExplosiveStation,
    [kTechId.ArmorSupply] = kTechId.ArmorStation,
    [kTechId.ElectronicSupply] = kTechId.ElectronicStation,
}

local function GetSupplyResearchAllowed(self, techId)
    local stationTypeTechId = CommandStation.kUpgradeToTargetType[techId]
    local available = not GetHasTech(self, stationTypeTechId) and not GetIsTechResearching(self, techId)
    return available and techId or kTechId.None
end

function CommandStation:GetTechButtons()

    local techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    local techId = self:GetTechId()
    if techId == kTechId.CommandStation then
        techButtons[1] = GetSupplyResearchAllowed(self,kTechId.StandardSupply)
        techButtons[2] = GetSupplyResearchAllowed(self,kTechId.ArmorSupply)
        techButtons[3] = GetSupplyResearchAllowed(self,kTechId.ElectronicSupply)
        techButtons[4] = GetSupplyResearchAllowed(self,kTechId.ExplosiveSupply)
    elseif techId == kTechId.ElectronicStation then
        techButtons[1] = kTechId.MACEMPBlast
        techButtons[4] = kTechId.PoweredExtractorTech
    elseif techId == kTechId.StandardStation then
        techButtons[1] = kTechId.DragonBreath
        techButtons[4] = kTechId.LightMachineGunUpgrade
    elseif techId == kTechId.ArmorStation then
        techButtons[1] = kTechId.ArmorRegen
        techButtons[4] = kTechId.LifeSustain
    elseif techId == kTechId.ExplosiveStation then
        techButtons[1] = kTechId.GrenadeLauncherUpgrade
        techButtons[4] = kTechId.MinesUpgrade
    end
    
    techButtons[5] = kTechId.MilitaryProtocol
    
    return techButtons
end


if Server then

    function CommandStation:UpdateResearch()

        local researchId = self:GetResearchingId()
        local stationTypeTechId = CommandStation.kUpgradeToTargetType[researchId]

        if stationTypeTechId then

            local techTree = self:GetTeam():GetTechTree()
            local researchNode = techTree:GetTechNode(stationTypeTechId)
            researchNode:SetResearchProgress(self.researchProgress)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))

        end
    end
    
    function CommandStation:OnResearchCancel(researchId)

        local stationTypeTechId = CommandStation.kUpgradeToTargetType[researchId]
        if stationTypeTechId then

            local team = self:GetTeam()
            if team then
                local techTree = team:GetTechTree()
                local researchNode = techTree:GetTechNode(stationTypeTechId)
                if researchNode then
                    researchNode:ClearResearching()
                    techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", 0))
                end
            end
        end
    end

    function CommandStation:OnResearchComplete(researchId)
        local upgradeTech = CommandStation.kUpgradeToTargetType[researchId]
        if upgradeTech then
            self:UpgradeToTechId(upgradeTech)
        end
        local techTree = self:GetTeam():GetTechTree()
        local researchNode = techTree:GetTechNode(upgradeTech)

        if researchNode then
            researchNode:SetResearchProgress(1)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))
            researchNode:SetResearched(true)
        end
    end
    
end

class 'StandardStation' (CommandStation)
StandardStation.kMapName = "standard_station"

class 'ExplosiveStation' (CommandStation)
ExplosiveStation.kMapName = "explosive_station"

class 'ArmorStation' (CommandStation)
ArmorStation.kMapName = "armor_station"

class 'ElectronicStation' (CommandStation)
ElectronicStation.kMapName = "electronic_station"

Shared.RegisterNetworkMessage("SwitchLocalize", {})