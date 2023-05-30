Skulk.kAdrenalineEnergyRecuperationRate = 30
function Skulk:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

        local reduction = kSkulkDamageReduction[doer:GetClassName()]
        if reduction then
            damageTable.damage = damageTable.damage * reduction
            return
        end
end