 
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/BotDebug.lua")
Script.Load("lua/bots/ManyToOne.lua")
Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/IterableDict.lua")

local kDefaultAudibleRange = 14
local kClientSoundAudibleRange = 22
local kBlipUpdateTime = 1
local kStructureUpdateTime = 0.5
local kFullUpdateTime = 0.133
local kThreatUpdateTime = 1

-- gBotDebug is only available on the server.
if gBotDebug then
    gBotDebug:AddBoolean("debugteam")
end

---@class TeamBrain
TeamBrain = nil
class 'TeamBrain'



local function GetAudibleEnemies(keepFunc, enemyTeamNum)
    PROFILE("TeamBrain - GetAudibleEnemies")

    local sounds = {}

    for _, sound in ientitylist(Shared.GetEntitiesWithClassname("SoundEffect")) do

        local ent = sound:GetParent()
        local validEnemy = HasMixin(ent, "MapBlip") and HasMixin(ent, "Team") and ent:GetTeamNumber() == enemyTeamNum
        if validEnemy and (keepFunc == nil or keepFunc(sound)) then
            table.insert( sounds, sound )
        end
    end

    return sounds

end

-- Update all information about this memory, assuming we have knowledge of it due to minimap or audible detection
---@param mem TeamBrain.Memory
---@param ignoreLOS boolean if true, assume we know about this entity regardless of whether it is currently seen by a player
local function UpdateMemory(mem, ent, locationMemories, ignoreLOS)
    PROFILE("TeamBrain - UpdateMemory")

    local time = Shared.GetTime()

    -- this works as long as this is run as part of the server, as we will always have full
    -- information about entities.
    if HasMixin(ent, "MapBlip") and (ignoreLOS or (ent.GetIsSighted and ent:GetIsSighted())) then

        --throttle map blip updates
        if mem.lastBlipUpdateTime + kBlipUpdateTime < time then
            mem.lastBlipUpdateTime = time
            mem.btype = select(2, ent:GetMapBlipInfo())
            mem.team = ent:GetTeamNumber()
        end

        mem.lastSeenPos = ent:GetOrigin()

        --update memory location cache if changed
        local lastSeenLoc = ent:GetLocationName()

        if locationMemories and lastSeenLoc ~= mem.lastSeenLoc then

            if mem.lastSeenLoc and mem.lastSeenLoc ~= "" then
                local locSet = locationMemories[mem.lastSeenLoc]

                if locSet then
                    locSet:RemoveElement(mem)
                end
            end

            if lastSeenLoc and lastSeenLoc ~= "" then
                local locSet = locationMemories[lastSeenLoc]

                if not locSet then
                    locSet = UnorderedSet()
                    locationMemories[lastSeenLoc] = locSet
                end

                locSet:Add(mem)
            end

            mem.lastSeenLoc = lastSeenLoc

        end

        local timeSinceLastUpdated = time - mem.lastSeenTime
        if ent:isa("Player") and timeSinceLastUpdated > 2 then
            DebugPrint("Updated %s %s", ent, ignoreLOS and " from sound" or " from sight")
        end
    end

    -- otherwise, do not update it - keep the last known position/type
    mem.lastSeenTime = time

end


local function CreateMemory(ent)

    assert(HasMixin(ent, "MapBlip"),
            string.format(
                    "Entity missing MapBlip mixin! (Old Entity Id?) - Last Class: %s", ent and GetLastEntityClass(ent:GetId()) or "None"))

    ---@type number
    local now = Shared.GetTime()
    local _, blipType = ent:GetMapBlipInfo()

    ---@class TeamBrain.Memory
    local mem =
    {
        entId = ent:GetId(),
        btype = blipType,
        team = HasMixin(ent, "Team") and ent:GetTeamNumber() or kTeamInvalid,
        threat = 0.0,
        nextThreatUpdateTime = 0.0,
        lastSeenLoc = ent:GetLocationName(),
        lastSeenPos = ent:GetOrigin(),
        lastSeenTime = now,
        lastBlipUpdateTime = now,
        creationTime = now,
    }
    return mem

end


local function MemoryToString(mem)

    local s = ""
    local ent = Shared.GetEntity(mem.entId)
    if ent ~= nil then
        s = s .. string.format("%d-%s", mem.entId, ent:GetClassName())
    else
        s = s .. "<NIL>"
    end
    
    return s
    
end

function TeamBrain:Initialize(label, teamNumber)

    -- table of entity ID to remembered blips
    -- remembered blips

    ---@type table<unknown, TeamBrain.Memory>
    self.entId2memory = {}
    ---@type table<unknown, integer>
    self.entId2index = {}
    ---@type TeamBrain.Memory[]
    self.entMemories = {}

    -- currently known-about entities, like if they're friendly, sighted, or parasited.
    self.knownEntities = UnorderedSet()

    -- list of command structures currently active
    self.commandStructures = UnorderedSet()

    -- list of resource towers currently active
    self.resourceTowers = UnorderedSet()

    -- list of locations with a command structure
    self.commandLocations = UnorderedSet()

    -- map location name -> UnorderedSet() <TeamBrain.Memory>
    ---@type table<string, TeamBrain.Memory[]>[]
    self.locationMemories = {
        [kTeam1Index] = IterableDict(),
        [kTeam2Index] = IterableDict()
    }

    -- location of the initial tech point
    ---@type string?
    self.initialTechPointLoc = nil

    self.lastUpdate = 0
    self.lastStructureUpdate = 0
    self.lastFullUpdate = 0

    self.debug = false
    self.label = label
    self.teamNumber = teamNumber

    self.teamBots = {}

    self.assignments = ManyToOne()
    self.assignments:Initialize()

    self.teamRoles = IterableDict()

    --dumb lifo for damage-alerts, Bots can dip into this data for potential targets/goals
    self.teamAlerts = {}

end

function TeamBrain:Reset()
    self.entId2memory = {}
    self.entId2index = {}
    self.entMemories = {}
    self.lastUpdate = 0
    self.lastStructureUpdate = 0
    self.lastFullUpdate = 0
    self.assignments:Reset()
    self.teamRoles:Clear()
    self.teamAlerts = {}
    self.knownEntities:Clear()

    self.commandStructures:Clear()
    self.commandLocations:Clear()
    self.resourceTowers:Clear()
    self.locationMemories[kTeam1Index]:Clear()
    self.locationMemories[kTeam2Index]:Clear()
    self.initialTechPointLoc = nil
end

function TeamBrain:OnBeginFrame()
    if self.lastUpdate < Shared.GetTime() then
        self:Update()
    end
end

local kEmptyMemories = UnorderedSet()

function TeamBrain:GetKnownEntities()
    return self.knownEntities
end

--[[
    Team memory management

    TeamBrains maintain a list of "memories" about all entities that were recently visible
    or known by members of the team, loosely modelling real player knowledge of the minimap
    and team communication.

    Every effort is made to ensure updating and curating these memories is as fast as
    possible, given that the team memory system is the primary way that Bots interact with
    the world around them.

    High-priority memories are updated every tick, while lower-priority memories are updated
    more slowly to reduce the per-frame expense.
--]]

function TeamBrain:GetMemories()
    if self.lastUpdate < Shared.GetTime() then
        self:Update()
    end

    return self.entMemories
end


function TeamBrain:AddMemory(entId, mem)
    local idx = #self.entMemories + 1

    self.entMemories[idx] = mem
    self.entId2index[entId] = idx
    self.entId2memory[entId] = mem

    local locMemories = self.locationMemories[mem.team]

    -- add the memory to the location memory cache if present
    local location = mem.lastSeenLoc

    if location and location ~= "" and locMemories then
        local locSet = locMemories[location]

        if not locSet then
            locSet = UnorderedSet()
            locMemories[location] = locSet
        end

        locSet:Add(mem)
    end
end

function TeamBrain:RemoveMemory(entId)
    local idx = self.entId2index[entId]
    local mem = self.entId2memory[entId]

    if idx then
        self.entId2index[entId] = nil
        self.entId2memory[entId] = nil
        self.assignments:RemoveGroup(entId)

        -- remove the memory from the list of entity memories
        if idx < #self.entMemories then
            local lastMem = self.entMemories[#self.entMemories]

            self.entMemories[idx] = lastMem
            self.entId2index[lastMem.entId] = idx
            table.remove(self.entMemories)
        else
            self.entMemories[idx] = nil
        end
    end

    -- remove the memory from the location memory cache
    local lastLoc = mem and mem.lastSeenLoc
    if mem and mem.team > 0 and lastLoc and lastLoc ~= "" then
        local locSet = self.locationMemories[mem.team][lastLoc]

        if locSet then
            locSet:RemoveElement(mem)
        end
    end
end

function TeamBrain:GetMemoryOfEntity(entId)
    return self.entId2memory[entId]
end

--Return a reference to the UnorderedSet of memories known at this location
function TeamBrain:GetMemoriesAtLocation(locationName, teamNumber)
    return self.locationMemories[teamNumber][locationName] or kEmptyMemories
end

-- simple two-level iterator function caching commonly-computed values in the iterator state
-- iterates through the contents of a list of UnorderedSets
---@return integer?, TeamBrain.Memory
local function _iter_location_memories(state, key)
    local nk = key + 1

    if nk <= state.len then
        return nk, state.active[nk]
    end

    -- skip all finished or empty sets
    while nk > state.len do
        nk = 1
        state.index = state.index + 1
        state.active = state.memories[state.index]

        -- reached the end of the array
        if not state.active then
            return nil, nil
        end

        state.len = #state.active
    end

    return nk, state.active[nk]
end

-- Get an iterator over all memories at the given location and any locations directly connected to it
-- returns an iterator triad to be used with a for loop
--BOT-FIXME: should cache a list of nearby memories when first accessed rather than iterating multiple sets
function TeamBrain:IterMemoriesNearLocation(locationName, teamNumber)

    local locGraph = GetLocationGraph()

    local memories = { self:GetMemoriesAtLocation(locationName, teamNumber) }
    local connected = locGraph:GetDirectPathsForLocationName(locationName)

    if connected then

        -- build a group of all connected locations
        for i = 1, #connected do
            table.insert(memories, self.locationMemories[teamNumber][connected[i]])
        end

    end

    local state = {
        memories = memories,
        active = nil,
        len = 0,
        index = 0
    }

    return _iter_location_memories, state, 0
end

-- apply a filter predicate to return all entities the team brain has a memory of that pass the predicate
function TeamBrain:FilterNearbyMemories(locationName, teamNumber, filter)
    PROFILE("TeamBrain:FilterNearbyMemories")

    local entities = {}

    for _, memory in self:IterMemoriesNearLocation(locationName, teamNumber) do
        if filter(memory) then
            table.insert(entities, Shared.GetEntity(memory.entId))
        end
    end

    return entities
end

function TeamBrain:SetInitialTechPoint(techPoint)
    self.initialTechPointLoc = techPoint:GetLocationName()
end

function TeamBrain:OnEntityChange(oldId, newId)

    -- make sure we clear the memory
    -- do not worry about the new ID, since it should get added via the normal blip code path

    if oldId and oldId ~= Entity.invalidId then

        self.knownEntities:RemoveElement(oldId)
        self:RemoveMemory(oldId)

        self.commandStructures:RemoveElement(oldId)
        self.resourceTowers:RemoveElement(oldId)

    end

    --NOTE: OnEntityChange should be run for both TeamBrains so there's no need to reach into the other brain
    --[[
    -- Update known entities, new endId means new entity, so it should be caught
    if oldId and oldId ~= Entity.invalidId then
        GetTeamBrain(kTeam1Index):GetKnownEntities():RemoveElement(oldId)
        GetTeamBrain(kTeam2Index):GetKnownEntities():RemoveElement(oldId)
    end
    --]]

--BOT-TODO This needs to be a register/event broadcast sort of thing, not hard-coded inline here
    --[[
    if oldId and newId == nil then
        if self.teamNumber == kTeam2Index then
            local ent = Shared.GetEntity(oldId)
            if ent then
                self:RunEntityKilledBroadcast(ent)
            end
        end
    end
    --]]

end

--[[
    World entity events

    UpdateEntityForTeamBrains is responsible for notifying the TeamBrain about entity deletion or changes in entity LOS visibility,
    through this set of functions which reduces the amount of polling we need to do on active memories

    NOTE: these may be called redundantly and quite often, so they need to be fast and idempotent
--]]

--Gained LOS or parasite on a new entity, make a memory for it if it doesn't exist already
function TeamBrain:AddKnownEntity(entId)
    local ent = Shared.GetEntity(entId)
    if not ent then return end

    self.knownEntities:Add(entId)

    if not self.entId2index[entId] then
        local mem = CreateMemory(ent)

        self:AddMemory(entId, mem)
    end
end

--Entity was killed/deleted, purge it from the team's memories
function TeamBrain:DeleteKnownEntity(entId)
    self.knownEntities:RemoveElement(entId)
    self:RemoveMemory(entId)
end

--Entity lost LOS or parasite, we still have the memory
function TeamBrain:RemoveKnownEntity(entId)
    self.knownEntities:RemoveElement(entId)
end

function TeamBrain:DebugDraw()

    -- TEMP
    if self.teamNumber ~= kMarineTeamType then
        return
    end

    for _,mem in ipairs(self.entMemories) do

        local lostTime = Shared.GetTime() - mem.lastSeenTime
        local ent = Shared.GetEntity(mem.entId)
        assert( ent ~= nil )

        Shared.DebugColor(0,1,1,1)
        Shared.DebugText( string.format("-- %s %0.2f (%d)",
                    ent:GetClassName(), lostTime,
                    self.assignments:GetNumAssignedTo(mem.entId)),
                mem.lastSeenPos, 0.0 )

        for _, playerId in ipairs(self.assignments:GetItems(mem.entId)) do
            local player = Shared.GetEntity(playerId)
            if player ~= nil then
                local playerPos = player:GetOrigin()
                local ofs = Vector(0,1,0)
                DebugLine( mem.lastSeenPos+ofs, playerPos+ofs, 0.0,
                        0.5,0.5,0.5,1,   true )
            end
        end

    end

end

--Can be construction completed, hive under attack, structure under attack, etc.
--Anything added here is removed after X time (expires)
function TeamBrain:AddNewAlert( forTechId, entityId, worldPos )
    assert(entityId, "Error: No entity-id passed for TeamBrain damage alert")
    assert(worldPos, "Error: No world-space position passed for TeamBrain damage alert")

    local newAlert = 
    {
        techId = forTechId,     --ehhh...might not be useful
        entId = entityId,
        pos = worldPos,
        time = Shared.GetTime()
    }

    local existingIdx = -1
    for i = 1, #self.teamAlerts do
        if self.teamAlerts[i].endId == entityId then
            existingIdx = i
            break
        end
    end
    
    if existingIdx > 0 then
        self.teamAlerts[existingIdx] = newAlert
        --Log("[%s] Updated Alert:\n %s", ( self.teamNumber == kTeam1Index and "Marines" or "Aliens" ), ToString(newAlert) )
    else
        --Log("[%s] New Alert:\n %s", ( self.teamNumber == kTeam1Index and "Marines" or "Aliens" ), ToString(newAlert) )
        table.insert(self.teamAlerts, newAlert)
    end
end

function TeamBrain:GetOldestAlerts( optLimit )
    local tmp = self.teamAlerts
    table.sort(tmp, 
        function(a, b)
            return a.time < b.time
        end
    )
    --TODO Add optional size limiter
    return tmp
end

function TeamBrain:GetFilteredAlerts( optLimit, filterFunc )
    PROFILE("TeamBrain:GetFilteredAlerts")
    local tmp = self.teamAlerts
    local filtered = {}
    for i = 1, #tmp do
        if filterFunc(tmp[i]) then
            table.insert(filtered, tmp[i])
        end
    end
    --TODO opt limit
    return filtered
end

function TeamBrain:GetAlertsWithinRange( ofOrigin, range )
    assert(ofOrigin)
    assert(range and range > 5)
    local filtered = {}
    for i = 1, #self.teamAlerts do
        local alert = self.teamAlerts[i]
        if alert then
            local dist = ( ofOrigin - alert.pos ):GetLength()
            if dist <= range then
                table.insert(filtered, alert)
            end
        end
    end
    return filtered
end

function TeamBrain:GetFilteredAlertsWithinRange( ofOrigin, range, filterFunc )
    PROFILE("TeamBrain:GetFilteredAlertsWithinRange")
    assert(ofOrigin)
    assert(range and range > 5)
    local filtered = {}
    for i = 1, #self.teamAlerts do
        local alert = self.teamAlerts[i]
        if alert then
            local dist = ( ofOrigin - alert.pos ):GetLength()
            if dist <= range and filterFunc(alert) then
                table.insert(filtered, alert)
            end
        end
    end
    return filtered
end


function TeamBrain:UpdateMemoryOfEntity( ent, fromSound )
    PROFILE("TeamBrain:UpdateMemoryOfEntity")

    local entId = ent:GetId()
    local entValid = HasMixin(ent, "MapBlip")

    if not entValid then
        return
    end

    local mem = self.entId2memory[ entId ]
    if not mem then
        mem = CreateMemory(ent)
        self:AddMemory(entId, mem)

        -- if ent:isa("Player") and gBotDebug:Get("spam") then
        --     Log("Brain %d detected %s from %s", self.teamNumber, ent, fromSound and "sound" or "sight")
        -- end
    end

    UpdateMemory( mem, ent, self.locationMemories[mem.team], fromSound )
end

--Calculate the 'strategic threat' of an entity based on its position relative to team assets
--This function is not responsible for doing per-entity prioritization 
--BOT-FIXME: decay memory threat value over time
---@param mem TeamBrain.Memory
function TeamBrain:UpdateMemoryThreatValue( mem, ent, addThreat )
    PROFILE("TeamBrain:UpdateMemoryThreatValue")

    local locGraph = GetLocationGraph()
    local pos = ent:GetOrigin()

    local threat = 0.0

    if mem.team ~= self.teamNumber then

        for _, location in ipairs(self.commandLocations) do

            local roomPos = locGraph.locationCentroids[location]
            local dist = pos:GetDistance(roomPos)

            --1.0 threat if within 10 meters of the hive room, trailing off to 0 at 30 meters
            local thisThreat = 1.0 - (dist - 10.0) * 0.05

            threat = math.max(threat, Clamp(thisThreat, 0.0, 1.0))

        end

    end

    local time = Shared.GetTime()
    threat = threat + (addThreat or 0)

    -- increase the memory's threat value if it changed, otherwise allow it to remain until the decay time
    if threat > mem.threat or mem.nextThreatUpdateTime < time then
        mem.threat = threat
    end

    -- if we have a high threat value, defer the next threat update so it retains the high threat
    mem.nextThreatUpdateTime = math.max(mem.nextThreatUpdateTime, time + kThreatUpdateTime * math.max(threat * 2.0, 1.0))

end

--Calculate the additional threat value an attacker memory should receive from having damaged a team target recently
---@param mem TeamBrain.Memory
function TeamBrain:CalcAttackerThreat( mem, entity )

    if mem.team == self.teamNumber then
        return 0.0
    end

    -- little bit of extra baseline threat for attacking a friendly
    local threat = 0.5

    --They're damaging a hive! Immediately respond!
    if self.commandStructures:Contains(entity:GetId()) then
        threat = 2.0
    end

    if self.resourceTowers:Contains(entity:GetId()) then
        threat = 1.0

        -- increase threat if this RT is directly connected to our starting tech point
        if self.initialTechPointLoc then
            local naturals = GetLocationGraph():GetNaturalRtsForTechpoint(self.initialTechPointLoc)

            if naturals and naturals:Contains(entity:GetLocationName()) then
                threat = threat + 0.5
            end
        end
    end

    --??

    --Per-team brains should extend this function as needed (e.g. attacker damaging an infantry portal or upgrade chamber)

    return threat
end

--Yes, this is lame, but without a true Effects-Events System. This is what we get
local kAlienLifeformAttackSounds = 
{
    "sound/NS2.fev/alien/skulk/bite",
    "sound/NS2.fev/alien/skulk/bite_alt",
    "sound/NS2.fev/alien/common/xenocide_start",
    "sound/NS2.fev/alien/gorge/spit",
    "sound/NS2.fev/alien/gorge/bilebomb",
    "sound/NS2.fev/alien/gorge/healspray",
    "sound/NS2.fev/alien/gorge/create_structure_start",
    "sound/NS2.fev/alien/lerk/bite",
    "sound/NS2.fev/alien/lerk/spore_spray_once",
    "sound/NS2.fev/alien/lerk/spores_hit",
    "sound/NS2.fev/alien/lerk/spikes",
    "sound/NS2.fev/alien/lerk/hit",
    "sound/NS2.fev/alien/fade/swipe",
    "sound/NS2.fev/alien/fade/blink",
    "sound/NS2.fev/alien/fade/stab",
    "sound/NS2.fev/alien/fade/metabolize",
    "sound/NS2.fev/alien/onos/gore",
    "sound/NS2.fev/alien/onos/stomp",
    "sound/NS2.fev/alien/onos/charge_hit_marine",
    "sound/NS2.fev/alien/onos/charge_hit_exo",
}

--McG:  Hhhhoooollly SHIT this is BAD...so absurdly slow. String match?! Seriously?
--FIXME Change SoundEffect class to accept additional, Server-scope only ...NO networked fields, to apply the data we need here.
--  ( this should basically be a SoundEffect:OnCreate() -> BroadcastToWorld() -> TeamBrain:ListenSoundEffect(effect)  ...like call. Polling is bonkers)
--doing string compares is just dumb. This also does fuck-all to account for Sound's attentuation from the listener's perspective
-- ...ok, it's worse than I thought. This is called, per Bot, per Sound, per Enemy, each time this runs...which happens each TeamBrain:Update()  ...christ that's too much.
function TeamBrain:GetIsSoundAudible(sound, friends)
    PROFILE("TeamBrain:GetIsSoundAudible")
    
    -- find all our players inside a 20m range
    -- we only do this call for sounds that belong to enemy players that are actually playing, so this
    -- should not be horribly expensive.
    
    -- here we simulate how "loud" a sound is
    local soundName = sound:GetSoundName()
    local dist = kDefaultAudibleRange

    if string.match(soundName, "draw") or string.match(soundName, "deploy") then
        dist = 5
    --TODO Add structure spawing/placement (world sound only, NOT CommUI snd)
    elseif string.match(soundName, "land_for_enemy") or string.match(soundName, "step_for_enemy") then
        dist = 12

    --[[
    McG: Removed. This give unfair advantage to Marine/Exo bots, as they don't have an idle sound, but some Aliens do
    elseif string.match(soundName, "idle") then
        dist = 3
    --]]

    elseif table.icontains( kAlienLifeformAttackSounds, soundName ) then
        dist = 14

    elseif string.match(soundName, "spawn") then
        dist = 3.5
    
    --Added, because...why not? Nothing harmful really doesn't come from this
    elseif string.match(soundName, "taunt") then
        dist = 5

    elseif string.match(soundName, "hive_deploy") then
        dist = 21.5

    --elseif string.match(soundName, "distress_beacon_alien") then    --Marine version isn't 3D sound(in-world)
        --dist = 25
    end
    
    --?? potentially augment dist value via sound.volume? lerp+ slerp*scalar?

    for _, friend in ipairs( friends ) do
        if sound:GetWorldOrigin():GetDistanceTo(friend:GetWorldOrigin()) <= dist then
            return true
        end
    end

    return false
end

function TeamBrain:GetIsClientSoundAudible(soundOrigin)
    PROFILE("TeamBrain:GetIsClientSoundAudible")

    for _, friend in ipairs( GetEntitiesForTeamWithinRange("Player", self.teamNumber, soundOrigin, kClientSoundAudibleRange) ) do
        if friend:GetIsAlive() then
            return true
        end
    end
    return false
end

--TODO Experiment with instead of all the expensive GetEntities in a loop...hook up PerceiverMixin, and fetch all teammates parsing out
--their "perceived" entities? Would be faster, but would require a few extra checks.
function TeamBrain:Update()
    PROFILE("TeamBrain:Update")

    -- if gBotDebug:Get("spam") then
    --     Log("TeamBrain:Update")
    -- end

    local time = Shared.GetTime()

    do PROFILE("TeamBrain:Update - GatherBots")
    -- Update our knowledge of player bots (do this each update to deal with bots being removed mid-game)

    local players = GetEntitiesForTeam("Player", self.teamNumber)

    table.clear(self.teamBots)

    for _, player in ipairs(players) do
        local client = player:GetClient()

        if player:GetIsVirtual() and client and client.bot then
            table.insert(self.teamBots, client.bot)
        end
    end

    end

    do PROFILE("TeamBrain:Update - KnownEntities")

    local enemyTeam = GetEnemyTeamNumber(self.teamNumber)

    -- update our entId2memory, keyed by blip ent IDs
    for i = 1, self.knownEntities:GetSize() do 
        local entId = self.knownEntities[i]

        if entId ~= nil then
            local ent = Shared.GetEntity(entId)
            local mem = self.entId2memory[entId]

            if ent then
                -- we always have "vision" on friendly entities due to minimap
                UpdateMemory(mem, ent, self.locationMemories[mem.team], mem.team == self.teamNumber)

                --BOT-FIXME: don't update threat values for entities that cannot ever have threat
                if mem.team == enemyTeam and mem.nextThreatUpdateTime < time then
                    self:UpdateMemoryThreatValue(mem, ent, 0.0)
                end

            end

        end
    end

    end

    --find all high-value structures that a team player could conceivably determine exists by being nearby to the fixed placement locations
    -- Do this every ~500ms as RTs and CommandStructures don't change often and it's unlikely for them to be completely passed by in the delay

    if self.lastStructureUpdate + kStructureUpdateTime < time then
        PROFILE("TeamBrain:Update - Structures")

        self.lastStructureUpdate = time

        do PROFILE("TeamBrain:Update - ResourceTowers")


        for _, resourceTower in ipairs( GetEntities("ResourceTower") ) do

            if resourceTower:GetTeamNumber() == self.teamNumber then

                self.resourceTowers:Add(resourceTower:GetId())

            else

                if #GetEntitiesForTeamWithinRange("Player", self.teamNumber, resourceTower:GetOrigin(), 30) > 0 then
                    self:UpdateMemoryOfEntity(resourceTower, true)
                end

            end
        end

        end

        do PROFILE("TeamBrain:Update - CommandStructures")

        self.commandLocations:Clear()

        -- Update all command structure locations etc.
        -- Update knowledge of all enemy command structures within range of a player
        for _, commandStructure in ipairs( GetEntities("CommandStructure") ) do

            if commandStructure:GetTeamNumber() == self.teamNumber then

                self.commandStructures:Add(commandStructure:GetId())

                local locName = commandStructure:GetLocationName()
                if locName and locName ~= "" then
                    self.commandLocations:Add(locName)
                end

            else

                if #GetEntitiesForTeamWithinRange("Player", self.teamNumber, commandStructure:GetOrigin(), 30) > 0 then
                    self:UpdateMemoryOfEntity(commandStructure, true)

                end
            end

        end

        -- Starting command structure destroyed, update initial tech point for "natural" RTs etc.
        -- Don't reassign if there are no more command structures (i.e. the game is over)
        if self.initialTechPointLoc and not self.commandLocations:Contains(self.initialTechPointLoc) and #self.commandLocations > 0 then
            self.initialTechPointLoc = self.commandLocations[1]
        end

        end

    end

    -- Do this every ~130ms rather than every tick as iterating entities is fairly expensive
    
    if self.lastFullUpdate + kFullUpdateTime < time then
        
        self.lastFullUpdate = time
        
        -- find all things that recently dealt damage to this team
        
        do PROFILE("TeamBrain:Update - LiveEntities")

            for _, ent in ipairs( GetEntitiesWithMixinForTeam("Live", self.teamNumber) ) do     --??? Should this not just be looping over Memories? Do we NEED the GetEntitiesWithMixinForTeam? It's expensive
                local damageTime = ent:GetTimeOfLastDamage()

                if damageTime and ent:GetIsAlive() and damageTime + 1 > time then
                    local attackerId = ent:GetAttackerIdOfLastDamage()
                    local attacker = Shared.GetEntity(attackerId)

                    if attacker and attacker.GetIsAlive and attacker:GetIsAlive() and attacker.GetMapBlipInfo then

                        -- always update the entity memory when team entities are attacked
                        self:UpdateMemoryOfEntity(attacker, true)
                        
                        local atkMem = self.entId2memory[attackerId]
                        if atkMem then
                            local threat = self:CalcAttackerThreat(atkMem, ent)
                            self:UpdateMemoryThreatValue(atkMem, attacker, threat)
                        end
                        
                        -- Log("%d Attacker %s Defender %s threat %s", self.teamNumber, attacker, ent, threat)

                    end

                end
            end

        end

        -- handle audio-based "passive perception" for players on this team
        -- runs at reduced rate as sighted / in-combat entities are in the known entities list

        local aliveFriends = {}

        for _, friend in ipairs( GetEntitiesForTeam("Player", self.teamNumber) ) do
            if friend:GetIsAlive() then
                table.insert(aliveFriends, friend)
            end
        end
        
        -- treat hearing an enemy the same as seeing it; a little odd but works fine
        local enemySounds = GetAudibleEnemies(
            function (sound)
                if sound:GetIsPlaying() and sound.volume > 0 then
                    --TODO Use count of sounds marked by this and skew as "scene noise"? e.g. More combats sounds, would drown out footsteps, etc.
                    return self:GetIsSoundAudible(sound, aliveFriends)
                end
                return false
            end,
            GetEnemyTeamNumber(self.teamNumber))
        
        do PROFILE("TeamBrain:Update - Add SoundEntities")

        for _, sound in ipairs(enemySounds) do
            local parent = sound:GetParent()
            self:UpdateMemoryOfEntity(parent, true)
        end

        end

    end

    do PROFILE("TeamBrain:Update - ExpireMemories")
    ------------------------------------------
    --  Remove memories that have been investigated (ie. a marine went to the last known pos),
    --  but it has been a while since we last saw it
    ------------------------------------------
    local entMemories = self.entMemories
    local removeMemories = {}

    for i, mem in ipairs(entMemories) do

        local memEntId = mem.entId
        local ent = Shared.GetEntity(memEntId)
        local removeIt = true
        
        -- never forget hives and CCs
        if ent and ent:isa("CommandStructure") then
            removeIt = false
        end

        if ent and removeIt then
            local memAge = time - mem.lastSeenTime
            
            -- we time out very old player memories because they are
            -- not very likely to be around that long
            --BOT-FIXME: don't time-out player memories until their threat value has decayed fully
            local veryOldPlayerMemory = ent:isa("Player") and memAge > 5    --TODO Move '5' to some BotsGlobals file (or TeamBrainGlobals, etc.)
            if not veryOldPlayerMemory then
                
                removeIt = false                
                if memAge > 5 then    --TODO Move '5' to globals file

                    for _,playerId in ipairs(self.assignments:GetItems(mem.entId)) do
                        
                        local player = Shared.GetEntity(playerId)
                        if player then 
                            
                            local playerPos = player:GetOrigin()
                            local didInvestigate = mem.lastSeenPos:GetDistance(playerPos) < 4.0     --TODO Move '4.0' to some BotsGlobals like file
                            if didInvestigate then
                                removeIt = true
                                break
                            end
                        end    
                    end
                end
            end
        end

        if removeIt then
            -- if gBotDebug:Get("spam") then
            --     Log("... remove memory of %s", memEntId)
            -- end

            table.insert(removeMemories, memEntId)
        end

    end

    for i, entId in ipairs(removeMemories) do
        self:RemoveMemory(entId)
    end

    end

    if #self.teamAlerts > 0 then
        PROFILE("TeamBrain:Update - ProcessAlerts")

        local tmpAlerts = self.teamAlerts
        for a = 1, #tmpAlerts do

            local alert = tmpAlerts[a]
            if alert == nil then   --handle nil-gaps
                table.remove(self.teamAlerts, a)
                goto CONTINUE
            end

            if time - alert.time > 8 then   --TODO Move expire time to globals file
                table.remove(self.teamAlerts, a)
                goto CONTINUE
            end

            local alertEnt = Shared.GetEntity(alert.entId)
            if not alertEnt or ( alertEnt.GetIsAlive and not alertEnt:GetIsAlive() ) then
                table.remove(self.teamAlerts, a)
                goto CONTINUE
            end

            ::CONTINUE::
        end
        tmpAlerts = nil
    end

    --DebugPrint("%s mem has %d blips", self.label, GetTableSize(self.entId2memory) )

    if gBotDebug:Get("debugall") or gBotDebug:Get("debugteam") then
        self:DebugDraw()
    end

    self.lastUpdate = Shared.GetTime()

end

--[[
***TEMP***
Very quick HACK to add role-limiting for Aliens
...ideally, this would need to change....A LOT, based on a slew of factors...this is just proof-of-concept
--]]

--HACK for Aliens ONLY atm ...but should add one for Marines, maybe?
kAlienTeamRoleLimits = {}   --TODO, turn to %, based on 12p games, but scale up to Xp
kAlienTeamRoleLimits[kTechId.Gorge] = 2
kAlienTeamRoleLimits[kTechId.Lerk] = 4
kAlienTeamRoleLimits[kTechId.Fade] = 4
kAlienTeamRoleLimits[kTechId.Onos] = 4 --orginal 3
function TeamBrain:GetIsRoleAllowed(newRole)
    --[[
    if GetWarmupActive() then
        return true
    end
    --]]
    if self.teamRoles[newRole] ~= nil then
        return self.teamRoles[newRole] + 1 <= kAlienTeamRoleLimits[newRole]
    end
    return true
end

function TeamBrain:GetActiveRoles()
    return self.teamRoles
end

function TeamBrain:ReportBotRole( role )
    --?? assert on limit?
    self.teamRoles[role] = self.teamRoles[role] ~= nil and self.teamRoles[role] + 1 or 1
end

function TeamBrain:GetRoleCount(role)
    return self.teamRoles[role] or 0
end


------------------------------------------
--  Events from bots
------------------------------------------

------------------------------------------
--  Bots should call this when they assign themselves to a memory, e.g. a bot deciding to attack a hive.
--  Used for load-balancing purposes.
------------------------------------------
function TeamBrain:AssignBotToMemory( bot, mem )

    local player = bot:GetPlayer()
    assert(player ~= nil)
    assert(mem ~= nil)
    local playerId = player:GetId()

    self.assignments:Assign( playerId, mem.entId )

end

function TeamBrain:AssignBotToEntity( bot, entId )
    if entId == nil then
    --some basic data-quality safety
        return
    end

    local mem = self.entId2memory[entId]
    if mem then
        self:AssignBotToMemory( bot, mem )
    end

end

-- Assign the passed player to the specified entity-key
-- This key may be a direct entity ID as returned from Entity.GetId, or an "auxilliary key" composed from an arbitrary string and an entity ID
-- Implicitly unassigns the player from the previous assigned key, if any
-- NOTE: prefer using this function compared to AssignBotToEntity etc, as this avoids a costly bot:GetPlayer() call
function TeamBrain:AssignPlayerToEntity( player, entId )
    self.assignments:Assign( player:GetId(), entId )
end

function TeamBrain:UnassignBot( bot )

    local player = bot:GetPlayer()
    assert(player ~= nil)
    local playerId = player:GetId()

    self.assignments:Unassign(playerId)

end

-- Unassign this player from its previous assignment
-- NOTE: prefer using this function compared to UnassignBot as this avoids a costly bot:GetPlayer() call
function TeamBrain:UnassignPlayer( player )
    self.assignments:Unassign(player:GetId())
end

function TeamBrain:GetIsAssignedToEntity( player, entId )
    return self.assignments:GetIsAssignedTo( player:GetId(), entId )
end

function TeamBrain:GetNumAssignedTo( mem, countsFunc )

    return self.assignments:GetNumAssignedTo( mem.entId, countsFunc )

end

-- Returns the number of players assigned to the specified entity-key
function TeamBrain:GetNumAssignedToEntity( entId )

    PROFILE("TeamBrain:GetNumAssignedToEntity")

    return #self.assignments:GetItems( entId )

end

-- Calculate and return the number of other player IDs currently assigned to the given entity-key
function TeamBrain:GetNumOthersAssignedToEntity( player, entId )
    local items = self.assignments:GetItems(entId)
    local playerId = player:GetId()
    local n = 0

    for i = 1, #items do
        if items[i] ~= playerId then
            n = n + 1
        end
    end

    return n
end

-- Calculate and return the number of other bots currently assigned to the given goal name
function TeamBrain:GetNumOtherBotsWithGoal( bot, goalName )
    local count = 0

    for i = 1, #self.teamBots do
        local brain = self.teamBots[i].brain

        if self.teamBots[i] ~= bot and brain and brain.goalAction and brain.goalAction.name == goalName then
            count = count + 1
        end
    end

    return count
end

-- Calculate and return the number of other bots currently assigned to the given goal name
function TeamBrain:GetNumOtherBotsWithGoalDetails( bot, goalName, key, value )
    local count = 0

    for i = 1, #self.teamBots do
        local brain = self.teamBots[i].brain

        if self.teamBots[i] ~= bot and brain and brain.goalAction and brain.goalAction.name == goalName and brain.goalAction[key] == value then
            count = count + 1
        end
    end

    return count
end

-- Calculate and return the number of other bots currently executing the given action
function TeamBrain:GetNumOtherBotsWithActionDetails( bot, actionName, key, value )
    local count = 0

    for i = 1, #self.teamBots do
        local brain = self.teamBots[i].brain

        if self.teamBots[i] ~= bot and brain and brain.lastAction and brain.lastAction.name == actionName and brain.lastAction[key] == value then
            count = count + 1
        end
    end

    return count
end

function TeamBrain:DebugDump()

    function Group2String(memEntId)
        local mem = self.entId2memory[memEntId]
        return mem and MemoryToString(mem) or tostring(memEntId)
    end

    function Item2String(playerId)
        local player = Shared.GetEntity(playerId)
        assert( player ~= nil )
        return player:GetName()
    end

    self.assignments:DebugDump( Item2String, Group2String )

end

-- ==============================================

local function dump_teambrain(team)
    local brain = GetTeamBrain(team)

    Log("\t%d Command Structures", #brain.commandStructures)
    for _, loc in ipairs(brain.commandLocations) do
        Log("\t  - Loc: %s", loc)
    end

    Log("\tTotal Memories: %d", #brain.entMemories)
    for i = 1, 2 do
        local lm = brain.locationMemories[i]
        Log("\tLocation Memories: Team %d", i)

        for k, v in pairs(lm) do
            Log("\t  - Location [%s]: %d memories", k, #v)
            if brain.initialTechPointLoc == k then
                Log("\t    - IsStartingTechPoint")
            end
            if brain.commandLocations:Contains(k) then
                Log("\t    - IsCommandLocation")
            end
    
            for _, mem in ipairs(v) do
                Log("\t    - %s-%s, team: %s, threat: %s", kMinimapBlipType[mem.btype], mem.entId, mem.team, mem.threat)
            end
        end
    end


    local players = GetEntitiesAliveForTeam("Player", team)

    Log("\tAlive Players: %d", #players)
    for _, player in ipairs(players) do
        Log("\t  - [%s]: location=%s", player:GetName(), player:GetLocationName())
    end

    Log("\tBots: %d", #brain.teamBots)

    Log("")
end

--[[
if Server then
    Server.HookNetworkMessage("DumpTeamBrain", function()
        Log("Dump Team Brain Data:")
    
        Log("")
        Log("Brain 1:")
    
        dump_teambrain(kTeam1Index)
    
        Log("")
        Log("Brain 2:")
    
        dump_teambrain(kTeam2Index)
    end)
end
--]]
