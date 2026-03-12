Script.Load("lua/Balance.lua")
Script.Load("lua/Hive.lua")
Script.Load("lua/NS2Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local AddMoveCommand = AddMoveCommand
local HasMixin = HasMixin

local IsOnNavMesh = Bishop.utility.IsOnNavMesh
local DoMove = Bishop.alien.gorge.DoMove

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kGorgeRetreatRadius = kHealsprayRadius      -- Arm's length of the Gorge.
local kHiveRetreatRadius = Hive.kHealRadius * 0.5 -- Well within heal radius.
local kMinHealthForGorge = 0.5 -- Don't risk it when low, use a Hive instead.
local kRetreatWeight = 15      -- Forces retreat as top priority.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Dynamic retreat.
--------------------------------------------------------------------------------

local function PerformRetreat(move, bot, brain, gorge, action)
  local target = action.target
  if not target or not HasMixin(target, "Live") or not target:GetIsAlive() then
    return
  end

  brain.teamBrain:UnassignBot(bot)
  move.commands = AddMoveCommand(move.commands, Move.SecondaryAttack)
  local engagementPoint = target:GetEngagementPoint()
  local distance = gorge:GetOrigin():GetDistance(engagementPoint)
  if (not action.isGorge and distance > kHiveRetreatRadius)
      or (action.isGorge and distance > kGorgeRetreatRadius) then
    DoMove(gorge:GetOrigin(), engagementPoint, bot, brain, move)
    return
  end

  local motion = bot:GetMotion()
  motion:SetDesiredViewTarget(engagementPoint)
  if gorge:GetIsUnderFire() then
    local damageOrigin = gorge:GetLastTakenDamageOrigin()
    local retreatDir = (engagementPoint - damageOrigin):GetUnit()
    local _, max = target:GetModelExtents()
    motion:SetDesiredMoveTarget(engagementPoint + (retreatDir * max.x))
  else
    motion:SetDesiredMoveTarget(nil)
  end
end

function Bishop.alien.gorge.actions.Retreat(bot, brain, gorge)
  local senses = brain:GetSenses()
  local health = gorge:GetHealthScalar()

  if not senses:Get("per_danger") or gorge.isHallucination then
    if brain.activeRetreat then
      brain.activeRetreat = false
    end
    return kNilAction
  end

  local nearestGorge = senses:Get("nearestGorge")
  local nearestHive = senses:Get("nearestHive")
  local selectedGorge = false
  local target = nearestHive.entity

  if nearestGorge.entity
      and health >= kMinHealthForGorge
      and nearestHive.distance
      and nearestGorge.distance < nearestHive.distance
      and IsOnNavMesh(nearestGorge.entity)
      and not gorge:GetIsUnderFire()
      and not nearestGorge.entity:GetIsUnderFire() then
    selectedGorge = true
    target = nearestGorge.entity
  end

  if not target then
    return kNilAction
  end
  brain.activeRetreat = true

  return {
    fastUpdate = true,
    name = "Retreat",
    perform = PerformRetreat,
    weight = kRetreatWeight,

    -- Action metadata.
    isGorge = selectedGorge,
    target = target
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
