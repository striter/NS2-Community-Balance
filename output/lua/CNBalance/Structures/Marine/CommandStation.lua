
Script.Load("lua/CNBalance/Mixin/SupplyProviderMixin.lua")
local baseOnInitialized = CommandStation.OnInitialized
function CommandStation:OnInitialized()
    baseOnInitialized(self)
    if Server then
        InitMixin(self, SupplyProviderMixin)
    end
end


kResearchToStationType =
{
    [kTechId.StandardSupply] = kTechId.StandardStation,
    [kTechId.ExplosiveSupply] = kTechId.ExplosiveStation,
    [kTechId.ArmorSupply] = kTechId.ArmorStation,
    [kTechId.ElectronicSupply] = kTechId.ElectronicStation,
}

local function GetSupplyResearchAllowed(self, techId)
    local stationTypeTechId = kResearchToStationType[techId]
    return not GetHasTech(self, stationTypeTechId) and not GetIsTechResearching(self, techId)
end

function CommandStation:GetTechButtons()

    local techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    local techId = self:GetTechId()
    if techId == kTechId.CommandStation then
        techButtons[1] = ConditionalValue(GetSupplyResearchAllowed(self,kTechId.StandardSupply),kTechId.StandardSupply,kTechId.None)
        techButtons[2] = ConditionalValue(GetSupplyResearchAllowed(self,kTechId.ArmorSupply),kTechId.ArmorSupply,kTechId.None)
        techButtons[3] = ConditionalValue(GetSupplyResearchAllowed(self,kTechId.ElectronicSupply),kTechId.ElectronicSupply,kTechId.None)
        --techButtons[4] = ConditionalValue(GetSupplyResearchAllowed(self,kTechId.ExplosiveSupply),kTechId.ExplosiveSupply,kTechId.None)
    elseif techId == kTechId.ElectronicStation then
        techButtons[1] = kTechId.MACEMPBlast
    elseif techId == kTechId.StandardStation then
        techButtons[1] = kTechId.DragonBreath
        techButtons[2] = kTechId.LightMachineGunUpgrade
    elseif techId == kTechId.ArmorStation then
        techButtons[1] = kTechId.LifeSustain
        techButtons[2] = kTechId.ArmorRegen
    end
    techButtons[4] = kTechId.MilitaryProtocol
    
    return techButtons
end

function CommandStation:OnResearchComplete(researchId)
    if researchId == kTechId.ExplosiveSupply then
        self:UpgradeToTechId(kTechId.ExplosiveStation)
    elseif researchId == kTechId.StandardSupply then
        self:UpgradeToTechId(kTechId.StandardStation)
    elseif researchId == kTechId.ArmorSupply then
        self:UpgradeToTechId(kTechId.ArmorStation)
    elseif researchId == kTechId.ElectronicSupply then
        self:UpgradeToTechId(kTechId.ElectronicStation)
    end
end

class 'StandardStation' (CommandStation)
StandardStation.kMapName = "standard_station"
--Shared.LinkClassToMap("StandardStation", StandardStation.kMapName, { })
--
class 'ExplosiveStation' (CommandStation)
ExplosiveStation.kMapName = "explosive_station"
--Shared.LinkClassToMap("ExplosiveStation",ExplosiveStation.kMapName , { })
--
class 'ArmorStation' (CommandStation)
ArmorStation.kMapName = "armor_station"
--Shared.LinkClassToMap("ExplosiveStation",ArmorStation.kMapName , { })
class 'ElectronicStation' (CommandStation)
ElectronicStation.kMapName = "electronic_station"
