Script.Load("lua/bishop/alien/AlienSharedSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local OldCreateFadeBrainSenses = CreateFadeBrainSenses

--------------------------------------------------------------------------------
-- Apply shared functions to the sense DB.
--------------------------------------------------------------------------------

function CreateFadeBrainSenses()
  local senses = OldCreateFadeBrainSenses()
  Bishop.alien.PopulateSharedSenses(senses)
  return senses
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
