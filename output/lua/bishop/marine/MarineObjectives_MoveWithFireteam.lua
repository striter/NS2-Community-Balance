Script.Load("lua/Globals.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/marine/Fireteam.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local DebugLine = DebugLine
local GetEntitiesForTeam = GetEntitiesForTeam
local IsValid = IsValid
local Shared_GetTime = Shared.GetTime
local table_random = table.random

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
local kTeamType = kMarineTeamType

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

--------------------------------------------------------------------------------
-- Fireteam leaders lead the team to a forward position.
--------------------------------------------------------------------------------
-- Previously fireteam leaders would return kNilAction and idle when no other
-- task was available, causing the entire fireteam to idle near the command
-- station. Now they advance towards the nearest forward Phase Gate, unclaimed
-- Tech Point, or known enemy location to keep the team moving.

---Selects a forward target position for the fireteam leader to move towards.
---@param bot Bot
---@param brain PlayerBrain
---@param marine Player
---@return Vector? targetPos
local function GetLeadTargetPosition(bot, brain, marine)
  local teamBrain = brain.teamBrain

  -- Priority 1: Phase Gates not in the initial tech point (forward gates).
  local phaseGates = GetEntitiesForTeam("PhaseGate", kTeamType)
  local initialLoc = teamBrain.initialTechPointLoc
  local bestGate, bestDist = nil, math.huge

  for _, gate in ipairs(phaseGates) do
    if gate:GetIsBuilt() then
      local gateLoc = gate:GetLocationName()
      -- Prefer gates outside the main base to push forward.
      if gateLoc ~= initialLoc then
        local dist = marine:GetDistanceSquared(gate)
        if dist < bestDist then
          bestDist = dist
          bestGate = gate
        end
      end
    end
  end

  if bestGate then
    return bestGate:GetOrigin()
  end

  -- Priority 2: Any Phase Gate (if all gates are in base or no forward gates).
  local closestGate
  bestDist = math.huge
  for _, gate in ipairs(phaseGates) do
    if gate:GetIsBuilt() then
      local dist = marine:GetDistanceSquared(gate)
      if dist < bestDist then
        bestDist = dist
        closestGate = gate
      end
    end
  end
  if closestGate then
    return closestGate:GetOrigin()
  end

  -- Priority 3: An unclaimed Tech Point.
  local techPoints = brain:GetSenses():Get("ent_techPoints_unclaimed")
  if #techPoints > 0 then
    return table_random(techPoints):GetOrigin()
  end

  -- No suitable target found.
  return nil
end

local function PerformLeadFireteam(move, bot, brain, marine, action)
  if Shared_GetTime() >= action.expires then
    return true
  end

  local origin = marine:GetOrigin()
  local targetPos = action.targetPos

  if origin:GetDistanceSquared(targetPos) <= 3 * 3 then
    -- Arrived at target, complete.
    return true
  end

  GetMarineMoveFunction(marine)(origin, targetPos, bot, brain, move)
end

local function ValidateLeadFireteam(bot, brain, marine, action)
  if not IsFireteamLeader(brain) then
    return false
  end
  return true
end

function Bishop.marine.objectives.MoveWithFireteam(bot, brain, marine)
  -- Leaders lead the team to a forward position instead of idling.
  if IsFireteamLeader(brain) then
    local targetPos = GetLeadTargetPosition(bot, brain, marine)
    if not targetPos then
      return kNilAction
    end

    return {
      name = "MoveWithFireteam",
      perform = PerformLeadFireteam,
      validate = ValidateLeadFireteam,
      weight = 1, -- Weight per class.

      -- Objective metadata.
      expires = Shared_GetTime() + kTimeout,
      targetPos = targetPos
    }
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
