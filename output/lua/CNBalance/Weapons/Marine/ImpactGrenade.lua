Script.Load("lua/Weapons/Projectile.lua")

class 'ImpactGrenade' (PredictedProjectile)

PrecacheAsset("cinematics/vfx_materials/elec_trails.surface_shader")

ImpactGrenade.kMapName = "impactgrenadeprojectile"
ImpactGrenade.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

ImpactGrenade.kDetonateRadius = 0.17
ImpactGrenade.kClearOnImpact = true
ImpactGrenade.kClearOnEnemyImpact = true

local networkVars = { }

local kLifeTime = 1.2

local kGrenadeCameraShakeDistance = 15
local kGrenadeMinShakeIntensity = 0.01
local kGrenadeMaxShakeIntensity = 0.14

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function ImpactGrenade:OnCreate()

    PredictedProjectile.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DamageMixin)

    if Server then

        self:AddTimedCallback(ImpactGrenade.TimedDetonateCallback, kLifeTime)

    end

end

function ImpactGrenade:GetDeathIconIndex()
    return kDeathMessageIcon.Grenade
end

function ImpactGrenade:GetDamageType()
    return kGrenadeLauncherGrenadeDamageType
end

function ImpactGrenade:GetIsAffectedByWeaponUpgrades()
    return true
end

function ImpactGrenade:GetWeaponTechId()
    return kTechId.GrenadeLauncher
end

function ImpactGrenade:GetTechId()
    return self:GetWeaponTechId()
end

function ImpactGrenade:ProcessHit(targetHit)
    if Server then
        self:Detonate(targetHit)
    end

    return true
end


function ImpactGrenade:ProcessNearMiss( targetHit, endPoint )
    if targetHit and GetAreEnemies(self, targetHit) then
        if Server then
            self:Detonate( targetHit )
        end

        return true
    end
end

if Server then

    function ImpactGrenade:TimedDetonateCallback()
        self:Detonate()
    end

    function ImpactGrenade:Detonate(targetHit)
    
        -- Do damage to nearby targets.
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius)
        
        -- Remove grenade and add firing player.
        table.removevalue(hitEntities, self)
        
        -- full damage on direct impact
        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kGrenadeLauncherImpactGrenadeDamage, targetHit, self:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        end

        RadiusDamage(hitEntities, self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius, kGrenadeLauncherImpactGrenadeDamage, self)
        
        -- TODO: use what is defined in the material file
        local surface = GetSurfaceFromEntity(targetHit)
        
        local params = { surface = surface }
        params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
        
        if GetDebugGrenadeDamage() then
            DebugWireSphere( self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius, 0.65, 1, 0, 0, 1 )
        end

        self:TriggerEffects("grenade_explode", params)
        
        CreateExplosionDecals(self)
        TriggerCameraShake(self, kGrenadeMinShakeIntensity, kGrenadeMaxShakeIntensity, kGrenadeCameraShakeDistance)
        
        DestroyEntity(self)
        
    end

    
    function ImpactGrenade:OnUpdate(deltaTime)

        PredictedProjectile.OnUpdate(self, deltaTime)

        if GetHasTech(self,kTechId.GrenadeLauncherDetectionShot) then

            for _, enemy in ipairs( GetEntitiesForTeamWithinRange("Alien", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kGrenadeLauncherDetectionShotRadius) ) do
            
                if enemy:GetIsAlive() then
                    self:Detonate()
                    break
                end
            
            end
        end
    end

end

Shared.LinkClassToMap("ImpactGrenade", ImpactGrenade.kMapName, networkVars)