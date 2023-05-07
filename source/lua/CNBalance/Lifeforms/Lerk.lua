Lerk.kAdrenalineEnergyRecuperationRate = 18.0
Lerk.kDamageReductionTable = {
    ["Shotgun"] = 0.9,
    ["Railgun"] = 0.8,
    ["Cannon"] = 0.8,
    ["Grenade"] = 0.75,
    ["PulseGrenade"] = 0.75,
    ["ImpactGrenade"] = 0.75,
}

function Lerk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
        local reduction = Lerk.kDamageReductionTable[doer:GetClassName()]
        if reduction then
            damageTable.damage = damageTable.damage * reduction
        end
end
