Script.Load("lua/bishop/utility/WaypointTools.lua")
Script.Load("lua/bishop/BishopSettings.lua")

if not Server then
  return
end

Script.Load("lua/bishop/lib/Constants.lua")
Script.Load("lua/bishop/lib/Entity.lua")
Script.Load("lua/bishop/lib/Math.lua")
Script.Load("lua/bishop/lib/Table.lua")

Script.Load("lua/BuildUtility.lua")
Script.Load("lua/CollisionRep.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/TechData.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/Vector.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/PlayerBrain.lua")

Script.Load("lua/bishop/global/BotUtils.lua")
Script.Load("lua/bishop/system/BotManager.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local cos = math.cos
local EntityFilterAllButIsaTechPoint = EntityFilterAllButIsa("TechPoint")
local EntityFilterAll = EntityFilterAll()
local GetDistanceToTouch = GetDistanceToTouch
local GetExtents = GetExtents
local GetIsBuildLegal = GetIsBuildLegal
local GetLocationForPoint = GetLocationForPoint
local GetNormalizedVector = GetNormalizedVector
local GetNormalizedVectorXZ = GetNormalizedVectorXZ
local GetTeamMemories = GetTeamMemories
local ipairs = ipairs
local math = math
local Pathing_GetClosestPoint = Pathing.GetClosestPoint
local random = math.random
local GetTime = Shared.GetTime ---@type function
local TraceRay = Shared.TraceRay ---@type function
local sin = math.sin
local table_contains = table.contains
local table_insert = table.insert
local ValidateSpawnPoint = ValidateSpawnPoint

local GetCachedTable = Bishop.lib.table.GetCachedTable

-- These are here to assist with VS Code context and completion.

---@class Move
---@field commands integer

---@class PlayerBrain
---@field activeRetreat boolean -- TODO: Should retreat data be elsewhere?
---@field GetSenses function
---@field isa function
---@field pack AlienPack? -- TODO: Should pack data be elsewhere?
---@field packLock boolean -- TODO: Should pack data be elsewhere?
---@field player ScriptActor?
---@field teamBrain TeamBrain

---@class Trace
---@field endPoint Vector
---@field fraction number

-- TODO: It's probably time to move all the building stuff into its own file.

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kBodyBlockDistance = 2.75    -- Bodyblocks considered within this range.
local kMinFacingTolerance = 0.67   -- Cosine above this is considered facing.

local kBuildingPadding = 0.4       -- Distance from walls and other buildings.
local kBuildingPaddingOverride = { -- Custom padding for certain buildings.
  [kTechId.Armory]        = 1.5,
  [kTechId.PhaseGate]     = 1.5,
  [kTechId.Sentry]        = 1.0,
  [kTechId.SentryBattery] = 2.5
}

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local CollisionRep_Default = CollisionRep.Default
local CollisionRep_Select = CollisionRep.Select
local kCircle = 2 * math.pi
local kStructureSnapRadius = kStructureSnapRadius
local kTechId = kTechId
local kTraceHeight = 20
local kVectorDown = Vector(0, -20, 0)
local kVectorUp = Vector(0, 0.5, 0)
local kVectorUpSlightly = Vector(0, 0.05, 0)
local PhysicsMask_AllButPCsAndRagdolls = PhysicsMask.AllButPCsAndRagdolls
local PhysicsMask_CommanderBuild = PhysicsMask.CommanderBuild

--------------------------------------------------------------------------------
-- Bot memories.
--------------------------------------------------------------------------------

-- Search the bot memories of team for btype.
-- Pass in kAlienTeamType or kMarineTeamType and an entry from kMinimapBlipType.
function Bishop.utility.SearchMemoriesFor(team, btype)
  local result = {}
  local memories = GetTeamMemories(kAlienTeamType)

  for _, memory in ipairs(memories) do
    if memory.btype == btype then
      table_insert(result, memory)
    end
  end

  return result
end

-- Search the bot memories of team for any in btypes.
-- Pass in kAlienTeamType or kMarineTeamType and an array of kMinimapBlipTypes.
function Bishop.utility.SearchMemoriesForAny(team, btypes)
  local result = {}
  local memories = GetTeamMemories(kAlienTeamType)

  for _, memory in ipairs(memories) do
    if table_contains(btypes, memory.btype) then
      table_insert(result, memory)
    end
  end

  return result
end

-- Returns true if any of entities are within squared range of point. Point can
-- be a position or an entity.
function Bishop.utility.EntityWithinSqrRange(point, entities, range)
  if point:isa("Entity") then
    point = point:GetOrigin()
  end
  for _, entity in ipairs(entities) do
    if entity:GetDistanceSquared(point) <= range then
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- Bot movement.
--------------------------------------------------------------------------------

-- Amount of sway (in radians) to apply if a bot is backpedalling.
local kBackPedalSway = math.pi / 6
-- Length of the sway sine wave in 2*pi / seconds.
local kBackPedalSwayTime = 2 * math.pi / 2

-- Returns a backpedal vector with a small amount of sway applied over time.
function Bishop.utility.GetBackpedalVector(alien, backAwayFrom)
  local position = alien:GetOrigin()
  local teammatePosition = backAwayFrom:GetOrigin()
  local vector = GetNormalizedVector(position - teammatePosition)

  local swayTime = kBackPedalSwayTime * GetTime()
  local sway = kBackPedalSway * sin(swayTime)
  local cosSway = cos(sway)
  local sinSway = sin(sway)

  return Vector(
    cosSway * vector.x - sinSway * vector.z,
    vector.y,
    sinSway * vector.x + cosSway * vector.z)
end

-- Returns the appropriate DoMove function for the given kTechId class. This is
-- used when a function is shared amongst multiple classes.
function Bishop.utility.GetMoveFunction(lifeform)
  if lifeform == kTechId.Skulk then
    return Bishop.alien.skulk.DoMove
  elseif lifeform == kTechId.Gorge then
    return Bishop.alien.gorge.DoMove
  elseif lifeform == kTechId.Lerk then
    return Bishop.alien.lerk.DoMove
  elseif lifeform == kTechId.Fade then
    return Bishop.alien.fade.DoMove
  elseif lifeform == kTechId.Onos then
    return Bishop.alien.onos.DoMove
  end
end

local performAttackFunctions = {}

---Gets the function used by attac actions for techId.
---@param techId integer
---@return function
function Bishop.utility.GetPerformAttackFunction(techId)
  return performAttackFunctions[techId]
end

---Sets the function used by attack actions for techId.
---@param techId integer
---@param func function
function Bishop.utility.SetPerformAttackFunction(techId, func)
  performAttackFunctions[techId] = func
end

function Bishop.utility.GetMarineMoveFunction(marine)
  if marine:isa("Exo") then
    return Bishop.marine.exo.DoMove
  end
  return Bishop.marine.DoMove
end

function Bishop.utility.IsFacing(entity, targetOrigin)
  -- Don't use GetEyePos() here since aliens can actually clip!
  local position = entity:GetOrigin()
  local viewDirection = GetNormalizedVectorXZ(entity:GetViewCoords().zAxis)
  local targetDirection = GetNormalizedVector(targetOrigin - position)

  return viewDirection:DotProduct(targetDirection) >= kMinFacingTolerance
end
local IsFacing = Bishop.utility.IsFacing

-- Returns true if alien and teammate are within kBodyBlockDistance of each
-- other and facing each other.
function Bishop.utility.IsTeammateBlocking(alien, teammate)
  local eyePos = alien:GetEyePos()
  local distance = GetDistanceToTouch(eyePos, teammate)

  if distance > kBodyBlockDistance then
    return false
  end

  return IsFacing(alien, teammate:GetOrigin())
    and IsFacing(teammate, alien:GetOrigin())
end

local kMaxDistanceFromNavmesh = 0.65

-- Returns true if entity is on or reasonably near the nav mesh, otherwise
-- returns false.
function Bishop.utility.IsOnNavMesh(entity)
  local position = entity:GetOrigin()
  local closestNavPosition = Pathing_GetClosestPoint(position)

  if position:GetDistance(closestNavPosition) > kMaxDistanceFromNavmesh then
    return false
  end

  return true
end

--------------------------------------------------------------------------------
-- Building.
--------------------------------------------------------------------------------

function Bishop.utility.IsPositionSafe(team, brain, position)
  local location = GetLocationForPoint(position)
  if not location then
    return true
  end

  return brain:GetIsSafeToDropInLocation(location:GetName(), team)
end

--------------------------------------------------------------------------------
-- Ray tracing.
--------------------------------------------------------------------------------
-- Previous attempts at bot point selection weren't taking map geometry into
-- account. Continue the trace until it falls through the world or finds a
-- floor.

local function BDebugLine() end
if Bishop.debug.rayTrace then
  BDebugLine = function(start, _end, t, r, g, b, a)
    DebugLine(start, _end, t, r, g, b, a)
  end
end

-- This is a stripped down adaptation of how mouse clicks are handled for human
-- commanders, with the assumption that the bot commander's camera is always
-- directly above its target.
function Bishop.utility.TraceFromAbove(point, radius)
  local topPoint = Vector(point.x, point.y + kTraceHeight, point.z)
  local randomAngle = random() * kCircle
  local bottomPoint = Vector(
    point.x + cos(randomAngle) * radius,
    point.y,
    point.z + sin(randomAngle) * radius)
  local pickVec = GetNormalizedVector(bottomPoint - topPoint)
  bottomPoint = topPoint + pickVec * 1000

  local trace
  while true do
    trace = TraceRay(topPoint, bottomPoint, CollisionRep_Select,
      PhysicsMask_CommanderBuild, EntityFilterAllButIsaTechPoint)
    local hitDistance = (topPoint - trace.endPoint):GetLength()

    -- The trace began from inside a surface.
    if trace.fraction == 0 or hitDistance < 0.1 then
      BDebugLine(topPoint, bottomPoint, 0.1, 0, 0, 1, 1)
      topPoint = topPoint + pickVec
    
    -- The ray went through the world without hitting anything.
    elseif trace.fraction == 1 then
      BDebugLine(topPoint, bottomPoint, 0.1, 1, 0, 0, 1)
      return nil
    
    -- The ray impacted a surface facing down. (i.e. roof geometry.)
    elseif trace.normal.y < 0 then
      BDebugLine(topPoint, trace.endPoint, 0.1, 1, 1, 0, 1)
      topPoint = trace.endPoint + pickVec * 0.01

    -- Successful trace!
    else
      BDebugLine(topPoint, trace.endPoint, 0.5, 0, 1, 0, 1)
      break
    end
  end

  return trace
end

local TraceFromAbove = Bishop.utility.TraceFromAbove

function Bishop.utility.TraceBuildPosition(point, minRadius, maxRadius, techId,
    locName, com)
  -- Is Wayne Brady gonna have to choke a bitch?
  local trace
  do
    local radius = random() * (maxRadius - minRadius) + minRadius
    trace = TraceFromAbove(point, radius)
    if not trace then
      return nil
    end
  end

  -- If locName is not nil, the point is rejected if outside of that location.
  -- Helps prevent duplicate building placement on tight maps like ns2_jambi.
  if locName and locName ~= "" then
    local location = GetLocationForPoint(trace.endPoint)
    if location and location:GetName() ~= locName then
      return nil
    end
  end

  -- Depending on the map, valid building positions aren't guaranteed to be
  -- pathable by bots.
  local position
  do
    local isLegal
    isLegal, position = GetIsBuildLegal(techId, trace.endPoint, 0,
      kStructureSnapRadius, com)
    if not isLegal or Pathing_GetClosestPoint(position) == position then
      return nil
    end
  end

  -- Enforce spacing from walls and other buildings. This is mainly for Phase
  -- Gates being placed hard against a wall where bots will struggle to path
  -- towars the entry. ValidateSpawnPoint returns nil if the check fails.
  if techId ~= kTechId.Cyst then
    local extents = GetExtents(techId)
    local capsuleHeight = extents.y
    local capsuleRadius = extents.x
      + (kBuildingPaddingOverride[techId] or kBuildingPadding)
    position = ValidateSpawnPoint(position + kVectorUp, capsuleHeight,
      capsuleRadius, EntityFilterAll, position + kVectorUpSlightly)
  end

  return position
end

---Direct call to TraceRay, use sparingly or throttle manually.
---@param start Vector
---@param finish Vector
---@return table?
function Bishop.utility.TraceRayDirect(start, finish)
  return TraceRay(start, finish, CollisionRep_Default,
    PhysicsMask_AllButPCsAndRagdolls, EntityFilterAll)
end

-- Traces are throttled to prevent bursts of traces when fastUpdate = true. This
-- obviously sacrifices accuracy but 1/8th of a second is acceptable.
local kPlayerBrainTickFrametime = kPlayerBrainTickFrametime

---Returns true if start has direct LOS to finish, ignoring entities.
---@param bot Bot
---@param start Vector
---@param finish Vector
---@return boolean
function Bishop.utility.HasLineOfSight(bot, start, finish)
  local time = GetTime()
  local traceData = GetCachedTable(bot, "trace")

  if not traceData.losTraceTime or time >= traceData.losTraceTime then
    traceData.losTraceTime = time + kPlayerBrainTickFrametime

    local trace = TraceRay(start, finish, CollisionRep_Default,
      PhysicsMask_AllButPCsAndRagdolls, EntityFilterAll)
    traceData.losTraceResult = trace and trace.fraction == 1
  end

  return traceData.losTraceResult
end

---Returns a rate-limited ray trace to the specified target position.
---@param player Player
---@param origin Vector
---@param target Vector
---@return Trace?
function Bishop.utility.GetTargetTrace(player, origin, target)
  local time = GetTime()
  local traceData = GetCachedTable(player, "trace")

  if not traceData.tgtTraceTime or time >= traceData.tgtTraceTime then
    traceData.tgtTraceTime = time + kPlayerBrainTickFrametime
    traceData.tgtTrace = TraceRay(origin, target, CollisionRep_Default,
      PhysicsMask_AllButPCsAndRagdolls, EntityFilterAll)
  end

  return traceData.tgtTrace
end

---Returns a rate-limited ray trace to the ground directly below the bot.
---@param player Player
---@param origin Vector
---@return Trace?
function Bishop.utility.GetGroundTrace(player, origin)
  local time = GetTime()
  local traceData = GetCachedTable(player, "trace")

  if not traceData.groundTraceTime or time >= traceData.groundTraceTime then
    traceData.groundTraceTime = time + kPlayerBrainTickFrametime
    traceData.groundTrace = TraceRay(origin, origin + kVectorDown,
      CollisionRep_Default, PhysicsMask_AllButPCsAndRagdolls, EntityFilterAll)
  end

  return traceData.groundTrace
end

--------------------------------------------------------------------------------
-- Tech related functions.
--------------------------------------------------------------------------------

---Returns true if techId is researched or currently researching.
---@param com Entity
---@param techId integer
---@return boolean
function Bishop.utility.IsTechStarted(com, techId)
  local techTree = GetTechTree(com:GetTeamNumber())
  local techNode = techTree and techTree:GetTechNode(techId) or nil

  if not techTree or not techNode then return false end
  return (techNode:GetResearched() and techTree:GetHasTech(techId)) or
    techNode:GetResearching()
end

--------------------------------------------------------------------------------
-- Geometry and volumes.
--------------------------------------------------------------------------------

---@class MemoryDistanceSqr
---@field memory TeamBrain.Memory|nil
---@field distanceSqr number|nil

---@param entity Entity
---@param memories TeamBrain.Memory[]
---@return MemoryDistanceSqr
function Bishop.utility.GetClosestMemoryTo(entity, memories)
  local minDistanceSqr = math.huge
  local closestMemory

  for _, mem in ipairs(memories) do
    local distanceSqr = entity:GetDistanceSquared(mem.lastSeenPos)
    if distanceSqr < minDistanceSqr then
      minDistanceSqr = distanceSqr
      closestMemory = mem
    end
  end

  return {
    memory = closestMemory,
    distanceSqr = closestMemory and minDistanceSqr or nil
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
