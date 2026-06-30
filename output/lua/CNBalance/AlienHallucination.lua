class "ProwlerHallucination" (Prowler)
ProwlerHallucination.kMapName = "prowlerHallucination"

function ProwlerHallucination:OnCreate()
    Prowler.OnCreate(self)
    self.isHallucination = true

    -- InitializePersonality (local in vanilla AlienHallucination.lua, not accessible from post hook)
    self.aimAbility = 0
    self.helpAbility = 0
    self.aggroAbility = 0
    self.sneakyAbility = 0
    self.personalityLabel = "Hallucination"

    InitMixin(self, SoftTargetMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })

    if Server then
        InitMixin(self, PlayerHallucinationMixin)
    end
end

function ProwlerHallucination:SetEmulation(player)
    self:SetName(player:GetName())
    self:SetHallucinatedClientIndex(player:GetClientIndex())

    if player:isa("Alien") and player.GetVariant then
        self:SetVariant(player:GetVariant())
        self:ForceUpdateModel()
    end
end

function ProwlerHallucination:GetClassNameOverride()
    return "Prowler"
end

function ProwlerHallucination:GetMapBlipType()
    return kMinimapBlipType.Prowler
end

Shared.LinkClassToMap("ProwlerHallucination", ProwlerHallucination.kMapName, {})

-- Player hallucinations inherit from player classes which use RagdollMixin.
-- RagdollMixin:GetDestroyOnKill returns self.ragdollCreated, which is only set
-- when GetHasClientModel() returns true (i.e. limitedModel). Player-type
-- entities use full ModelMixin where limitedModel is false, so ragdollCreated
-- stays nil and GetDestroyOnKill returns falsy. LiveMixin:Kill then skips
-- DestroyEntity, leaving dead hallucination entities lingering in the world
-- (including attached visuals like Onos bone shield material).
-- Override GetDestroyOnKill for all hallucination classes so they are
-- destroyed immediately when killed, matching ScriptActor-type Hallucination.
if Server then

    local function HallucinationGetDestroyOnKill()
        return true
    end

    SkulkHallucination.GetDestroyOnKill = HallucinationGetDestroyOnKill
    GorgeHallucination.GetDestroyOnKill = HallucinationGetDestroyOnKill
    LerkHallucination.GetDestroyOnKill = HallucinationGetDestroyOnKill
    FadeHallucination.GetDestroyOnKill = HallucinationGetDestroyOnKill
    OnosHallucination.GetDestroyOnKill = HallucinationGetDestroyOnKill
    ProwlerHallucination.GetDestroyOnKill = HallucinationGetDestroyOnKill

end