Script.Load("lua/bishop/global/Stuck.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local OldPerformMove = Bishop.alien.onos.PerformMove
local StuckMove = Bishop.global.stuck.StuckMove

--------------------------------------------------------------------------------
-- Hook in the unstuck movement logic.
--------------------------------------------------------------------------------

function Bishop.alien.onos.DoMove(from, to, bot, brain, move)
  local onos = bot:GetPlayer()
  if StuckMove(bot, onos, move, onos:GetOrigin(), to) then
    return
  end

  OldPerformMove(from, to, bot, brain, move)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
