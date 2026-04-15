Script.Load("lua/Balance.lua")
Script.Load("lua/CollisionRep.lua")
Script.Load("lua/NS2Utility.lua")
Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/BabblerEggAbility.lua")
Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local DebugLine = DebugLine
local EntityFilterAll = EntityFilterAll
local max = math.max
local Shared_GetTime = Shared.GetTime
local Shared_TraceRay = Shared.TraceRay

local Log = Bishop.debug.BileMineLog
local SearchMemoriesForAny = Bishop.utility.SearchMemoriesForAny

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kMaxActionWeight = 9       -- Action weight when close to target.
local kMinActionWeight = 2       -- Action weight when kActionWeightDistance.
local kActionDistSqr   = 60 * 60 -- Distance to slerp min/max action weight.

local kDangerRadiusSqr = 8 * 8   -- Reactively place mines when close to danger.
local kTimeBetweenAttempts = 2   -- Cooldown on fail to limit TraceRay calls.

local kMemoryTypes = {           -- Memories to consider for placement.
  kMinimapBlipType.Marine,
  kMinimapBlipType.Exo,
  kMinimapBlipType.ARC
}

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local CollisionRep_Damage = CollisionRep.Damage
local DropStructureAbility_kMapName = DropStructureAbility.kMapName
local kActionWeightDelta = kMaxActionWeight - kMinActionWeight
local kDebug = Bishop.debug.bileMine
local kDownVector = Vector(0, -5, 0)
local kEnergyCost = BabblerEggAbility.GetEnergyCost(nil)
local kNumBabblerEggsPerGorge = kNumBabblerEggsPerGorge
local kNilAction = Bishop.lib.constants.kNilAction
local kStructureId = 4 -- Index into DropStructureAbility.kSupportedStructures.
local kTechId_BabblerEgg = kTechId.BabblerEgg
local PhysicsMask_Bullets = PhysicsMask.Bullets

--------------------------------------------------------------------------------
-- Debug options.
--------------------------------------------------------------------------------

local kDebugBilePlacement = Bishop.debug.bileMine -- Show visual cues.
local kDebugSpam = false                          -- Test placement.

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

local function GetBotBileMineCount(gorge)
  return gorge:GetTeam():GetNumDroppedGorgeStructures(gorge, kTechId_BabblerEgg)
end

local function GetActionWeight(distanceSqr)
  if kDebugSpam then
    return kMaxActionWeight
  end

  local interp = max(0, 1 - distanceSqr / kActionDistSqr)
  return interp * kActionWeightDelta + kMinActionWeight
end

--------------------------------------------------------------------------------
-- Place Bile Mines in areas of recent marine or ARC traffic.
--------------------------------------------------------------------------------
-- Since the action is a binary on/off, there's no need to determine a placement
-- location, just dump the mine right infront of the Gorge.

local function PerformBuildBileMine(move, bot, brain, gorge, action)
  brain.timeNextBileMineAttempt = Shared_GetTime() + kTimeBetweenAttempts

  if gorge:GetEnergy() < kEnergyCost then
    if kDebug then Log("Energy dropped after action selection, skipping.") end
    return
  end

  -- Since getting the bot Gorge to look at an exact point on the floor infront
  -- would be extremely tedious, make the simplifying assumption that it already
  -- is.
  local position, normal
  do
    local infront = gorge:GetEyePos() + gorge:GetViewCoords().zAxis * 2
    if kDebugBilePlacement then
      DebugLine(gorge:GetEyePos(), infront, 5, 1, 1, 0, 1)
    end

    local trace = Shared_TraceRay(infront, infront + kDownVector,
      CollisionRep_Damage, PhysicsMask_Bullets, EntityFilterAll())
    if trace.fraction == 1 then
      if kDebugBilePlacement then
        DebugLine(infront, infront + kDownVector, 5, 1, 0, 0, 1)
      end
      if kDebug then Log("First trace to floor failed.") end
      brain.timeNextBileMineAttempt = Shared_GetTime() + kTimeBetweenAttempts
      return
    else
      if kDebugBilePlacement then
        DebugLine(infront, trace.endPoint, 5, 0, 1, 0, 1)
      end
      position = trace.endPoint
      normal = trace.normal
    end
  end

  gorge:SetActiveWeapon(DropStructureAbility_kMapName, true)
  local buildAbility = gorge:GetWeapon(DropStructureAbility_kMapName)
  buildAbility:SetActiveStructure(kStructureId)
  local placePosition, isValid, _, placeNormal =
    buildAbility:GetPositionForStructure(gorge:GetEyePos(),
    gorge:GetViewCoords().zAxis, BabblerEggAbility, position, normal)

  if not isValid then
    if kDebug then Log("Placement position was invalid.") end
    return
  end

  if kDebug then Log("Attempting placement.") end
  buildAbility:OnDropStructure(gorge:GetOrigin(), gorge:GetViewCoords().zAxis,
    kStructureId, placePosition, placeNormal)
end

function Bishop.alien.gorge.actions.BuildBileMine(bot, brain, gorge)
  if gorge.isHallucination
      or GetBotBileMineCount(gorge) >= kNumBabblerEggsPerGorge
      or gorge:GetEnergy() < kEnergyCost
      or Shared_GetTime() < brain.timeNextBileMineAttempt
      or gorge:GetIsUnderFire() then
    return kNilAction
  end

  local placeMine = false
  local position = gorge:GetOrigin()
  local memories = SearchMemoriesForAny(kAlienTeamType, kMemoryTypes)
  for _, memory in ipairs(memories) do
    if position:GetDistanceSquared(memory.lastSeenPos) <= kDangerRadiusSqr then
      placeMine = true
      break
    end
  end

  if not placeMine and not kDebugSpam then
    return kNilAction
  end

  return {
    name = "BuildBileMine",
    perform = PerformBuildBileMine,
    weight = GetActionWeight(gorge:GetOrigin():GetDistanceSquared(position))
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
