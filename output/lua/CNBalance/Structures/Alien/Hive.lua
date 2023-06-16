
Script.Load("lua/CNBalance/Mixin/SupplyProviderMixin.lua")
local baseOnInitialized = Hive.OnInitialized
function Hive:OnInitialized()
    baseOnInitialized(self)
    if Server then
        InitMixin(self, SupplyProviderMixin)
    end
end


function Hive:GetTechButtons()

    local techButtons = { kTechId.ShiftHatch, kTechId.None, kTechId.None, kTechId.None, --kTechId.LifeFormMenu,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    local techId = self:GetTechId()
    if techId == kTechId.Hive then
        techButtons[5] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToCragHive), kTechId.UpgradeToCragHive, kTechId.None)
        techButtons[6] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToShadeHive), kTechId.UpgradeToShadeHive, kTechId.None)
        techButtons[7] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToShiftHive), kTechId.UpgradeToShiftHive, kTechId.None)
    elseif techId == kTechId.CragHive then
        techButtons[5] = kTechId.DrifterRegeneration
        techButtons[6] = kTechId.CystCarapace
        techButtons[3] = kTechId.CragTunnel
    elseif techId == kTechId.ShiftHive then
        techButtons[5] = kTechId.DrifterCelerity
        techButtons[6] = kTechId.CystCelerity
        techButtons[3] = kTechId.ShiftTunnel
    elseif techId == kTechId.ShadeHive then
        techButtons[5] = kTechId.DrifterCamouflage
        techButtons[6] = kTechId.CystCamouflage
        techButtons[3] = kTechId.ShadeTunnel
    end
    
    if self.bioMassLevel <= 1 then
        techButtons[2] = kTechId.ResearchBioMassOne
    elseif self.bioMassLevel <= 2 then
        techButtons[2] = kTechId.ResearchBioMassTwo
    elseif self.bioMassLevel <= 3 then
        techButtons[2] = kTechId.ResearchBioMassThree
    end


    return techButtons
    
end

if Server then
    local baseOnResearchComplete = Hive.OnResearchComplete
    function Hive:OnResearchComplete(researchId)
        baseOnResearchComplete(self,researchId)

        if researchId == kTechId.CragTunnel then        --Inform matured tunnel to update armor amount
            for _, tunnel in ipairs(GetEntitiesForTeam("TunnelEntrance", self:GetTeamNumber())) do
                tunnel:UpdateMaturity(true)
            end
        end
    end
end 