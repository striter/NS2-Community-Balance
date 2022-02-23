Skulk.kAdrenalineEnergyRecuperationRate = 30

Skulk.kGrenadeDamageReduction = 0.7

function Skulk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

        local className = string.lower(doer:GetClassName())
        if className == "grenade" or className == "impactgrenade" then
            damageTable.damage = damageTable.damage * Skulk.kGrenadeDamageReduction
        end
end
