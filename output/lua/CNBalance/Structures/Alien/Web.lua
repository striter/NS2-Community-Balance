
local kWebDamageTaken = {
    ["Axe"] = true,
    ["Knife"] = true,
    ["Grenade"] = true,
    ["ClusterGrenade"] = true,
    ["ImpactGrenade"] = true,
    ["SubMachineGun"] = true,
    ["LightMachineGun"] = true,
    ["Flamethrower"] = true,
}

function Web:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)
    -- webs can't be destroyed with bullet weapons
    if doer ~= nil and  damageType ~= kDamageType.Flame and not kWebDamageTaken[doer:GetClassName()] then
        damageTable.damage = 0
    end

end
