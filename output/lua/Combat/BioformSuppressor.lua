Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/SupplyUserMixin.lua")
Script.Load("lua/OwnerMixin.lua")

class 'BioformSuppressor' (ScriptActor)
BioformSuppressor.kMapName = "bioformsuppressor"
BioformSuppressor.kRange = kBioformSuppressRange
BioformSuppressor.kModelName = PrecacheAsset("models/marine/capture_point/cp_capturepoint_1.model")
local kAnimationGraph = PrecacheAsset("models/marine/capture_point/cp_capturepoint_1.animation_graph")
BioformSuppressor.kMutationCinematic = PrecacheAsset("cinematics/cp/cp_mutation.cinematic")
BioformSuppressor.kSteamCinematic = PrecacheAsset("cinematics/cp/capture_point_steam001.cinematic")

local networkVars =
{
    suppressing = "boolean",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(PowerConsumerMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function BioformSuppressor:OnCreate()

    ScriptActor.OnCreate(self)

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
    InitMixin(self, LOSMixin)
    InitMixin(self, CorrodeMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)

    if Client then

        InitMixin(self, CommanderGlowMixin)

    end

    if Server then
        InitMixin(self, OwnerMixin)
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

end

function BioformSuppressor:OnInitialized()

    ScriptActor.OnInitialized(self)

    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)

    if Server then

        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        InitMixin(self, SupplyUserMixin)
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, InfestationTrackerMixin)

    elseif Client then
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
    end

    self:SetModel(BioformSuppressor.kModelName, kAnimationGraph)

end

function BioformSuppressor:GetReceivesStructuralDamage()
    return true
end

function BioformSuppressor:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function BioformSuppressor:GetTechButtons(techId)

    local table = { kTechId.None,kTechId.None,kTechId.None, kTechId.None,
                    kTechId.None,kTechId.None,kTechId.None, kTechId.None,
                    kTechId.Cancel }      --Cancel at 9 to hide cancel button

    if not self.suppressing then
        table[1] = kTechId.BioformSuppressProtocol
    end
    
    return table

end

function BioformSuppressor:GetCanRecycle()
    return not self:GetIsBuilt()
end

function BioformSuppressor:GetIsSuppressing()
    return GetIsUnitActive(self) and self.suppressing
end

function BioformSuppressor:OnPowerOff()
    self.suppressing = false
end

function BioformSuppressor:OnResearchComplete(researchId)

    if researchId == kTechId.BioformSuppressProtocol then
        self.suppressing = true
    end

end

if Server then

    local kSuppressInterval = 2
    local kDamagePerInterval = 50
    function BioformSuppressor:OnUpdate()

        local now = Shared.GetTime()
        if self.timeNextSuppress and now < self.timeNextSuppress + kSuppressInterval then return end
        self.timeNextSuppress = now

        if GetIsUnitActive(self) then
            self:SetIsParasited(true)
            self:SetIsSighted(true)
        end
        
        if not self.suppressing then return end
        local electrifyMixin = GetEntitiesWithMixinForTeamWithinRange("Electrify", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), BioformSuppressor.kRange)
        for _, entity in pairs(electrifyMixin) do
            if not entity:isa("Player") then
                entity:SetElectrified(kSuppressInterval + 0.5)
                entity:TakeDamage(kDamagePerInterval, self, self, nil, nil, kDamagePerInterval, 0, kDamageType.Normal, true)
                if entity.SetIsSighted then
                    entity:SetIsSighted(true)
                end
            end
        end
        
    end
end

if Client then

    --function BioformSuppressor:OnTag(tagName)
    --
    --    PROFILE("BioformSuppressor:OnTag")
    --
    --
    --end
    

    function BioformSuppressor:OnUpdateAnimationInput(modelMixin)

        PROFILE("BioformSuppressor:OnUpdateAnimationInput")

        local active = GetIsUnitActive(self)
        local scalar = self:GetResearchingId() ~= kTechId.None and self:GetResearchProgress() * 100 or 0
        if self.suppressing then
            scalar = 100
        end
        
        modelMixin:SetAnimationInput("captureRate", active and scalar or -1)

    end
    
    function BioformSuppressor:OnUpdate()

        local active = GetIsUnitActive(self)
        if active then
            if not self.mutationCinematic then

                self.mutationCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
                self.mutationCinematic:SetCinematic(BioformSuppressor.kMutationCinematic)
                self.mutationCinematic:SetCoords(self:GetCoords())
                self.mutationCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)

            end
        else
            if self.mutationCinematic then
                Client.DestroyCinematic(self.mutationCinematic)
                self.mutationCinematic = nil
            end
        end
        
        if self:GetIsSuppressing() then
            if not self.steam1 then
                self.steam1 = Client.CreateCinematic(RenderScene.Zone_Default)
                self.steam1:SetCinematic(BioformSuppressor.kSteamCinematic)
                self.steam1:SetCoords(self:GetCoords())
                self.steam1:SetRepeatStyle(Cinematic.Repeat_Endless)
            end
        else
            if self.steam1 then
                Client.DestroyCinematic(self.steam1)
                self.steam1 = nil
            end
        end
        
    end

    function BioformSuppressor:OnDestroy()

        ScriptActor.OnDestroy(self)
        if self.mutationCinematic then
            Client.DestroyCinematic(self.mutationCinematic)
            self.mutationCinematic = nil
        end

        if self.steam1 then
            Client.DestroyCinematic(self.steam1)
            self.steam1 = nil
        end
    end
    
    function BioformSuppressor:OnUpdateRender()

    end

end


function BioformSuppressor:GetRequiresPower()
    return true
end

Shared.LinkClassToMap("BioformSuppressor", BioformSuppressor.kMapName, networkVars)
