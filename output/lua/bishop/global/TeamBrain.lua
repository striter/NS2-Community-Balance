Script.Load("lua/bots/BrainSenses.lua")

Script.Load("lua/bishop/BishopUtility.lua")
Script.Load("lua/bishop/global/GlobalSenses.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---@class TeamBrain
---@field packs AlienPack[]

---@return BrainSenses
function TeamBrain:GetSenses()
  if not self.teamSenses then
    self.teamSenses = BrainSenses()
    self.teamSenses:Initialize()
    self.teamSenses:SetParentSenses(Bishop.global.GetSenses())
    self.teamSenses:SetMaster()
    self.teamSenses:SetTeamNumber(self.teamNumber)
    self:PopulateTeamSenses(self.teamSenses)
  end

  return self.teamSenses
end

function TeamBrain:OnBeginFrame()
  if self.lastUpdate < Shared.GetTime() then
    self.teamSenses:OnBeginFrame()
    self:Update()
  end
end

--------------------------------------------------------------------------------
-- Allow marine bots to hear Hydra sounds.
--------------------------------------------------------------------------------
-- Marines have trouble spotting Hydras on walls or ceilings, so allow them to
-- hear instead.

local kAlienLifeformAttackSounds = 
{
  "sound/NS2.fev/alien/skulk/bite",
  "sound/NS2.fev/alien/skulk/bite_alt",
  "sound/NS2.fev/alien/common/xenocide_start",
  "sound/NS2.fev/alien/gorge/spit",
  "sound/NS2.fev/alien/gorge/bilebomb",
  "sound/NS2.fev/alien/gorge/healspray",
  "sound/NS2.fev/alien/gorge/create_structure_start",
  "sound/NS2.fev/alien/lerk/bite",
  "sound/NS2.fev/alien/lerk/spore_spray_once",
  "sound/NS2.fev/alien/lerk/spores_hit",
  "sound/NS2.fev/alien/lerk/spikes",
  "sound/NS2.fev/alien/lerk/hit",
  "sound/NS2.fev/alien/fade/swipe",
  "sound/NS2.fev/alien/fade/blink",
  "sound/NS2.fev/alien/fade/stab",
  "sound/NS2.fev/alien/fade/metabolize",
  "sound/NS2.fev/alien/onos/gore",
  "sound/NS2.fev/alien/onos/stomp",
  "sound/NS2.fev/alien/onos/charge_hit_marine",
  "sound/NS2.fev/alien/onos/charge_hit_exo",
  "sound/NS2.fev/alien/structures/hydra/idle",
  "sound/NS2.fev/alien/structures/hydra/attack"
}

Shine.SetUpValue(_G.TeamBrain.GetIsSoundAudible, "kAlienLifeformAttackSounds",
  kAlienLifeformAttackSounds)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
