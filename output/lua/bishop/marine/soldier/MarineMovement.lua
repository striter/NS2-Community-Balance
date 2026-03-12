Script.Load("lua/bishop/global/Stuck.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local OldPerformMove = Bishop.marine.PerformMove
local StuckMove = Bishop.global.stuck.StuckMove

--------------------------------------------------------------------------------
-- Hook in the unstuck movement logic.
--------------------------------------------------------------------------------

function Bishop.marine.DoMove(from, to, bot, brain, move, isUse, noSprint)
  local marine = bot:GetPlayer()
  if StuckMove(bot, marine, move, marine:GetOrigin(), to) then
    return
  end

  OldPerformMove(from, to, bot, brain, move, isUse, noSprint)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
