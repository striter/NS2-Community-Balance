Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Initialize variables required by railgun Exo objectives.
--------------------------------------------------------------------------------

local function RailgunBrain_Init(self)
  self.nextSecureResourcesTime = 0
  self.nextSecureTechPointTime = 0
end

Shine.Hook.SetupClassHook("RailgunBrain", "Initialize",
  "BishopRailgunBrainInitialize", "PassivePost")
Shine.Hook.Add("BishopRailgunBrainInitialize", "BishopRGBIHook",
  RailgunBrain_Init)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
