-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\DotMarker.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    This class is used for damage over time effects. You can use it for static, dynamic,
--    single target and attach to another entity.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/OwnerMixin.lua")

-- store tables of effects played recently for entities, so same effects won't stack and spam the client and network (multiple bilebombs in one place)
local gRecentEffects = {}

local function GetShouldPlayerEffectFor(effectName, entity)

end

class 'DotMarker' (ScriptActor)

DotMarker.kMapName = "dotmarker"

local kDefaultEffectName = "damage"

local networkVars =
{
    targetId = "entityid"
}

AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)

DotMarker.kType = enum({'Static', 'Dynamic', 'SingleTarget'})

local function GetRelativImpactPoint(origin, hitEntity)

    PROFILE("GetRelativImpactPoint")

    local impactPoint
    local worldImpactPoint

    local targetOrigin = hitEntity:GetOrigin() + Vector(0, 0.2, 0)

    if hitEntity.GetEngagementPoint then
        targetOrigin = hitEntity:GetEngagementPoint()
    end
    
    if origin == targetOrigin then
        return Vector(0,0.2,0), targetOrigin
    end
    
    local trace = Shared.TraceRay(origin, targetOrigin, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOnly(hitEntity))

    if trace.entity == hitEntity then
    
        impactPoint = Vector()
        local hitEntityCoords = hitEntity:GetCoords()
        local direction = trace.endPoint - hitEntityCoords.origin
        impactPoint.z = hitEntityCoords.zAxis:DotProduct(direction)
        impactPoint.x = hitEntityCoords.xAxis:DotProduct(direction)
        impactPoint.y = hitEntityCoords.yAxis:DotProduct(direction)
        worldImpactPoint = trace.endPoint

    else
    
        local trace = Shared.TraceRay(origin, targetOrigin, CollisionRep.LOS, PhysicsMask.Bullets, EntityFilterAll())
        if trace.fraction > 0.9 then
        
            impactPoint = Vector(0,0.2,0)
            worldImpactPoint = hitEntity:GetOrigin()
        
        end
    
    end

    return impactPoint, worldImpactPoint

end

function DotMarker:SetFallOffFunc(fallOffFunc)
    self.fallOffFunc = fallOffFunc
end

local function ConstructTargetEntry(origin, hitEntity, damage, radius, ignoreLos, customImpactPoint, fallOffFunc)

    local entry = {}
    
    if not hitEntity or not hitEntity:GetCanTakeDamage() then
        return nil
    end

    local worldImpactPoint
    entry.impactPoint, worldImpactPoint = GetRelativImpactPoint(origin, hitEntity)
    
    if entry.impactPoint or ignoreLos or customImpactPoint then
    
        if not worldImpactPoint then
            worldImpactPoint = hitEntity:GetOrigin()
        end
        
        entry.id = hitEntity:GetId()
        if radius ~= 0 then
        
            local distanceFraction = (worldImpactPoint - origin):GetLength() / radius
            if fallOffFunc then
                distanceFraction = fallOffFunc(distanceFraction)
            end
            distanceFraction = Clamp(distanceFraction, 0, 1)
            entry.damage = damage * (1 - distanceFraction)
            
        else
            entry.damage = damage
        end
        
        entry.damage = math.max(entry.damage, 0.1)
        
        if customImpactPoint then
            entry.impactPoint = customImpactPoint
        else
            entry.impactPoint = ConditionalValue(entry.impactPoint, entry.impactPoint, Vector(0,0,0))
        end
        
        return entry
    
    end

end

-- caches damage dropoff and target ids so it does not need to be recomputed every time
local function ConstructCachedTargetList(origin, forTeam, damage, radius, fallOffFunc)

    local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", forTeam, origin, radius)
    local targetList = {}
    local targetIds = {}
    
    for index, hitEntity in ipairs(hitEntities) do
        local entry = ConstructTargetEntry(origin, hitEntity, damage, radius, false, nil, fallOffFunc)
        
        if entry then
            table.insert(targetList, entry)
            targetIds[hitEntity:GetId()] = true
        end
    end
    
    return targetList, targetIds
    
end

function DotMarker:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, LOSMixin)
    
    self.targetList = nil
    self.damageIntervall = 1
    self.damage = 10
    self.radius = 10
    self.damageType = kDamageType.Normal
    self.targetEffectName = kDefaultEffectName
    self.targetId = Entity.invalidId
    self.dotMarkerType = DotMarker.kType.Static
    self.timeLastUpdate = Shared.GetTime()
    self.deathIconIndex = kDeathMessageIcon.None
    self.targetIds = {}
    self.affectedByCrush = false
    self.playerDamageDealt = 0
end

function DotMarker:OverrideCheckVision()
    return false
end

function DotMarker:TimeUp()
    DestroyEntity(self)
end

function DotMarker:GetNotifiyTarget(target)
    return not target or not target:isa("Player")
end

function DotMarker:SetLifeTime(lifeTime)
    self.lifeTime = lifeTime
    self:AddTimedCallback(DotMarker.TimeUp, lifeTime)
end

function DotMarker:SetDotMarkerType(dotMarkerType)
    self.dotMarkerType = dotMarkerType
end

function DotMarker:SetTargetEffectName(targetEffectName)
    self.targetEffectName = targetEffectName
end

function DotMarker:SetDamageIntervall(damageIntervall)
    self.damageIntervall = damageIntervall
    self.timeLastUpdate = Shared.GetTime()
end

function DotMarker:SetDamageType(damageType)
    self.damageType = damageType
end

function DotMarker:GetDamageType()
    return self.damageType
end

function DotMarker:SetTechId( id )
    self.techId = id
end

function DotMarker:GetTechId()
    return self.techId
end
    

-- this is per second
function DotMarker:SetDamage(damage)
    self.damage = damage
end

function DotMarker:SetRadius(radius)
    self.radius = radius
end

function DotMarker:SetDeathIconIndex(iconIndex)
    self.deathIconIndex = iconIndex
end

function DotMarker:GetDeathIconIndex()
    return self.deathIconIndex
end

function DotMarker:SetIsAffectedByCrush(affectedByCrush)
    self.affectedByCrush = affectedByCrush
end

function DotMarker:GetIsAffectedByCrush()
    return self.affectedByCrush
end

function DotMarker:GetWeaponTechId()
    local deathIconIndex = self:GetDeathIconIndex()

    if deathIconIndex == kDeathMessageIcon.AcidRocket then
        return kTechId.AcidRocket
    elseif deathIconIndex == kDeathMessageIcon.AcidSpray then
        return kTechId.AcidSpray
    end
    
    return kTechId.BileBomb
end

function DotMarker:SetAttachToTarget(target, impactPoint)

    self.targetId = target:GetId()
    
    -- store relative impact point
    if impactPoint then
        local hitEntityCoords = target:GetCoords()
        local direction = impactPoint - hitEntityCoords.origin
        self.impactPoint = Vector(0,0,0)
        self.impactPoint.z = hitEntityCoords.zAxis:DotProduct(direction)
        self.impactPoint.x = hitEntityCoords.xAxis:DotProduct(direction)
        self.impactPoint.y = hitEntityCoords.yAxis:DotProduct(direction)
    end
    
end

local function ApplyDamage(self, targetList)

    for index, targetEntry in ipairs(targetList) do
    
        local entity = Shared.GetEntity(targetEntry.id)     

        if entity and self.destroyCondition and self.destroyCondition(self, entity) then
            DestroyEntity(self)
            break
        end

        if entity and self.targetIds[entity:GetId()] and entity:GetCanTakeDamage() and (not self.immuneCondition or not self.immuneCondition(self, entity)) then

            local worldImpactPoint = entity:GetCoords():TransformPoint(targetEntry.impactPoint)
            
            local doDamage = false
            local isPlayer = entity:isa("Player")
            if not isPlayer then
                doDamage = true
            elseif self.playerDamageDealt <= self.lifeTime * kDOTPlayerDamageMaxLifeTime then
                self.playerDamageDealt = self.playerDamageDealt + self.damageIntervall
                doDamage = true
            end
            
            --local previousHealthScalar = entity:GetHealthScalar()
            -- we don't need to specify a surface here, since dot marker can only damage actual targets and ignores world geometry
            if doDamage then
                self:DoDamage(self.damageIntervall * self.damage, entity, worldImpactPoint, -targetEntry.impactPoint, "none")
            end
            --local newHealthScalar = entity:GetHealthScalar()
            --entity:TriggerEffects(self.targetEffectName, { doer = self, effecthostcoords = Coords.GetTranslation(worldImpactPoint) })
            
        end
        
    end

end

function DotMarker:OnEntityChange(oldId)

    if self.dotMarkerType == DotMarker.kType.SingleTarget then
    
        if oldId == self.targetId then
            DestroyEntity(self)
        end
        
    elseif self.dotMarkerType == DotMarker.kType.Static then

        if self.targetIds[oldId] ~= nil then
            self.targetIds[oldId] = false
        end
    
    end
end

function DotMarker:SetDestroyCondition(func)
    self.destroyCondition = func
end

function DotMarker:OnUpdate(deltaTime)

    if Server then

        if self.timeLastUpdate + self.damageIntervall < Shared.GetTime() then
            -- we are attached to a target, update position
            if self.targetId ~= Entity.invalidId then        
                local target = Shared.GetEntity(self.targetId)
                if target then
                    self:SetOrigin(target:GetOrigin())  
                end
            end

            local targetList = self.targetList
            
            if self.dotMarkerType == DotMarker.kType.SingleTarget then

                -- single target will deal damage only to the attached target (used for poison dart)
                if not targetList and self.targetId ~= Entity.invalidId then
                    
                    local target = Shared.GetEntity(self.targetId)

                    if target then

                        self.targetList = {}
                        table.insert(self.targetList, ConstructTargetEntry(self:GetOrigin(), target, self.damage, self.radius, true, self.impactPoint, self.fallOffFunc) )
                        targetList = self.targetList
                        
                    end
                    
                end

            elseif self.dotMarkerType == DotMarker.kType.Dynamic then
            
                -- in case for dynamic dot marker recalculate the target list each damage tick (used for burning)
                targetList = ConstructCachedTargetList(self:GetOrigin(), GetEnemyTeamNumber(self:GetTeamNumber()), self.damage, self.radius, self.fallOffFunc)
                
            elseif self.dotMarkerType == DotMarker.kType.Static then
            
                -- calculate the target list once and reuse it later (used for bilebomb)
                if not targetList then
                    self.targetList, self.targetIds = ConstructCachedTargetList(self:GetOrigin(), GetEnemyTeamNumber(self:GetTeamNumber()), self.damage, self.radius, self.fallOffFunc)
                    targetList = self.targetList
                end
            
            end
            
            if targetList then
                ApplyDamage(self, targetList)
            end
                
            self.timeLastUpdate = Shared.GetTime()
            
        end
    
    elseif Client then
    
    
    end

end


Shared.LinkClassToMap("DotMarker", DotMarker.kMapName, networkVars)