
if Server then

    function EMPBlast:Perform()

        self:TriggerEffects("comm_powersurge", { effecthostcoords = self:GetCoords() }) --TODO Refactor CommanderAbility to use EffectsManager, update this called event once done (add sound)

        local owner = self:GetOwner()
        local scalar = 1
        if owner then
            scalar = NS2Gamerules_GetUpgradedDamageScalar( owner, kTechId.PowerSurge )
        end
        
        for _, alien in ipairs(GetEntitiesForTeamWithinRange("Alien", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kPowerSurgeEMPDamageRadius)) do
            self:DoDamage(kPowerSurgeEMPDamage * scalar, alien, alien:GetOrigin(), GetNormalizedVector(alien:GetOrigin() - self:GetOrigin()), "none")
            alien:SetElectrified(kPowerSurgeEMPElectrifiedDuration)
            alien:TriggerEffects("emp_blasted")
        end

    end

end
