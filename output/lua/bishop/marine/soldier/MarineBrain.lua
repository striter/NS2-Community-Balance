Script.Load("lua/TechTreeConstants.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class MarineBrain : PlayerBrain

local function MarineBrain_Init(self)
  self.nextSecureResourcesTime = 0
  self.nextSecureTechPointTime = 0
end

Shine.Hook.SetupClassHook("MarineBrain", "Initialize",
  "BishopMarineBrainInitialize", "PassivePost")
Shine.Hook.Add("BishopMarineBrainInitialize", "BishopMBIHook", MarineBrain_Init)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
