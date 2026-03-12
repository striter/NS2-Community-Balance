Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

Bishop.alienCom.offensiveTunnel = {}

local Shared_GetEntity = Shared.GetEntity

--------------------------------------------------------------------------------
-- Balance variables and constants.
--------------------------------------------------------------------------------
--    ┌─────────┐    ┌───────────────┐    ┌───────────┐    
--    │         │    │               │    │           │  Losing the cyst before
-- ┌─►│ Unbuilt ├───►│ CystRequested ├───►│ CystReady │  construction also falls
-- │  │         │    │               │    │           │  back to .Unbuilt.
-- │  └─────────┘    └───────────────┘    └─────▲─────┘    
-- └─────────────┬─────────────────────┬────────┤  If the offensive tunnel dies
--               │                     │        │  at any point below this line
--           ┌───┴────┐            ┌───┴───┐    │  immediately fall back to the
--           │        │            │       │    │  .Unbuilt state.
--           │ Shaded │◄───────────┤ Built │◄───┤          
--           │        │            │       │    │          
--           └┬───────┘            └──────┬┘    │          
--            │                           │     ▲          
--            │    ┌──────────────────┐   │     │  Tunnels marked as irrelevant
--            │    │                  │   │     │  start a scan for a new
--            └───►│ TunnelIrrelevant │◄──┘     │  location to move it to.
--                 │                  ├◄───────►┤          
--                 └─────────┬────────┘         │          
--                           ▼     ┌────────────┤          
--                 ┌───────────────┴──┐  ┌──────┴───────┐  
--                 │                  │  │              │  NewCystReady triggers
--                 │ NewCystRequested ├─►│ NewCystReady │  the collapse of the
--                 │                  │  │              │  existing tunnel then
--                 └──────────────────┘  └──────────────┘  reverts to CystReady.

Bishop.alienCom.offensiveTunnel.kTunnelState = enum({
  "Unbuilt",          -- Almost every state falls back here if the tunnel dies.
  "CystRequested",
  "CystReady",
  "Built",            -- Anything >= Built means a tunnel exists.
  "Shaded",
  "Irrelevant",       -- Anything >= TunnelIrrelevant used for relocating.
  "NewCystRequested",
  "NewCystReady"
})

local kTunnelState = Bishop.alienCom.offensiveTunnel.kTunnelState

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

function Bishop.alienCom.offensiveTunnel.GetOffensiveCyst(teamBrain)
  return Shared_GetEntity(teamBrain.offensiveTunnelCystId)
end

function Bishop.alienCom.offensiveTunnel.GetOffensiveCystPosition(teamBrain)
  -- This value is approximate if the cyst isn't built, and is replaced with the
  -- actual position when built.
  return teamBrain.offensiveTunnelCystPosition
end

function Bishop.alienCom.offensiveTunnel.GetOffensiveTunnel(teamBrain)
  return Shared_GetEntity(teamBrain.offensiveTunnelId)
end

local GetOffensiveTunnel = Bishop.alienCom.offensiveTunnel.GetOffensiveTunnel

function Bishop.alienCom.offensiveTunnel.GetOffensiveEntrance(teamBrain)
  return Shared_GetEntity(teamBrain.offensiveTunnelId):GetOtherEntrance()
end

function Bishop.alienCom.offensiveTunnel.GetOffensiveTunnelPosition(teamBrain)
  -- This value is approximate if the tunnel isn't built, and is replaced with
  -- the actual position when built.
  return teamBrain.offensiveTunnelPosition
end

function Bishop.alienCom.offensiveTunnel.OffensiveTunnelCystExists(teamBrain)
  local state = teamBrain.offensiveTunnelState

  if state <= kTunnelState.CystRequested then
    return false
  end

  if state >= kTunnelState.Built then
    local tunnelEntity = GetOffensiveTunnel(teamBrain)
    if IsValid(tunnelEntity) and tunnelEntity:GetIsInfested() then
      return true
    end
  end

  local entityId = teamBrain.offensiveTunnelCystId
  local entity = Shared_GetEntity(entityId)

  if not IsValid(entity) or not entity:GetIsAlive() then
    return false
  end

  return true
end

function Bishop.alienCom.offensiveTunnel.OffensiveTunnelExists(teamBrain)
  if teamBrain.offensiveTunnelState <= kTunnelState.CystReady then
    return false
  end

  local entityId = teamBrain.offensiveTunnelId
  local entity = Shared_GetEntity(entityId)

  if not IsValid(entity) or not entity:GetIsAlive() then
    return false
  end

  return true
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
