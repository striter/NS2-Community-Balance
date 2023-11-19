
function GrenadeLauncher:GetCatalystSpeedBase()
    local speed=1   
    if GetHasTech(self,kTechId.GrenadeLauncherUpgrade)  then
        speed =1.33
    end
    return speed
end


GrenadeLauncher.kLauncherBarrelDist = 1.5

GrenadeLauncher.kGrenadeSpeed = 25
GrenadeLauncher.kGrenadeBounce = 0.15
GrenadeLauncher.kGrenadeFriction = 0.35

GrenadeLauncher.kImpactGrenadeSpeed = 35
GrenadeLauncher.kImpactGrenadeFriction = 0.2

local baseOnPrimaryAttack = GrenadeLauncher.OnPrimaryAttack
function GrenadeLauncher:OnPrimaryAttack(player)
    player.firePrimary = true
    baseOnPrimaryAttack(self,player)
end

--function GrenadeLauncher:GetHasSecondary(player)
--    return true
--end
--
--function GrenadeLauncher:OnSecondaryAttack(player)
--    player.firePrimary = false
--    baseOnPrimaryAttack(self,player)
--end

function GrenadeLauncher:ShootGrenade(player)

    PROFILE("GrenadeLauncher:ShootGrenade")

    self:TriggerEffects("grenadelauncher_attack")

    if Server or (Client and Client.GetIsControllingPlayer()) then

        local viewCoords = player:GetViewCoords()
        local eyePos = player:GetEyePos()

        local floorAim = 1 - math.min(viewCoords.zAxis.y,0) -- this will be a number 1-2

        local startPointTrace = Shared.TraceCapsule(eyePos, eyePos + viewCoords.zAxis * floorAim * GrenadeLauncher.kLauncherBarrelDist, Grenade.kRadius+0.0001, 0, CollisionRep.Move, PhysicsMask.PredictedProjectileGroup, EntityFilterTwo(self, player))
        local startPoint = startPointTrace.endPoint

        local direction = viewCoords.zAxis


        local round="Grenade"
        local speed = GrenadeLauncher.kGrenadeSpeed
        local friction = GrenadeLauncher.kImpactGrenadeFriction
        --if not player.firePrimary then
        --    round="ImpactGrenade"
        --    speed= GrenadeLauncher.kImpactGrenadeSpeed
        --end

        player:CreatePredictedProjectile(round, startPoint, direction * speed,
                                         GrenadeLauncher.kGrenadeBounce, friction,
                                         nil, PhysicsMask.GLGrenadeGroup)
    end

end

local baseDoDamage = DamageMixin.DoDamage
function DamageMixin:DoDamage(damage, target, point, direction, surface, altMode, showtracer)
    local attacker = nil
    -- Get the attacker
    if self:GetParent() and self:GetParent():isa("Player") then
        attacker = self:GetParent()
    elseif HasMixin(self, "Owner") and self:GetOwner() and self:GetOwner():isa("Player") then
        attacker = self:GetOwner()
    end

    if (target and attacker and attacker:GetId() == target:GetId()) then
        --if GetHasTech(self,kTechId.GrenadeLauncherUpgrade) then
        --    target:DeductHealth(kGrenadeLauncherAllyBlastDamage,attacker,self)
        --else
        
        local healthConstant = kExplosiveSelfDamage[self:GetClassName()]
        if healthConstant then
            target:DeductHealth(healthConstant,attacker,self)
            return
        end
        --end
    end
    return baseDoDamage(self, damage, target, point, direction, surface, altMode, showtracer)
end
