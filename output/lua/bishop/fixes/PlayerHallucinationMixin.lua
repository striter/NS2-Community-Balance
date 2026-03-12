Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Prevent all cases of Hallucinations sending chat messages.
--------------------------------------------------------------------------------

function PlayerHallucinationMixin:SendTeamMessage()
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
