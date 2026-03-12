Script.Load("lua/Balance.lua")
Script.Load("lua/Hive.lua")
Script.Load("lua/NetworkMessages_Server.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/VoiceOver.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Lifeform.lua")
Script.Load("lua/bishop/alien/Pack.lua")
Script.Load("lua/bishop/alien/Retreat.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alien.retreat = {}

local ConditionalValue = ConditionalValue
local CreateVoiceMessage = CreateVoiceMessage
local DebugLine = DebugLine
local GetDistanceToTouch = GetDistanceToTouch
local IsValid = IsValid
local kTechId = kTechId
local kVoiceId = kVoiceId
local Shared_GetTime = Shared.GetTime

local GetBackpedalVector = Bishop.utility.GetBackpedalVector
local GetCurrentLifeform = Bishop.alien.lifeform.GetCurrentLifeform
local GetMoveFunction = Bishop.utility.GetMoveFunction
local IsOnNavMesh = Bishop.utility.IsOnNavMesh
local IsTeammateBlocking = Bishop.utility.IsTeammateBlocking
local kNilAction = Bishop.lib.constants.kNilAction
local LeavePack = Bishop.alien.pack.LeavePack
local sharedObjectives = Bishop.alien.objectives

--------------------------------------------------------------------------------
-- Balance values and function constants.
--------------------------------------------------------------------------------

-- If the alien is already this close to its retreat target, it might as well
-- commit.
local kCancelRetreatDistance = 20
-- The absolute health to cancel a retreat. This exists to allow aliens to
-- retreat from rooms full of marines, then return to useful activity once
-- they're safe.
local kCancelRetreatHealth = {
  [kTechId.Skulk] = 0.5,
  [kTechId.Lerk] = 0.85,
  [kTechId.Fade] = 0.80,
  [kTechId.Onos] = 0.75
}
-- After a Gorge has healed the alien to this health, abort the retreat.
local kHealToForGorge = 0.90
local kHealToForHive = 0.96
-- If a Gorge is closer than this value, it's very likely in the same room as
-- the retreating alien and shouldn't be chosen as a retreat target.
local kMinGorgeDistance = 30
-- If the alien's health is below this value, don't lock up a Gorge, just
-- perform a full hive retreat instead.
local kMinHealthForGorge = {
  [kTechId.Skulk] = 0.1,
  [kTechId.Lerk] = 0.5,
  [kTechId.Fade] = 0.62,
  [kTechId.Onos] = 0.67
}
-- Aliens must retreat for at least this long - prevents jitter.
local kMinRetreatTime = 4
-- Rate to spam 'Q' when near a Gorge.
local kRequestHealRate = 10
-- Hug the retreat target at this distance.
local kRetreatHiveDistance = Hive.kHealRadius * 0.5
local kRetreatGorgeDistance = kHealsprayRadius - 0.2

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kDebugBodyblock = Bishop.debug.bodyBlock

--------------------------------------------------------------------------------
-- Dynamically scale retreat by the number of outnumbering enemies.
--------------------------------------------------------------------------------
-- Onos bots in particular have a tendency to run into rooms full of marines and
-- then decide to retreat far too late. This change scales up the minimum HP for
-- a retreat by the number of marines an alien is outnumbered by, as well as
-- allowing a retreat to abort early when the alien is reasonably safe.

local function PerformRetreat(move, bot, brain, alien, action)
  local eyePos = alien:GetEyePos()
  local target = action.target
  local distance = GetDistanceToTouch(eyePos, target)
  local healTo = action.healTo
  local isGorge = action.isGorge
  local time = Shared_GetTime()

  if not alien:GetIsUnderFire() and distance >= kCancelRetreatDistance then
    healTo = kCancelRetreatHealth[GetCurrentLifeform(alien)]
  end

  if alien:GetHealthScalar() >= healTo
      and time > action.minTime then
    brain.activeRetreat = false
    return true
  end

  brain.teamBrain:UnassignBot(bot)
  local engagementPoint = target:GetEngagementPoint()
  local motion = bot:GetMotion()
  local targetDistance = ConditionalValue(isGorge, kRetreatGorgeDistance,
    kRetreatHiveDistance)

  if distance > targetDistance then
    local teammate = brain:GetSenses():Get("ent_teammate_nearest").entity

    if not teammate or not IsTeammateBlocking(alien, teammate) then
      motion:SetDesiredViewTarget()
      action.Move(eyePos, engagementPoint, bot, brain, move, true)
    else
      local teammatePosition = teammate:GetOrigin()
      local backpedalVector = GetBackpedalVector(alien, teammate)
      if kDebugBodyblock then
        DebugLine(eyePos, teammatePosition, 1/4, 0, 1, 0, 1)
        DebugLine(eyePos, eyePos + backpedalVector * 3, 1/4, 1, 0, 0, 1)
      end
      motion:SetDesiredViewTarget(teammatePosition)
      motion:SetDesiredMoveDirection(backpedalVector)
    end
  else
    if isGorge then
      if alien:GetIsUnderFire() or target:GetIsUnderFire() then
        brain.activeRetreat = false
        return true
      end

      if not brain.lastRequestHealTime
          or brain.lastRequestHealTime + kRequestHealRate < time then
        CreateVoiceMessage(alien, kVoiceId.AlienRequestHealing)
        brain.lastRequestHealTime = time
      end
    end

    motion:SetDesiredViewTarget(engagementPoint)

    if alien:GetIsUnderFire() then
      local damageOrigin = alien:GetLastTakenDamageOrigin()
      local adjustDirection = (engagementPoint - damageOrigin):GetUnit()
      local _, maxExtent = target:GetModelExtents()

      if maxExtent then
        local reposition = engagementPoint + (adjustDirection * maxExtent.x)

        action.Move(eyePos, reposition, bot, brain, move)
      else
        return true
      end
    else
      motion:SetDesiredMoveTarget()
    end
  end
end

local function ValidateRetreat(bot, brain, alien, action)
  local target = action.target

  if not IsValid(target) or not target:GetIsAlive()
      or (action.isGorge and not IsOnNavMesh(target)) then
    brain.activeRetreat = false
    return false
  end

  return true
end

function sharedObjectives.Retreat(bot, brain, alien)
  if alien.isHallucination then
    return kNilAction
  end

  local senses = brain:GetSenses()
  local health = alien:GetHealthScalar()
  local activeRetreat = brain.activeRetreat
  local lifeform = GetCurrentLifeform(alien)
  do
    if not senses:Get("per_danger")
        and (not activeRetreat
        or (activeRetreat and Shared_GetTime() >= brain.activeRetreatTime
        + kMinRetreatTime)) then
      brain.activeRetreat = false
      return kNilAction
    end
  end

  local selectedGorge = false
  local target
  do
    local nearestGorge = senses:Get("nearestGorge")
    local nearestHive = senses:Get("nearestHive")
    target = nearestHive.entity

    if nearestGorge.entity
        and nearestGorge.distance >= kMinGorgeDistance
        and health >= kMinHealthForGorge[lifeform]
        and nearestHive.distance
        and nearestGorge.distance < nearestHive.distance
        and IsOnNavMesh(nearestGorge.entity) then
      selectedGorge = true
      target = nearestGorge.entity
    end
  end

  if not target then
    return kNilAction
  end

  if not activeRetreat then
    brain.activeRetreat = true
    brain.activeRetreatTime = Shared_GetTime()
  end
  if brain.pack then
    LeavePack(brain)
  end

  return {
    name = "Retreat",
    perform = PerformRetreat,
    validate = ValidateRetreat,
    weight = 1, -- Override per lifeform.

    -- Objective metadata.
    healTo = ConditionalValue(selectedGorge, kHealToForGorge, kHealToForHive),
    isGorge = selectedGorge,
    minTime = brain.activeRetreatTime + kMinRetreatTime,
    Move = GetMoveFunction(lifeform),
    target = target
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
