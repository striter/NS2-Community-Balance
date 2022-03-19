Skulk.kAdrenalineEnergyRecuperationRate = 30

Skulk.kGrenadeLauncherDamageReduction = 0.7

function Skulk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

        local className = string.lower(doer:GetClassName())
        if className == "grenade" or className == "impactgrenade" or className == "pulsegrenade" then
            damageTable.damage = damageTable.damage * Skulk.kGrenadeLauncherDamageReduction
            return
        end
end