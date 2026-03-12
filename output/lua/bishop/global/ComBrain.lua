Script.Load("lua/TechData.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class CommanderBrain : PlayerBrain
---@field ExecuteTechId function

local GetIsBuildTunnelTech = Shine.GetUpValue(_G.CommanderBrain.ExecuteTechId,
  "GetIsBuildTunnelTech", true)
local LookupTechData = LookupTechData
local Shared_GetTime = Shared.GetTime

--------------------------------------------------------------------------------
-- Increase the commander's responsiveness.
--------------------------------------------------------------------------------
-- The default value of 0.5 was likely chosen to match the CPU power of machines
-- back in 2012. Increasing the action tick rate shouldn't cause any problems.
-- This change was made for the glory of medpack spamming.

CommanderBrain.kActionDelay = 0.25

--------------------------------------------------------------------------------
-- Add a parameter to ExecuteTechId that allows for building rotation.
--------------------------------------------------------------------------------

function CommanderBrain:ExecuteTechId(com, techId, position, hostEntity,
    targetId, trace, azimuth)
  PROFILE("CommanderBrain:ExecuteTechId")

  local techNode = com:GetTechTree():GetTechNode(techId)
  local allowed, canAfford = hostEntity:GetTechAllowed(techId, techNode, com)
  if not (allowed and canAfford) then
    return
  end

  -- UWE: We should probably use ProcessTechTreeAction instead here.
  com.isBotRequestedAction = true -- Hackapalooza...
  local success, keepGoing
  if techId == kTechId.Cyst or GetIsBuildTunnelTech(techId) then
    com:ProcessTechTreeAction(techId, position, azimuth or 0, position)
  else
    success, keepGoing = com:ProcessTechTreeActionForEntity(techNode, position,
      Vector(0, 1, 0), true, azimuth or 0, hostEntity, trace, targetId)
  end

  if success then
    local cooldown = LookupTechData(techId, kTechDataCooldown, 0)
    if cooldown ~= 0 then
      com:SetTechCooldown(techId, cooldown, Shared_GetTime())
    end
  else
    DebugPrint("COM BOT ERROR: Failed to perform action %s",
      EnumToString(kTechId, techId))
  end

  return success
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
