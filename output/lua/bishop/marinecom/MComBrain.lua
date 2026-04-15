Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class MarineCommanderBrain : CommanderBrain
---@field lastMedPackTime number
---@field medpackRequests SupportRequest[]

local function BishopMarineCommanderBrainInit(self)
  self.lastAmmoPackTime = 0
  self.lastMedPackTime = 0
  self.nextMoveOrderTime = 0
  self.nextTunnelScanTime = 0

  self.medpackRequests = {} ---@type SupportRequest[]

  -- TODO: Move out of here and remove hardcoded team.
  self:GetSenses():SetParentSenses(GetTeamBrain(kMarineTeamType):GetSenses())
end

Shine.Hook.SetupClassHook("MarineCommanderBrain", "Initialize",
  "BishopMarineCommanderBrainInitialize", "PassivePost")
Shine.Hook.Add("BishopMarineCommanderBrainInitialize", "BishopMCBIHook",
  BishopMarineCommanderBrainInit)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
