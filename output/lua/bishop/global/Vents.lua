Script.Load("lua/Table.lua")
Script.Load("lua/UtilityShared.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/data/VentPaths.lua")
Script.Load("lua/bishop/global/VentLoader.lua")
Script.Load("lua/bishop/global/VentPathing.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Clamp = Clamp
local DebugLine = DebugLine
local DotProduct = Math.DotProduct ---@type function
local GetBotWalkDistance = GetBotWalkDistance
local GetTime = Shared.GetTime ---@type function
local max = math.max
local min = math.min
local random = math.random
local TContains = table.contains
local TRemove = table.remove

local GetBestVentPath = Bishop.global.vents.GetBestVentPath
local GetClosestPointIndex = Bishop.lib.math.GetClosestPointIndex
local GetCurrentVentPath = Bishop.global.vents.GetCurrentVentPath
local GetPathEntrancePoint = Bishop.global.vents.GetPathEntrancePoint
local GetVent = Bishop.global.vents.GetVent
local GetVentSegment = Bishop.global.vents.GetVentSegment
local Log = Bishop.debug.VentLog
local MeasureVentPathDistance = Bishop.global.vents.MeasureVentPathDistance

-- TODO: Perhaps vents should cache a table of all vent exit positions and which
-- segment they belong to.

---@class VentSegment
---@field bias number Hardcoded path bonus or penalty to scale vent usage.
---@field debugEntryCount integer The number of recorded bot entries.
---@field debugGenCount integer The number of paths generated.
---@field finish integer[] List of segments connected to the end of this one.
---@field finishPos Vector End position of the path.
---@field length number Exact length of segment path.
---@field lengthRev number Exact length of segment reverse path.
---@field path Vector[] The PointArray for this segment.
---@field pathRev Vector[] The PointArray for this segment's reverse path.
---@field plane Plane? An optional plane that slices the volumes.
---@field start integer[] List of segments connected to the start of this one.
---@field startPos Vector Start position of the path.
---@field volumes Volume[] An array of volumes that enclose this segment.

---@class Vent
---@field debugEntryCount integer The number of recorded bot entries.
---@field debugGenCount integer The number of paths generated.
---@field length number The average segment length of this vent. TODO: Unused.
---@field segments VentSegment[] Array of segments for this vent indexed by ID.
---@field volume Volume The union of all segment volumes for this vent.

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kEntropyUpdateTime = 10 -- Time between updating randomized entropy.
local kMaxEntropy = 1.20 -- Randomized path cost to make usage unpredictable.
local kMinEntropy = 0.50
local kEntropyRange = kMaxEntropy - kMinEntropy
local kResetTime = 10 -- Force invalidate a vent path periodically.
local kResetToleranceSqr = 5 -- Minimum progress to ignore stuck condition.
local kVentScanFrequency = 1 -- Throttle full vent scans.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kDebug = Bishop.debug.vents
local kDebugVecUp = Vector(0, 5, 0)
local kVecDown = Vector(0, -1, 0)
local kVecUp = Vector(0, 1, 0)
local kVentResult = Bishop.global.vents.kVentResult
local vd = Bishop.global.vents.data

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

---@param bot Bot
---@return VentPath
local function GetBotVentPath(bot)
  return bot.ventPath or {}
end

-- TODO: Move this into BotMotion.
-- Sets the bot's view and movement directly towards "to". Functions anywhere,
-- including off the nav mesh.
local function MoveDirectlyTo(motion, from, to)
  motion:SetDesiredMoveDirection((to - from):GetUnit())
  motion:SetDesiredViewTarget(to)
end

---Randomizes penalty to reduce predictiveness of pathing.
---@param bot Bot
local function UpdateVentEntropy(bot)
  -- Changing the entropy with an active path could cause unpredictable results.
  if GetBotVentPath(bot).active then return end

  local time = GetTime()
  if time > bot.nextVentEntropyTime then
    bot.ventEntropy = kMinEntropy + random() * kEntropyRange
    bot.nextVentEntropyTime = time + kEntropyUpdateTime
  end
end

---Periodically resets a vent path if progress is not being made.
---@param bot Bot
---@param from Vector
local function InvalidateVentPath(bot, from)
  local ventPath = GetBotVentPath(bot)
  local time = GetTime()
  if ventPath.active and time > bot.nextVentResetTime then
    bot.nextVentResetTime = time + kResetTime
    if not ventPath.ventStuckPos then
      ventPath.ventStuckPos = from
      return
    elseif from:GetDistanceSquared(ventPath.ventStuckPos)
        < kResetToleranceSqr then
      ventPath.active = false
    else
      ventPath.ventStuckPos = from
    end
  end
end

---Returns the position referenced by ventPath.iter in the current path segment.
---@param ventPath VentPath
---@return Vector?
function Bishop.global.vents.GetVentIteratorPosition(ventPath)
  if not ventPath.active then return nil end
  return GetCurrentVentPath(ventPath)[ventPath.iter]
end

local GetVentIteratorPosition = Bishop.global.vents.GetVentIteratorPosition

---@param ventPath VentPath
---@param ventEntropy number
local function LogVentPath(ventPath, ventEntropy)
  Log("  Vent: %s, Path: %s", ventPath.ventId, ventPath.path)
  Log("  Reverse: %s", ventPath.reverse)
  Log("  exitDistance: %s, entropy: %s", ventPath.exitDistance, ventEntropy)
end

---@param path VentPath
local function LogVentStats(path)
  local vent = GetVent(path.ventId)
  local segment = GetVentSegment(path.ventId, path.path[1])
  vent.debugGenCount = vent.debugGenCount + 1
  segment.debugGenCount = segment.debugGenCount + 1
end

---@param path VentPath
local function LogVentEntry(path)
  local vent = GetVent(path.ventId)
  local segment = GetVentSegment(path.ventId, path.path[1])
  vent.debugEntryCount = vent.debugEntryCount + 1
  segment.debugEntryCount = segment.debugEntryCount + 1
end

--------------------------------------------------------------------------------
-- Vent path traversal.
--------------------------------------------------------------------------------

---Determines the next relevant point along the vent path given the current
---position. Returns true if the vent path has ended and sets active to false.
---@param bot Bot
---@param position Vector
---@return boolean
local function ShuffleVentIterator(bot, position)
  local ventPath = GetBotVentPath(bot)
  local segment = ventPath.path[1]
  local segmentPath = GetCurrentVentPath(ventPath)
  local reverse = TContains(ventPath.reverse, segment)
  local nextSegment = false
  local lastSegment = not ventPath.path[2] or ventPath.path[2] == 0
  ventPath.lastPos = position

  -- When entering a vent, shuffle the path forward to reduce hesitation.
  local iter = GetClosestPointIndex(segmentPath, position)
  if reverse then
    iter = iter - 1
    iter = max(iter, 1)
  else
    iter = iter + 1
    iter = min(iter, #segmentPath)
  end

  if reverse then
    while iter > 1 and position:GetDistanceSquared(segmentPath[iter]) < 2 do
      iter = iter - 1
    end
    -- Don't switch to the next segment until the bot is really close to the end
    -- of the current path. Switching early causes wall clipping issues.
    if iter <= 1 and (position:GetDistanceSquared(segmentPath[iter]) < 2)
        or (lastSegment and (position - segmentPath[1]):GetLengthSquaredXZ()
        < 0.5 and (position - segmentPath[1]):GetLengthSquared() < 16) then
      nextSegment = true
    end
  else
    local n = #segmentPath
    while iter < n and position:GetDistanceSquared(segmentPath[iter]) < 2 do
      iter = iter + 1
    end
    -- Same as above.
    if iter >= n and (position:GetDistanceSquared(segmentPath[iter]) < 2)
        or (lastSegment and (position - segmentPath[n]):GetLengthSquaredXZ()
        < 0.5 and (position - segmentPath[n]):GetLengthSquared() < 16) then
      nextSegment = true
    end
  end
  ventPath.iter = iter

  if nextSegment then
    TRemove(ventPath.path, 1)

    if #ventPath.path == 0 or ventPath.path[1] == 0 then
      ventPath.active = false

      if kDebug then
        Log("%s - vent path completed.", bot:GetPlayer())
        DebugLine(position, position + kDebugVecUp, 0.2, 0, 1, 0, 1)
      end

      return true
    else
      if TContains(ventPath.reverse, ventPath.path[1]) then
        ventPath.iter = #GetCurrentVentPath(ventPath)
      else
        ventPath.iter = 1
      end
      return ShuffleVentIterator(bot, position)
    end
  end

  return false
end

---TODO: Testing without this for a while.
---If a path gets reset before a bot enters a vent, it can cause hesitative
---movement. Detect this and get the bot back to its correct path.
---@param ventPath VentPath
---@param from Vector
local function UpdateEntryIter(ventPath, from)
  local iter = GetClosestPointIndex(GetCurrentVentPath(ventPath), from)
  local iterPos = GetCurrentVentPath(ventPath)[iter]
  if iterPos:GetDistanceSquared(from) < 4 then
    ventPath.iter = iter
  end
end

--------------------------------------------------------------------------------
-- High level vent logic.
--------------------------------------------------------------------------------
-- Determining desirable vents given the bot's position and destination.

-- Vertical line debug drawing:
--   Red: Current path invalidated.
--   Yellow: Path overwritten with a new one.
--   Blue: Path atEntry flag set to true.
--   Green: Path completed.

---Returns the total (entrance + traversal + exit) distance of a vent path.
---@param start Vector
---@param path VentPath
---@param isInside boolean
---@return number
local function GetEstimatedDistance(start, path, isInside)
  local enterDistance = isInside and 0.0
    or GetBotWalkDistance(start, GetPathEntrancePoint(path))

  return enterDistance
    + MeasureVentPathDistance(path, start)
    + path.exitDistance
end

---@param target Vector|ScriptActor|Entity
---@return Vector
local function ConvertToOrigin(target)
  if target:isa("ScriptActor") or target:isa("Entity") then
    return target:GetOrigin()
  end

  ---@diagnostic disable-next-line: return-type-mismatch
  return target
end

---Handles the selection and updating of vent paths.
---@param bot Bot
---@param player Player
---@param to Vector|ScriptActor|Entity
---@return integer ventResult
---@return number walkDistance
---@return Vector toOverride
local function GetVentDistance(bot, player, to)
  local from = player:GetEyePos()
  local walkDistance = GetBotWalkDistance(player, to)
  local bestResult = kVentResult.NoVent
  local bestDistance = walkDistance

  to = ConvertToOrigin(to)
  UpdateVentEntropy(bot)
  InvalidateVentPath(bot, from)

  if GetBotVentPath(bot).active then
    local result, path, distance = GetBestVentPath(bot, bot.ventPath.ventId,
      from, to, walkDistance)

    -- A new path using the same vent was generated, or the same path reused.
    if result ~= kVentResult.NoVent then
      bestResult = result
      bestDistance = distance or walkDistance

      if path then
        bot.ventPath = path

        if kDebug then
          Log("%s - vent path overwritten:", player)
          LogVentPath(path, bot.ventEntropy)
          LogVentStats(path)
          DebugLine(from, from + kDebugVecUp, 0.2, 1, 1, 0, 1)
        end
      end

    -- The current path is now invalid.
    else
      bot.ventPath.active = false

      if kDebug then
        Log("%s - vent path invalidated", player)
        DebugLine(from, from + kDebugVecUp, 0.2, 1, 0, 0, 1)
      end
    end
  end

  -- There is no currently active vent path, consider all nearby vents.
  if not GetBotVentPath(bot).active then
    for i = 1, #vd do
      local result, path, distance = GetBestVentPath(bot, i, from, to,
        bestDistance)

      if result ~= kVentResult.NoVent and distance < bestDistance and path then
        bot.ventPath = path
        bestResult = result
        bestDistance = distance
      elseif kDebug and result ~= kVentResult.NoVent then
        Log("  Vent %s ignored because distance was %s > %s. (Entropy %s.)", i,
          distance, bestDistance, bot.ventEntropy)
      end
    end

    if kDebug and GetBotVentPath(bot).active then
      Log("%s - vent path generated:", player)
      LogVentPath(bot.ventPath, bot.ventEntropy)
    end

    -- Full traversal scans are skipped in GetBestVentPath, but the timer can't
    -- be updated there since multiple vents could be within range.
    if GetTime() >= bot.nextVentScanTime then
      bot.nextVentScanTime = GetTime() + kVentScanFrequency
    end
  end

  -- I wish Lua had switch statements.
  if not GetBotVentPath(bot).active then
    return kVentResult.NoVent, walkDistance, to

  elseif bestResult == kVentResult.WithinVent then
    local exit = ShuffleVentIterator(bot, from)
    local iteratorPosition = GetVentIteratorPosition(bot.ventPath)

    -- If the path ends and the target is still inside the vent, assume it is
    -- directly reachable from the current position.
    if exit then return kVentResult.Direct, from:GetDistance(to), to end

    if kDebug and not iteratorPosition then
      Log("Silent error: kVentResult.WithinVent has no iterator position!")
    end

    return bestResult, GetEstimatedDistance(from, bot.ventPath, true),
      iteratorPosition or from + player:GetViewCoords().zAxis + kVecDown

  elseif bestResult == kVentResult.EnterVent then
    if not bot.ventPath.atEntry then
      -- UpdateEntryIter(bot.ventPath, from)
    end

    local iteratorPosition = GetVentIteratorPosition(bot.ventPath)

    if not bot.ventPath.atEntry and iteratorPosition then
      if (iteratorPosition - from):GetLengthSquaredXZ() > 9 then
        bestResult = kVentResult.TravelToVent
        bot.ventPath.lastPos = from
      else
        bot.ventPath.atEntry = true

        if kDebug then
          Log("%s - vent path entry flag", player)
          LogVentEntry(bot.ventPath)
          DebugLine(from, from + kDebugVecUp, 0.2, 0, 0, 1, 1)
        end
      end
    end

    if bot.ventPath.atEntry then
      ShuffleVentIterator(bot, from)
      iteratorPosition = GetVentIteratorPosition(bot.ventPath)
    end

    if not iteratorPosition then
      return bestResult, walkDistance,
        from + player:GetViewCoords().zAxis + kVecDown
    end

    return bestResult, GetEstimatedDistance(from, bot.ventPath, false),
      iteratorPosition

  elseif bestResult == kVentResult.NavigateVent then
    local exit = ShuffleVentIterator(bot, from)
    local iteratorPosition = GetVentIteratorPosition(bot.ventPath)

    if exit then return kVentResult.NoVent, walkDistance, to end

    if kDebug and not iteratorPosition then
      Log("Silent error: kVentResult.NavigateVent has no iterator position!")
    end

    return bestResult, GetEstimatedDistance(from, bot.ventPath, true),
      iteratorPosition or from + player:GetViewCoords().zAxis + kVecDown

  elseif bestResult == kVentResult.Direct then
    return bestResult, from:GetDistance(to), to

  -- Execution should NEVER end up here, something is seriously wrong.
  else
    Bishop.Error("A vent path returned kVentResult.NoVent.")
    return kVentResult.NoVent, walkDistance, to
  end
end

---Nudge the target position to encourage a better view point when travelling
---vertically.
---@param origin Vector
---@param position Vector
---@param isEntry boolean
---@return Vector
local function AdjustTargetPosition(origin, position, isEntry)
  local delta = Clamp(position.y - origin.y, -0.2, 0.2)
  if isEntry then delta = delta * 3 end

  position.y = position.y + delta
  return position
end

-- Forward line debug drawing:
--   Green: Travelling to vent: navmesh on.
--   Blue: Within vent.
--   Aqua: Navigate vent.
--   Red: Entering vent.
--   Purple: Direct movement.

-- Implemented in the same manner as HandleAlienTunnelMove but should be called
-- AFTER the tunnel functions.
-- Return values:
--   1) A boolean that when true no function should interfere with pathing.
--   2) The distance from the bot's move target.
--   3) The desired move position, altered if the bot should enter a vent.
function Bishop.global.vents.HandleVentMove(from, to, bot, brain, move)
  local player = bot:GetPlayer()

  if player.isHallucination then
    bot:GetMotion():SetDesiredMoveTarget(to)
    return false, GetBotWalkDistance(player, to)
  end

  local eResult, distance, position = GetVentDistance(bot, player, to)
  local motion = bot:GetMotion()
  local terminatePathing = false
  local returnPosition = nil
  -- bot.overridePathing = false (Moved to Stuck.lua.)
  bot.offNavMesh = false

  -- Experimental change to allow jumping movements coupled with vent motion.
  if GetTime() >= brain.nextVentJumpTime then
    local moveVector = position - from
    if moveVector.y > 1.0 and moveVector:GetLengthSquaredXZ() < 5 and
        player:GetIsOnGround() then
      move.commands = AddMoveCommand(move.commands, Move.Jump)
      brain.nextVentJumpTime = GetTime() + 1
    end
  end

  if eResult == kVentResult.NoVent then
    motion:SetDesiredMoveTarget(position)

  elseif eResult == kVentResult.TravelToVent then
    motion:SetDesiredMoveTarget(position)
    returnPosition = position

    if kDebug then DebugLine(from, position, 0.2, 0, 1, 0, 1) end

  elseif eResult == kVentResult.WithinVent then
    position = AdjustTargetPosition(from, position, false)
    MoveDirectlyTo(motion, from, position)
    terminatePathing = true
    bot.offNavMesh = true

    if kDebug then DebugLine(from, position, 0.2, 0, 0, 1, 1) end

  elseif eResult == kVentResult.EnterVent then
    position = AdjustTargetPosition(from, position, true)
    MoveDirectlyTo(motion, from, position)
    motion:SetIgnoreStuck(true)
    terminatePathing = true
    bot.offNavMesh = true

    if DotProduct((position - from):GetUnit(), kVecUp) > 0.80 then
      move.commands = AddMoveCommand(move.commands, Move.MovementModifier)
      move.commands = RemoveMoveCommand(move.commands, Move.Crouch)
    end

    if kDebug then DebugLine(from, position, 0.2, 1, 0, 0, 1) end

  elseif eResult == kVentResult.NavigateVent then
    position = AdjustTargetPosition(from, position, false)
    MoveDirectlyTo(motion, from, position)
    terminatePathing = true
    bot.offNavMesh = true

    if kDebug then DebugLine(from, position, 0.2, 0, 1, 1, 1) end

  elseif eResult == kVentResult.Direct then
    MoveDirectlyTo(motion, from, position)
    bot.offNavMesh = true

    if kDebug then DebugLine(from, position, 0.2, 1, 0, 1, 1) end
  end

  -- Override pathing applies a tweak in BotMotion that temporarily disables
  -- SetDesiredMove and SetDesiredLook changes.
  if terminatePathing then bot.overridePathing = true end

  return terminatePathing, distance, returnPosition
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
