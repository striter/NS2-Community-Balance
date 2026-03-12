Script.Load("lua/bishop/global/Stuck.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local OldPerformMove = Bishop.marine.exo.PerformMove
local StuckMove = Bishop.global.stuck.StuckMove

--------------------------------------------------------------------------------
-- Hook in the unstuck movement logic.
--------------------------------------------------------------------------------

function Bishop.marine.exo.DoMove(from, to, bot, brain, move)
  local exo = bot:GetPlayer()
  if StuckMove(bot, exo, move, exo:GetOrigin(), to) then
    return
  end

  OldPerformMove(from, to, bot, brain, move)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
