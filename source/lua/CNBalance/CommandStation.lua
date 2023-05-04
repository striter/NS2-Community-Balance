kResearchToStationType =
{
    [kTechId.StandardSupply] = kTechId.StandardStation,
    [kTechId.ExplosiveSupply] = kTechId.ExplosiveStation,
    [kTechId.ArmorSupply] = kTechId.ArmorStation,
}

local function GetSupplyResearchAllowed(self, techId)
    local stationTypeTechId = kResearchToStationType[techId]
    return not GetHasTech(self, stationTypeTechId) and not GetIsTechResearching(self, techId)
end

function CommandStation:GetTechButtons()

    local techButtons = { kTechId.ShiftHatch, kTechId.None, kTechId.None, kTechId.LifeFormMenu,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    local techId = self:GetTechId()
    if techId == kTechId.CommandStation then
        techButtons[1] = ConditionalValue(GetSupplyResearchAllowed(self,kTechId.StandardSupply),kTechId.StandardSupply,kTechId.None)
        techButtons[2] = ConditionalValue(GetSupplyResearchAllowed(self,kTechId.ArmorSupply),kTechId.ArmorSupply,kTechId.None)
        techButtons[3] = ConditionalValue(GetSupplyResearchAllowed(self,kTechId.ExplosiveSupply),kTechId.ExplosiveSupply,kTechId.None)
    elseif techId == kTechId.ExplosiveStation then
        techButtons[1] = kTechId.MinesUpgrade
        techButtons[2] = kTechId.GrenadeLauncherDetectionShot
        techButtons[3] = kTechId.GrenadeLauncherAllyBlast
        techButtons[4] = kTechId.GrenadeLauncherUpgrade
    elseif techId == kTechId.StandardStation then
        techButtons[1] = kTechId.LightMachineGunUpgrade
        techButtons[2] = kTechId.DragonBreath
        techButtons[3] = kTechId.CannonTech
    elseif techId == kTechId.ArmorStation then
        techButtons[1] = kTechId.CombatBuilderTech
        techButtons[2] = kTechId.LifeSustain
        techButtons[3] = kTechId.ArmorRegen
    end
    
    return techButtons
end

function CommandStation:OnResearchComplete(researchId)
    if researchId == kTechId.ExplosiveSupply then
        self:UpgradeToTechId(kTechId.ExplosiveStation)
    elseif researchId == kTechId.StandardSupply then
        self:UpgradeToTechId(kTechId.StandardStation)
    elseif researchId == kTechId.ArmorSupply then
        self:UpgradeToTechId(kTechId.ArmorStation)
    end
end

class 'StandardStation' (CommandStation)
StandardStation.kMapName = "standard_station"
Shared.LinkClassToMap("StandardStation", StandardStation.kMapName, { })

class 'ExplosiveStation' (CommandStation)
ExplosiveStation.kMapName = "explosive_station"
Shared.LinkClassToMap("ExplosiveStation",ExplosiveStation.kMapName , { })

class 'ArmorStation' (CommandStation)
ArmorStation.kMapName = "armor_station"
Shared.LinkClassToMap("ExplosiveStation",ArmorStation.kMapName , { })
