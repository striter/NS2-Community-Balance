Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/Bishop/marine/Fireteam.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Shared_GetTime = Shared.GetTime

local GetMarineMoveFunction = Bishop.utility.GetMarineMoveFunction
local IsFireteamLeader = Bishop.marine.fireteam.IsFireteamLeader

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kCooldownTime          = 10 -- Prevent objective re-running immediately.
local kDistanceToCompleteSqr = 16 -- Distance to mark the objective as complete.
local kFireteamsPerResourceNode = 1 -- Fireteam leaders to send to each node.
local kTimeout = 10               -- Expiry to reconsider objectives.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Take fireteams to secure unclaimed or enemy resource nodes.
--------------------------------------------------------------------------------

local function PerformSecureResources(move, bot, brain, marine, action)
  if Shared_GetTime() >= action.expires then
    -- This is required to prevent GetNumOtherBotsWithGoalDetails conflicting
    -- with the same bot reconsidering its objective.
    brain:InterruptCurrentGoalAction()
    return true
  end
  local origin = marine:GetOrigin()
  local resourceNodeOrigin = action.resourceNode:GetOrigin()
  if origin:GetDistanceSquared(resourceNodeOrigin)
      <= kDistanceToCompleteSqr then
    brain.nextSecureResourcesTime = Shared_GetTime() + kCooldownTime
    return true
  end

  GetMarineMoveFunction(marine)(origin, resourceNodeOrigin, bot, brain, move)
end

local function ValidateSecureResources(bot, brain, marine, action)
  if not IsFireteamLeader(brain) then
    return false
  end
  return true
end

function Bishop.marine.objectives.SecureResources(bot, brain, marine)
  if not IsFireteamLeader(brain)
      or Shared_GetTime() < brain.nextSecureResourcesTime then
    return kNilAction
  end

  local resourceNode = brain:GetSenses():Get("idealResourceNode")
  if not resourceNode
      or brain.teamBrain:GetNumOtherBotsWithGoalDetails(bot, "SecureResources",
        "resourceNode", resourceNode) >= kFireteamsPerResourceNode then
    return kNilAction
  end

  return {
    name = "SecureResources",
    perform = PerformSecureResources,
    validate = ValidateSecureResources,
    weight = 1, -- Weight per class.

    -- Objective metadata.
    expires = Shared_GetTime() + kTimeout,
    resourceNode = resourceNode
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
