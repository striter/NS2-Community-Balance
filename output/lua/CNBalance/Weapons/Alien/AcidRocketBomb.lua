-- //=============================================================================
-- //
-- // lua\Weapons\Alien\AcidRocketBomb.lua
-- //
-- // Created by Charlie Cleveland (charlie@unknownworlds.com)
-- // Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
-- //
-- // Bile AcidRocketBomb projectile
-- //
-- //=============================================================================

Script.Load("lua/Weapons/PredictedProjectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/Weapons/DotMarker.lua")

PrecacheAsset("cinematics/vfx_materials/decals/bilebomb_decal.surface_shader")

class 'AcidRocketBomb' (PredictedProjectile)

AcidRocketBomb.kMapName            = "acidrocketbomb"
AcidRocketBomb.kModelName          = PrecacheAsset("models/alien/fade/acidRocket/acidbomb.model")
AcidRocketBomb.kClearOnImpact = true
AcidRocketBomb.kClearOnEnemyImpact = true
local kWhipBombTrailCinematic = PrecacheAsset("cinematics/alien/whip/dripping_slime.cinematic")

-- // The max amount of time a AcidRocketBomb can last for
AcidRocketBomb.kLifetime = 6

local networkVars = {}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function AcidRocketBomb:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, DamageMixin)
    InitMixin(self, TeamMixin)

    self.radius = kAcidRocketBombRadius
    
    if Server then
        self:AddTimedCallback(AcidRocketBomb.TimeUp, AcidRocketBomb.kLifetime)
    end
end
--[[
function AcidRocketBomb:OnInitialized()

    PredictedProjectile.OnInitialized(self)
    


end
]]--
function AcidRocketBomb:GetProjectileModel()
    return AcidRocketBomb.kModelName
end 
   
function AcidRocketBomb:GetDeathIconIndex()
    return kDeathMessageIcon.AcidRocket
end

if Server then

    local function SineFalloff(distanceFraction)
        local piFraction = Clamp(distanceFraction, 0, 1) * math.pi / 2
        return math.cos(piFraction + math.pi) + 1 
    end

    function AcidRocketBomb:ProcessHit(targetHit, surface, normal)

        if not self.detonated then
            
            local dotMarker = CreateEntity(DotMarker.kMapName, self:GetOrigin() + normal * 0.2, self:GetTeamNumber())
            dotMarker:SetDamageType(kAcidRocketBombDamageType)
            dotMarker:SetLifeTime(kAcidRocketBombDuration)
            dotMarker:SetDamage(kAcidRocketBombDamage) --was set to kAcidRocketBombDamage, made newdamage type to slow down dps.
            dotMarker:SetRadius(kAcidRocketBombSplashRadius)
            dotMarker:SetDamageIntervall(kAcidRocketBombDotIntervall)
            dotMarker:SetDotMarkerType(DotMarker.kType.Static)
            dotMarker:SetTargetEffectName("bilebomb_hit")
            dotMarker:SetDeathIconIndex(kDeathMessageIcon.AcidRocket)
            dotMarker:SetOwner(self:GetOwner())
            dotMarker:SetFallOffFunc(SineFalloff)
            
            dotMarker:TriggerEffects("acidrocket_hit")

            DestroyEntity(self)
            
            CreateExplosionDecals(self, "bilebomb_decal")

        end

    end
    
    function AcidRocketBomb:TimeUp(currentRate)

        DestroyEntity(self)
        return false
    
    end

end

function AcidRocketBomb:GetNotifiyTarget()
    return false
end


Shared.LinkClassToMap("AcidRocketBomb", AcidRocketBomb.kMapName, networkVars)