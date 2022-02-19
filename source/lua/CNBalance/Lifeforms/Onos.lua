function Onos:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

    if hitPoint ~= nil and self:GetIsBoneShieldActive() and self:GetHitsBoneShield(doer, hitPoint) then

        local className = doer:GetClassName()
        local absorb = className ~= "Railgun" and className ~= "Grenade"
        if absorb then
            damageTable.damage = damageTable.damage * kBoneShieldDamageReduction
            --TODO Exclude local player and trigger local-player only effect
            self:TriggerEffects("boneshield_blocked", { effecthostcoords = Coords.GetTranslation(hitPoint) } )
        end
        
    end
end
