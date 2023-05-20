Onos.kBlockDoers =
set {
    "Minigun",
    "Railgun",
    "Pistol",
    "Rifle",
    "HeavyMachineGun",
    "Shotgun",
    "Sentry",
    "PulseGrenade",
    "ClusterFragment",
    "Mine",
    "Claw",
    "Flamethrower",
    "Grenade", -- Grenade Launcher
    "ImpactGrenade",
    "Mine",
    "Revolver",
    "SubMachineGun",
    "LightMachineGun",
    "Cannon",
}

function Onos:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

    if hitPoint ~= nil and self:GetIsBoneShieldActive() and self:GetHitsBoneShield(doer, hitPoint) then

        local className = string.lower(doer:GetClassName())
        local reduction = 0.225
        if className == "railgun" then
            reduction = 0
        end

        if reduction ~= 0 then
            damageTable.damage = damageTable.damage * reduction
            --TODO Exclude local player and trigger local-player only effect
            self:TriggerEffects("boneshield_blocked", { effecthostcoords = Coords.GetTranslation(hitPoint) } )
        end
    end
    
    local reduction = kOnosDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end


Script.Load("lua/Combat/Devour.lua")

function Onos:GetHasMovementSpecial()
    return true
end

if Server then

    function Onos:GetTierOneTechId()
        return kTechId.Devour
    end
    
end

function Onos:CanBeStampeded(ent)
    
    if ent.nextStampede and Shared.GetTime() < ent.nextStampede then
        return false
    end
    
    if not GetAreEnemies(self, ent) or not ent:GetIsAlive() or ent:isa("DevouredPlayer") then
        return false
    end
    
    return true
end