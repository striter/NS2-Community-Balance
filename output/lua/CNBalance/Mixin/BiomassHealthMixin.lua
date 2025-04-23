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
    GetExtraHealth = "Return health gain per team's biomassMixin"
}

BiomassHealthMixin.expectedMixins = {
    Live = "Required to addjust max health"
}

function BiomassHealthMixin:__initmixin()
    PROFILE("BiomassHealthMixin:__initmixin")

    if Server then
        self.extraHealth = 0
    end
end

if Server then

    function BiomassHealthMixin:OnTeamChange()
        local team = self:GetTeam()
        local _techLevel = 0
        local playerAboveLimit = 0
        if team then
            _techLevel = team.GetBioMassLevel and team:GetBioMassLevel() or 0
            playerAboveLimit = team.GetTeamType and GetPlayersAboveLimit(team:GetTeamType()) or 0
        end
        self:UpdateHealthAmount(playerAboveLimit, _techLevel)
    end

    function BiomassHealthMixin:UpdateHealthAmount(playersAboveLimit, _techLevel)

        _techLevel = Clamp(_techLevel - 1,0,kMaxBiomassHealthMultiplyLevel)
        local recentWins = GetTeamInfoEntity(kAlienTeamType).recentWins
        local newExtraHealth = self.GetExtraHealth and self:GetExtraHealth(_techLevel,playersAboveLimit,recentWins) or 0
        
        if newExtraHealth == 0 then return end
        
        newExtraHealth = math.floor(newExtraHealth)
        newExtraHealth = math.min(newExtraHealth,3000)  --Clamp it due to hive max health greater than expected limit (?)

        if newExtraHealth ~= self.extraHealth  then
            -- maxHealth is a integer
            local healthDelta = math.round(newExtraHealth - self.extraHealth)
            self:AdjustMaxHealth(math.max(self:GetMaxHealth() + healthDelta,200))
            self.extraHealth = newExtraHealth
        end
    end

    function BiomassHealthMixin:GetAdditionalHealth()
        return self.extraHealth
    end
    
end