Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local function BishopAlienCommanderBrainInit(self)
  self.droppedNaturalRts = true -- Temporary override for compatibility.
  self.lastCystBuildTime = 0
  self.lastHarvesterBuildTime = {}
  self.lastNonCombatHatchTime = -1000
  self.nextContaminateTime = 0
  self.nextOffensiveCystAttempt = 0

  -- TODO: Move out of here and remove hardcoded team.
  self:GetSenses():SetParentSenses(GetTeamBrain(kAlienTeamType):GetSenses())
end

Shine.Hook.SetupClassHook("AlienCommanderBrain", "Initialize",
  "BishopAlienCommanderBrainInitialize", "PassivePost")
Shine.Hook.Add("BishopAlienCommanderBrainInitialize", "BishopACBIHook",
  BishopAlienCommanderBrainInit)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
