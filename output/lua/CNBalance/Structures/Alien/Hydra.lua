
function Hydra:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, ClogFallMixin)
    InitMixin(self, DigestMixin)
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin, { kPlayFlinchAnimations = true })
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, TeleportMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, CatalystMixin)
    -- InitMixin(self, SoftTargetMixin)
    InitMixin(self, BiomassHealthMixin)
    
    self.alerting = false
    self.attacking = false
    self.hydraParentId = Entity.invalidId
    self.variant = kDefaultHydraVariant
    
    if Server then
        InitMixin(self, InfestationTrackerMixin)

        self:SetUpdates(true, kDefaultUpdateRate)
    end

end