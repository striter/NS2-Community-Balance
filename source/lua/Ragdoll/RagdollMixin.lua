-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\RagdollMixin.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

---------------- dude
local kRagdollTime = 12 -- 3
------------------

RagdollMixin = CreateMixin(RagdollMixin)
RagdollMixin.type = "Ragdoll"

RagdollMixin.expectedMixins =
{
    Live = "Needed for SetIsAlive()."
}

RagdollMixin.expectedCallbacks =
{
    SetPhysicsType = "Sets the physics to the passed in type.",
    GetPhysicsType = "Returns the physics type, dynamic, kinematic, etc.",
    SetPhysicsGroup = "Sets the physics group to the passed in value.",
    GetPhysicsGroup = "",
    GetPhysicsModel = "Returns the physics model.",
    TriggerEffects = ""
}

RagdollMixin.optionalCallbacks =
{
    GetRagdollTextureIndex = "Provide ragdoll entity with base material texture index to set when rendered"
}

function RagdollMixin:GetIsRagdoll()
    return self:GetPhysicsGroup() == PhysicsGroup.RagdollGroup
end

local function GetDamageImpulse(doer, point)

    if doer and point then
        return GetNormalizedVector(doer:GetOrigin() - point) * 1.5 * 0.01
    end
    return nil

end

if Server then

    function RagdollMixin:GetDestroyOnKill()
        return self.ragdollCreated
    end

    function RagdollMixin:OnKill(attacker, doer, point, direction)

        if point then

            self.deathImpulse = GetDamageImpulse(doer, point)
            self.deathPoint = Vector(point)

            if doer then
                self.doerClassName = doer:GetClassName()
            end

        end

        local doerClassName

        if doer ~= nil then
            doerClassName = doer:GetClassName()
        end

        if not self.consumed then
            self:TriggerEffects("death", { classname = self:GetClassName(), effecthostcoords = Coords.GetTranslation(self:GetOrigin()), doer = doerClassName })
        end

        -- Server does not process any tags when the model is client side animated. assume death animation takes 0.5 seconds and switch then to ragdoll mode.
        if self.GetHasClientModel and self:GetHasClientModel() and (not HasMixin(self, "GhostStructure") or not self:GetIsGhostStructure()) then

            CreateRagdoll(self)
            self.ragdollCreated = true

        end

    end

end

local function UpdateTimeToDestroy(self, deltaTime)

    if self.timeToDestroy then

        self.timeToDestroy = self.timeToDestroy - deltaTime

        if self.timeToDestroy <= 0 then

            self:SetModel(nil)

            local destructionAllowedTable = { allowed = true }
            if self.GetDestructionAllowed then
                self:GetDestructionAllowed(destructionAllowedTable)
            end

            if destructionAllowedTable.allowed then

                DestroyEntitySafe(self)
                self.timeToDestroy = nil

            end

        end

    end

end

local function SharedUpdate(self, deltaTime)

    if Server then
        UpdateTimeToDestroy(self, deltaTime)
    end

end

function RagdollMixin:OnUpdate(deltaTime)
    PROFILE("RagdollMixin:OnUpdate")
    SharedUpdate(self, deltaTime)
end

function RagdollMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

local function UpdatePhysics(self)
    if HasMixin(self, "Model") and ( self:GetIsRagdoll() or ( HasMixin(self, "Live") and not self:GetIsAlive() ) ) then

        local collisionModel = self:GetCollisionModel()
        if collisionModel and not self.removedCollisionReps then

            for i = 0, #CollisionRep - 1 do
                collisionModel:RemoveCollisionRep(i)
            end
            self.removedCollisionReps = true

        end

    end
end

function RagdollMixin:OnUpdatePhysics()
    UpdatePhysics(self)
end

function RagdollMixin:OnFinishPhysics()
    UpdatePhysics(self)
end


local function SetRagdoll(self, deathTime)

    if Server then

        if self:GetPhysicsGroup() ~= PhysicsGroup.RagdollGroup then

            self:SetPhysicsType(PhysicsType.Dynamic)

            self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)

            -- Apply landing blow death impulse to ragdoll (but only if we didn't play death animation).
            if self.deathImpulse and self.deathPoint and self:GetPhysicsModel() and self:GetPhysicsType() == PhysicsType.Dynamic then

                self:GetPhysicsModel():AddImpulse(self.deathPoint, self.deathImpulse)
                self.deathImpulse = nil
                self.deathPoint = nil
                self.doerClassName = nil

            end

            if deathTime then
                self.timeToDestroy = deathTime
            end

        end

    end

end

if Server then

    --
    -- The entity could be configured to not ragdoll even if the animation tells it to.
    --
    function RagdollMixin:SetBypassRagdoll(bypass)
        self.bypassRagdoll = bypass
    end

    function RagdollMixin:OnTag(tagName)

        PROFILE("RagdollMixin:OnTag")

        if not self.GetHasClientModel or not self:GetHasClientModel() then

            if tagName == "death_end" then

                if self.bypassRagdoll then
                    self:SetModel(nil)
                else
                    SetRagdoll(self, kRagdollTime)
                end

            elseif tagName == "destroy" then
                DestroyEntitySafe(self)
            end

        end

    end

end
