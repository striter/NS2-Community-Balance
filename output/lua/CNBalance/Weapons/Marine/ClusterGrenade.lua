-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Marine\ClusterGrenade.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Projectile.lua")

class 'ClusterGrenade' (PredictedProjectile)

ClusterGrenade.kMapName = "clustergrenadeprojectile"
ClusterGrenade.kModelName = PrecacheAsset("models/marine/grenades/gr_cluster_world.model")

local networkVars = { }

local kLifeTime = 1.2

ClusterGrenade.kRadius = 0.085
ClusterGrenade.kDetonateRadius = 0.17
ClusterGrenade.kClearOnImpact = true
ClusterGrenade.kClearOnEnemyImpact = true

local kGrenadeCameraShakeDistance = 15
local kGrenadeMinShakeIntensity = 0.01
local kGrenadeMaxShakeIntensity = 0.12

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

local kClusterGrenadeFragmentPoints =
{
    Vector(0.1, 0.12, 0.1),
    Vector(-0.1, 0.12, -0.1),
    Vector(0.1, 0.12, -0.1),
    Vector(-0.1, 0.12, 0.1),

    Vector(-0.0, 0.12, 0.1),
    Vector(-0.1, 0.12, 0.0),
    Vector(0.1, 0.12, 0.0),
    Vector(0.0, 0.12, -0.1),
}

function ClusterGrenade:CreateFragments()

    local origin = self:GetOrigin()
    local player = self:GetOwner()

    for i = 1, #kClusterGrenadeFragmentPoints do

        local creationPoint = origin + kClusterGrenadeFragmentPoints[i]
        local fragment = CreateEntity(ClusterFragment.kMapName, creationPoint, self:GetTeamNumber())

        local startVelocity = GetNormalizedVector(creationPoint - origin) * (3 + math.random() * 6) + Vector(0, 4 * math.random(), 0)
        fragment:Setup(player, startVelocity, true, nil, self)

    end

end

function ClusterGrenade:OnCreate()

    PredictedProjectile.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DamageMixin)

    if Server then

        self:AddTimedCallback(ClusterGrenade.TimedDetonateCallback, kLifeTime)

    end

end

function ClusterGrenade:ProcessHit(targetHit, surface)

    if targetHit and GetAreEnemies(self, targetHit) then

        if Server then
            self:Detonate(targetHit)
        end

        return true

    end

    return false

end

function ClusterGrenade:ProcessNearMiss( targetHit, endPoint )
    if targetHit and GetAreEnemies(self, targetHit) then
        if Server then
            self:Detonate( targetHit )
        end
        return true
    end
end

if Server then

    function ClusterGrenade:TimedDetonateCallback()
        self:Detonate()
    end

    function ClusterGrenade:BurnNearbyAbilities()
        local origin = self:GetOrigin()
        local range = kClusterGrenadeDamageRadius

        -- lerk spores
        local spores = GetEntitiesWithinRange("SporeCloud", origin, range)

        -- lerk umbra
        local umbras = GetEntitiesWithinRange("CragUmbra", origin, range)

        -- bilebomb (gorge and contamination), whip bomb
        local bombs = GetEntitiesWithinRange("Bomb", origin, range)
        local whipBombs = GetEntitiesWithinRange("WhipBomb", origin, range)

        for _, spore in ipairs(spores) do
            self:TriggerEffects("burn_spore", {effecthostcoords = Coords.GetTranslation(spore:GetOrigin())})
            DestroyEntity(spore)
        end

        for _, umbra in ipairs(umbras) do
            self:TriggerEffects("burn_umbra", {effecthostcoords = Coords.GetTranslation(umbra:GetOrigin())})
            DestroyEntity(umbra)
        end

        for _, bomb in ipairs(bombs) do
            self:TriggerEffects("burn_bomb", {effecthostcoords = Coords.GetTranslation(bomb:GetOrigin())})
            DestroyEntity(bomb)
        end

        for _, bomb in ipairs(whipBombs) do
            self:TriggerEffects("burn_bomb", {effecthostcoords = Coords.GetTranslation(bomb:GetOrigin())})
            DestroyEntity(bomb)
        end
    end

    function ClusterGrenade:BurnEntities(ents)
        local owner = self:GetOwner()
        for i = 1, #ents do
            local ent = ents[i]
            if HasMixin(ent, "Fire") and GetAreEnemies(owner, ent) then
                ent:SetOnFire(owner, self)
            end
        end
    end

    function ClusterGrenade:Detonate(targetHit)
        local grenadeTech = GetHasTech(self,kTechId.GrenadeTech)
        local clusterFlame = GetHasTech(self,kTechId.ExplosiveStation)
        if grenadeTech then
            self:CreateFragments()
        end
        if clusterFlame then
            self:CastFlame()
        end
        
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kClusterGrenadeDamageRadius)
        table.removevalue(hitEntities, self)

        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kClusterGrenadeDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
            if clusterFlame and targetHit.SetOnFire then
                targetHit:SetOnFire(self,self)
            end
        end

        RadiusDamage(hitEntities, self:GetOrigin(), kClusterGrenadeDamageRadius, kClusterGrenadeDamage, self)

        local surface = GetSurfaceFromEntity(targetHit)

        local params = { surface = surface }
        if not targetHit then
            params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
        end

        if GetDebugGrenadeDamage() then
            DebugWireSphere( self:GetOrigin(), kClusterGrenadeDamageRadius, 0.5, 1, 1, 0, 1 )
        end

        self:TriggerEffects("cluster_grenade_explode", params)
        CreateExplosionDecals(self)
        TriggerCameraShake(self, kGrenadeMinShakeIntensity, kGrenadeMaxShakeIntensity, kGrenadeCameraShakeDistance)

        DestroyEntity(self)

    end
end

function ClusterGrenade:GetMeleeOffset()
    return 0.0
end
ClusterGrenade.kConeWidth = 0.1
function ClusterGrenade:CastFlame()

    local player = self:GetOwner()
    if not player then return end

    local startPoint = self:GetOrigin()
    local extents = Vector(ClusterGrenade.kConeWidth,ClusterGrenade.kConeWidth,ClusterGrenade.kConeWidth)
    local range = 1

    local filterEnts = {player}

    local fireDirection =  self:GetVelocity():Normalize()
    local targetTrace =  TraceMeleeBox(self, startPoint,fireDirection, extents, range, PhysicsMask.Flame, EntityFilterList(filterEnts))
    if targetTrace.fraction == 1 then
        fireDirection = Vector(0,-1,0)
        targetTrace = TraceMeleeBox(self, startPoint,fireDirection, extents, range, PhysicsMask.Flame, EntityFilterList(filterEnts))
    end

    local endPoint = targetTrace.endPoint
    local normal = targetTrace.normal

    -- Check for spores in the way.
    if Server then
        Flamethrower.BurnSporesAndUmbra(self,startPoint, endPoint)
    end

    if targetTrace.fraction ~= 1 then

        --Create flame below target
        if targetTrace.entity then
            local groundTrace = Shared.TraceRay(endPoint, endPoint + Vector(0, -2.6, 0), CollisionRep.Default, PhysicsMask.CystBuild, EntityFilterAllButIsa("TechPoint"))
            if groundTrace.fraction ~= 1 then
                fireDirection = fireDirection * 0.55 + normal
                fireDirection:Normalize()

                Flamethrower.CreateFlame(self,player, groundTrace.endPoint, groundTrace.normal, fireDirection)
            end
        else
            fireDirection = fireDirection * 0.55 + normal
            fireDirection:Normalize()
            Flamethrower.CreateFlame(self,player, endPoint, normal, fireDirection)
        end

    end
    

end

function ClusterGrenade:GetDeathIconIndex()
    return kDeathMessageIcon.ClusterGrenade
end

Shared.LinkClassToMap("ClusterGrenade", ClusterGrenade.kMapName, networkVars)


class 'ClusterFragment' (Projectile)

ClusterFragment.kMapName = "clusterfragment"
--ClusterFragment.kModelName = PrecacheAsset("models/effects/frag_metal.model")

function ClusterFragment:OnCreate()

    Projectile.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DamageMixin)

    if Server then
        self:AddTimedCallback(ClusterFragment.TimedDetonateCallback, math.random() * 1 + 0.5)
    elseif Client then
        self:AddTimedCallback(ClusterFragment.CreateResidue, 0.06)
    end

end

function ClusterFragment:GetProjectileModel()
    return ClusterFragment.kModelName
end

function ClusterFragment:GetDeathIconIndex()
    return kDeathMessageIcon.ClusterGrenade
end

if Server then

    function ClusterFragment:TimedDetonateCallback()
        self:Detonate()
    end

    function ClusterFragment:Detonate(targetHit)

        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kClusterFragmentDamageRadius)
        table.removevalue(hitEntities, self)

        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kClusterFragmentDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        end

        RadiusDamage(hitEntities, self:GetOrigin(), kClusterFragmentDamageRadius, kClusterFragmentDamage, self)

        local surface = GetSurfaceFromEntity(targetHit)

        local params = { surface = surface }
        if not targetHit then
            params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
        end

        if GetDebugGrenadeDamage() then
            DebugWireSphere( self:GetOrigin(), kClusterFragmentDamageRadius, 0.5, 1, 0.498, 0, 1 )
        end


        local clusterFlame = GetHasTech(self,kTechId.ExplosiveStation)
        if clusterFlame then
            ClusterGrenade.CastFlame(self)
        end
        
        self:TriggerEffects("cluster_fragment_explode", params)
        CreateExplosionDecals(self)
        DestroyEntity(self)

    end

    function ClusterFragment:GetMeleeOffset()
        return 0.0
    end
end

function ClusterFragment:CreateResidue()

    self:TriggerEffects("clusterfragment_residue")
    return true

end

Shared.LinkClassToMap("ClusterFragment", ClusterFragment.kMapName, networkVars)