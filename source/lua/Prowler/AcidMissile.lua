-- Acid missile projectile
--
--=============================================================================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
--Script.Load("lua/Weapons/DotMarker.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")
PrecacheAsset("cinematics/vfx_materials/decals/bilebomb_decal.surface_shader")

class 'AcidMissile' (PredictedProjectile)

AcidMissile.kMapName            = "acidmissile"
--AcidMissile.kModelName          = PrecacheAsset("models/alien/gorge/spit.model")
AcidMissile.kProjectileCinematic = PrecacheAsset("cinematics/alien/gorge/gorge_spit.cinematic")

AcidMissile.kRadius             = 0.16
AcidMissile.kClearOnImpact      = true
AcidMissile.kClearOnEnemyImpact = true
AcidMissile.kSplashRadius       = 2.0
AcidMissile.kDamage             = kAcidSprayDamage

-- The max amount of time a AcidMissile can last for
AcidMissile.kLifetime = 5

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function AcidMissile:OnCreate()
    
    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
        self:AddTimedCallback(AcidMissile.TimeUp, AcidMissile.kLifetime)
    end

end

function AcidMissile:GetDeathIconIndex()
    return kDeathMessageIcon.AcidSpray
end

function AcidMissile:GetDamageType()
    return kAcidSprayDamageType
end

if Server then

    --[[local function SineFalloff(distanceFraction)
        local piFraction = Clamp(distanceFraction, 0, 1) * math.pi / 2
        return math.cos(piFraction + math.pi) + 1 
    end--]]

    function AcidMissile:ProcessHit(targetHit, surface, normal)        
        
        local explosionOrigin = self:GetOrigin()
        local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), explosionOrigin, AcidMissile.kSplashRadius)
        
        if targetHit then

            table.removevalue(hitEntities, targetHit)
            
            if not HasMixin(targetHit, "Team") or self:GetTeamNumber() ~= targetHit:GetTeamNumber() then
                self:DoDamage(AcidMissile.kDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - explosionOrigin), "none")
            end
        end

        for _, entity in ipairs(hitEntities) do

            local targetOrigin = GetTargetOrigin(entity)
            if not GetWallBetween(explosionOrigin, targetOrigin, entity) then
                self:DoDamage(AcidMissile.kDamage, entity, targetOrigin, GetNormalizedVector(entity:GetOrigin() - explosionOrigin), "none")
            end

        end
        
        self:TriggerEffects("whipbomb_hit")

        DestroyEntity(self)
        
        CreateExplosionDecals(self, "bilebomb_decal")

    end
    
    function AcidMissile:TimeUp(currentRate)

        DestroyEntity(self)
        return false
    
    end

end

function AcidMissile:GetNotifiyTarget()
    return false
end

function AcidMissile:GetIsAffectedByFocus()
    return false --true
end

function AcidMissile:GetMaxFocusBonusDamage()
    return kSpitFocusDamageBonusAtMax
end

function AcidMissile:GetFocusAttackCooldown()
    return kSpitFocusAttackSlowAtMax
end

function AcidMissile:GetIsAffectedByCrush()
    return true
end

Shared.LinkClassToMap("AcidMissile", AcidMissile.kMapName, networkVars)