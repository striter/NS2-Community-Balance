class "ProwlerHallucination" (Prowler)
ProwlerHallucination.kMapName = "prowlerHallucination"

function ProwlerHallucination:OnCreate()
    Prowler.OnCreate(self)
    self.isHallucination = true

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
    end
end

function ProwlerHallucination:GetClassNameOverride()
    return "Prowler"
end

function ProwlerHallucination:GetMapBlipType()
    return kMinimapBlipType.Drifter
end

Shared.LinkClassToMap("ProwlerHallucination", ProwlerHallucination.kMapName, {})