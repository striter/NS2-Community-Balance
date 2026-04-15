Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Initialize Gorge variables used by Bishop.
--------------------------------------------------------------------------------

local function GorgeBrain_Initialize(self)
  self.hydraQueue = {}
  self.timeNextBileMineAttempt = 0
  self.timeNextHydraScan = 0
  self.timeNextWebAttempt = 0
end

Shine.Hook.SetupClassHook("GorgeBrain", "Initialize",
  "BishopGorgeBrainInitialize", "PassivePost")
Shine.Hook.Add("BishopGorgeBrainInitialize", "BishopGBIHook",
  GorgeBrain_Initialize)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
