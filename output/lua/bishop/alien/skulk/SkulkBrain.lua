Script.Load("lua/NetworkMessages_Server.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/VoiceOver.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local CreateVoiceMessage = CreateVoiceMessage
local kTechId = kTechId
local kVoiceId = kVoiceId

--------------------------------------------------------------------------------
-- Initialize Bishop's Skulk variables on brain creation.
--------------------------------------------------------------------------------

local function SkulkBrain_Initialize(self)
  self.nextBunnyhopTime = 0
  self.nextLeapTime = 0
  self.nextVentJumpTime = 0
end

Shine.Hook.SetupClassHook("SkulkBrain", "Initialize", "BishopSkulkBrainInit",
  "PassivePost")
Shine.Hook.Add("BishopSkulkBrainInit", "BishopSBIHook", SkulkBrain_Initialize)

--------------------------------------------------------------------------------
-- Drop a Nutrient Mist request right before the Skulk brain is dumped.
--------------------------------------------------------------------------------
-- The brain is about to be deleted by PlayerBrain:Update() due to a lifeform
-- mismatch.

local function SkulkBrain_UpdatePre(self, bot)
  local skulk = bot:GetPlayer()
  self.hasMoved = false

  if skulk and skulk:isa("Embryo")
      and (skulk.gestationTypeTechId == kTechId.Onos
        or skulk.gestationTypeTechId == kTechId.Fade) then
    CreateVoiceMessage(skulk, kVoiceId.AlienRequestMist)
  end
end

Shine.Hook.SetupClassHook("SkulkBrain", "Update", "BishopSkulkBrainUpdatePre",
  "PassivePre")
Shine.Hook.Add("BishopSkulkBrainUpdatePre", "BishopSBUPHook",
  SkulkBrain_UpdatePre)

Bishop.debug.FileExit(debug.getinfo(1, "S"))
