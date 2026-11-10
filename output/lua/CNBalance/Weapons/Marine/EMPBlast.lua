
if Server then

    function EMPBlast:Perform()

        self:TriggerEffects("comm_powersurge", { effecthostcoords = self:GetCoords() }) --TODO Refactor CommanderAbility to use EffectsManager, update this called event once done (add sound)

        local baseDamage = kPowerSurgeEMPDamage * NS2Gamerules_GetUpgradedDamageScalar( self:GetOwner(), kTechId.PowerSurge )
        local now = Shared.GetTime()
        local repeatDamageWindow = kEMPBlastRepeatDamageWindow or 0.5
        local repeatDamageScalar = kEMPBlastRepeatDamageScalar or 0.5
        for _, alien in ipairs(GetEntitiesForTeamWithinRange("Alien", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kPowerSurgeEMPDamageRadius)) do

            local damage = baseDamage
            local lastHitTime = alien.empBlastRepeatHitTime
            alien.empBlastRepeatHitTime = now
            if lastHitTime and now - lastHitTime <= repeatDamageWindow then
                damage = damage * repeatDamageScalar
            end

            self:DoDamage(damage, alien, alien:GetOrigin(), GetNormalizedVector(alien:GetOrigin() - self:GetOrigin()), "none")
            alien:SetElectrified(kPowerSurgeEMPElectrifiedDuration)
            alien:TriggerEffects("emp_blasted")
        end

    end

end
