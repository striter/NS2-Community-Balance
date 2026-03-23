Script.Load("lua/Balance.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/Vector.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/CommonAlienActions.lua")
Script.Load("lua/Weapons/Alien/Spores.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Retreat.lua")
Script.Load("lua/bishop/alien/lerk/LerkMovement.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local AddMoveCommand = AddMoveCommand
local GetBestAimPoint = GetBestAimPoint
local GetDistanceToTouch = GetDistanceToTouch
local GetEntitiesWithinRange = GetEntitiesWithinRange
local GetTunnelDistanceForAlien = GetTunnelDistanceForAlien
local IsValid = IsValid
local Pathing_GetClosestPoint = Pathing.GetClosestPoint
local Shared_GetEntity = Shared.GetEntity

local DoMove = Bishop.alien.lerk.DoMove
local GenerateRetreatPath = Bishop.alien.lerk.GenerateRetreatPath
local GetActionWeight = Bishop.alien.lerk.GetActionWeight
local PerformRetreatMove = Bishop.alien.lerk.PerformRetreatMove
local PerformSporeHostiles = Bishop.alien.lerk.PerformSporeHostiles

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kAttackDistance = kSpikesRange -- Max range to attack from.
local kBiteRange = 1.5               -- Range to switch from Spikes to Bite.
local kDesiredDistance = 16          -- Range to enemies when not biting.
local kRetreatHiveRadiusSqr = Hive.kHealRadius * Hive.kHealRadius * 0.6
local kMaxAttackDistance = 50        -- Don't target beyond this range.
local kMinEnergyToSpore = kSporesDustEnergyCost * 1.5 -- Don't use all energy.
local kRecoverEnergyBegin = 0.30     -- Retreat to regain energy.
local kRecoverEnergyEnd = 0.55       -- End retreat once energy is above.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes = Bishop.alien.lerk.kActionTypes
local kNilAction = Bishop.lib.constants.kNilAction
local kSporesDustCloudRadius = kSporesDustCloudRadius
local kSporeWeapon = Spores.kMapName

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function PerformAttackEntity(eyePos, target, targetPos, bot, brain, move)
  local senses = brain:GetSenses()
  local hasLineOfSight = not HasMixin(target, "LOS") or target:GetIsSighted()
  local aimPos = hasLineOfSight and GetBestAimPoint(target)
    or (targetPos + Vector(0, 0.5, 0))
  local distance = GetDistanceToTouch(eyePos, target)
  local clearShot = bot:GetBotCanSeeTarget(target)
  local attack = distance < kAttackDistance and clearShot
  local shotguns = senses:Get("nearbyThreats").numShotguns > 0

  -- Don't consider biting at all if there are shotguns involved or the Lerk is
  -- outnumbered. Always bite if the opposite is true. (Safe but aggressive.)
  local shouldBite = senses:Get("per_outnumbered_count") <= 0 and not shotguns

  -- Instead of sitting idle behind a wall, harass the target, but not if a
  -- shotgunner is trying to bait them around the corner.
  -- or (not clearShot and not shotguns) : Add to force Spikes LoS when testing.
  if shouldBite then
    if target:isa("Player") then
      brain.forceFlap = true
    end
    DoMove(eyePos, aimPos, bot, brain, move)
  else
    -- The Lerk should put ALL targets at range if attempting to maintain
    -- distance, not just the current one.
    local nearestThreat = senses:Get("mem_threat_nearest").memory
    local nearestThreatEntity = Shared_GetEntity(nearestThreat.entId)
    if nearestThreatEntity then
      PerformRetreatMove(eyePos, aimPos, bot, brain, nearestThreatEntity, move)
    else
      PerformRetreatMove(eyePos, aimPos, bot, brain, target, move)
    end
  end

  local accGroup = distance < kBiteRange and kBotAccWeaponGroup.LerkBite or
    kBotAccWeaponGroup.LerkSpikes
  attack = attack and bot.aim and bot.aim:UpdateAim(target, aimPos, accGroup)

  if attack then
    bot:GetPlayer():SetActiveWeapon(LerkBite.kMapName)
    if distance < kBiteRange then
      move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)
      if not target:isa("Player") then
        bot:GetMotion():SetDesiredMoveTarget()
      end
    else
      move.commands = AddMoveCommand(move.commands, Move.SecondaryAttack)
    end
  end
end

--------------------------------------------------------------------------------
-- Separate Lerk combat energy recovery into its own action.
--------------------------------------------------------------------------------
-- This was formerly embedded into Attack/Retreat and triggered a full objective
-- retreat to begin. This is incompatible with the shared retreat of Bishop.

local function PerformRecoverEnergy(move, bot, brain, lerk, action)
  local target = action.target
  if not IsValid(target) or not target:GetIsAlive() then
    return
  end

  if lerk:GetDistanceSquared(target) > kRetreatHiveRadiusSqr then
    bot:GetMotion():SetDesiredViewTarget()
    DoMove(lerk:GetEyePos(), target:GetEngagementPoint(), bot, brain, move)
  end
end

function Bishop.alien.lerk.actions.RecoverEnergy(bot, brain, lerk)
  local energy = lerk:GetEnergy() / lerk:GetMaxEnergy()
  local hive = brain:GetSenses():Get("nearestHive").entity

  if (not hive or energy > kRecoverEnergyBegin)
      and not brain.activeRecovery then
    return kNilAction
  end

  -- End an active recovery once energy is above recovery threshold.
  if brain.activeRecovery and energy > kRecoverEnergyEnd then
    brain.activeRecovery = false
    return kNilAction
  end

  -- Trigger the start of a new recovery when below recovery threshold.
  if not brain.activeRecovery and energy <= kRecoverEnergyBegin then
    brain.activeRecovery = true
  end

  if not brain.activeRecovery or not hive then
    return kNilAction
  end

  return {
    name = "RecoverEnergy",
    perform = PerformRecoverEnergy,
    weight = GetActionWeight(kActionTypes.RecoverEnergy),

    -- Action metadata.
    target = hive
  }
end

--------------------------------------------------------------------------------
-- Allow the Lerk to spam Spores more often if the target is mobile.
--------------------------------------------------------------------------------

function Bishop.alien.lerk.actions.Spore(bot, brain, lerk)
  local senses = brain:GetSenses()

  if not lerk:GetWeapon(kSporeWeapon)
      or lerk:GetEnergy() < kMinEnergyToSpore
      or senses:Get("per_danger") or brain.activeRetreat then
    return kNilAction
  end

  local target = senses:Get("nearestSporesTarget")
  if not target
      or not bot:GetBotCanSeeTarget(lerk, target)
      or #GetEntitiesWithinRange("SporeCloud", target:GetOrigin(),
        kSporesDustCloudRadius) > 0 then
    return kNilAction
  end

  return {
    name = "Spore",
    perform = PerformSporeHostiles,
    weight = GetActionWeight(kActionTypes.Spore),

    -- Action metadata.
    target = target
  }
end

--------------------------------------------------------------------------------
-- Select between Spikes and Bite based on the predicted outcome.
--------------------------------------------------------------------------------
-- The Lerk should maintain its fear of shotguns, but also take into account
-- the number of nearby friendlies. If aliens outnumber marines and there are no
-- shotguns, go directly for the throat. Spikes may be used while closing the
-- distance for extra damage.

local function PerformAttack(move, bot, brain, lerk, action)
  local eyePos = lerk:GetEyePos()
  local memory = action.bestMem
  local target = Shared_GetEntity(memory.entId)
  brain.teamBrain:UnassignBot(bot)
  brain.teamBrain:AssignBotToMemory(bot, memory)
  if not target then
    return
  end

  local targetPosition = Pathing_GetClosestPoint(memory.lastSeenPos)
  if target:isa("Player") then
    GenerateRetreatPath(eyePos, targetPosition, memory, brain)
  else
    brain.savedPathPoints = nil
    brain.savedPathPointsIt = nil
  end

  -- Keep Bot_Maintenance's chat message intact.
  if bot:GetPlayer().GetClient and bot:GetPlayer():GetClient()
      and bot:GetPlayer():GetClient():GetIsVirtual()
      and target:GetTeamNumber() ~= bot:GetTeamNumber() then
    local chatMsg = "Wings and venom earthlings! " .. target:GetMapName()
      .. " in " .. target:GetLocationName()
    bot:SendTeamMessage(chatMsg, 60)
  end

  PerformAttackEntity(eyePos, target, memory.lastSeenPos, bot, brain, move)
end

--------------------------------------------------------------------------------
-- Modify Lerk attack action to support new dynamic retreat values.
--------------------------------------------------------------------------------

function Bishop.alien.lerk.actions.Attack(bot, brain, lerk)
  local senses = brain:GetSenses()
  local danger = senses:Get("per_danger")

  -- TODO: This should be moved into the Interrupt action later.
  if danger and brain.goalAction and brain.goalAction.name ~= "Retreat" then
    brain:InterruptCurrentGoalAction()
  end

  if (danger or brain.activeRetreat) and not lerk.isHallucination then
    return kNilAction
  end

  local memory = senses:Get("nearbyThreats").memory
  if not memory then
    return kNilAction
  end

  local distance = select(2,
    GetTunnelDistanceForAlien(lerk, memory.lastSeenPos))
  if distance > kMaxAttackDistance then
    return kNilAction
  end

  return {
    fastUpdate = true,
    name = "Attack",
    perform = PerformAttack,
    weight = GetActionWeight(kActionTypes.Attack),

    -- Action metadata.
    bestMem = memory
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
