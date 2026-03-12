Script.Load("lua/Entity.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/global/SharedTeamSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@param senses BrainSenses
function Bishop.alien.PopulateTeamSenses(senses)
  Bishop.global.PopulateSharedTeamSenses(senses)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
