Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = CommandStation.OnCreate
function CommandStation:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function CommandStation:GetHealthPerTeamExceed()
    return kCommandStationHealthPerPlayerAdd
end

Script.Load("lua/CNBalance/Mixin/SupplyProviderMixin.lua")
local baseOnInitialized = CommandStation.OnInitialized
function CommandStation:OnInitialized()
    baseOnInitialized(self)
    if Server then
        InitMixin(self, SupplyProviderMixin)
    end
end

CommandStation.kResearchToStationType =
{
    [kTechId.StandardSupply] = kTechId.StandardStation,
    [kTechId.ExplosiveSupply] = kTechId.ExplosiveStation,
    [kTechId.ArmorSupply] = kTechId.ArmorStation,
    [kTechId.ElectronicSupply] = kTechId.ElectronicStation,
}

local function GetSupplyResearchAllowed(self, techId)
    local stationTypeTechId = CommandStation.kResearchToStationType[techId]
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

function CommandStation:OnResearchComplete(researchId)
    local upgradeTech = CommandStation.kResearchToStationType[researchId]
    if upgradeTech then
        self:UpgradeToTechId(upgradeTech)
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