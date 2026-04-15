Script.Load("lua/Table.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/Bishop/marine/Fireteam.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Shared_GetTime = Shared.GetTime
local table_random = table.random

local GetMarineMoveFunction = Bishop.utility.GetMarineMoveFunction
local IsFireteamLeader = Bishop.marine.fireteam.IsFireteamLeader

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kCooldownTime          = 10 -- Prevent objective re-running immediately.
local kDistanceToCompleteSqr = 25 -- Distance to mark the objective as complete.
local kFireteamsPerTechPoint = 2  -- Fireteam leaders to send to each TP.
local kTimeout = 10               -- Expiry to reconsider objectives.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Take fireteams to secure unclaimed tech points.
--------------------------------------------------------------------------------

local function PerformSecureTechPoint(move, bot, brain, marine, action)
  if Shared_GetTime() >= action.expires then
    -- This is required to prevent GetNumOtherBotsWithGoalDetails conflicting
    -- with the same bot reconsidering its objective.
    brain:InterruptCurrentGoalAction()
    return true
  end
  local origin = marine:GetOrigin()
  local techPointOrigin = action.techPoint:GetOrigin()
  if origin:GetDistanceSquared(techPointOrigin) <= kDistanceToCompleteSqr then
    brain.nextSecureTechPointTime = Shared_GetTime() + kCooldownTime
    return true
  end

  GetMarineMoveFunction(marine)(origin, techPointOrigin, bot, brain, move)
end

local function ValidateSecureTechPoint(bot, brain, marine, action)
  if action.techPoint:GetAttached() or not IsFireteamLeader(brain) then
    return false
  end
  return true
end

function Bishop.marine.objectives.SecureTechPoint(bot, brain, marine)
  if not IsFireteamLeader(brain)
      or Shared_GetTime() < brain.nextSecureTechPointTime then
    return kNilAction
  end

  local techPoint = table_random(
    brain:GetSenses():Get("ent_techPoints_unclaimed"))
  if not techPoint
      or brain.teamBrain:GetNumOtherBotsWithGoalDetails(bot, "SecureTechPoint",
        "techPoint", techPoint) >= kFireteamsPerTechPoint then
    return kNilAction
  end

  return {
    name = "SecureTechPoint",
    perform = PerformSecureTechPoint,
    validate = ValidateSecureTechPoint,
    weight = 1, -- Weight per class.

    -- Objective metadata.
    expires = Shared_GetTime() + kTimeout,
    techPoint = techPoint
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
