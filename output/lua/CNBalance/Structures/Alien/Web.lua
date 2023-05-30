
function Web:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)

    -- webs can't be destroyed with bullet weapons
    if doer ~= nil and not (doer:isa("Axe") or doer:isa("Knife") or doer:isa("Grenade") or doer:isa("ClusterGrenade") or doer:isa("Flamethrower") or damageType == kDamageType.Flame) then
        damageTable.damage = 0
    end

end
