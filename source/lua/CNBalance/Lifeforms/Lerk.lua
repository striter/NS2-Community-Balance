Lerk.kAdrenalineEnergyRecuperationRate = 18.0

Lerk.kGrenadeDamageReduction = 0.8

function Lerk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

        local className = string.lower(doer:GetClassName())

        if className == "grenade" or className == "impactgrenade" then
            damageTable.damage = damageTable.damage * Lerk.kGrenadeDamageReduction
        end
        
end
