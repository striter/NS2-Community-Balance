Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/Bishop/marine/Fireteam.lua")
Script.Load("lua/bishop/marine/MarineTeamSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local Shared_GetTime = Shared.GetTime

local CleanFireteams = Bishop.marine.fireteam.CleanFireteams

--------------------------------------------------------------------------------
-- Balance values.
--------------------------------------------------------------------------------

local kFireteamCleanInterval = 5

--------------------------------------------------------------------------------
-- Initialize required variables.
--------------------------------------------------------------------------------

local function BishopMarineTeamBrainInit(self)
  self.fireteams = {}
  self.nextFireteamCleanTime = kFireteamCleanInterval

  self.offensivePhaseGateTime = 0
end

Shine.Hook.SetupClassHook("MarineTeamBrain", "Initialize",
  "BishopMarineTeamBrainInitialize", "PassivePost")
Shine.Hook.Add("BishopMarineTeamBrainInitialize", "BishopMBTIHook",
  BishopMarineTeamBrainInit)

---@param senses BrainSenses
function MarineTeamBrain:PopulateTeamSenses(senses)
  Bishop.marine.PopulateTeamSenses(senses)
end

local function MarineTeamBrain_Update(self)
  if Shared_GetTime() > self.nextFireteamCleanTime then
    self.nextFireteamCleanTime = self.nextFireteamCleanTime
      + kFireteamCleanInterval
    CleanFireteams(self)
  end
end

Shine.Hook.SetupClassHook("MarineTeamBrain", "Update",
  "BishopMarineTeamBrainUpdate", "PassivePost")
Shine.Hook.Add("BishopMarineTeamBrainUpdate", "BishopMTBUHook",
  MarineTeamBrain_Update)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
