
-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\BabblerPheromone.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Attracts babblers.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/TeamMixin.lua")

class 'BabblerPheromone' (Projectile)

BabblerPheromone.kMapName = "babblerpheromone"
BabblerPheromone.kModelName = PrecacheAsset("models/alien/babbler/babbler_ball.model")

PrecacheAsset("models/alien/babbler/babbler_ball.surface_shader")

local kBabblerSearchRange = 1000
local kBabblerPheromoneDuration = 5
local kPheromoneEffectInterval = 0.15

local networkVars =
{
    destinationEntityId = "entityid",
    impact = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

function BabblerPheromone:OnCreate()

    Projectile.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)

    if Server then

        self.destinationEntityId = Entity.invalidId

        self:AddTimedCallback(BabblerPheromone.TimeUp, kBabblerPheromoneDuration)
        self.impact = false
        self.worldCollision = false

    end

    self.radius = 0.1
    self.mass = 1
    self.linearDamping = 0
    self.restitution = 0.95
    self:SetGroupFilterMask(PhysicsMask.NoBabblers)

end


-- Force order for all babblers to the same target
function BabblerPheromone:MoveBabblers()
    local orig = self:GetOrigin()
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
    local nearestTargets = GetEntitiesForTeamWithinRange("Player", enemyTeamNumber, orig, 15)
    local target
    local targetPos

    for _, ent in ipairs(nearestTargets) do
        if ent and not GetWallBetween(orig, ent:GetOrigin(), ent) then
            target = ent
            targetPos = ent.GetEngagementPoint and ent:GetEngagementPoint() or ent:GetOrigin()
            break
        end
    end

    local owner = self:GetOwner()
    for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), orig, kBabblerSearchRange ))
    do
        if babbler:GetOwner() == owner then
            --if babbler:GetIsClinged() and babbler:GetParent() == owner then
            --    babbler:Detach()
            --end

            if target then
                babbler:SetMoveType(kBabblerMoveType.Attack, target, targetPos, true)
                -- Log("Attack group order issued by the bait toward %s", target)
            else
                -- Log("Move group order issued by the bait toward %s", target)
                babbler:SetMoveType(kBabblerMoveType.Move, nil, self:GetOrigin(), true)
            end
        end
    end
end

function BabblerPheromone:GetProjectileModel()
    return BabblerPheromone.kModelName
end

function BabblerPheromone:OnDestroy()

    Projectile.OnDestroy(self)

    if Server and not self.triggeredPuff then
        self:TriggerEffects("babbler_pheromone_puff")
    end

end

function BabblerPheromone:OnUpdateRender()

    if not self.timeLastPheromoneEffect or self.timeLastPheromoneEffect + kPheromoneEffectInterval < Shared.GetTime() then

        if self.destinationEntityId and self.destinationEntityId ~= Entity.invalidId and Shared.GetEntity(self.destinationEntityId) then

            local destinationEntity = Shared.GetEntity(self.destinationEntityId)
            destinationEntity:TriggerEffects("babbler_pheromone")

        else
            self:TriggerEffects("babbler_pheromone")
        end

        self.timeLastPheromoneEffect = Shared.GetTime()

    end

end

function BabblerPheromone:GetSimulatePhysics()
    return not self.impact
end

function BabblerPheromone:SetAttached(target)
    self.destinationEntityId = target:GetId()
end

if Server then


    function BabblerPheromone:OnUpdate(deltaTime)

        Projectile.OnUpdate(self, deltaTime)

        if not self.firstUpdate then

            self.firstUpdate = true


            --for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), self:GetOrigin(), kBabblerSearchRange )) do
            --
            --    if babbler:GetIsClinged() and babbler:GetOwner() == gorge and babbler:GetParent() == gorge then
            --
            --        babbler:Detach()
            --
            --    end
            --
            --end
            
            --local gorge = self:GetOwner()
            --for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), self:GetOrigin(), kBabblerSearchRange )) do
            --
            --    if babbler:GetIsClinged() and babbler:GetOwner() == gorge and babbler:GetParent() == gorge then
            --
            --        babbler:Detach()
            --
            --    end
            --
            --end

        end

    end

    local function CanGetAttach(self, entity)
        -- Can only attach to friends
        if not GetAreFriends(self, entity) then
            return false
        end

        -- Can only attach when there are attach points available
        if HasMixin(entity, "BabblerCling") and not entity:GetCanAttachBabbler() then
            return false
        end

        -- Don't attach to babbler owners that allready have max babblers
        -- Exclude current owner so gorge can reattack own bablers
        local owner = self:GetOwner()
        if entity ~= owner and HasMixin(entity, "BabblerOwner")
                and entity:GetBabblerCount() >= entity:GetMaxBabblers() then
            return false
        end

        return true
    end

    -- Helper function to adjust babbler move type
    local function GetMoveType(self, entity)
        local moveType = kBabblerMoveType.Move

        if CanGetAttach(self, entity) then
            moveType = kBabblerMoveType.Cling
        elseif GetAreEnemies(self, entity) and HasMixin(entity, "Live") and entity:GetIsAlive() and entity:GetCanTakeDamage() or ( entity:isa("PowerPoint") and entity:GetBuiltFraction() >= 0.009 ) then
            moveType = kBabblerMoveType.Attack
        end

        return moveType
    end

    local function Hatch(self,entity)
        local owner = self:GetOwner()
        local moveType = GetMoveType(self, entity)
        local origin = self:GetOrigin()
        local position = HasMixin(entity, "Target") and entity:GetEngagementPoint() or entity:GetOrigin()
        local newBabbler = CreateEntity(Babbler.kMapName, origin, self:GetTeamNumber())
        local client = owner:GetClient()
        if client and client.variantData then
            newBabbler:SetVariant( client.variantData.babblerVariant )
        end
        newBabbler:TriggerEffects("babbler_engage")
        newBabbler:SetOwner(owner)
        newBabbler.clinged = true
        newBabbler:Detach(true,kBabblerPheromoneHatchLifeTime)
        newBabbler:SetMoveType(moveType, entity, position, true)
        self:TriggerEffects("Babbler_hatch")
    end


    function BabblerPheromone:TimeUp()
        self:HatchNearby()
        DestroyEntity(self)
    end

    function BabblerPheromone:HatchNearby()
        for _, entity in pairs(GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), 7)) do
            if entity:GetCanTakeDamage() and entity:GetIsAlive() then
                Hatch(self,entity)
                break
            end
        end

    end
    
    function BabblerPheromone:ProcessHit(entity)

        if not self.worldCollision then
            --if not entity then -- the rest of the code will handle the case where we hit an entity
            --    self:MoveBabblers() -- Move babblers where the ball bounce
            --end
            self.worldCollision = true
        end

        if entity and entity:isa("BabblerEgg") and entity:GetIsBuilt() and entity:PheromoneHatch() then
            DestroyEntity(self)
            return
        end

        local isValidHit =
        entity and
                ( entity:isa("PowerPoint") and entity:GetBuiltFraction() >= 0.009 ) or
                ( entity and (GetAreEnemies(self, entity) or HasMixin(entity, "BabblerCling")) and HasMixin(entity, "Live") and entity:GetIsAlive() )

        if isValidHit then


            -- Ensure the impact flag is set even if the entity can't take damage.
            -- Otherwise there will be errors when attacking a Vortexed Marine for example.
            self.impact = true
            if entity:GetCanTakeDamage() then

                self.destinationEntityId = entity:GetId()
                self:SetModel(nil)
                self:TriggerEffects("babbler_pheromone_puff")
                self.triggeredPuff = true

                local owner = self:GetOwner()
                local moveType = GetMoveType(self, entity)
                local origin = self:GetOrigin()
                if moveType == kBabblerMoveType.Attack then

                elseif moveType == kBabblerMoveType.Cling then
                    local position = HasMixin(entity, "Target") and entity:GetEngagementPoint() or entity:GetOrigin()
                    for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), origin, kBabblerSearchRange )) do
                        if babbler:GetOwner() == owner then
                            if babbler:GetIsClinged() then

                                if babbler:GetParent() == owner then
                                    babbler:Detach()
                                end

                                babbler:SetMoveType(moveType, entity, position, true)

                            end
                        end
                    end
                end

                self:HatchNearby()
                DestroyEntity(self)

            end

        end

    end

    function BabblerPheromone:OnEntityChange(oldId)

        if oldId == self.destinationEntityId then
            DestroyEntity(self)
        end

    end

    function BabblerPheromone:GetIsAttached()
        return self.destinationEntityId ~= Entity.invalidId
    end

    function BabblerPheromone:TimeUp()
        DestroyEntity(self)
    end

end

Shared.LinkClassToMap("BabblerPheromone", BabblerPheromone.kMapName, networkVars)
