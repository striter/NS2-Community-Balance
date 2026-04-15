Script.Load("lua/Entity.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/skulk/SkulkMovement.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetEntitiesAliveForTeam = GetEntitiesAliveForTeam
local ipairs = ipairs
local IsValid = IsValid
local Shared_GetTime = Shared.GetTime

local DoMove = Bishop.alien.skulk.DoMove
local GetObjectiveWeight = Bishop.alien.skulk.GetObjectiveWeight

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kAlienTeamType = kAlienTeamType
local kObjectiveTypes = Bishop.alien.skulk.objectiveTypes
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Gestate into eggs placed by the commander.
--------------------------------------------------------------------------------
-- Since this is implemented as an objective, a bot will never do this if there
-- are enemies nearby.

local function PerformTakeEgg(move, bot, brain, skulk, action)
  local egg = action.egg
  local eggOrigin = egg:GetOrigin()
  brain.teamBrain:AssignPlayerToEntity(skulk, egg:GetId())

  if skulk:GetOrigin():GetDistanceSquared(eggOrigin) < 4
      and egg:InternalGetCanBeUsed(skulk) then
    local useSuccessTable = { useSuccess = true }
    egg:OnUse(skulk, Shared_GetTime(), useSuccessTable)
    if useSuccessTable.useSuccess then
      bot.desiredLifeform = nil
      return true
    end
  else
    DoMove(skulk:GetEyePos(), eggOrigin, bot, brain, move)
  end
end

local function ValidateTakeEgg(bot, brain, skulk, action)
  local egg = action.egg
  if not IsValid(egg) or not egg:GetIsAlive() or not egg:GetIsEmpty() then
    return false
  end
  return true
end

function Bishop.alien.skulk.objectives.TakeEgg(bot, brain, skulk)
  if skulk.isHallucination then
    return kNilAction
  end

  local chosenEgg = nil
  local eggs = GetEntitiesAliveForTeam("Egg", kAlienTeamType)
  local teamBrain = brain.teamBrain

  for _, egg in ipairs(eggs) do
    if egg:InternalGetCanBeUsed(skulk)
        and teamBrain:GetNumOthersAssignedToEntity(skulk, egg:GetId()) <= 0 then
      chosenEgg = egg
      break
    end
  end

  if not chosenEgg then
    return kNilAction
  end

  return {
    name = "TakeEgg",
    perform = PerformTakeEgg,
    validate = ValidateTakeEgg,
    weight = GetObjectiveWeight(kObjectiveTypes.TakeEgg),

    -- Objective metadata.
    egg = chosenEgg
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
