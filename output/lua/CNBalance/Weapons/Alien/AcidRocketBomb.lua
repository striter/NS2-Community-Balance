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
AcidRocketBomb.kProjectileCinematic = PrecacheAsset("cinematics/alien/gorge/gorge_spit.cinematic")
AcidRocketBomb.kClearOnImpact = true
AcidRocketBomb.kClearOnEnemyImpact = true
AcidRocketBomb.kRadius = 0.25

AcidRocketBomb.kMinLifeTime = 0
-- // The max amount of time a AcidRocketBomb can last for
AcidRocketBomb.kLifetime = 3

local networkVars = {}

AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)


function AcidRocketBomb:OnCreate()

    PredictedProjectile.OnCreate(self)

    InitMixin(self, DamageMixin)
    InitMixin(self, TeamMixin)

    if Server then
        self:AddTimedCallback(AcidRocketBomb.TimeUp, AcidRocketBomb.kLifetime)
    end

end

function AcidRocketBomb:OnUpdate(deltaTime)
    PredictedProjectile.OnUpdate(self,deltaTime)

end

function AcidRocketBomb:OnDestroy()

    PredictedProjectile.OnDestroy(self)


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

    function AcidRocketBomb:ProcessHit(targetHit, surface, normal)

        if not self:GetIsDestroyed() then
            self:Detonate(normal)
        end
    end

    function AcidRocketBomb:TimeUp(currentRate)

        if not self:GetIsDestroyed() then
            self:Detonate(Vector(0,0,0))
        end
        return false

    end

    local function NoFalloff()
        return 0
    end
    function AcidRocketBomb:Detonate(normal)

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
        dotMarker:SetFallOffFunc(NoFalloff)

        dotMarker:TriggerEffects("acidrocket_hit")

        DestroyEntity(self)

        CreateExplosionDecals(self, "bilebomb_decal")
    end
    
end

function AcidRocketBomb:GetNotifiyTarget()
    return false
end



function AcidRocketBomb:OnModifyModelCoords(coords)     --Wrong axis
    local xAxis = coords.xAxis 
    coords.xAxis = -coords.zAxis
    coords.zAxis = xAxis
    return coords
end


Shared.LinkClassToMap("AcidRocketBomb", AcidRocketBomb.kMapName, networkVars)