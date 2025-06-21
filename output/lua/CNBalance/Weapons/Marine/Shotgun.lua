Shotgun.kDamageFalloffReductionFactor = 0.5 -- 50% reduction
Shotgun.kDamageFalloffStart = 8 -- in meters, full damage closer than this.
Shotgun.kDamageFalloffEnd = 15 -- in meters, minimum damage further than this, gradient between start/end.
Shotgun.kShotgunRings =
{
    { pelletCount = 1, distance = 0.0000, pelletSize = 0.03, pelletDamage = 10, thetaOffset = 0},
    { pelletCount = 3, distance = 0.3500, pelletSize = 0.024, pelletDamage = 10, thetaOffset = math.pi},
    { pelletCount = 5, distance = 0.6364, pelletSize = 0.02, pelletDamage = 10, thetaOffset = math.pi},
    { pelletCount = 8, distance = 1.0000, pelletSize = 0.016, pelletDamage = 10, thetaOffset = math.pi},
}
Shotgun._RecalculateSpreadVectors()

local kShotgunFireSpeedMult = 1 -- 1.08
local kShotgunFireAnimationLength = 0.8474577069282532 / kShotgunFireSpeedMult -- defined by art asset.     --0.8474577069282532
Shotgun.kFireDuration = kShotgunFireAnimationLength -- same duration for now.

function Shotgun:GetPrimaryMinFireDelay()
    return kShotgunFireAnimationLength
end

function Shotgun:OnUpdateAnimationInput(modelMixin)
    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    modelMixin:SetAnimationInput("attack_mult", kShotgunFireSpeedMult)
end

function Shotgun:GetMaxClips()
    return kShotGunClipNum
end

function Shotgun:FirePrimary(player)

    local viewAngles = player:GetViewAngles()
    viewAngles.roll = NetworkRandom() * math.pi * 2

    local shootCoords = viewAngles:GetCoords()

    -- Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local range = self:GetRange()

    -- Ensure spread vectors are up-to-date. Disabled for production
    -- Shotgun._RecalculateSpreadVectors()

    local numberBullets = self:GetBulletsPerShot()
    if GetHasTech(self,kTechId.Weapons3) or GetHasTech(self,kTechId.Weapons2) then
        self:TriggerEffects("shotgun_attack_sound_max")
    else
        self:TriggerEffects("shotgun_attack_sound")
    end
    self:TriggerEffects("shotgun_attack")

    for bullet = 1, math.min(numberBullets, #self.kSpreadVectors) do

        if not self.kSpreadVectors[bullet] then
            break
        end

        local spreadVector = self.kSpreadVectors[bullet].vector
        local pelletSize = self.kSpreadVectors[bullet].size
        local spreadDamage = self.kSpreadVectors[bullet].damage

        local spreadDirection = shootCoords:TransformVector(spreadVector)

        local startPoint = player:GetEyePos() + shootCoords.xAxis * spreadVector.x * self.kStartOffset + shootCoords.yAxis * spreadVector.y * self.kStartOffset

        local endPoint = player:GetEyePos() + spreadDirection * range

        local targets, trace, hitPoints = GetBulletTargets(startPoint, endPoint, spreadDirection, pelletSize, filter)

        HandleHitregAnalysis(player, startPoint, endPoint, trace)

        local direction = (trace.endPoint - startPoint):GetUnit()
        local hitOffset = direction * kHitEffectOffset
        local impactPoint = trace.endPoint - hitOffset
        local effectFrequency = self:GetTracerEffectFrequency()
        local showTracer = bullet % effectFrequency == 0

        local numTargets = #targets

        if numTargets == 0 then
            self:ApplyBulletGameplayEffects(player, nil, impactPoint, direction, 0, trace.surface, showTracer)
        end

        if Client and showTracer then
            TriggerFirstPersonTracer(self, impactPoint)
        end

        for i = 1, numTargets do

            local target = targets[i]
            local hitPoint = hitPoints[i]

            local thisTargetDamage = spreadDamage

            -- Apply a damage falloff for shotgun damage.
            if self.kDamageFalloffReductionFactor ~= 1 then
                local distance = (hitPoint - startPoint):GetLength()
                local falloffFactor = Clamp((distance - self.kDamageFalloffStart) / (self.kDamageFalloffEnd - self.kDamageFalloffStart), 0, 1)
                local nearDamage = thisTargetDamage
                local farDamage = thisTargetDamage * self.kDamageFalloffReductionFactor
                thisTargetDamage = nearDamage * (1.0 - falloffFactor) + farDamage * falloffFactor
            end

            self:ApplyBulletGameplayEffects(player, target, hitPoint - hitOffset, direction, thisTargetDamage, "", showTracer and i == numTargets)

            local client = Server and player:GetClient() or Client
            if not Shared.GetIsRunningPrediction() and client.hitRegEnabled then
                RegisterHitEvent(player, bullet, startPoint, trace, thisTargetDamage)
            end

        end

    end

end

--local kSecondaryTracerName = PrecacheAsset("cinematics/marine/railgun/tracer_small.cinematic")
--local kSecondaryTracerResidueName = PrecacheAsset("cinematics/marine/railgun/tracer_residue_small.cinematic")
--local kMuzzleEffectName = PrecacheAsset("cinematics/marine/shotgun/muzzle_flash.cinematic")
--
--local kSecondaryAttackDamage = 70
--local function FireSecondary(self,player)
--    -- self:TriggerEffects("shotgun_attack_sound")
--    self:TriggerEffects("shotgun_attack_secondary")
--
--    local viewAngles = player:GetViewAngles()
--    local shootCoords = viewAngles:GetCoords()
--    
--    -- Filter ourself out of the trace so that we don't hit ourselves.
--    local filter = EntityFilterTwo(player, self)
--    local range = self:GetRange()
--    
--    local numberBullets = self:GetBulletsPerShot()
--    local startPoint = player:GetEyePos()
--    local bulletSize = self:GetBulletSize()
--
--    local spreadDirection = self:CalculateSpreadDirection(shootCoords, player)
--    local endPoint = startPoint + spreadDirection * range
--    local targets, trace, hitPoints = GetBulletTargets(startPoint, endPoint, spreadDirection, bulletSize, filter)        
--    local damage = kSecondaryAttackDamage
--
--    HandleHitregAnalysis(player, startPoint, endPoint, trace)        
--
--    local direction = (trace.endPoint - startPoint):GetUnit()
--    local hitOffset = direction * kHitEffectOffset
--    local impactPoint = trace.endPoint - hitOffset
--
--    local numTargets = #targets
--    
--    if numTargets == 0 then
--        self:ApplyBulletGameplayEffects(player, nil, impactPoint, direction, 0, trace.surface, true)
--    end
--    
--    if Client then
--        local tracerStart = self.GetBarrelPoint and self:GetBarrelPoint() or self:GetOrigin()
--        local tracerVelocity = GetNormalizedVector(impactPoint - tracerStart) * kTracerSpeed
--        CreateTracer(tracerStart, impactPoint, tracerVelocity, self , kSecondaryTracerName, kSecondaryTracerResidueName)
--    end
--
--    for i = 1, numTargets do
--
--        local target = targets[i]
--        local hitPoint = hitPoints[i]
--
--        self:ApplyBulletGameplayEffects(player, target, hitPoint - hitOffset, direction, damage, "", i == numTargets)
--        
--        local client = Server and player:GetClient() or Client
--        if not Shared.GetIsRunningPrediction() and client.hitRegEnabled then
--            RegisterHitEvent(player, bullet, startPoint, trace, damage)
--        end
--    
--    end
--        
--end
--
--local baseOnPrimaryAttack = Shotgun.OnPrimaryAttack
--function Shotgun:OnPrimaryAttack(player)
--    player.firePrimary = true
--    baseOnPrimaryAttack(self,player)
--end
--
--function Shotgun:GetHasSecondary(player)
--    return true
--end
--
--function Shotgun:OnSecondaryAttack(player)
--    player.firePrimary = false
--    baseOnPrimaryAttack(self,player)
--end
--
--
--local baseOnPrimaryAttack = Shotgun.FirePrimary
--function Shotgun:FirePrimary(player)
--    if player.firePrimary then
--        baseOnPrimaryAttack(self,player)
--    else
--        FireSecondary(self,player)
--    end
--end

