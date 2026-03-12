-- NOTE: Currently disabled when Bot_Maintenance is loaded due to conflicts.

Script.Load("lua/Balance.lua")
Script.Load("lua/BalanceMisc.lua")
Script.Load("lua/TechTreeConstants.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local kScanDuration = kScanDuration
local kTechId = kTechId
local Shared_GetTime = Shared.GetTime

local actions = Bishop.marineCom.actions
local kActionTypes = Bishop.marineCom.kActionTypes
local GetActionWeight = Bishop.marineCom.GetActionWeight
local kNilAction = Bishop.lib.constants.kNilAction
local TraceFromAbove = Bishop.utility.TraceFromAbove

--------------------------------------------------------------------------------
-- Scan the hive when marines are nearby.
--------------------------------------------------------------------------------
-- Bot marines are often unaware that an enemy hive and structures are nearby,
-- instead opting to walk right past them.

local kMinResources = 20
local kMaxMarineDistance = kARCRange
local kTraceScanRadius = 5

local function PerformScanHive(move, bot, brain, com, action)
  local success = brain:ExecuteTechId(com, kTechId.Scan, action.trace.endPoint,
    com, action.entityId, action.trace)

  if success then
    brain.timeNextScan = Shared_GetTime() + kScanDuration
  end
end

function actions.ScanHive(bot, brain, com)
  local resources = com:GetTeamResources()
  local senses = brain:GetSenses()

  if Shared_GetTime() < brain.timeNextScan
      or resources < kMinResources
      or not senses:Get("doableTechIds")[kTechId.Scan] then
    return kNilAction
  end

  local closest = senses:Get("closestHiveToMarines")

  if not closest.distance
      or closest.distance > kMaxMarineDistance
      or not closest.hive:GetIsCloaked() then
    return kNilAction
  end

  local trace = TraceFromAbove(closest.hive:GetOrigin(), kTraceScanRadius)

  if not trace then
    return kNilAction
  end

  return {
    name = "ScanHive",
    perform = PerformScanHive,
    weight = GetActionWeight(kActionTypes.ScanHive),

    -- Action metadata.
    entityId = closest.hive:GetId(),
    trace = trace
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
