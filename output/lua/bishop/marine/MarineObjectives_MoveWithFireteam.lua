Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/marine/Fireteam.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local DebugLine = DebugLine
local IsValid = IsValid
local Shared_GetTime = Shared.GetTime

local GetBackpedalVector = Bishop.utility.GetBackpedalVector
local IsFacing = Bishop.utility.IsFacing
local IsFireteamLeader = Bishop.marine.fireteam.IsFireteamLeader
local GetMarineMoveFunction = Bishop.utility.GetMarineMoveFunction

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kFollowDistanceSqr = 5 * 5 -- Distance to maintain to leader.
local kTimeout = 10              -- Expiry to reconsider objectives.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kDebugBodyblock = Bishop.debug.bodyBlock
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Keep fireteam members close to the leader.
--------------------------------------------------------------------------------

local function PerformMoveWithFireteam(move, bot, brain, marine, action)
  if not action.leader:GetIsAlive() or Shared_GetTime() >= action.expires then
    return true
  end

  local origin = marine:GetOrigin()
  local leader = action.leader
  local leaderOrigin = leader:GetOrigin()

  if origin:GetDistanceSquared(leaderOrigin) > kFollowDistanceSqr then
    GetMarineMoveFunction(marine)(origin, leaderOrigin, bot, brain, move)
  elseif not IsFacing(leader, origin) then
    bot:GetMotion():SetDesiredMoveTarget()
  else
    local backpedalVector = GetBackpedalVector(marine, leader)
    if kDebugBodyblock then
      local eyePos = marine:GetEyePos()
      DebugLine(eyePos, eyePos + backpedalVector * 3, 1/4, 1, 0, 0, 1)
    end
    bot:GetMotion():SetDesiredMoveDirection(backpedalVector)
  end
end

local function ValidateMoveWithFireteam(bot, brain, marine, action)
  if not IsValid(action.leader) or not action.leader:GetIsAlive()
      or IsFireteamLeader(brain)
      or not IsFireteamLeader(action.leaderBrain) then
    return false
  end
  return true
end

function Bishop.marine.objectives.MoveWithFireteam(bot, brain, marine)
  if IsFireteamLeader(brain) then
    return kNilAction
  end

  local leader = brain.fireteam.leader.player
  if not IsValid(leader) or not leader:GetIsAlive() then
    return kNilAction
  end

  return {
    name = "MoveWithFireteam",
    perform = PerformMoveWithFireteam,
    validate = ValidateMoveWithFireteam,
    weight = 1, -- Weight per class.

    -- Objective metadata.
    expires = Shared_GetTime() + kTimeout,
    leader = leader,
    leaderBrain = brain.fireteam.leader
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
