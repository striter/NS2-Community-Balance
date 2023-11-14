
-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\SporeCloud.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
--    This class is used for the lerks spore dust cloud attack (trailing spores).
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/EffectsMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/BiomassHealthMixin.lua")


class 'SporeCloud' (Entity)

-- Spores didn't stack in NS1 so consider that
SporeCloud.kMapName = "sporecloud"

--SporeCloud.kLoopingEffect = PrecacheAsset("cinematics/alien/lerk/spore_trail.cinematic")
SporeCloud.kLoopingEffectAlien = PrecacheAsset("cinematics/alien/lerk/spore_trail_alien.cinematic")
SporeCloud.kStartEffect = PrecacheAsset("cinematics/alien/lerk/spore_projection.cinematic")
--SporeCloud.kFadeOutEffect = PrecacheAsset("cinematics/alien/lerk/spore_trail_fadeout.cinematic")

-- Damage per think interval (from NS1)
-- 0.5 in NS1, reducing to make sure sprinting machines take damage
local kDamageInterval = 0.25

-- Keep table of entities that have been hurt by spores to make
-- spores non-stackable. List of {entityId, time} pairs.

local gHurtBySpores = { }

-- how fast we drop
SporeCloud.kDropSpeed = 0.6
-- how far away from our drop-target before we slow down the speed
SporeCloud.kDropSlowDistance = 0.4
-- minimum distance above floor we drop to
SporeCloud.kDropMinDistance = 1.1

SporeCloud.kMaxRange = 17
SporeCloud.kTravelSpeed = 60 --m/s

local networkVars =
{
    destination = "vector",
    sporeMineDust = "boolean",
}

AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function SporeCloud:OnCreate()

    Entity.OnCreate(self)

    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, EffectsMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, BiomassHealthMixin)
    
    if Server then

        InitMixin(self, OwnerMixin)

        self.nextDamageTime = 0

    end

    self:SetUpdates(true, kRealTimeUpdateRate)

    self.createTime = Shared.GetTime()
    -- note: let the cloud linger a little bit after it stops doing damage to let the animation play out
    self.endOfDamageTime = self.createTime + kSporesDustCloudLifetime
    self.destroyTime = self.endOfDamageTime + 2

    self:SetRelevancyDistance(kMaxRelevancyDistance)

end


function SporeCloud:SetTravelDestination(position, sporeMineCast)      --I prefer this one (Initialize)
    self.destination = position
    self.sporeMineDust = sporeMineCast ~= nil
end

function SporeCloud:OnDestroy()
    Entity.OnDestroy(self)

    self:TriggerEffects("spores_hit_end")

    if Client then
        if self.sporeEffect then
            Client.DestroyCinematic(self.sporeEffect)
            self.sporeEffect = nil
        end

        if self.sporeSpawnEffect then
            Client.DestroyCinematic(self.sporeSpawnEffect)
            self.sporeSpawnEffect = nil
        end
    end

end


local function GetEntityRecentlyHurt(entityId, time)

    for index, pair in ipairs(gHurtBySpores) do
        if pair[1] == entityId and pair[2] > time then
            return true
        end
    end

    return false

end

local function SetEntityRecentlyHurt(entityId)

    for index, pair in ipairs(gHurtBySpores) do
        if pair[1] == entityId then
            table.remove(gHurtBySpores, index)
        end
    end

    table.insert(gHurtBySpores, {entityId, Shared.GetTime()})

end

function SporeCloud:GetDamageType()
    return kDamageType.Gas
end

function SporeCloud:GetModelOrigin()
    return self:GetOrigin()
end

function SporeCloud:GetEngagementPoint()
    return self:GetOrigin() + Vector(0, 0.5, 0)
end

function SporeCloud:GetDeathIconIndex()
    return kDeathMessageIcon.SporeCloud
end

-- Have damage radius grow to maximum non-instantly
function SporeCloud:GetDamageRadius()
    local scalar = Clamp((Shared.GetTime() - self.createTime) * 2, 0, 1)
    return scalar * kSporesDustCloudRadius
end

function SporeCloud:GetTechId()
    return kTechId.Spores
end

-- They stick around for a while - don't show the numbers. Too much.
function SporeCloud:GetShowHitIndicator()
    return false
end

function SporeCloud:SporeDamage(time)

    local enemies = GetEntitiesForTeam("Player", GetEnemyTeamNumber(self:GetTeamNumber()))
    local damageRadius = self:GetDamageRadius()

    -- When checking if spore cloud can reach something, only walls and door entities will block the damage.
    local filterNonDoors = EntityFilterAllButIsa("Door")
    for index, entity in ipairs(enemies) do

        local attackPoint = entity:GetEyePos()
        if (attackPoint - self:GetOrigin()):GetLength() < damageRadius then

            if not entity:isa("Commander") and not GetEntityRecentlyHurt(entity:GetId(), (time - kDamageInterval)) then

                -- Make sure spores can "see" target
                local trace = Shared.TraceRay(self:GetOrigin(), attackPoint, CollisionRep.Damage, PhysicsMask.Bullets, filterNonDoors)
                if trace.fraction == 1.0 or trace.entity == entity then

                    self:DoDamage(kSporesDustDamagePerSecond * kDamageInterval, entity, trace.endPoint, (attackPoint - trace.endPoint):GetUnit(), "organic" )

                    -- Spores can't hurt this entity for kDamageInterval
                    SetEntityRecentlyHurt(entity:GetId())

                end

            end

        end

    end
end


function SporeCloud:OnUpdate(deltaTime)

    local time = Shared.GetTime()
    -- Spawn the spores blasting out effect
    if Client then
        if not self.sporeMineDust then      --Don't cast this one
            if self.destination and not self.sporeSpawnEffect then
                self.sporeSpawnEffect = Client.CreateCinematic(RenderScene.Zone_Default)
                self.sporeSpawnEffect:SetCinematic(SporeCloud.kStartEffect)
                self.sporeSpawnEffect:SetRepeatStyle(Cinematic.Repeat_Endless)

                local coords = Coords.GetIdentity()
                coords.origin = self:GetOrigin()
                coords.zAxis = GetNormalizedVector(self:GetOrigin()-self.destination)
                coords.xAxis = GetNormalizedVector(coords.yAxis:CrossProduct(coords.zAxis))
                coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)

                self.sporeSpawnEffect:SetCoords(coords)
            end
        end
    end

    if Server then
        --[[
        if not self.targetY then
            local trace = Shared.TraceRay(self:GetOrigin(), self:GetOrigin() - Vector(0,10,0), CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())

            self.targetY = trace.endPoint.y + SporeCloud.kDropMinDistance
        end
    
        -- drop by a constant speed until we get close to the target, at which time we slow down the drop
        local origin = self:GetOrigin()
        local remDrop = origin.y - self.targetY
        local speed = SporeCloud.kDropSpeed 
       if remDrop < SporeCloud.kDropSlowDistance then
            speed = SporeCloud.kDropSpeed * remDrop / SporeCloud.kDropSlowDistance
        end
        -- cut bandwidth; when the speed is slow enough, we stop updating
        if speed > 0.05 then
            origin.y = origin.y - speed * deltaTime
            self:SetOrigin(origin)
        end
        ]]

        -- Move the actual spore cloud.
        if self.destination and not self.doneTraveling then
            
            local travelVector = self.destination - self:GetOrigin()
            local travelSpeed = self.sporeMineDust and kSporeMineCloudTravelSpeed or SporeCloud.kTravelSpeed
            if travelVector:GetLengthSquared() > 0.09 then
                local distance = travelVector:GetLength()
                local distanceFraction = distance / SporeCloud.kMaxRange
                self:SetOrigin( self:GetOrigin() + GetNormalizedVector(travelVector) * deltaTime * travelSpeed * distanceFraction )
            else
                self.doneTraveling = true
                self:TriggerEffects("spores_hit")
            end

        end

        -- we do damage until the spores have died away.
        if time > self.nextDamageTime and time < self.endOfDamageTime then

            self:SporeDamage(time)
            self.nextDamageTime = time + kDamageInterval
        end

        if  time > self.destroyTime then
            self:TriggerEffects("spores_hit_end")
            DestroyEntity(self)
        end

    elseif Client then

        local coords = Coords.GetIdentity()
        coords.origin = self:GetOrigin()
        --coords.zAxis = Vector.zAxis
        --coords.xAxis = Vector.xAxis
        --coords.yAxis = Vector.yAxis

        if self.sporeEffect then
            self.sporeEffect:SetCoords( coords )
        else

            self.sporeEffect = Client.CreateCinematic(RenderScene.Zone_Default)
            --[[
            local effectName = SporeCloud.kLoopingEffect
            if not GetAreEnemies(self, Client.GetLocalPlayer()) then
                effectName = SporeCloud.kLoopingEffectAlien
            end
            --]]

            self.sporeEffect:SetCinematic( SporeCloud.kLoopingEffectAlien )
            self.sporeEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.sporeEffect:SetCoords( coords )

        end

    end

end

function SporeCloud:GetHealthPerBioMass()
    return kSporeCloudHealthPerBiomass
end

if Server then

    function SporeCloud:OnKill()
        self:TriggerEffects("burn_spore", { effecthostcoords = Coords.GetTranslation(self:GetOrigin()) } )
    end

    function SporeCloud:GetDestroyOnKill()
        return true
    end

    function SporeCloud:GetSendDeathMessageOverride()
        return false
    end
end

if Client then

    function SporeCloud:OnUpdateRender()

        if self.sporeSpawnEffect and self.destination then
            local coords = Coords.GetIdentity()
            coords.origin = self:GetOrigin()
            coords.zAxis = GetNormalizedVector(self:GetOrigin()-self.destination)
            coords.xAxis = GetNormalizedVector(coords.yAxis:CrossProduct(coords.zAxis))
            coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)

            self.sporeSpawnEffect:SetCoords(coords)
        end

    end

end

function SporeCloud:GetRemainingLifeTime()
    return math.min(0, self.endOfDamageTime - Shared.GetTime())
end

Shared.LinkClassToMap("SporeCloud", SporeCloud.kMapName, networkVars)
