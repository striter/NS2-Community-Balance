Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/data/StuckPaths.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local ipairs = ipairs

local IsPointWithinVolume = Bishop.lib.math.IsPointWithinVolume
local HasLineOfSight = Bishop.utility.HasLineOfSight

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kDebug = Bishop.debug.stuck
local kZeroVector = Vector(0, 0, 0)

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

-- Draw any active stuck volumes when debugging is enabled.
local function DebugStuckBox(volume)
  if kDebug then
    DebugBox(volume.min, volume.max, kZeroVector, 0.2, 1, 1, 1, 1)
  end
end

-- Only draw lines with Bishop.debug.stuck enabled.
local function DebugStuckLine(...)
  if kDebug then
    DebugLine(...)
  end
end

-- Returns false if not within a major volume, or returns true with the index of
-- which major volume passed the test.
local function IsWithinMajorVolume(origin)
  for i, clusterVolume in ipairs(kStuckVolume) do
    if IsPointWithinVolume(origin, clusterVolume) then
      return true, i
    end
  end
  return false
end

---Loads stuck volumes for the current map if they exist.
local function LoadStuckData()
  if kDebug then Bishop.debug.StuckLog("Loading stuck data.") end

  ---@type string
  local mapName = Shared.GetMapName()
  if table.contains(kStuckMaps, mapName) then
    local file = "lua/bishop/data/StuckPaths_" .. mapName .. ".lua"
    Script.Load(file)
  end

  local count = 0
  for i, stuckCluster in ipairs(kStuckData) do
    ---@type Volume
    kStuckVolume[i] = {
      min = Vector(math.huge, math.huge, math.huge),
      max = Vector(-math.huge, -math.huge, -math.huge)
    }

    for _, stuckEntry in ipairs(stuckCluster) do
      Bishop.lib.math.ExpandVolume(kStuckVolume[i], {stuckEntry.volume})
      count = count + 1
    end
  end

  if kDebug then
    Bishop.debug.StuckLog("Loaded %s volumes in %s clusters.", count,
      #kStuckData)
  end
end

Shine.Hook.Add("MapPostLoad", "BishopStuckGen", LoadStuckData)

--------------------------------------------------------------------------------
-- Stuck detection.
--------------------------------------------------------------------------------

-- Returns false if the bot is not stuck, otherwise returns true and the indices
-- of the major volume and entry.
local function IsBotStuck(bot, origin, to)
  bot.overridePathing = false
  if bot.offNavMesh then return false end

  local stuck, major = IsWithinMajorVolume(origin)
  if stuck then
    local minor = nil
    for i, stuckEntry in ipairs(kStuckData[major]) do
      if IsPointWithinVolume(origin, stuckEntry.volume) then
        minor = i
        break
      end
    end

    if not minor then return false end

    -- If the bot has direct line of sight to its target, allow it to continue.
    if HasLineOfSight(bot, origin, to) then
      bot:GetMotion():SetDesiredMoveDirection((to - origin):GetUnit())
      bot:GetMotion():SetDesiredViewTarget(to)
      bot.offNavMesh = true
      bot.overridePathing = true
      DebugStuckLine(origin, to, 0.2, 0, 1, 0, 1)
      return false
    end

    return true, major, minor
  end

  return false
end

-- Returns true if StuckMove has control of this bot, otherwise returns false.
function Bishop.global.stuck.StuckMove(bot, entity, move, origin, to)
  bot.offNavMesh = false
  local stuck, major, minor = IsBotStuck(bot, origin, to)
  if not stuck then
    return false
  end

  local stuckEntry = kStuckData[major][minor]
  local flag = stuckEntry.flag

  -- Special flag exempting Skulks, usually because it's considered a vent.
  if (flag == kStuckFlag.NoSkulk or flag == kStuckFlag.NoSkulkJump)
      and entity:isa("Skulk") then
    return false

  -- AndOnosCrouch is still a stuck position.
  elseif flag == kStuckFlag.AndOnosCrouch then
    if entity:isa("Onos") then
      move.commands = AddMoveCommand(move.commands, Move.Crouch)
    end

  -- Force Onos to crouch through this volume but isn't considered stuck.
  elseif flag == kStuckFlag.OnosCrouch then
    if entity:isa("Onos") then
      move.commands = AddMoveCommand(move.commands, Move.Crouch)
      DebugStuckBox(stuckEntry.volume)
    end
    return false

  -- Bots should jump to get out of here.
  elseif (flag == kStuckFlag.Jump or flag == kStuckFlag.NoSkulkJump)
      and not entity.jumpHandled then
    move.commands = AddMoveCommand(move.commands, Move.Jump)

  -- A crouch is mandatory for all bots.
  elseif flag == kStuckFlag.Crouch then
    move.commands = AddMoveCommand(move.commands, Move.Crouch)
  end

  local motion = bot:GetMotion()
  local target = stuckEntry.destination
  if target then
    motion:SetDesiredMoveDirection((target - origin):GetUnit())
    motion:SetDesiredViewTarget(target)
    bot.offNavMesh = true
    bot.overridePathing = true
    DebugStuckLine(origin, target, 0.2, 1, 0, 0, 1)
  end
  DebugStuckBox(stuckEntry.volume)
  return true
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
