Shotgun.kDamageFalloffReductionFactor = 1 -- 50% reduction

local kShotgunFireSpeedMult = 1.08
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
