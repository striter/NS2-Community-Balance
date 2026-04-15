Script.Load("lua/bishop/alien/AlienSharedSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Apply shared functions to the sense DB.
--------------------------------------------------------------------------------

local OldCreateOnosBrainSenses = CreateOnosBrainSenses

function CreateOnosBrainSenses()
  local senses = OldCreateOnosBrainSenses()
  Bishop.alien.PopulateSharedSenses(senses)
  return senses
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
