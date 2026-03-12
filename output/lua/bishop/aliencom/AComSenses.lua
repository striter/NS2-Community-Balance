Script.Load("lua/bishop/alien/AlienSharedSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local OldCreateAlienComSenses = CreateAlienComSenses

function CreateAlienComSenses()
  local senses = OldCreateAlienComSenses()
  Bishop.alien.PopulateSharedSenses(senses)

  return senses
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
