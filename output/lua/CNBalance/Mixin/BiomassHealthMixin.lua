-- ======= Copyright (c) 2003-2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Mixins\BiomassHealthMixin.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

BiomassHealthMixin = CreateMixin( BiomassHealthMixin )
BiomassHealthMixin.type = "BiomassHealth"

BiomassHealthMixin.networkVars =
{
}

BiomassHealthMixin.expectedCallbacks =
{
    GetHealthPerBioMass = "Return health gain per team's biomassMixin"
}

BiomassHealthMixin.expectedMixins = {
    Live = "Required to addjust max health"
}

function BiomassHealthMixin:__initmixin()
    PROFILE("BiomassHealthMixin:__initmixin")

    if Server then
        self.biomassHealth = 0
    end
end

if Server then

    function BiomassHealthMixin:OnTeamChange()
        local team = self:GetTeam()
        local biomassLevel = 0
        local playerAboveLimit = 0
        if team then
            biomassLevel = team.GetBioMassLevel and team:GetBioMassLevel() or 0
            playerAboveLimit = team.GetTeamType and GetPlayersAboveLimit(team:GetTeamType()) or 0
        end
        self:UpdateHealthAmount(playerAboveLimit,biomassLevel)
    end

    function BiomassHealthMixin:UpdateHealthAmount(playersAboveLimit,bioMassLevel)
        local healthPerBiomass = self.GetHealthPerBioMass and self:GetHealthPerBioMass() or 0
        local healthPerPlayerExceed = self.GetHealthPerTeamExceed and self:GetHealthPerTeamExceed() or 0
        
        if healthPerBiomass == 0 and healthPerPlayerExceed == 0 then return end
        
        local level = math.max(0, bioMassLevel - 1)
        local newBiomassHealth = level * healthPerBiomass + playersAboveLimit * healthPerPlayerExceed

        if newBiomassHealth ~= self.biomMassHealth  then
            -- maxHealth is a integer
            local healthDelta = math.round(newBiomassHealth - self.biomassHealth)
            self:AdjustMaxHealth(self:GetMaxHealth() + healthDelta)
            self.biomassHealth = newBiomassHealth
        end
    end

    function BiomassHealthMixin:GetAdditionalHealth()
        return self.biomassHealth
    end
end