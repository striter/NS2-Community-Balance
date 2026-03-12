Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Prevent mass kicking of bots when spamming 'E' on the command station.
--------------------------------------------------------------------------------

function NS2Gamerules:OnCommanderLogin(commandStructure, newCommander)
  local teamInfo = GetTeamInfoEntity(commandStructure:GetTeamNumber())

  if teamInfo:GetLastCommIsBot() then
    for i = 1, #gCommanderBots do
      local bot = gCommanderBots[i]
      if bot
          and bot:GetPlayer():GetTeamNumber()
            == commandStructure:GetTeamNumber() then
        bot:Disconnect()
        teamInfo.lastCommIsBot = false
        break
      end
    end
  end

  if not self.gameInfo:GetRookieMode() and not Shared.GetCheatsEnabled()
     and Server.IsDedicated() and not self.botTraining
     and newCommander:GetIsRookie() then
    Server.SendNetworkMessage(nil, "CommanderLoginError", {}, true)
  end

  return not commandStructure:GetTeam():GetHasCommander()
end

--------------------------------------------------------------------------------
-- Always allow bots to join a team no matter how stacked it is.
--------------------------------------------------------------------------------

local function NS2Gamerules_GetCanJoinTeamNumber(self, player)
  if Server.GetOwner(player):GetIsVirtual() then
    return true
  end
end

Shine.Hook.SetupClassHook("NS2Gamerules", "GetCanJoinTeamNumber",
  "BishopGamerulesJoin", "ActivePost")
Shine.Hook.Add("BishopGamerulesJoin", "BishopGRJTNHook",
  NS2Gamerules_GetCanJoinTeamNumber)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
