Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/alien/Lifeform.lua")
Script.Load("lua/bishop/alien/Pack.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local DebugLine = DebugLine
local IsValid = IsValid
local Shared_GetTime = Shared.GetTime

local CreatePack = Bishop.alien.pack.CreatePack
local GetBackpedalVector = Bishop.utility.GetBackpedalVector
local GetCurrentLifeform = Bishop.alien.lifeform.GetCurrentLifeform
local GetMaxPackSize = Bishop.alien.pack.GetMaxPackSize
local GetMoveFunction = Bishop.utility.GetMoveFunction
local GetPackSize = Bishop.alien.pack.GetPackSize
local IsFacing = Bishop.utility.IsFacing
local JoinPack = Bishop.alien.pack.JoinPack
local kNilAction = Bishop.lib.constants.kNilAction
local LeavePack = Bishop.alien.pack.LeavePack
local MergePack = Bishop.alien.pack.MergePack
local sharedObjectives = Bishop.alien.objectives

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kDebugBodyblock = Bishop.debug.bodyBlock

--------------------------------------------------------------------------------
-- Join packs when encountering fellow hive members.
--------------------------------------------------------------------------------
-- Having this system be dynamic allows for the occasional free roaming alien,
-- but ultimately encourages teamwork.

local kTimeBetweenPackScans = 1
local kMaxRangeForPackFormationSqr = 15 * 15

local function GetTeammateBrainWithinPackRange(brain)
  local nearestAlien = brain:GetSenses():Get("ent_teammate_nearest")

  if not IsValid(nearestAlien.entity)
      or nearestAlien.entity.isHallucination
      or not nearestAlien.entity:GetClient()
      or not nearestAlien.entity:GetClient():GetIsVirtual()
      or nearestAlien.distanceSqr > kMaxRangeForPackFormationSqr then
    return nil
  end

  -- Some literal hive mind shit.
  return nearestAlien.entity:GetControllingBot().brain
end

local function JoinOrFormPack(brain)
  local brainWithinRange = GetTeammateBrainWithinPackRange(brain)

  if not brainWithinRange then
    return
  end

  if not brainWithinRange.pack then
    CreatePack(brain)

    if brain.pack then
      JoinPack(brain.pack, brainWithinRange)
    end
  else
    JoinPack(brainWithinRange.pack, brain)
  end
end

local function AttemptPackMerge(brain)
  local brainWithinRange = GetTeammateBrainWithinPackRange(brain)

  if not brainWithinRange then
    return
  end

  if brainWithinRange.pack and brain.pack ~= brainWithinRange.pack then
    MergePack(brain.pack, brainWithinRange.pack)
  end
end

--------------------------------------------------------------------------------
-- Move around with the pack.
--------------------------------------------------------------------------------
-- This is a low priority objective, and can be overridden by all actions and
-- other lifeform responsibilities. Aliens are allowed the opportunity to
-- reconsider their objective after being in combat, as they may need to
-- retreat.

local kFollowDistance = 3

local function PerformMoveWithPack(move, bot, brain, alien, action)
  local eyePos = alien:GetEyePos()
  local target = action.target
  local distance = GetDistanceToTouch(eyePos, target)

  if alien:GetIsInCombat() or not target:GetIsAlive() then
    return true
  end

  brain.teamBrain:UnassignBot(bot)
  local engagementPoint = target:GetEngagementPoint()
  local motion = bot:GetMotion()

  if distance > kFollowDistance then
    motion:SetDesiredViewTarget(target:GetOrigin())
    action.Move(eyePos, engagementPoint, bot, brain, move)
  else
    if not IsFacing(target, alien:GetOrigin()) then
      motion:SetDesiredMoveTarget()
    else
      local backpedalVector = GetBackpedalVector(alien, target)
      if kDebugBodyblock then
        DebugLine(eyePos, eyePos + backpedalVector * 3, 1/4, 1, 0, 0, 1)
      end
      if bot.offNavMesh then
        LeavePack(brain)
      end
      motion:SetDesiredMoveDirection(backpedalVector)
    end
  end
end

local function ValidateMoveWithPack(bot, brain, alien, action)
  if not brain.pack or brain.pack.leader ~= action.leader
      or not IsValid(action.target) or not IsValid(brain.player) then
    return false
  end

  return true
end

function sharedObjectives.MoveWithPack(bot, brain, alien)
  if alien.isHallucination then
    return kNilAction
  end
  local time = Shared_GetTime()

  -- TODO: Initialise lastPackScanTime to remove the extra check.
  if not brain.pack and not brain.packLock and (not brain.lastPackScanTime or
      time + kTimeBetweenPackScans > brain.lastPackScanTime) then
    JoinOrFormPack(brain)
    brain.lastPackScanTime = time
  end

  if brain.pack and (not brain.lastPackScanTime or time + kTimeBetweenPackScans
      > brain.lastPackScanTime) then
    AttemptPackMerge(brain)
    brain.lastPackScanTime = time
  end

  local pack = brain.pack

  if not pack or pack.leader == brain or not IsValid(pack.leader.player) then
    return kNilAction
  end

  -- The weight and perform fields must be filled per lifeform. This is due to
  -- each lifeform having its own priorities and PerformMove function.
  return {
    name = "MoveWithPack",
    perform = PerformMoveWithPack,
    validate = ValidateMoveWithPack,
    weight = 1, -- Override per lifeform.

    -- Action metadata.
    leader = pack.leader,
    Move = GetMoveFunction(GetCurrentLifeform(alien)),
    target = pack.leader.player -- Always check validity before use.
  }
end

--------------------------------------------------------------------------------
-- Assault tech points with the pack.
--------------------------------------------------------------------------------
-- Once the pack has grown to adequate size, they should seek to gain map
-- control. Other bots will be running MoveWithPack, this objective is intended
-- only for the pack leader.

local kMaxDistanceToComplete = 5
local kMaxMissingPackMembersForAssault = 1
local kMaxRangeForTechPointAssault = 100

local function PerformAssaultTechPoint(move, bot, brain, alien, action)
  local eyePos = alien:GetEyePos()
  local target = action.target
  local distance = GetDistanceToTouch(eyePos, target)

  if alien:GetIsInCombat() or not target:GetIsAlive()
     or distance < kMaxDistanceToComplete then
    return true
  end

  brain.teamBrain:UnassignBot(bot)
  local engagementPoint = target:GetEngagementPoint()
  local motion = bot:GetMotion()

  motion:SetDesiredViewTarget(target:GetOrigin())
  action.Move(eyePos, engagementPoint, bot, brain, move)
end

local function ValidateAssaultTechPoint(bot, brain, alien, action)
  if not brain.pack or brain.pack.leader ~= brain
      or not IsValid(action.target) or not action.target:GetIsAlive()
      or not IsValid(brain.player) or brain.player:GetIsInCombat() then
    return false
  end

  return true
end

function sharedObjectives.AssaultTechPoint(bot, brain, alien)
  local pack = brain.pack

  if not pack or pack.leader ~= brain
      or GetPackSize(pack)
      < GetMaxPackSize() - kMaxMissingPackMembersForAssault then
    return kNilAction
  end

  -- TODO: Target marine occupied tech points based on memories instead.
  local commandStations = GetEntitiesAliveForTeam("CommandStation",
    GetEnemyTeamNumber(bot:GetTeamNumber()))
  
  if #commandStations == 0 then
    return kNilAction
  end

  local distance, commandStation = GetMinTableEntry(commandStations,
    function(commandStation)
      return select(2, GetTunnelDistanceForAlien(alien, commandStation))
    end)
  
  if distance > kMaxRangeForTechPointAssault then
    return kNilAction
  end
  
  -- The weight and perform fields must be filled per lifeform. This is due to
  -- each lifeform having its own priorities and PerformMove function.
  return {
    name = "AssaultTechPoint",
    perform = PerformAssaultTechPoint,
    weight = 1, -- Override per lifeform.
    validate = ValidateAssaultTechPoint,

    -- Action metadata.
    Move = GetMoveFunction(GetCurrentLifeform(alien)),
    target = commandStation
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
