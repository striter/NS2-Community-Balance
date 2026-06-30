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
  self.nextOffensivePhaseGateValidateTime = 0
end

Shine.Hook.SetupClassHook("MarineTeamBrain", "Initialize",
  "BishopMarineTeamBrainInitialize", "PassivePost")
Shine.Hook.Add("BishopMarineTeamBrainInitialize", "BishopMBTIHook",
  BishopMarineTeamBrainInit)

---@param senses BrainSenses
function MarineTeamBrain:PopulateTeamSenses(senses)
  Bishop.marine.PopulateTeamSenses(senses)
end

local kOffensivePhaseGateValidateInterval = 1

local function ValidateOffensivePhaseGateId(self)
  local phaseGateId = self.offensivePhaseGateId
  if not phaseGateId then
    return
  end

  local phaseGate = Shared.GetEntity(phaseGateId)
  if not phaseGate or not phaseGate:isa("PhaseGate") or not phaseGate:GetIsAlive() then
    self.offensivePhaseGateId = nil
  end
end

local function MarineTeamBrain_Update(self)
  local time = Shared_GetTime()

  if time > self.nextOffensivePhaseGateValidateTime then
    self.nextOffensivePhaseGateValidateTime = time
      + kOffensivePhaseGateValidateInterval
    ValidateOffensivePhaseGateId(self)
  end

  if time > self.nextFireteamCleanTime then
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
