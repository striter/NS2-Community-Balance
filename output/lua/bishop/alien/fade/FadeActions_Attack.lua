Script.Load("lua/Globals.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/bots/BotUtils.lua")
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/CommonAlienActions.lua")
Script.Load("lua/Weapons/Alien/StabBlink.lua")
Script.Load("lua/Weapons/Alien/SwipeBlink.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/fade/FadeMovement.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local AddMoveCommand = AddMoveCommand
local ConditionalValue = ConditionalValue
local DotProduct = Math.DotProduct ---@type function
local GetBestAimPoint = GetBestAimPoint
local GetEntity = Shared.GetEntity ---@type function
local GetMaxTableEntry = GetMaxTableEntry
local GetPositionBehindTarget = GetPositionBehindTarget
local GetTunnelDistanceForAlien = GetTunnelDistanceForAlien
local IsPointInCone = IsPointInCone
local max = math.max
local RemoveMoveCommand = RemoveMoveCommand
local select = select
local GetTime = Shared.GetTime ---@type function

local DoMove = Bishop.alien.fade.DoMove
local GetActionWeight = Bishop.alien.fade.GetActionWeight
local GetEntityIfAlive = Bishop.lib.entity.GetEntityIfAlive
local IsFacing = Bishop.utility.IsFacing

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kAttackRange = 2.4          -- Range to close in on target.
local kAvoidRange = 20            -- Don't close risky distances under fire.
local kGuerrillaTriggerTime = 0.5 -- Time to check after damage for retreat.
local kMaxAttackDistance = 50     -- Ignore targets beyond this distance.
local kMaxBodyBlockDistance = 1.5 -- Bodyblock detection distance threshold.
local kMinBodyBlockTime = 2.5     -- Ignore bodyblocks within this retreat time.

local kImmediate = {              -- Immediate threats receive bonus value.
  [kMinimapBlipType.Marine]        = true,
  [kMinimapBlipType.JetpackMarine] = true,
  [kMinimapBlipType.Exo]           = true
}
local kUrgencies = {              -- Target urgency based on team attention.
  [kMinimapBlipType.Marine] =            {2, 0.7, 1.2},
  [kMinimapBlipType.JetpackMarine] =     {2, 0.8, 1.2},
  [kMinimapBlipType.Exo] =               {2, 0.9, 1.2},

  [kMinimapBlipType.ARC] =               {1, 0.8, 1.2},
  [kMinimapBlipType.MAC] =               {1, 0.8, 1.2},
  [kMinimapBlipType.Sentry] =            {2, 0.8, 1.2},
  [kMinimapBlipType.SentryBattery] =     {2, 0.8, 1.2},
  [kMinimapBlipType.CommandStation] =    {2, 0.3, 1.2},
  [kMinimapBlipType.ArmsLab] =           {2, 0.3, 1.2},
  [kMinimapBlipType.PrototypeLab] =      {2, 0.3, 1.2},
  [kMinimapBlipType.RoboticsFactory] =   {2, 0.3, 1.2},
  [kMinimapBlipType.PhaseGate] =         {2, 0.2, 1.2},
  [kMinimapBlipType.Observatory] =       {2, 0.2, 1.15},
  [kMinimapBlipType.Armory] =            {2, 0.2, 1.15},
  [kMinimapBlipType.Extractor] =         {1, 0.2, 1.1},
  [kMinimapBlipType.InfantryPortal] =    {1, 0.2, 1.0},
--[kMinimapBlipType.PowerPoint] =        {1, 0.2, 0.6},
}

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes = Bishop.alien.fade.kActionTypes
local kBotAccWeaponGroup = kBotAccWeaponGroup
local kNilAction = Bishop.lib.constants.kNilAction

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function GetAttackUrgency(bot, fade, memory)
  local entity = GetEntityIfAlive(memory.entId)
  if not entity or not kUrgencies[memory.btype] then
    return nil
  end

  -- Apply bonus to immediate threats based on distance.
  local distance = fade:GetOrigin():GetDistance(entity:GetOrigin())
  if distance < 15 and kImmediate[memory.btype] then
    return 1.2 + 1 / max(distance, 1)
  end

  -- Until Stab is unlocked, Fades should only attack structures if they have
  -- nothing else to do.
  local urgency = kUrgencies[memory.btype]
  local penalty = entity.GetIsGhostStructure
    and not fade:GetWeapon(StabBlink.kMapName) and 0.5 or 1
  if not fade:GetIsUnderFire() then
    penalty = penalty * 1.1
  end

  -- Apply load balancing based on team's targets.  
  if bot.brain.teamBrain:GetNumOthersAssignedToEntity(fade, memory.entId)
      >= urgency[1] then
    return urgency[2] * penalty
  end
  return urgency[3] * penalty
end

-- If the Fade has dealt damage recently and is outnumbered, force a temporary
-- retreat to begin.
local function GuerrillaRetreat(brain, fade)
  local senses = brain:GetSenses()
  local time = GetTime()
  if not brain.activeRetreat
      and #senses:Get("ent_hives_built") > 0
      and brain:GetSenses():Get("per_outnumbered_count") > 0
      and (time - fade:GetTimeLastDamageDealt()) < kGuerrillaTriggerTime then
    brain.activeRetreat = true
    brain.activeRetreatTime = time
  end
end

--------------------------------------------------------------------------------
-- Fade attack actions.
--------------------------------------------------------------------------------

local function PerformAttackEntity(eyePos, target, bot, brain, move)
  GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(),
    kBotDebugSection.ActionWeight, "Target", ToString(target))
  local aimPos = GetBestAimPoint(target)
  local fade = bot:GetPlayer()
  local isPlayer = target:isa("Player")
  -- local distance = select(2, GetTunnelDistanceForAlien(fade, target))
  local distance = GetDistanceToTouch(eyePos, target)
  local behindPos = GetPositionBehindTarget(fade, target, kAttackRange)

  if distance <= kAttackRange then -- + math.random(0.05, 0.125)
    fade:SetActiveWeapon(SwipeBlink.kMapName, true)

    -- Only take a swing if moving towards the target. If the Fade is moving
    -- away the swing is very likely to miss and just waste energy.
    if DotProduct(fade:GetVelocity():GetUnit(),
        (aimPos - eyePos):GetUnit()) >= 0 then
      move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)
    end

    if bot.aim then
      bot.aim:UpdateAim(target, aimPos, kBotAccWeaponGroup.Swipe)
    end

    if isPlayer then
      -- Try to strafe behind the target if it's aiming at the Fade.
      local strafePos = IsPointInCone(aimPos, target:GetEyePos(),
        target:GetViewAngles():GetCoords().zAxis, math.rad(55)) and behindPos
        or aimPos
      local strafeDir = (eyePos - strafePos):CrossProduct(Vector(0, 1, 0))
      local time = GetTime()
      strafeDir:Normalize()
      strafeDir = strafeDir * ConditionalValue(math.sin(time * 3.5)
        + math.sin(time * 4.5) > 0, -1, 1)
      if strafeDir:GetLengthSquared() > 0 then
        -- DebugLine(eyePos, eyePos + strafeDir, 0.2, 1, 0, 0, 1)
        bot:GetMotion():SetDesiredMoveDirection(strafeDir)
      end
    else
      -- No need for complicated logic against non-Marine targets. (MAC / ARC.)
      if distance <= kAttackRange * 0.915 then
        bot:GetMotion():SetDesiredMoveTarget()
        move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)
        move.commands = RemoveMoveCommand(move.commands, Move.Jump)
        move.commands = RemoveMoveCommand(move.commands, Move.SecondaryAttack)
      end
    end
  else
    if isPlayer and distance >= kAvoidRange and fade:GetIsUnderFire() then
      brain.activeRetreat = true
      brain.activeRetreatTime = GetTime()
    else
      DoMove(eyePos, behindPos or target:GetOrigin(), bot, brain, move)
    end
  end
end

local function PerformAttackStructure(eyePos, target, bot, brain, move)
  GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(),
    kBotDebugSection.ActionWeight, "Target", ToString(target))
  local aimPos = GetBestAimPoint(target)
  local fade = bot:GetPlayer()
  -- local distance = select(2, GetTunnelDistanceForAlien(fade, target))
  local distance = GetDistanceToTouch(eyePos, target)

  if distance <= kAttackRange and not target:GetIsGhostStructure() then
    if bot.aim then
      bot.aim:UpdateAim(target, aimPos, kBotAccWeaponGroup.Swipe)
    end

    local stabWeapon = fade:GetWeapon(StabBlink.kMapName)
    if stabWeapon then
      fade:SetActiveWeapon(StabBlink.kMapName)
    end

    move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)

    if distance <= kAttackRange * 0.915 then
      bot:GetMotion():SetDesiredMoveTarget()
      move.commands = RemoveMoveCommand(move.commands, Move.Jump)
      move.commands = RemoveMoveCommand(move.commands, Move.SecondaryAttack)
    end
  else
    DoMove(eyePos, target:GetOrigin(), bot, brain, move)
  end
end

local function PerformAttack(move, bot, brain, fade, action)
  local memory = action.memory
  local target = GetEntity(memory.entId)
  brain.teamBrain:UnassignBot(bot)
  brain.teamBrain:AssignBotToMemory(bot, memory)

  if target then
    if target.GetIsGhostStructure then
      PerformAttackStructure(fade:GetEyePos(), target, bot, brain, move)
    else
      PerformAttackEntity(fade:GetEyePos(), target, bot, brain, move)

      -- Preserve Bot_Maintenance's chat message.
      local chatMsg = "Blink and slash marines! " .. target:GetMapName()
        .. " in " .. target:GetLocationName()
      bot:SendTeamMessage(chatMsg, 60)
    end
  else
    DoMove(fade:GetEyePos(), memory.lastSeenPos, bot, brain, move)
  end
end

function Bishop.alien.fade.actions.Attack(bot, brain, fade)
  GuerrillaRetreat(brain, fade)

  local _, memory = GetMaxTableEntry(brain:GetSenses():Get("mem_enemies"),
    function(memory)
      return GetAttackUrgency(bot, fade, memory)
    end)

  if not memory then
    return kNilAction
  end

  local targetPosition = memory.lastSeenPos
  local distance = select(2, GetTunnelDistanceForAlien(fade, targetPosition))
  local retreating = brain.activeRetreat
  local danger = brain:GetSenses():Get("per_danger")

  -- TODO: This should be moved into the Interrupt action later.
  if danger and brain.goalAction and brain.goalAction.name ~= "Retreat" then
    brain:InterruptCurrentGoalAction()
  end

  if not (distance <= kMaxAttackDistance         -- Regular attack condition.
        and not danger
        and not retreating)
      and not (distance <= kMaxBodyBlockDistance -- Bodyblock detection.
        and IsFacing(fade, targetPosition)
        and retreating
        and GetTime() > brain.activeRetreatTime + kMinBodyBlockTime)
      and not fade.isHallucination then
    return kNilAction
  end

  return {
    fastUpdate = true,
    name = "Attack",
    perform = PerformAttack,
    weight = GetActionWeight(kActionTypes.Attack),

    -- Action metadata.
    memory = memory
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
