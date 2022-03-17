
Shotgun.kShotgunRings =
--[[
 {
    { pelletCount = 1, distance = 0.0000, pelletSize = 0.016, pelletDamage = 10, thetaOffset = 0},
    { pelletCount = 4, distance = 0.3500, pelletSize = 0.016, pelletDamage = 10, thetaOffset = 0},
    { pelletCount = 4, distance = 0.6364, pelletSize = 0.016, pelletDamage = 10, thetaOffset = math.pi * 0.25},
    { pelletCount = 4, distance = 1.0000, pelletSize = 0.016, pelletDamage = 10, thetaOffset = 0},
    { pelletCount = 4, distance = 1.1314, pelletSize = 0.016, pelletDamage = 10, thetaOffset = math.pi * 0.25}
}
]]--

--[[ #1 test 
    {
    { pelletCount = 1, distance = 0.0000, pelletSize = 0.016, pelletDamage = 10, thetaOffset = 0},
    { pelletCount = 4, distance = 0.3000, pelletSize = 0.016, pelletDamage = 10, thetaOffset = 0},
    { pelletCount = 4, distance = 0.4500, pelletSize = 0.016, pelletDamage = 10, thetaOffset = math.pi * 0.25},
    { pelletCount = 4, distance = 0.6000, pelletSize = 0.016, pelletDamage = 10, thetaOffset = 0},
    { pelletCount = 4, distance = 1.0000, pelletSize = 0.016, pelletDamage = 10, thetaOffset = math.pi * 0.25},
}
]]--
{ --#2 add pellet number reduce damage
    { pelletCount = 1, distance = 0.0000, pelletSize = 0.016, pelletDamage = 6.8, thetaOffset = 0},
    { pelletCount = 4, distance = 0.1500, pelletSize = 0.016, pelletDamage = 6.8, thetaOffset = 0},
    { pelletCount = 4, distance = 0.2500, pelletSize = 0.016, pelletDamage = 6.8, thetaOffset = math.pi * 0.25},
    { pelletCount = 4, distance = 0.4500, pelletSize = 0.016, pelletDamage = 6.8, thetaOffset =0},
    { pelletCount = 4, distance = 0.6364, pelletSize = 0.016, pelletDamage = 6.8, thetaOffset = math.pi * 0.25},
    { pelletCount = 4, distance = 0.8500, pelletSize = 0.016, pelletDamage = 6.8, thetaOffset = 0},
    { pelletCount = 4, distance = 1.0000, pelletSize = 0.016, pelletDamage = 6.8, thetaOffset = math.pi * 0.25},
}
Shotgun._RecalculateSpreadVectors()

local baseOnPrimaryAttack = Shotgun.OnPrimaryAttack
function Shotgun:OnPrimaryAttack(player)
    player.firePrimary = true
    baseOnPrimaryAttack(self,player)
end

function Shotgun:GetHasSecondary(player)
    return true
end

function Shotgun:OnSecondaryAttack(player)
    player.firePrimary = false
    baseOnPrimaryAttack(self,player)
end


local kSecondaryTracerName = PrecacheAsset("cinematics/marine/railgun/tracer_small.cinematic")
local kSecondaryTracerResidueName = PrecacheAsset("cinematics/marine/railgun/tracer_residue_small.cinematic")
local kMuzzleEffectName = PrecacheAsset("cinematics/marine/shotgun/muzzle_flash.cinematic")

local kSecondaryAttackDamage = 70
local function FireSecondary(self,player)
    -- self:TriggerEffects("shotgun_attack_sound")
    self:TriggerEffects("shotgun_attack_secondary")

    local viewAngles = player:GetViewAngles()
    local shootCoords = viewAngles:GetCoords()
    
    -- Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local range = self:GetRange()
    
    local numberBullets = self:GetBulletsPerShot()
    local startPoint = player:GetEyePos()
    local bulletSize = self:GetBulletSize()

    local spreadDirection = self:CalculateSpreadDirection(shootCoords, player)
    local endPoint = startPoint + spreadDirection * range
    local targets, trace, hitPoints = GetBulletTargets(startPoint, endPoint, spreadDirection, bulletSize, filter)        
    local damage = kSecondaryAttackDamage

    HandleHitregAnalysis(player, startPoint, endPoint, trace)        

    local direction = (trace.endPoint - startPoint):GetUnit()
    local hitOffset = direction * kHitEffectOffset
    local impactPoint = trace.endPoint - hitOffset

    local numTargets = #targets
    
    if numTargets == 0 then
        self:ApplyBulletGameplayEffects(player, nil, impactPoint, direction, 0, trace.surface, true)
    end
    
    if Client then
        local tracerStart = self.GetBarrelPoint and self:GetBarrelPoint() or self:GetOrigin()
        local tracerVelocity = GetNormalizedVector(impactPoint - tracerStart) * kTracerSpeed
        CreateTracer(tracerStart, impactPoint, tracerVelocity, self , kSecondaryTracerName, kSecondaryTracerResidueName)
    end

    for i = 1, numTargets do

        local target = targets[i]
        local hitPoint = hitPoints[i]

        self:ApplyBulletGameplayEffects(player, target, hitPoint - hitOffset, direction, damage, "", i == numTargets)
        
        local client = Server and player:GetClient() or Client
        if not Shared.GetIsRunningPrediction() and client.hitRegEnabled then
            RegisterHitEvent(player, bullet, startPoint, trace, damage)
        end
    
    end
        
end


local baseOnPrimaryAttack = Shotgun.FirePrimary
function Shotgun:FirePrimary(player)
    if player.firePrimary then
        baseOnPrimaryAttack(self,player)
    else
        FireSecondary(self,player)
    end
end
