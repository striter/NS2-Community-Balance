Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Initialize variables required by minigun Exo objectives.
--------------------------------------------------------------------------------

local function MinigunBrain_Init(self)
  self.nextSecureResourcesTime = 0
  self.nextSecureTechPointTime = 0
end

Shine.Hook.SetupClassHook("MinigunBrain", "Initialize",
  "BishopMinigunBrainInitialize", "PassivePost")
Shine.Hook.Add("BishopMinigunBrainInitialize", "BishopMGBIHook",
  MinigunBrain_Init)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
