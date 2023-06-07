-- ======= Copyright (c) 2017, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ClogFallMixin.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Makes clogs fall when they lose their attachment to the environment.
--    Also handles anything attached to clogs (currently only hydras).
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

ClogFallMixin = CreateMixin(ClogFallMixin)
ClogFallMixin.type = "ClogFall"

kClogFallSpeed = 5
kClogFallWaitingUpdateRate = 1.0 / 5.0 -- 5hz update for checking if we should fall if we're resting on an entity.
kClogFallMaxUpdateRate = 1.0 / 30.0 -- 30hz update for falling clogs.
kClogFallTraceRadius = 0.3 -- same as if we were placing the clog as a gorge.

kHydraTraceExtents = Vector(0.5, 0.5, 0.5)
kHydraTraceStartOffset = 0.5 -- along coords.yAxis

ClogFallMixin.optionalCallbacks =
{
    OnClogFall = "Called when clog fall starts.",
    OnClogFallDone = "Called when we reached the ground, param 'isAttached'."
}

ClogFallMixin.networkVars = {}

function ClogFallMixin:__initmixin()
    
    PROFILE("ClogFallMixin:__initmixin")
    
    if Server then
        self.connectedClogs = {}

        -- when groups of connected clogs fall, we only update one clog, and update the rest of the group via a list of
        -- stored entity ids that we know were connected to the "driver" clog when the fall started.
        self.passengers = nil -- clog ids that will be driven by this clog
        self.gatheredClogs = nil -- same as above, but in an associative table.

        self.accumulatedDelta = 0.0
    end

end

local function UpdateClientPredictOrigin(self)

    if self.OnUpdatePhysics then
        self:OnUpdatePhysics()
    end

    return true

end

function ClogFallMixin:OnInitialized()

    if Client or Predict then
        self:AddFieldWatcher("m_origin", UpdateClientPredictOrigin)
    end

end

if Server then

    function ClogFallMixin:OnEntityChange(oldId, newId)

        if table.removevalue(self.connectedClogs, oldId) then
            if newId then
                table.insert(self.connectedClogs, newId)
            end
        end

    end

end

-- takes an empty table, gather, and an id of a starting clog, and traverses all the connected clogs to create a
-- table of connected ancestors.
-- Will return true if it encounters any entities marked as "doneFalling", meaning they can never fall again (ie they are
-- resting on map geometry/props, that will never change), and therefore the entire cluster can be considered on the ground
-- without any additional traces.
local function GatherConnected(gather, passengers, newClogId)

    assert(newClogId ~= Entity.invalidId)

    -- early out if this clog has already been added to the gathered list.
    if gather[newClogId] then
        return
    end

    local newClog = Shared.GetEntity(newClogId)
    if not newClog then
        return
    end

    if newClog.doneFalling then
        return true
    end

    if newClog.fallWaiting then
        -- resting on an entity that... as far as we know... hasn't moved yet.
        return true
    end

    -- Clear the following fields in case the clog being checked was driving some already falling clogs.
    -- Just make sure the driving clog isn't the one we're currently working on.
    if newClog.passengers ~= passengers then
        newClog.passengers = nil
        newClog.gatheredClogs = nil
        if newClog:isa("Clog") then -- never disable updates for the hydra.
            newClog:SetUpdates(false)
        end
    end

    -- add this clog, so we don't duplicate our efforts.
    gather[newClogId] = true
    table.insert(passengers, newClogId)

    -- add all the connected clogs, and their descendants.
    for _, id in ipairs(newClog.connectedClogs) do
        if GatherConnected(gather, passengers, id) then
            return true -- exit immediately if an entity in the cluster is known to be already on the ground
        end
    end

end

local function BeginHydraFall(hydra)

    local id = hydra:GetId()
    hydra.passengers = { id }
    hydra.gatheredClogs = { [id] = true }

end

local function BabblerEggHatching(egg)
    -- Really sensitive, something moved ? hatch !
    if Server and egg then
        if egg:GetIsBuilt() then
            egg:Explode()
        else
            egg:Kill()
        end
    end
end

local function SporeMineExplode(sporemine)
    if Server and sporemine then
        if sporemine:GetIsBuilt() then
            sporemine:Explode()
        else
            sporemine:Kill()
        end

    end
end

-- Gathers all the indirectly connected clogs (and other clog-fall-mixin users, eg hydras), and sets up the cluster
-- to make it fall.  Optimization: will fail if any of the clogs in the heirarchy are known to be on the ground already.
local function BeginClogFall(clog)

    if clog:isa("Hydra") then
        BeginHydraFall(clog)
        return
    end

    if clog:isa("BabblerEgg") then
        BabblerEggHatching(clog)
        return
    end

    if clog:isa("SporeMine") then
        SporeMineExplode(clog)
        return
    end
    
    if clog:isa("Web") then
        return -- noop
    end

    -- create table containing all connected and indirectly connected clogs.
    clog.gatheredClogs = {} -- associative list for constant-time access
    clog.passengers = {} -- regular list, for JIT-able iteration.
    if GatherConnected(clog.gatheredClogs, clog.passengers, clog:GetId()) then
        -- one of the clogs in the heirarchy was static.
        clog.gatheredClogs = nil
        clog.passengers = nil
        return
    end

    clog:SetUpdates(true, kRealTimeUpdateRate)

end

if Server then


    function ClogFallMixin_AllChildFalling(self)
        for _, childClogId in ipairs(self.connectedClogs) do

            local childClog = Shared.GetEntity(childClogId)
            if childClog then
                -- remove the dying clog from the child's connected clogs.
                table.removevalue(childClog.connectedClogs, self:GetId())
                BeginClogFall(childClog)
            end

        end

        self.connectedClogs = {} --Empty table just to make sure nothing breaks afterwards
    end

    -- Disconnect this destroyed clog from any clogs it was connected to, and as we do this, make the formerly connected
    -- children start falling.
    function ClogFallMixin:OnDestroy()

        if self:isa("Clog") or self:isa("Web") then
            -- only clogs and webs influence clog falls... everything else is just along for the ride.
            ClogFallMixin_AllChildFalling(self)
        end

    end

end

local function ClogFallMixin_CountStackedClog(root, ids, clogs, webs, maxCount)

    for _, id in ipairs(root.connectedClogs) do
        if #clogs >= maxCount then
            break
        end

        if not ids[id] then
            local ent = Shared.GetEntity(id)

            ids[id] = true
            if ent and ent:isa("Clog") or ent:isa("Web") then
                table.insert(ent:isa("Clog") and clogs or webs, ent)
                clogs, webs = ClogFallMixin_CountStackedClog(ent, ids, clogs, webs, maxCount)
            end
        end
    end

    return clogs, webs

end

function ClogFallMixin:ConnectToClog(structure)

    assert(Server)
    assert(structure)
    assert(structure:GetId() ~= Entity.invalidId)

    table.insert(self.connectedClogs, structure:GetId())
    table.insert(structure.connectedClogs, self:GetId())

    local maxClogsOnWeb = 3
    local clogs, webs = ClogFallMixin_CountStackedClog(self, {}, {}, {}, maxClogsOnWeb + 1)

    -- Log("attached = %s/%s", tostring(#clogs), tostring(#webs))
    if #clogs > maxClogsOnWeb and #webs > 0 then
        for _, web in ipairs(webs) do -- Too much for this tiny web
            web:AddTimedCallback(function(self) self:Kill() ; end, 0)
            ClogFallMixin_AllChildFalling(web)
        end
        return
    end

end

function ClogFallMixin:RemoveAttachedClog(structure)

    assert(Server)
    assert(structure)
    assert(structure:GetId() ~= Entity.invalidId)

    table.removevalue(self.connectedClogs, structure:GetId())
    table.removevalue(structure.connectedClogs, self:GetId())

end

-- Filter for clog fall.  We exclude the clogs that are part of the falling group, as we don't want them to self-collide.
local function FilterClogFall(self, gatheredClogs)
    return function(test)
        if test:isa("Babbler") then
            return true
        end

        if test:isa("BabblerPheromone") then
            return true
        end

        -- For now, allow players to stop clogs falling... players were getting stuck.
        --[========[
        if test:isa("Player") then
            return true
        end
        --]========]

        if test:isa("Web") then
            return true
        end

        if test:isa("Ragdoll") then -- hydra ragdolls slip through even though they *should* be filtered out.
            return true
        end

        if test:isa("Weapon") then
            return true
        end

        if not test then
            return true
        end

        if self == test then
            return true
        end

        if gatheredClogs and gatheredClogs[test:GetId()] then
            return true
        end

        return false
    end
end

-- Movement for a single hydra falling.
local function UpdateHydraFall(self, deltaTime)

    -- hydras without clogs will fall to the ground and then stand upright.
    -- hydras are not connected to anything else, so this is simple.
    local offset = kClogFallSpeed * deltaTime
    local startPointOffset = self:GetCoords().yAxis * kHydraTraceStartOffset
    local startPoint = self:GetOrigin() + startPointOffset
    local endPoint = startPoint - Vector(0, offset, 0)

    local trace = Shared.TraceBox(kHydraTraceExtents, startPoint, endPoint, CollisionRep.Default,
        PhysicsMask.AllButPCsAndRagdollsAndBabblers, FilterClogFall(self))

    if trace.fraction ~= 1 then
        -- hit something... see what it was.
        self:SetOrigin(trace.endPoint)

        if trace.entity then
            -- hit an entity... if it's a clog, we'll just attach to this clog.
            if trace.entity:isa("Clog") then
                -- make the hydra point straight out of clog.
                self:OnClogFallDone(false, (self:GetOrigin() - trace.entity:GetOrigin()):GetUnit())
                self.passengers = nil
                self.gatheredClogs = nil
                self:ConnectToClog(trace.entity)
            else
                -- there's some other entity impeding the hydra from falling...
                -- reorient the hydra as usual, but keep performing checks to see if we should
                -- start falling again.
                self:OnClogFallDone(false, trace.normal)
                self.fallWaiting = 0.0 -- doubles as a cooldown for checking.
                self.passengers = nil
                self.gatheredClogs = nil
            end
        else
            -- must've hit map geometry or something... nothing to attach to.
            self:OnClogFallDone(false, trace.normal)
            self.doneFalling = true -- the hydra has entered a state where it can never fall again.
            self.passengers = nil
            self.gatheredClogs = nil
        end
    else
        -- fell through air, hitting nothing
        self:SetOrigin(endPoint - startPointOffset)
    end

end

local function UpdateBabblerEggFall(self, deltaTime)
    BabblerEggHatching(self)
end

local function UpdateSporeMineFall(self, deltaTime)
    SporeMineExplode(self)
end

local function UpdateWebFall(self, deltaTime)
    return
end

local function UpdateClogFall(self, deltaTime)

    -- perform a trace for each clog in the cluster.  When one hits something, they all stop.
    -- note that a clog will be its own passenger, to keep things consistent.
    local hitOffset
    local offset = kClogFallSpeed * deltaTime

    for i=1, (self.passengers and #self.passengers or 0) do
        local passenger = Shared.GetEntity(self.passengers[i])

        if passenger and passenger:isa("Clog") then
            local startPoint = passenger:GetOrigin()
            local endPoint = startPoint - Vector(0, offset, 0)
            local radius = kClogFallTraceRadius
            local trace = Shared.TraceCapsule(startPoint, endPoint, radius, 0.0,
                CollisionRep.Default, PhysicsMask.AllButPCsAndRagdollsAndBabblers, FilterClogFall(self, self.gatheredClogs))

            if trace.fraction ~= 1 then
                -- Something was hit.  Make note of how far we got before we hit something.
                hitOffset = (startPoint.y - endPoint.y) * trace.fraction

                if trace.entity then
                    -- if we hit an entity, see what it was.  If it's a clog, we should connect them up.
                    if trace.entity:isa("Clog") then
                        -- We hit another clog.  Connect them up.
                        passenger:ConnectToClog(trace.entity)
                    elseif trace.entity:isa("Hydra") then
                        -- Looks like we're crushing a hydra.  Kill it.
                        trace.entity:Kill()
                        passenger.fallWaiting = 0.0 -- setup fall waiting, otherwise clog will hover above dead hydra.
                        passenger:SetUpdates(true, kRealTimeUpdateRate)
                    elseif trace.entity:isa("BabblerEgg") then
                        BabblerEggHatching(trace.entity)
                        passenger.fallWaiting = 0.0
                        passenger:SetUpdates(true, kRealTimeUpdateRate)
                    elseif trace.entity:isa("SporeMine") then
                        SporeMineExplode(trace.entity)
                        passenger.fallWaiting = 0.0
                        passenger:SetUpdates(true, kRealTimeUpdateRate)
                    else
                        -- Whatever we hit, it wasn't a clog or a hydra.  Stop falling, but keep checking underneath
                        -- this clog to make sure that whatever it is, when it moves or dies, we start falling again.
                        passenger.fallWaiting = 0.0 -- doubles as a cooldown for checking.
                        passenger:SetUpdates(true, kRealTimeUpdateRate)
                    end
                else
                    -- if we didn't hit an entity, then that means that what we hit is static, and therefore this object
                    -- has reached its final destination -- it will never move again.
                    passenger.doneFalling = true
                end

                break
            end
        end
    end

    if hitOffset then
        offset = hitOffset
    end

    -- crush any hydras that are being pushed into spaces they can't fit into.
    for i=(self.passengers and #self.passengers or 0), 1, -1 do
        local passenger = Shared.GetEntity(self.passengers[i])
        if not (passenger and passenger.GetIsAlive and passenger:GetIsAlive()) then
            self.gatheredClogs[self.passengers[i]] = nil
            table.remove(self.passengers, i)
        else
            if passenger:isa("Hydra") or passenger:isa("BabblerEgg") or passenger:isa("SporeMine") then
                local startPoint = passenger:GetOrigin() + passenger:GetCoords().yAxis * kHydraTraceStartOffset
                local endPoint = startPoint - Vector(0, offset, 0)

                local trace = Shared.TraceBox(kHydraTraceExtents, startPoint, endPoint, CollisionRep.Default,
                    PhysicsMask.AllButPCsAndRagdollsAndBabblers, FilterClogFall(self, self.gatheredClogs))
                if trace.fraction ~= 1 then
                    -- hydra hit something on the way down, kill it.
                    self.gatheredClogs[passenger:GetId()] = nil
                    table.remove(self.passengers, i)
                    passenger:Kill()
                end
            end
        end
    end

    -- Shift all clogs downwards by the amount of offset
    for i=1, (self.passengers and #self.passengers or 0) do
        local passenger = Shared.GetEntity(self.passengers[i])
        if passenger then
            passenger:SetOrigin(passenger:GetOrigin() - Vector(0, offset, 0))
        end
    end

    if hitOffset then
        -- Something was hit.  Stop falling.
        for i=1, (self.passengers and #self.passengers or 0) do
            local passenger = Shared.GetEntity(self.passengers[i])
            if passenger then
                if passenger.OnClogFallDone then
                    passenger:OnClogFallDone(true) -- attached=true
                end
            end
        end

        self.passengers = nil
        self.gatheredClogs = nil
        self.accumulatedDelta = 0.0

        if not self.fallWaiting then
            self:SetUpdates(false) -- don't disable updates if we are simply waiting.
        end
    end

end

-- Filter for checking if the entity that was holding up a clog fall has moved/died yet.
local function FilterClogCheck(self)
    return function(test)
        if test:isa("Babbler") then
            return true
        end

        if test:isa("BabblerPheromone") then
            return true
        end

        -- For now, allow players to stop clogs falling... players were getting stuck.
        --[========[
        if test:isa("Player") then
            return true
        end
        --]========]

        if test:isa("Weapon") then
            return true
        end

        if test:isa("Clog") then
            return true
        end

        if test:isa("Hydra") then
            return true
        end

        if test:isa("Web") then
            return true
        end

        -- don't allow dead entities to hold up progress
        if not (test and test.GetIsAlive and test:GetIsAlive()) then
            return true
        end

        -- should be filtered out by physics mask... but apparenly some get through...
        if test:isa("Ragdoll") then
            return true
        end

        if self == test then
            return true
        end

        return false
    end
end

local function UpdateClogFallWaiting(self, _)

    local offset = kClogFallSpeed * kClogFallMaxUpdateRate
    local startPoint = self:GetOrigin()
    local endPoint = startPoint - Vector(0, offset, 0)
    local radius = kClogFallTraceRadius
    local trace = Shared.TraceCapsule(startPoint, endPoint, radius, 0.0,
        CollisionRep.Default, PhysicsMask.AllButPCsAndRagdollsAndBabblers, FilterClogCheck(self))

    -- tolerance for whatever little empty space is between the clog and the entity blocking it.
    if trace.fraction > 0.01 then
        -- entity has moved.
        self.fallWaiting = nil
        BeginClogFall(self)
    end

end

local function UpdateHydraFallWaiting(self, _)

    local offset = kClogFallSpeed * kClogFallMaxUpdateRate
    local startPoint = self:GetOrigin() + self:GetCoords().yAxis * kHydraTraceStartOffset
    local endPoint = startPoint - Vector(0, offset, 0)
    local trace = Shared.TraceBox(kHydraTraceExtents, startPoint, endPoint, CollisionRep.Default,
        PhysicsMask.AllButPCsAndRagdollsAndBabblers, FilterClogFall(self))

    if trace.fraction > 0.01 then
        -- entity has moved
        self.fallWaiting = nil
        BeginHydraFall(self)
    end

end

local function UpdateBabblerEggFallWaiting(self, _)
    BabblerEggHatching(self)
end

local function UpdateSporeMineFallWaiting(self, _)
    SporeMineExplode(self)
end

local function UpdateWebFallWaiting(self, _)
    return
end

local function UpdateFallWaiting(self, deltaTime)

    self.fallWaiting = self.fallWaiting - deltaTime
    if self.fallWaiting <= 0 then
        self.fallWaiting = kClogFallWaitingUpdateRate
    else
        return
    end

    if self:isa("Clog") then
        UpdateClogFallWaiting(self, deltaTime)
    elseif self:isa("Hydra") then
        UpdateHydraFallWaiting(self, deltaTime)
    elseif self:isa("BabblerEgg") then
        UpdateBabblerEggFallWaiting(self, deltaTime)
    elseif self:isa("SporeMine") then
        UpdateBabblerEggFallWaiting(self, deltaTime)
    elseif self:isa("Web") then
        UpdateSporeMineFallWaiting(self, deltaTime)
    else
        assert(false)
    end

end

if Server then

    function ClogFallMixin:OnUpdate(deltaTime)

        if self.doneFalling then
            if self:isa("Clog") then
                -- Hydras still update when done falling, but clogs don't.
                self:SetUpdates(false)
            end
            return
        end

        if self.fallWaiting then -- remember... lua treats 0.0 as true when evaluated this way.
            -- Entity isn't falling, but was previously stopped from falling by an entity.  Periodically check to
            -- see if that entity has moved.
            UpdateFallWaiting(self, deltaTime)
            return
        end

        self.accumulatedDelta = self.accumulatedDelta + deltaTime
        if self.accumulatedDelta < kClogFallMaxUpdateRate then
            return
        end

        ----------------------
        -- COOLDOWN BARRIER --
        ----------------------

        if self:isa("Clog") then -- catch-all to disable updates for clogs that no longer need updating.
            if self.passengers and #self.passengers == 0 then
                self.passengers = nil
                self.gatheredClogs = nil
            end

            if not self.passengers then
                self:SetUpdates(false)
                self.accumulatedDelta = 0.0
                return
            end
        end

        if self.passengers then -- the entity is driving the fall.
            if self:isa("Clog") then
                UpdateClogFall(self, self.accumulatedDelta)
            elseif self:isa("Hydra") then
                UpdateHydraFall(self, self.accumulatedDelta)
            elseif self:isa("BabblerEgg") then
                UpdateBabblerEggFall(self, self.accumulatedDelta)
            elseif self:isa("SporeMine") then
                UpdateSporeMineFall(self, self.accumulatedDelta)
            elseif self:isa("Web") then
                UpdateWebFall(self, self.accumulatedDelta)
            end
        end

        -- do this last so we have an accurate deltaTime to send to our various update functions.
        self.accumulatedDelta = self.accumulatedDelta - kClogFallMaxUpdateRate

    end

end
