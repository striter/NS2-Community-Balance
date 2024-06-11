-- Acid missile projectile
--
--=============================================================================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/Weapons/DotMarker.lua")
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


        local dotMarker = CreateEntity(DotMarker.kMapName, self:GetOrigin() + normal * 0.2, self:GetTeamNumber())
        dotMarker:SetTechId(kTechId.BileBomb)
        dotMarker:SetDamageType(self:GetDamageType())
        dotMarker:SetLifeTime(2)
        dotMarker:SetDamage(AcidMissile.kDamage)
        dotMarker:SetRadius(AcidMissile.kSplashRadius)
        dotMarker:SetDamageIntervall(kBileBombDotInterval)
        dotMarker:SetDotMarkerType(DotMarker.kType.Static)
        dotMarker:SetTargetEffectName("bilebomb_onstructure")
        dotMarker:SetDeathIconIndex(kDeathMessageIcon.AcidSpray)
        dotMarker:SetIsAffectedByCrush(true)
        dotMarker:SetOwner(self:GetOwner())
        local function NoFalloff()
            return 0
        end
        dotMarker:SetFallOffFunc(NoFalloff)
        dotMarker:TriggerEffects("whipbomb_hit")

        local explosionOrigin = self:GetOrigin()
        local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), explosionOrigin, AcidMissile.kSplashRadius)
        for _, hitEntity in ipairs(hitEntities) do

            local targetOrigin = GetTargetOrigin(hitEntity)
            if not GetWallBetween(explosionOrigin, targetOrigin, hitEntity) then
                if HasMixin(hitEntity, "Webable") then
                    hitEntity:SetWebbed(1, true)
                end

                if (hitEntity.SetCorroded) then
                    hitEntity:SetCorroded()
                end
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