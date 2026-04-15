Script.Load("lua/bishop/global/Stuck.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local OldPerformMove = Bishop.alien.gorge.PerformMove
local StuckMove = Bishop.global.stuck.StuckMove

--------------------------------------------------------------------------------
-- Hook in the unstuck movement logic.
--------------------------------------------------------------------------------

function Bishop.alien.gorge.DoMove(from, to, bot, brain, move)
  local gorge = bot:GetPlayer()
  if StuckMove(bot, gorge, move, gorge:GetOrigin(), to) then
    return
  end

  OldPerformMove(from, to, bot, brain, move)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
