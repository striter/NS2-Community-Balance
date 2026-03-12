Script.Load("lua/Balance.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/MixinUtility.lua")
Script.Load("lua/bots/BotUtils.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/skulk/SkulkMovement.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local ceil = math.ceil
local GetBestAimPoint = GetBestAimPoint
local GetClosestPoint = Pathing.GetClosestPoint ---@type function
local GetEntity = Shared.GetEntity ---@type function
local GetTime = Shared.GetTime ---@type function
local HasMixin = HasMixin
local max = math.max
local min = math.min

local DoMove = Bishop.alien.skulk.DoMove
local GetCachedTable = Bishop.lib.table.GetCachedTable
local GetEntityClosestTo = Bishop.lib.entity.GetClosestEntityTo
local GetEntityIfAlive = Bishop.lib.entity.GetEntityIfAlive
local GetVentIteratorPosition = Bishop.global.vents.GetVentIteratorPosition
local IsFacingAway = Bishop.lib.math.IsFacingAway
local RetreatAlien = Bishop.global.pathHistory.RetreatAlien
local TraceRayDirect = Bishop.utility.TraceRayDirect

local kAlienTeamType = kAlienTeamType
local kBiteDamage = kBiteDamage
local kDebug = Bishop.debug.skulk
local kMinimapBlipType = kMinimapBlipType

local actions = Bishop.alien.skulk.actions

--------------------------------------------------------------------------------
-- Constants and balance values.
--------------------------------------------------------------------------------

-- If >= [kZergIndex] friendlies are attacking this target, use [kLowIndex] as
-- the urgency, else [kHighIndex].

local kZergIndex = 1
local kLowIndex = 2
local kHighIndex = 3

--------------------------------------------------------------------------------
-- Active attack weights.
--------------------------------------------------------------------------------

local activeUrgencies = {
  [kMinimapBlipType.Exo] =               {4, 0.6, 1.6},
  [kMinimapBlipType.Marine] =            {2, 0.5, 1.5},
  [kMinimapBlipType.JetpackMarine] =     {1, 0.4, 1.4},
  [kMinimapBlipType.Sentry] =            {3, 0.3, 1.3}
}

--------------------------------------------------------------------------------
-- Passive attack weights.
--------------------------------------------------------------------------------
-- Move all the inert structures to the bottom, as well as give Skulks the
-- ability to bite power nodes so long as they are powering something. Bump up
-- Infantry Portals, Phase Gates and Observatories because these structures are
-- key to securing tech points.

local passiveUrgencies = {
  [kMinimapBlipType.ARC] =               {2, 0.6, 0.95},
  [kMinimapBlipType.InfantryPortal] =    {3, 0.8, 0.95},
  [kMinimapBlipType.PhaseGate] =         {3, 0.8, 0.95},
  [kMinimapBlipType.Observatory] =       {2, 0.2, 0.8},
  [kMinimapBlipType.CommandStation] =    {4, 0.2, 0.65},
  [kMinimapBlipType.ArmsLab] =           {3, 0.2, 0.6},
  [kMinimapBlipType.PrototypeLab] =      {1, 0.2, 0.55},
  [kMinimapBlipType.SentryBattery] =     {2, 0.2, 0.5},
  [kMinimapBlipType.Extractor] =         {2, 0.2, 0.5},
  [kMinimapBlipType.MAC] =               {1, 0.2, 0.4},
  [kMinimapBlipType.PowerPoint] =        {1, 0.1, 0.25},
  [kMinimapBlipType.Armory] =            {2, 0.1, 0.2},
  [kMinimapBlipType.RoboticsFactory] =   {2, 0.1, 0.2}
}

--------------------------------------------------------------------------------
-- Attack urgency.
--------------------------------------------------------------------------------
-- Includes an extra check for power nodes and some optimizations, otherwise is
-- the same as vanilla. This is in the actions array because the vanilla Attack
-- action is still being used.

function actions.GetAttackUrgency(bot, skulk, memory)
  local target = GetEntity(memory.entId)

  if not HasMixin(target, "Live") or not target:GetIsAlive()
      or (target.GetTeamNumber and target:GetTeamNumber() == kAlienTeamType)
      then
    return nil
  end

  local numTeammatesWithThisTarget =
    bot.brain.teamBrain:GetNumOthersAssignedToEntity(skulk, memory.entId)

  local distance = skulk:GetOrigin():GetDistance(target:GetOrigin())
  local inCombat = skulk:GetIsInCombat()
  local underFire = skulk:GetIsUnderFire()
  local closeBonus = 0

  -- Bonus goes from [2-0] as distance goes from [0-20].
  if distance < 20 then
    closeBonus = max(0, (distance * -0.1) + 2)
  end

  -- Bonus goes up by [0-0.9] as health goes from [30%-Dead].
  if target:GetHealthScalar() < 0.3 then
    closeBonus = closeBonus + (0.3 - target:GetHealthScalar()) * 3
  end

  local passiveUrgency = passiveUrgencies[memory.btype]

  if passiveUrgency then
    -- The default behaviour targeted ghost command stations and extractors.
    -- Phase gates have been added because the gate might be outside the hive.
    if target.GetIsGhostStructure and target:GetIsGhostStructure()
        and memory.btype ~= kMinimapBlipType.Extractor
        and memory.btype ~= kMinimapBlipType.CommandStation
        and memory.btype ~= kMinimapBlipType.PhaseGate then
      return nil
    end

    -- Don't bite power nodes that aren't powering anything. Marines can cheese
    -- map control by building random power nodes to divert Skulks away from
    -- other useful tasks.
    if memory.btype == kMinimapBlipType.PowerPoint then
      if not target:HasConsumerRequiringPower() then
        return nil
      end
      local locationGroup = GetLocationContention():GetLocationGroup(
        target:GetLocationName())
      if locationGroup and locationGroup:GetNumMarineStructures() < 2 then
        return nil
      end
    end

    -- Sacrificial Skulk in trade for a building. Vanilla NS2 returned a huge
    -- number which caused Skulks to drop their targets all over the map.
    local bitesRequired = ceil(target:GetEHP() / kBiteDamage)

    if bitesRequired <= 5 then closeBonus = closeBonus * 3 end

    local nearestThreat = bot.brain:GetSenses():Get("nearestThreat")

    if nearestThreat.distance and nearestThreat.distance <= 8 then
      return nil
    end

    -- According to vanilla comments, this helps with structures blocking
    -- doorways.
    if not inCombat then closeBonus = closeBonus * 3 end

    if numTeammatesWithThisTarget >= passiveUrgency[kZergIndex] then
      return passiveUrgency[kLowIndex] + closeBonus
    end

    return passiveUrgency[kHighIndex] + closeBonus
  end

  local activeUrgency = activeUrgencies[memory.btype]

  if activeUrgency then
    -- Consider close targets high urgency regardless of teammates.
    if distance < 15 or inCombat then numTeammatesWithThisTarget = 0 end

    closeBonus = closeBonus + (distance < 20 and memory.threat or 0.0)

    if numTeammatesWithThisTarget >= activeUrgency[kZergIndex] then
      return activeUrgency[kLowIndex] + closeBonus
    end

    return activeUrgency[kHighIndex] + closeBonus
  end

  return nil
end

-- All code below this line is not in use.

local kAssistTeammateRadiusSqr = 8 * 8
local kDangerRadiusSqr = 9 * 9
local kDefendHiveRadiusSqr = 35 * 35
local kDesiredRange = 1.3
local kMaxBiteRange = 1.5
local kMinHiddenTime = 0.6
local kMinSneakRadiusSqr = 5 * 5
local kRecentDamageTime = 1
local kSneakRadiusSqr = 40 * 40
local kVectorUp = Vector(0, 1, 0)

---@class SkulkAttackState
---@field mem TeamBrain.Memory
---@field hiding boolean
---@field lastVisibleTime number
---@field targetTime number
---@field creepResult boolean
---@field creepTime number

---@param attackState SkulkAttackState
---@param mem TeamBrain.Memory
local function ResetAttackState(attackState, mem)
  attackState.mem = mem
  attackState.hiding = false
  attackState.lastVisibleTime = 0
  attackState.targetTime = GetTime()
  attackState.creepResult = false

  -- Don't reset the creepTime to avoid excessive ray tracing calls if the Skulk
  -- switches targets erratically.
  if not attackState.creepTime then
    attackState.creepTime = 0
  end
end

---@param skulk Player
local function IsUnderFireNow(skulk)
  return GetTime() - skulk:GetTimeLastDamageTaken() < kRecentDamageTime
end

---@param bot Bot
---@param skulk Player
---@param move Move
---@param enemy Player|ScriptActor
local function ParasiteTarget(bot, skulk, move, enemy)
  if skulk:SetActiveWeapon(Parasite.kMapName, true)
      and bot.aim:UpdateAim(enemy, GetBestAimPoint(enemy),
      kBotAccWeaponGroup.BiteLeap) then
    move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)
  end
end

---@param bot Bot
---@param brain PlayerBrain
---@param skulk Player
---@param move Move
---@param enemy Player
---@param sneak boolean
local function DirectAttackPlayer(bot, brain, skulk, move, enemy, sneak)
  local distanceSqr = skulk:GetDistanceSquared(enemy)
  if distanceSqr <= kMinSneakRadiusSqr then
    move.commands = RemoveMoveCommand(move.commands, Move.MovementModifier)
  end

  if not bot:GetBotCanSeeTarget(enemy) then
    bot:GetMotion():SetDesiredViewTarget()
    DoMove(skulk:GetOrigin(), enemy:GetOrigin(), bot, brain, move)
    return
  end

  local motion = bot:GetMotion()
  local engagementPoint = GetBestAimPoint(enemy)
  local strafeDir = (skulk:GetEyePos() - engagementPoint):CrossProduct(
    kVectorUp)
  do
    ---@type SkulkAttackState
    local attackState = GetCachedTable(skulk, "attack")
    local time = GetTime() - attackState.targetTime

    if math.sin(time * 3.5) > 0 then
      strafeDir = strafeDir * -1
    end
  end

  if GetDistanceToTouch(skulk:GetEyePos(), enemy) > kMaxBiteRange then
    if not enemy:GetIsParasited() and not sneak then
      DoMove(skulk:GetOrigin(), enemy:GetOrigin(), bot, brain, move)
      ParasiteTarget(bot, skulk, move, enemy)
    else
      if IsUnderFireNow(skulk) or not IsFacingAway(enemy, skulk) then
        local distance = skulk:GetDistance(enemy)
        local strafeDistance = min(0.1 * distance + 0.2, 0.8)
        local strafePosition = engagementPoint + (strafeDir * strafeDistance)
          + (enemy:GetVelocity():GetUnit() * 0.1)

        -- If the target is near a railing or ledge, a strafing movement may
        -- make the target inaccessible.
        local strafePathPoint = GetClosestPoint(strafePosition)
        if strafePathPoint == strafePosition
            or strafePathPoint:GetDistanceSquared(strafePosition) > 4 then
          strafePosition = engagementPoint
        end

        DoMove(skulk:GetOrigin(), strafePosition, bot, brain, move)
        motion:SetDesiredViewTarget()

        if kDebug then
          DebugLine(strafePosition, strafePosition + kVectorUp*3, 0.2, 1, 1, 1,
            1)
        end
      else
        DoMove(skulk:GetOrigin(), enemy:GetOrigin(), bot, brain, move)
      end
    end
  else
    if skulk:SetActiveWeapon(BiteLeap.kMapName, true)
        and bot.aim:UpdateAim(enemy, engagementPoint,
          kBotAccWeaponGroup.BiteLeap) then
      move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)
    end

    -- Random strafing motions when in melee range to throw off marine aim.
    motion:SetDesiredMoveDirection(
      (enemy:GetOrigin() + (strafeDir * 0.5) - skulk:GetOrigin()):GetUnit())
  end
end

---@param bot Bot
---@param attackState SkulkAttackState
---@param engagementPoint Vector
local function CanCreepForward(bot, attackState, engagementPoint)
  local time = GetTime()
  if time < attackState.creepTime then return attackState.creepResult end

  local pathPoint
  if bot.ventPath and bot.ventPath.active then
    pathPoint = GetVentIteratorPosition(bot.ventPath)
  else
    local motion = bot:GetMotion()
    -- TODO: Is 10 point lookahead enough or should it be less/more?
    if motion.desiredMoveTarget and motion.currPathPoints
        and motion.currPathPointsIt + 10 < #motion.currPathPoints then
      pathPoint = motion.currPathPoints[motion.currPathPointsIt + 10]
    end
  end

  if not pathPoint then return false end

  local trace = TraceRayDirect(pathPoint, engagementPoint)
  attackState.creepResult = not (trace and trace.fraction == 1)
  attackState.creepTime = time + 0.5

  if kDebug then
    if attackState.creepResult then
      DebugLine(pathPoint, engagementPoint, 0.5, 0, 1, 0, 1)
    else
      DebugLine(pathPoint, engagementPoint, 0.5, 1, 0, 0, 1)
    end
  end

  return attackState.creepResult
end

-- TODO: This doesn't do Xenocide at all yet!

---@param bot Bot
---@param brain PlayerBrain
---@param skulk Player
---@param move Move
---@param enemy Player
---@param mem TeamBrain.Memory
local function AttackPlayer(bot, brain, skulk, move, enemy, mem)
  local attackState = GetCachedTable(skulk, "attack") ---@type SkulkAttackState
  if attackState.mem ~= mem then
    ResetAttackState(attackState, mem)
  end

  -- Hallucinations are supposed to be dumb, forego all advanced logic.
  if skulk.isHallucination then
    DirectAttackPlayer(bot, brain, skulk, move, enemy, false)
    return
  end

  local senses = brain:GetSenses()
  do
    local nearestHive = senses:Get("ent_hive_nearest")
    local nearestHiveToTarget = GetEntityClosestTo(enemy,
      senses:Get("ent_hives_alive"))
    if (nearestHive.distanceSqr and nearestHive.distanceSqr
        <= kDefendHiveRadiusSqr)
        or (nearestHiveToTarget.distanceSqr and nearestHiveToTarget.distanceSqr
        <= kDefendHiveRadiusSqr) then
      DirectAttackPlayer(bot, brain, skulk, move, enemy, false)
      if kDebug then
        DebugLine(skulk:GetEyePos(), enemy:GetEngagementPoint(), 0.2, 1, 0, 0,
          1)
      end

      return
    end
  end

  local distanceSqr = skulk:GetDistanceSquared(enemy)
  local nearestTeammate = GetEntityClosestTo(enemy,
    senses:Get("ent_teammates_alive"))
  local isTeammateInvolved = nearestTeammate.distanceSqr
    and nearestTeammate.distanceSqr <= kAssistTeammateRadiusSqr
  local isFacingAway = IsFacingAway(enemy, skulk)
  local isInSight = bot:GetBotCanSeeTarget(enemy)
  local motion = bot:GetMotion()

  if kDebug then
    if isInSight then
      DebugLine(skulk:GetOrigin(), skulk:GetOrigin() + Vector(0, 4, 0), 0.2, 1,
        0, 0, 1)
    else
      DebugLine(skulk:GetOrigin(), skulk:GetOrigin() + Vector(0, 4, 0), 0.2, 0,
        0, 1, 1)
    end
  end

  local shouldSneak = distanceSqr <= kSneakRadiusSqr and not isTeammateInvolved
    and (not isInSight or isFacingAway) and not IsUnderFireNow(skulk)
  if shouldSneak then
    move.commands = AddMoveCommand(move.commands, Move.MovementModifier)
  end

  if distanceSqr > kDangerRadiusSqr
      and not (enemy:GetIsDoingDamage() and enemy:GetLastTarget() ~= skulk)
      and not isTeammateInvolved then
    if not enemy:GetIsParasited() then
      DoMove(skulk:GetOrigin(), enemy:GetOrigin(), bot, brain, move)
      attackState.hiding = false

      if isInSight then
        ParasiteTarget(bot, skulk, move, enemy)
      else
        motion:SetDesiredViewTarget()
      end

      if kDebug then
        DebugLine(skulk:GetEyePos(), enemy:GetEngagementPoint(), 0.2, 1, 1, 0,
          1)
      end
    elseif attackState.hiding and not IsUnderFireNow(skulk) then
      if isInSight and not isFacingAway then
        attackState.hiding = false
        attackState.lastVisibleTime = GetTime()
        RetreatAlien(skulk, bot, brain, move, DoMove)

        if kDebug then
          DebugLine(skulk:GetEyePos(), enemy:GetEngagementPoint(), 0.2, 0, 1, 0,
            1)
        end
      elseif isFacingAway then
        DirectAttackPlayer(bot, brain, skulk, move, enemy, shouldSneak)

        if kDebug then
          DebugLine(skulk:GetEyePos(), enemy:GetEngagementPoint(), 0.2, 0, 0, 1,
            1)
        end
      else
        local engagementPoint = enemy:GetEngagementPoint()

        if CanCreepForward(bot, attackState, engagementPoint) then
          DirectAttackPlayer(bot, brain, skulk, move, enemy, true)
        else
          motion:SetDesiredMoveTarget()
          motion:SetDesiredViewTarget(engagementPoint)
        end

        if kDebug then
          DebugLine(skulk:GetEyePos(), engagementPoint, 0.2, 0, 0, 0, 1)
        end
      end
    else
      if isInSight then
        attackState.lastVisibleTime = GetTime()
      elseif attackState.lastVisibleTime + kMinHiddenTime <= GetTime() then
        attackState.hiding = true
      end

      RetreatAlien(skulk, bot, brain, move, DoMove)

      if kDebug then
        DebugLine(skulk:GetEyePos(), enemy:GetEngagementPoint(), 0.2, 0, 1, 0,
          1)
      end
    end
  else
    --DebugLine(skulk:GetEyePos(), player:GetEngagementPoint(), 0.2, 1, 0, 0, 1)
    DirectAttackPlayer(bot, brain, skulk, move, enemy, shouldSneak)
  end
end

---@param skulk Player
---@param target ScriptActor
---@return Vector?
local function GetCoverPosition(skulk, target)
  local extents = HasMixin(target, "Extents") and target:GetMaxExtents()
  local damageOrigin = skulk:GetLastTakenDamageOrigin()
  if not extents or not damageOrigin then return nil end

  local targetOrigin = target:GetOrigin()
  return targetOrigin + ((targetOrigin - damageOrigin):GetUnit()
    * extents:GetLengthXZ())
end

---@param skulk Player
---@param brain PlayerBrain
---@param target ScriptActor
---@return Vector?
local function GetThreatCoverPosition(skulk, brain, target)
  local extents = HasMixin(target, "Extents") and target:GetMaxExtents()
  ---@type MemoryDistanceSqr
  local threatMemory = brain:GetSenses():Get("mem_threat_nearest")
  if not extents or not threatMemory.memory
      or threatMemory.distanceSqr >= 400 then
    return nil
  end

  local targetOrigin = target:GetOrigin()
  return targetOrigin
    + ((targetOrigin - threatMemory.memory.lastSeenPos):GetUnit()
    * extents:GetLengthXZ())
end

---@param bot Bot
---@param brain PlayerBrain
---@param skulk Player
---@param move Move
---@param target ScriptActor
local function AttackPassive(bot, brain, skulk, move, target)
  local motion = bot:GetMotion()
  local isInSight = bot:GetBotCanSeeTarget(target)
  local aimPoint = GetBestAimPoint(target)
  local touchDistance = GetDistanceToTouch(skulk:GetEyePos(), target)
  local canAttack = isInSight and touchDistance <= kMaxBiteRange
    and bot.aim:UpdateAim(target, aimPoint, kBotAccWeaponGroup.BiteLeap)

  if not target:GetIsParasited() and isInSight then
    ParasiteTarget(bot, skulk, move, target)
    DoMove(skulk:GetOrigin(), target:GetOrigin(), bot, brain, move)
    return
  end

  local coverPosition
  if skulk:GetIsUnderFire() then
    coverPosition = GetCoverPosition(skulk, target)
  else
    coverPosition = GetThreatCoverPosition(skulk, brain, target)
  end

  if canAttack and skulk:SetActiveWeapon(BiteLeap.kMapName, true) then
    move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)

    if coverPosition then
      DoMove(skulk:GetOrigin(), coverPosition, bot, brain, move)
    elseif touchDistance > kDesiredRange then
      DoMove(skulk:GetOrigin(), target:GetOrigin(), bot, brain, move)
    else
      motion:SetDesiredMoveTarget()
    end
  else
    if isInSight then
      motion:SetDesiredViewTarget(aimPoint)
    else
      motion:SetDesiredViewTarget()
    end

    DoMove(skulk:GetOrigin(), coverPosition or target:GetOrigin(), bot, brain,
      move)
  end
end

---@param move Move
---@param bot Bot
---@param brain PlayerBrain
---@param skulk Player
---@param action Action
function Bishop.alien.skulk.PerformAttack2(move, bot, brain, skulk, action)
  local ent = GetEntityIfAlive(action.memory.entId)
  if ent then
    if ent:isa("Player") then
      ---Target is definitely a player.
      ---@diagnostic disable-next-line: param-type-mismatch
      AttackPlayer(bot, brain, skulk, move, ent, action.memory)
    else
      AttackPassive(bot, brain, skulk, move, ent)
    end
  else
    DoMove(skulk:GetOrigin(), action.memory.lastSeenPos, bot, brain, move)
  end
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
