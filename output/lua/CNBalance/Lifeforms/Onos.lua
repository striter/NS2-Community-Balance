Onos.kBountyThreshold = kBountyClaimMinOnos

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

local kFuelDeductPerHit = 1 / 200
function Onos:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

    local classname = doer:GetClassName()
    if hitPoint ~= nil and self:GetIsBoneShieldActive() and self:GetHitsBoneShield(doer, hitPoint) then
        local reduction = kOnosBoneShieldDamageReduction[classname] or kOnosBoneShieldDefaultReduction
        --TODO Exclude local player and trigger local-player only effect
        if reduction ~= 0 then
            damageTable.damage = damageTable.damage * reduction
            self:TriggerEffects("boneshield_blocked", { effecthostcoords = Coords.GetTranslation(hitPoint) } )

            local boneShield = self:GetActiveWeapon()
            local fuel = boneShield:GetFuel() - kFuelDeductPerHit
            boneShield:SetFuel(fuel)
            if Server then
                if fuel <= 0 then
                    self:TriggerEffects("onos_shield_break")
                end
            end
        end
        return
    end
    
    local reduction = kOnosDamageReduction[classname]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
        return
    end
end


Script.Load("lua/Combat/Devour.lua")

function Onos:GetHasMovementSpecial()
    return true
end

function Onos:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return techLevel * kOnosHealtPerBioMass 
            + extraPlayers * math.max(12.5 - recentWins * 2.5,0)
            - recentWins * 25
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
    
    if not ent:GetIsAlive() or ent:isa("DevouredPlayer") then
        return false
    end

    if ent:isa("Onos") and ent:GetIsCharging() then
        return false
    end
    
    return true
end

function Onos:GetIsDevouring()

    local devourWeapon = self:GetWeapon(Devour.kMapName)
    if devourWeapon then
        return devourWeapon.devouringScalar and devourWeapon.devouringScalar > 0.01
    end
    return false
end

function Onos:GetMaxSpeed(possible)

    if possible then
        return Onos.kMaxSpeed
    end

    local chargeSpeed = Onos.kChargeSpeed
    local normalSpeed = Onos.kMaxSpeed

    if GetHasCarapaceUpgrade(self) then
        local shellLevel = self:GetShellLevel()
        chargeSpeed = chargeSpeed - shellLevel * 0.66
        normalSpeed = normalSpeed - shellLevel * 0.2
    end

    if self:GetIsDevouring() then
        chargeSpeed = chargeSpeed - 2.5
    end
    
    local boneShieldSlowdown = self:GetIsBoneShieldActive() and kBoneShieldMoveFraction or 1
    local chargeExtra = self:GetChargeFraction() * (chargeSpeed - normalSpeed)
    
    return ( normalSpeed + chargeExtra ) * boneShieldSlowdown

end

function Onos:ModifyCelerityBonus( celerityBonus )

    if self:GetIsBoneShieldActive()
        or self:GetIsDevouring() 
    then
        return 0
    end
    

    return celerityBonus * kOnosCeleritySpeedMultiply

end

function Onos:UpdateRumbleSound()

    if Client then

        local rumbleSound = Shared.GetEntity(self.rumbleSoundId)
        local speed = self:GetCrouching() and 0 or self:GetSpeedScalar()
        if rumbleSound then
            rumbleSound:SetParameter("speed",speed , 1)
        end
    end
end

function Onos:GetPlayFootsteps()
    return self:GetVelocityLength() > .75 
            and self:GetIsOnGround() 
            and self:GetIsAlive()
            and not self:GetCrouching()
end



function Onos:GetNearbyStampedeables(origin)
    local players = GetEntitiesWithinRange("Player", origin, Onos.kStampedeCheckRadius)
    local targets = {}

    for i = 1, #players do
        local player = players[i]
        if player ~= self then

            if self:CanBeStampeded(player) then
                table.insert(targets, player)
            end
        end
        
    end

    return targets
end


function Onos:Stampede()
    if not self:GetCanStampede() then return end

    local axis = self:GetViewAngles():GetCoords().zAxis
    local hitAxis = (axis * Vector(1, 0, 1)):GetUnit()
    local chargeExtends = Onos.kChargeExtents

    
    local hitOrigin = self:GetOrigin() + Vector(0, 1, 0) + (hitAxis * chargeExtends.z)
    local stampedables = self:GetNearbyStampedeables(hitOrigin)
    
    local clogs = GetEntitiesWithinRange("Clog", hitOrigin, Onos.kStampedeCheckRadius)
    for _,clog in pairs(clogs) do
        clog:OnKill()
        DestroyEntity(clog)
    end

    if #stampedables < 1 then return end

    local hitboxCoords = Coords.GetLookIn(hitOrigin, hitAxis, Vector(0, 1, 0))
    local invHitboxCoords = hitboxCoords:GetInverse() -- could possibly optimize with Transpose() instead?
    for i = 1, #stampedables do
        local marine = stampedables[i]
        local localSpacePosition = invHitboxCoords:TransformPoint(marine:GetEngagementPoint())
        local extents = marine:GetExtents()

        -- If entity is touching box, impact it.
        if math.abs(localSpacePosition.x) <= chargeExtends.x + extents.x and
                math.abs(localSpacePosition.y) <= chargeExtends.y + extents.y and
                math.abs(localSpacePosition.z) <= chargeExtends.z + extents.z then

            self:Impact(marine)

        end
    end
end