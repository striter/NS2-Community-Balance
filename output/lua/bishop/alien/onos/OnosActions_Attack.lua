Script.Load("lua/Vector.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/CommonAlienActions.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetMaxTableEntry = GetMaxTableEntry
local GetTunnelDistanceForAlien = GetTunnelDistanceForAlien
local Shared_GetTime = Shared.GetTime

local actions = Bishop.alien.onos.actions
local actionTypes = Bishop.alien.onos.actionTypes
local GetActionWeight = Bishop.alien.onos.GetActionWeight
local GetAttackUrgency = Bishop.alien.onos.actions.GetAttackUrgency
local IsFacing = Bishop.utility.IsFacing
local kExecAttackAction = Bishop.alien.onos.actions.kExecAttackAction
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Modify Onos attack action to support new dynamic retreat values.
--------------------------------------------------------------------------------

local kMaxAttackDistance = 50
local kMaxBodyBlockDistance = 1.5
local kMinBodyBlockTime = 2

function actions.Attack(bot, brain, onos)
  local senses = brain:GetSenses()
  local danger = senses:Get("per_danger")

  local urgency, memory = GetMaxTableEntry(senses:Get("mem_enemies"),
    function(memory)
      return GetAttackUrgency(bot, memory)
    end)

  if not memory then
    return kNilAction
  end

  -- TODO: This should be moved into the Interrupt action later.
  if danger and brain.goalAction and brain.goalAction.name ~= "Retreat" then
    brain:InterruptCurrentGoalAction()
  end

  local targetPosition = memory.lastSeenPos
  local distance = select(2, GetTunnelDistanceForAlien(onos, targetPosition))

  if not (distance <= kMaxAttackDistance -- Regular attack condition.
        and not danger
        and not brain.activeRetreat)
      and not (distance <= kMaxBodyBlockDistance -- Bodyblock detection.
        and IsFacing(onos, targetPosition)
        and brain.activeRetreat
        and Shared_GetTime() > brain.activeRetreatTime + kMinBodyBlockTime)
      and not onos.isHallucination then
    return kNilAction
  end

  return {
    fastUpdate = true,
    name = "Attack",
    perform = kExecAttackAction,
    weight = GetActionWeight(actionTypes.Attack),

    -- Action metadata.
    bestMem = memory
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
