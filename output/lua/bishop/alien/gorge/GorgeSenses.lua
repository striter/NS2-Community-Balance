Script.Load("lua/bishop/alien/AlienSharedSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Apply shared functions to the sense DB.
--------------------------------------------------------------------------------

local OldCreateGorgeBrainSenses = CreateGorgeBrainSenses

function CreateGorgeBrainSenses()
  local senses = OldCreateGorgeBrainSenses()
  Bishop.alien.PopulateSharedSenses(senses)
  return senses
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
