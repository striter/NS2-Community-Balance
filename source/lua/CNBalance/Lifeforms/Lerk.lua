Lerk.kAdrenalineEnergyRecuperationRate = 18.0
Lerk.kDamageReductionTable = {
    ["grenade"] = 0.8,
    ["pulsegrenade"] = 0.8,
    ["impactgrenade"] = 0.8,
    ["railgun"] = 0.8,
}

function Lerk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

        local className = string.lower(doer:GetClassName())
        local reduction = Lerk.kDamageReductionTable[string.lower(doer:GetClassName())]
        if reduction then
            damageTable.damage = damageTable.damage * reduction
        end
end
