
if Server then

    function EMPBlast:Perform()

        self:TriggerEffects("comm_powersurge", { effecthostcoords = self:GetCoords() }) --TODO Refactor CommanderAbility to use EffectsManager, update this called event once done (add sound)

        local damage = kPowerSurgeEMPDamage * NS2Gamerules_GetUpgradedDamageScalar( self:GetOwner(), kTechId.PowerSurge )
        for _, alien in ipairs(GetEntitiesForTeamWithinRange("Alien", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kPowerSurgeEMPDamageRadius)) do
            self:DoDamage(damage, alien, alien:GetOrigin(), GetNormalizedVector(alien:GetOrigin() - self:GetOrigin()), "none")
            --alien:SetElectrified(kPowerSurgeEMPElectrifiedDuration)
            alien:TriggerEffects("emp_blasted")
        end

    end

end
