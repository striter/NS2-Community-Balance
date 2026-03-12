Script.Load("lua/BalanceMisc.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/Utility.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local ipairs = ipairs
local IsValid = IsValid
local Shared_GetEntity = Shared.GetEntity
local Shared_GetTime = Shared.GetTime

local EntityWithinSqrRange = Bishop.utility.EntityWithinSqrRange
local GetActionWeight = Bishop.marineCom.GetActionWeight
local SearchMemoriesFor = Bishop.utility.SearchMemoriesFor
local TraceFromAbove = Bishop.utility.TraceFromAbove

--------------------------------------------------------------------------------
-- Balance.
--------------------------------------------------------------------------------

local kCooldown          = kScanDuration -- Wait period between scans.
local kMarineDistanceSqr = 10 * 10       -- Marine distance for scan (m^2). 
local kMinResources      = 20            -- Minimum team resources for scan.
local kScanOffset        = 1             -- Offset from exact position.

--------------------------------------------------------------------------------
-- Constants.
--------------------------------------------------------------------------------

local kActionTypes = Bishop.marineCom.kActionTypes
local kNilAction = Bishop.lib.constants.kNilAction
local kTechId_Scan = kTechId.Scan
local kTunnelEntranceBlip = kMinimapBlipType.TunnelEntrance

--------------------------------------------------------------------------------
-- Scan known cloaked tunnels when marines are nearby.
--------------------------------------------------------------------------------
-- Marines will ignore cloaked structures even if they have previously been
-- spotted. Having the commander scan then will ensure the bots target them.

local function PerformScanTunnel(move, bot, brain, com, action)
  local success = brain:ExecuteTechId(com, kTechId_Scan, action.trace.endPoint,
    com, action.entityId, action.trace)
  if success then
    brain.nextTunnelScanTime = Shared_GetTime() + kCooldown
  end
end

function Bishop.marineCom.actions.ScanTunnel(bot, brain, com)
  local teamResources = com:GetTeamResources()
  local senses = brain:GetSenses()
  if Shared_GetTime() < brain.nextTunnelScanTime
      or teamResources < kMinResources
      or not senses:Get("doableTechIds")[kTechId_Scan] then
    return kNilAction
  end

  local marines = senses:Get("marines")
  local knownTunnels = SearchMemoriesFor(kMarineTeamType, kTunnelEntranceBlip)
  local scanTunnel
  for _, tunnelMemory in ipairs(knownTunnels) do
    local tunnel = Shared_GetEntity(tunnelMemory.entId)
    if IsValid(tunnel) and tunnel:GetIsAlive() and tunnel:GetIsCloaked()
        and EntityWithinSqrRange(tunnel, marines, kMarineDistanceSqr) then
      scanTunnel = tunnel
      break
    end
  end
  if not scanTunnel then
    return kNilAction
  end

  local trace = TraceFromAbove(scanTunnel:GetOrigin(), kScanOffset)
  if not trace then
    return kNilAction
  end

  return {
    name = "ScanTunnel",
    perform = PerformScanTunnel,
    weight = GetActionWeight(kActionTypes.ScanTunnel),

    -- Action metadata.
    entityId = scanTunnel:GetId(),
    trace = trace
  }
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
