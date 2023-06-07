Lerk.kAdrenalineEnergyRecuperationRate = 18.0
function Lerk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
        local reduction = kLerkDamageReduction[doer:GetClassName()]
        if reduction then
            damageTable.damage = damageTable.damage * reduction
        end
end

if Server then
    function Lerk:GetTierTwoTechId()
        return kTechId.Spores
    end

    function Lerk:GetTierThreeTechId()
        return kTechId.Umbra
    end
end
