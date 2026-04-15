Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/UtilityShared.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Pack.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Clamp = Clamp
local GetBotWalkDistance = GetBotWalkDistance
local GetTime = Shared.GetTime ---@type function
local ipairs = ipairs
local TContains = table.contains
local TInsert = table.insert
local TRemove = table.remove
local VectorsApproxEqual = VectorsApproxEqual

local GetClosestPointIndex = Bishop.lib.math.GetClosestPointIndex
local GetSignedDistanceFromPlane = Bishop.lib.math.GetSignedDistanceFromPlane
local IsPointWithinVolume = Bishop.lib.math.IsPointWithinVolume
local HasLineOfSight = Bishop.utility.HasLineOfSight

--------------------------------------------------------------------------------
-- Balance.
--------------------------------------------------------------------------------

local kMinWalkDistance = 15 -- Prefer immediate paths when available.
local kMaxDistanceSqr = 35 * 35 -- Only consider immediately available vents.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

Bishop.global.vents.kVentResult = enum({
  "NoVent",       -- No desire to move through a vent.
  "TravelToVent", -- Not close enough to hand over pathing control.
  "ExitVent",     -- Leaving a vent and returning to the nav mesh.
  "WithinVent",   -- Move target is within the current vent.
  "EnterVent",    -- Move to a vent entrance.
  "NavigateVent", -- Continue pathing through the current vent.
  "Direct"        -- Move target is directly visible in this vent.
})
local kHuge = math.huge
local kVentResult = Bishop.global.vents.kVentResult
local vd = Bishop.global.vents.data

---@class VentPath
---@field active boolean Whether this path is in use.
---@field atEntry boolean True when the bot has begun using a vent path.
---@field exitDistance number The walk distance from vent exit to destination.
---@field goalPos Vector The bot's original destination.
---@field goalSegment integer The final segment in this path.
---@field iter integer The current array index of the active PointArray.
---@field lastPos Vector The bot's previous position when last processed.
---@field path integer[] An ordered list of segments for this path.
---@field reverse integer[] A list of segments which must run in reverse.
---@field ventId integer The vent ID for this path.
---@field ventStuckPos Vector? Position for use with vent stuck detection.

-- TODO: There are cases where lastPos isn't being initialized for new paths.

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

---Returns the Vent with ventId.
---@param ventId integer
---@return Vent
function Bishop.global.vents.GetVent(ventId)
  return vd[ventId]
end

local GetVent = Bishop.global.vents.GetVent

---Returns the VentSegment structure for ventId and segmentId.
---@param ventId integer
---@param segmentId integer
---@return VentSegment
function Bishop.global.vents.GetVentSegment(ventId, segmentId)
  return GetVent(ventId).segments[segmentId]
end

local GetVentSegment = Bishop.global.vents.GetVentSegment

---Returns the appropriate segment length for the given vent segment and
---direction.
---@param ventId integer
---@param segmentId integer
---@param isReverse boolean
---@return number
local function GetVentSegmentLength(ventId, segmentId, isReverse)
  return isReverse and GetVentSegment(ventId, segmentId).lengthRev
    or GetVentSegment(ventId, segmentId).length
end

---Returns the appropriate PointArray for the given ventId and segmentId based
---on isReverse.
---@param ventId integer
---@param segmentId integer
---@param isReverse boolean
---@return Vector[]
local function GetVentSegmentPath(ventId, segmentId, isReverse)
  local segment = GetVentSegment(ventId, segmentId)
  return isReverse and segment.pathRev or segment.path
end

---Returns the current PointArray being used by ventPath.
---@param ventPath VentPath
---@return Vector[]
function Bishop.global.vents.GetCurrentVentPath(ventPath)
  local segmentId = ventPath.path[1]
  return GetVentSegmentPath(ventPath.ventId, segmentId,
    TContains(ventPath.reverse, segmentId))
end

local GetCurrentVentPath = Bishop.global.vents.GetCurrentVentPath

---Return the current vent segment's bias value.
---@param ventPath VentPath
---@return number
local function GetCurrentVentPathBias(ventPath)
  return GetVentSegment(ventPath.ventId, ventPath.path[1]).bias
end

---Returns the segment ID within ventId for the given point, or 0 if the point
---is not inside the vent.
---@param ventId any
---@param point any
---@return integer
local function GetVentSegmentForPoint(ventId, point)
  local vent = GetVent(ventId)
  if IsPointWithinVolume(point, vent.volume) then
    for i, segment in ipairs(vent.segments) do
      if not segment.plane
          or GetSignedDistanceFromPlane(segment.plane, point) < 0 then
        for _, volume in ipairs(segment.volumes) do
          if IsPointWithinVolume(point, volume) then
            return i
          end
        end
      end
    end
  end

  return 0
end

---Returns the segmentId for ventId containing the closest vent exit to point.
---@param ventId integer
---@param point Vector
---@return integer segmentId
---@return number exitDistance
local function GetClosestVentExitTo(ventId, point)
  local bestExit = 1
  local bestDistance = kHuge

  for i, segment in ipairs(GetVent(ventId).segments) do
    if TContains(segment.start, 0) then
      local exitDistance = GetBotWalkDistance(segment.startPos, point)
      if exitDistance < bestDistance then
        bestExit = i
        bestDistance = exitDistance
      end
    end

    if TContains(segment.finish, 0) then
      local exitDistance = GetBotWalkDistance(segment.finishPos, point)
      if exitDistance < bestDistance then
        bestExit = i
        bestDistance = exitDistance
      end
    end
  end

  return bestExit, bestDistance
end

---Determines whether vent entrances are further away than walkDistance, or the
---vent is too far away to be considered useful
---@param start Vector
---@param ventId integer
---@param walkDistance number
---@return boolean
local function IsVentIdeal(start, ventId, walkDistance)
  -- If the walkDistance is sufficiently low enough, there is no point wasting
  -- time with a vent path since the target is likely close.
  if walkDistance < kMinWalkDistance then
    return false
  end

  for _, segment in ipairs(GetVent(ventId).segments) do
    if (TContains(segment.start, 0)
        and start:GetDistanceSquared(segment.startPos) <= kMaxDistanceSqr
        and GetBotWalkDistance(start, segment.startPos) < walkDistance)

        or (TContains(segment.finish, 0)
        and start:GetDistanceSquared(segment.finishPos) <= kMaxDistanceSqr
        and GetBotWalkDistance(start, segment.finishPos) < walkDistance) then
      return true
    end
  end

  return false
end

---Returns the entrance point of an already generated path.
---@param ventPath VentPath
---@return Vector
function Bishop.global.vents.GetPathEntrancePoint(ventPath)
  local segmentId = ventPath.path[1]
  local path = GetCurrentVentPath(ventPath)
  return TContains(ventPath.reverse, segmentId) and path[#path] or path[1]
end

local GetPathEntrancePoint = Bishop.global.vents.GetPathEntrancePoint

---Returns an estimate of the current segment's remaining distance.
---@param ventPath VentPath
---@param position Vector
---@return number
local function MeasureSegmentPathDistance(ventPath, position)
  local segmentId = ventPath.path[1]
  local isReverse = TContains(ventPath.reverse, segmentId)
  local path = GetCurrentVentPath(ventPath)
  local currIter = ventPath.iter
  local prevIter = isReverse and currIter + 1 or currIter - 1
  local progress = 0.0 -- Rough estimate of percentage to next iter.

  -- Assuming each point in the path is roughly the same distance apart provides
  -- a cheap alternative to computing the exact length.
  if prevIter > 0 and prevIter <= #path then
    local distanceToPrev = position:GetDistance(path[currIter])
    local distanceToCurr = position:GetDistance(path[prevIter])
    progress = distanceToCurr / (distanceToPrev + distanceToCurr)
    progress = Clamp(progress, 0, 1)
  end

  local estimatedIter = isReverse and (currIter + progress)
    or (currIter - progress)
  local percent = isReverse and ((#path - estimatedIter) / #path)
    or (estimatedIter / #path)

  return percent * GetVentSegmentLength(ventPath.ventId, segmentId,
    TContains(ventPath.reverse, segmentId))
end

---Returns an estimate of the total remaining vent path distance.
---@param ventPath VentPath
---@param position Vector
---@return number
function Bishop.global.vents.MeasureVentPathDistance(ventPath, position)
  if not ventPath.active then return 0.0 end

  local distance = MeasureSegmentPathDistance(ventPath, position)
  local ventId = ventPath.ventId

  for i = 2, #ventPath.path do
    local segmentId = ventPath.path[i]
    if segmentId > 0 then
      distance = distance + GetVentSegmentLength(ventId, segmentId,
        TContains(ventPath.reverse, segmentId))
    end
  end

  return distance
end

local MeasureVentPathDistance = Bishop.global.vents.MeasureVentPathDistance

---Returns the total (entrance + traversal + exit) distance of a vent path
---weighted by segment bias and entropy.
---@param bot Bot
---@param start Vector
---@param path VentPath
---@param isInside boolean
---@return number
local function GetBiasedDistance(bot, start, path, isInside)
  -- The bias is not applied to the exit->finish distance to prevent loops.
  local enterDistance = isInside and 0.0
    or GetBotWalkDistance(start, GetPathEntrancePoint(path))
  --[[ return ((enterDistance + GetVent(path.ventId).length)
    * GetCurrentVentPathBias(path) + path.exitDistance) * bot.ventEntropy ]]

  -- TODO: The new system albeit slightly more accurate is a gross overestimate
  -- due to how GetBotWalkDistance works. For now the old measurement is being
  -- used.
  return ((enterDistance + MeasureVentPathDistance(path, start))
    * GetCurrentVentPathBias(path) + path.exitDistance) * bot.ventEntropy
end

---Returns the midpoint between the bot's origin and eye position.
---@param bot Bot
---@return Vector
local function GetOriginEyePosAverage(bot)
  local player = bot:GetPlayer()
  return (player:GetEyePos() + player:GetOrigin()) / 2
end

--------------------------------------------------------------------------------
-- Breadth first search implementation over vent segments.
--------------------------------------------------------------------------------
-- VentBFS assumes all segments are the same length to avoid expensive distance
-- calculations. Therefore the goal is to minimize the total number of segments
-- in the path.

---Calculates which path segments need to be run in reverse and inserts them
---into the ventPath structure.
---@param ventPath VentPath
local function CalculateReversePaths(ventPath)
  local segmentPath = ventPath.path
  local segments = GetVent(ventPath.ventId).segments

  for i = 1, #segmentPath - 1 do
    local thisSegment = segmentPath[i]
    local nextSegment = segmentPath[i+1]
    if TContains(segments[thisSegment].start, nextSegment) then
      TInsert(ventPath.reverse, thisSegment)
    end
  end

  if #segmentPath > 1 and segmentPath[#segmentPath] ~= 0 then
    local thisSegment = segmentPath[#segmentPath]
    local prevSegment = segmentPath[#segmentPath-1]
    if TContains(segments[prevSegment].start, thisSegment) then
      TInsert(ventPath.reverse, thisSegment)
    end
  end
end

---Generates a path structure for ventId that starts at startSegment and leads
---to finishSegment.
---@param ventId integer
---@param startSegment integer
---@param finishSegment integer
---@param isInVent boolean
---@param shouldExitVent boolean
---@param start Vector
---@param finish Vector
---@return VentPath
local function VentBFS(ventId, startSegment, finishSegment, isInVent,
    shouldExitVent, start, finish)
  local path = { ---@type VentPath
    active = true,
    atEntry = false,
    ventId = ventId,
    path = { startSegment },
    reverse = {},
    goalSegment = finishSegment,
    goalPos = finish,
    lastPos = Vector(0, 0, 0),
    iter = 1,
    exitDistance = 0
  }

  local parents = {}
  do
    local queue = {startSegment}
    local visited = {startSegment}
    local segments = GetVent(ventId).segments
    
    while #queue > 0 do
      local currentSegment = queue[1]

      if currentSegment > 0 then
        for _, segmentId in ipairs(segments[currentSegment].start) do
          if not TContains(visited, segmentId) then
            TInsert(queue, segmentId)
            TInsert(visited, segmentId)
            parents[segmentId] = currentSegment
          end
        end

        for _, segmentId in ipairs(segments[currentSegment].finish) do
          if not TContains(visited, segmentId) then
            TInsert(queue, segmentId)
            TInsert(visited, segmentId)
            parents[segmentId] = currentSegment
          end
        end

        if parents[finishSegment] ~= nil then
          break
        end
      end

      TRemove(queue, 1)
    end
  end

  while finishSegment ~= startSegment do
    TInsert(path.path, 2, finishSegment)
    finishSegment = parents[finishSegment]
  end

  -- TODO: May not be necessary anymore. Experiment.
  if shouldExitVent then
    TInsert(path.path, 0)
  end

  CalculateReversePaths(path)
  if isInVent then
    path.iter = GetClosestPointIndex(GetCurrentVentPath(path), start)
  elseif TContains(path.reverse, path.path[1]) then
    path.iter = #GetCurrentVentPath(path)
  end

  return path
end

--------------------------------------------------------------------------------
-- Primary calls for vent pathing.
--------------------------------------------------------------------------------

---Generates a path from currentSegment to desiredSegment within the same vent.
---@param ventId integer
---@param currentSegment integer
---@param desiredSegment integer
---@param start Vector
---@param finish Vector
---@return integer result
---@return VentPath ventPath
---@return number distance
local function GetInterVentPath(ventId, currentSegment, desiredSegment, start,
    finish)
  if currentSegment == desiredSegment then
    local segmentPath = GetVentSegmentPath(ventId, currentSegment, false)
    local startIter = GetClosestPointIndex(segmentPath, start)
    local finishIter = GetClosestPointIndex(segmentPath, finish)
    local path = {
      active = true,
      ventId = ventId,
      path = { currentSegment },
      reverse = startIter > finishIter and { currentSegment } or {},
      goalSegment = desiredSegment,
      goalPos = finish,
      lastPos = start,
      iter = startIter,
      exitDistance = 0
    }
    return kVentResult.WithinVent, path, -1
  end

  local path = VentBFS(ventId, currentSegment, desiredSegment, true, false,
    start, finish)
  -- Returning -1 distance enforces a high priority.
  return kVentResult.WithinVent, path, -1
end

---Optimized traversal for simple A-B vents. Refuses to generate a path if the
---best entrance is also the best exit.
---@param ventId integer
---@param start Vector
---@param finish Vector
---@return VentPath?
local function GetSimpleVentPath(ventId, start, finish)
  local segment = GetVentSegment(ventId, 1)
  local shouldStartAtFront = GetBotWalkDistance(start, segment.startPos)
    < GetBotWalkDistance(start, segment.finishPos)
  local forwardDistance = GetBotWalkDistance(segment.finishPos, finish)
  local reverseDistance = GetBotWalkDistance(segment.startPos, finish)
  local shouldEndAtFront = reverseDistance < forwardDistance

  if shouldStartAtFront == shouldEndAtFront then return nil end

  return {
    active = true,
    ventId = ventId,
    path = { 1, 0 },
    reverse = shouldStartAtFront and {} or {1},
    goalSegment = 1,
    goalPos = finish,
    lastPos = start,
    iter = shouldStartAtFront and 1 or #segment.pathRev,
    exitDistance = shouldStartAtFront and forwardDistance or reverseDistance
  }
end

---Optimized exit pathing for simple A-B vents. Returns an exit path without
---invoking the pathfinder.
---@param ventId integer
---@param start Vector
---@param finish Vector
---@return VentPath
local function GetExitSimpleVentPath(ventId, start, finish)
  local segment = GetVentSegment(ventId, 1)
  local forwardDistance = GetBotWalkDistance(segment.finishPos, finish)
  local reverseDistance = GetBotWalkDistance(segment.startPos, finish)
  local shouldReverse = reverseDistance < forwardDistance
  return {
    active = true,
    ventId = ventId,
    path = { 1, 0 },
    reverse = shouldReverse and {1} or {},
    goalSegment = 1,
    goalPos = finish,
    lastPos = start,
    iter = shouldReverse and #segment.pathRev or 1,
    exitDistance = shouldReverse and reverseDistance or forwardDistance
  }
end

---Generates a path starting from within a vent back out to the regular map.
---@param ventId integer
---@param currentSegment integer
---@param start Vector
---@param finish Vector
---@return integer result
---@return VentPath ventPath
---@return number distance
local function GetExitVentPath(ventId, currentSegment, start, finish)
  if #GetVent(ventId).segments == 1 then
    local path = GetExitSimpleVentPath(ventId, start, finish)
    return kVentResult.NavigateVent, path, -1
  end

  local bestExit, bestDistance = GetClosestVentExitTo(ventId, finish)
  local path = VentBFS(ventId, currentSegment, bestExit, true, true, start,
    finish)
  path.exitDistance = bestDistance

  -- Returning -1 distance enforces a high priority.
  return kVentResult.NavigateVent, path, -1
end

---Returns a vent path from outside to within the vent.
---@param ventId integer
---@param desiredSegment integer
---@param start Vector
---@param finish Vector
---@return integer result
---@return VentPath ventPath
---@return number distance
local function GetEnterVentPath(ventId, desiredSegment, start, finish)
  local bestEntrance = GetClosestVentExitTo(ventId, start)
  local path = VentBFS(ventId, bestEntrance, desiredSegment, false, false,
    start, finish)

  -- Returning -1 distance enforces a high priority.
  return kVentResult.EnterVent, path, -1
end

---Returns a full vent traversal path, including entry and exit.
---@param bot Bot
---@param ventId integer
---@param start Vector
---@param finish Vector
---@return integer result
---@return VentPath? ventPath
---@return number? distance
local function GetVentPath(bot, ventId, start, finish)
  if #GetVent(ventId).segments == 1 then
    local path = GetSimpleVentPath(ventId, start, finish)
    if path then
      return kVentResult.EnterVent, path,
        GetBiasedDistance(bot, start, path, false)
    else
      return kVentResult.NoVent
    end
  end

  local bestEntrance = GetClosestVentExitTo(ventId, start)
  local bestExit, distance = GetClosestVentExitTo(ventId, finish)
  if bestEntrance == bestExit then
    return kVentResult.NoVent
  end

  local path = VentBFS(ventId, bestEntrance, bestExit, false, true, start,
    finish)
  path.exitDistance = distance
  return kVentResult.EnterVent, path,
    GetBiasedDistance(bot, start, path, false)
end

---Finds a relevant path using ventId given start and end points.
---Pass the engagement point instead of the eyepos or origin to get a more
---accurate vent volume reading.
---@param bot Bot
---@param ventId integer
---@param start Vector
---@param finish Vector
---@param walkDistance number
---@return integer result
---@return VentPath? ventPath
---@return number? distance
function Bishop.global.vents.GetBestVentPath(bot, ventId, start, finish,
    walkDistance)
  local scanPoint = GetOriginEyePosAverage(bot)
  local currentSegment = GetVentSegmentForPoint(ventId, scanPoint)
  local desiredSegment = GetVentSegmentForPoint(ventId, finish)
  local ventPath = bot.ventPath and bot.ventPath.active
    and bot.ventPath.ventId == ventId and bot.ventPath or {}

  -- Fast path if no update is required.
  if not ventPath.active and GetTime() < bot.nextVentScanTime
      and currentSegment == 0 and desiredSegment == 0 then
    return kVentResult.NoVent
  end

  -- Already in a vent, path is within the same vent.
  if currentSegment > 0 and desiredSegment > 0 then
    if HasLineOfSight(bot, scanPoint, finish) then
      return kVentResult.Direct, nil, start:GetDistance(finish)
    end

    if ventPath.active and ventPath.goalSegment == desiredSegment
        and VectorsApproxEqual(start, ventPath.lastPos, 16) then
      return kVentResult.WithinVent, nil, GetBiasedDistance(bot, start,
        ventPath, true)
    end

    return GetInterVentPath(ventId, currentSegment, desiredSegment, start,
      finish)

  -- Already in a vent, path leads outside the vent.
  elseif currentSegment > 0 then
    -- Allow bypassing invalidation for bots leaving vents.
    if (ventPath.active or ventPath.goalPos)
        and VectorsApproxEqual(ventPath.goalPos, finish, 9)
        and VectorsApproxEqual(start, ventPath.lastPos, 16) then
      return kVentResult.NavigateVent, nil, ventPath.exitDistance
    end

    return GetExitVentPath(ventId, currentSegment, start, finish)

  -- Not in a vent, desired point is within the vent.
  elseif desiredSegment > 0 then
    if ventPath.active and VectorsApproxEqual(ventPath.goalPos, finish, 9) then
      return kVentResult.EnterVent, nil, GetBotWalkDistance(start,
        GetPathEntrancePoint(ventPath))
    end

    return GetEnterVentPath(ventId, desiredSegment, start, finish)

  -- Calculate a vent path in, through and out of this vent.
  else
    local packLeader = bot.brain and bot.brain.pack
      and bot.brain.pack.leader == bot.brain

    if ventPath.active and VectorsApproxEqual(ventPath.goalPos, finish, 9)
        and not packLeader then
      -- TODO: Does this function even need to return distance for active paths?
      return kVentResult.EnterVent, nil,
        GetBiasedDistance(bot, start, ventPath, false)
    end

    if not packLeader and IsVentIdeal(start, ventId, walkDistance) then
      return GetVentPath(bot, ventId, start, finish)
    end
  end

  return kVentResult.NoVent
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
