Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Suppress draw errors caused by all-bot games.
--------------------------------------------------------------------------------
-- If a game ends in a draw with no human commanders, ScoringMixin.lua throws an
-- absolute fit. Abort out of the function before this can happen.

function ScoringMixin:SetCommanderExitTime(teamNumber, time)
  if #self.weightedCommanderTimes[teamNumber] == 0 then
    return false
  end

  local i = #self.weightedCommanderTimes[teamNumber]
  repeat
    if self.weightedCommanderTimes[teamNumber][i].exit == -1 then
      self.weightedCommanderTimes[teamNumber][i].exit = time
      return true
    end
    i = i - 1
  until i < 1

  return false
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
