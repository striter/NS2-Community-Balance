Script.Load("lua/bishop/marine/MarineSharedSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Apply shared and marine functions to the sense DB.
--------------------------------------------------------------------------------

local OldCreateExoBrainSenses = CreateExoBrainsSenses

function CreateExoBrainsSenses()
  local senses = OldCreateExoBrainSenses()

  Bishop.marine.PopulateSharedSenses(senses)

  return senses
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
