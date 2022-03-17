
function Hive:GetTechButtons()

    local techButtons = { kTechId.ShiftHatch, kTechId.None, kTechId.None, kTechId.LifeFormMenu,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    local techId = self:GetTechId()
    if techId == kTechId.Hive then
        techButtons[5] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToCragHive), kTechId.UpgradeToCragHive, kTechId.None)
        techButtons[6] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToShadeHive), kTechId.UpgradeToShadeHive, kTechId.None)
        techButtons[7] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToShiftHive), kTechId.UpgradeToShiftHive, kTechId.None)
    elseif techId == kTechId.CragHive then
        techButtons[5] = kTechId.DrifterRegeneration
        techButtons[6] = kTechId.CystCarapace
    elseif techId == kTechId.ShiftHive then
        techButtons[5] = kTechId.DrifterCelerity
        techButtons[6] = kTechId.CystCelerity
    elseif techId == kTechId.ShadeHive then
        techButtons[5] = kTechId.DrifterCamouflage
        techButtons[6] = kTechId.CystCamouflage
    end
    
    if self.bioMassLevel <= 1 then
        techButtons[2] = kTechId.ResearchBioMassOne
    elseif self.bioMassLevel <= 2 then
        techButtons[2] = kTechId.ResearchBioMassTwo
    elseif self.bioMassLevel <= 3 then
        techButtons[2] = kTechId.ResearchBioMassThree
    end
    
    techButtons[3] = kTechId.FastTunnel

    return techButtons
    
end
