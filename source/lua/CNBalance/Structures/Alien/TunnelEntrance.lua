-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\TunnelEntrance.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Entrance to a gorge tunnel. A "GorgeTunnel" entity is created once both entrances are completed.
--    In case both tunnel entrances are destroyed, the tunnel will collapse.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/AlienTunnelVariantMixin.lua")

Script.Load("lua/Tunnel.lua")

---@class \TunnelEntrance : ScriptActor
class 'TunnelEntrance' (ScriptActor)

TunnelEntrance.kMapName = "tunnelentrance"

TunnelEntrance.kModelName = PrecacheAsset("models/alien/tunnel/mouth.model")
TunnelEntrance.kModelNameShadow = PrecacheAsset("models/alien/tunnel/mouth_shadow.model")
local kAnimationGraph = PrecacheAsset("models/alien/tunnel/mouth.animation_graph")

local kSwallowAnimationLength = Shared.GetAnimationLength(TunnelEntrance.kModelName, "swallow")
local kClogEatTime = kSwallowAnimationLength * 0.55
local kClogEatRadius = 1.5
local kClogEatRadiusSq = kClogEatRadius * kClogEatRadius
local kClogEatHeight = 2.5
local kClogSearchRadius = Vector(kClogEatRadius, kClogEatHeight, 0):GetLength()

local kUpdateDestructionInterval = 1.0

local networkVars =
{
    otherEntranceId = "entityid",
    tunnelId = "entityid",
    open = "boolean",
    beingUsed = "boolean",
    timeLastExited = "time",
    destLocationId = "entityid",
    clogNearMouth = "boolean",
    skipOpenAnimation = "boolean",
    --timeResearchStarted is used to synchronize the two sides of the tunnels and their research state.
    timeResearchStarted = "time",
    --variant = "enum kAlienTunnelVariants"
    camouflaged = "boolean",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(CatalystMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(AlienTunnelVariantMixin, networkVars)

function TunnelEntrance:OnCreate()

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
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, InfestationMixin)

    if Server then

        InitMixin(self, InfestationTrackerMixin)
        self.open = false
        self.tunnelId = Entity.invalidId
        self.lastAutoBuildTime = 0
        self.isPlayingConnectedEffects = false

    elseif Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

    self.timeLastInteraction = 0
    self.timeLastExited = 0
    self.destLocationId = Entity.invalidId
    self.otherEntranceId = Entity.invalidId
    self.clogNearMouth = false
    self.timeResearchStarted = 0

end

function TunnelEntrance:OnInitialized()

    ScriptActor.OnInitialized(self)

    if Server then

        InitMixin(self, StaticTargetMixin)
        InitMixin(self, SleeperMixin)

        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        self.onNormalInfestation = false

    elseif Client then

        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)

    end

    self.skipOpenAnimation = true

    InitMixin(self, AlienTunnelVariantMixin)

end

function TunnelEntrance:OnResearchComplete(techId)

    local success = false

    if techId == kTechId.UpgradeToInfestedTunnel then
        self:UpgradeToTechId(kTechId.InfestedTunnel)
        self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
    end

    return success

end

function TunnelEntrance:OnMaturityComplete()

    self:UpgradeToTechId(kTechId.InfestedTunnel)
    self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())

end

function TunnelEntrance:GetTunnelTimeResearchStarted()
    return self.timeResearchStarted
end

function TunnelEntrance:OnResearch(researchId)

    --The InfestedTunnel research has started. Let's track this event and tell our other tunnel to do the same (if the other
    -- tunnel wasn't the one to already tell us first! The timeResearchStarted variable keeps us from stackOverflowing each
    -- tunnel telling the other back and forth to start research.
    if researchId == kTechId.UpgradeToInfestedTunnel then
        self.timeResearchStarted = Shared.GetTime()

        local otherEntrance = self:GetOtherEntrance()
        if otherEntrance and (otherEntrance:GetTunnelTimeResearchStarted() == 0) then
            otherEntrance:SetResearching(self:GetTeam():GetTechTree():GetTechNode(researchId), self:GetTeam():GetCommander())
        end
    end

end

function TunnelEntrance:OnResearchCancel(researchId)

    --The InfestedTunnel research has been cancelled. Let's track this event and tell our other tunnel to do the same (if the other
    -- tunnel wasn't the one to already tell us first! The timeResearchStarted variable keeps us from stackOverflowing each
    -- tunnel telling the other back and forth to start research.
    if researchId == kTechId.UpgradeToInfestedTunnel then
        self.timeResearchStarted = 0

        local otherEntrance = self:GetOtherEntrance()
        if otherEntrance and (otherEntrance:GetTunnelTimeResearchStarted() ~= 0) then
            otherEntrance:CancelResearch()
        end
    end

end

function TunnelEntrance:OnDestroy()

    ScriptActor.OnDestroy(self)

    if Client then

        Client.DestroyRenderDecal(self.decal)
        self.decal = nil

    end

end

function TunnelEntrance:SetVariant(tunnelVariant)

    if tunnelVariant == kAlienTunnelVariants.Shadow or tunnelVariant == kAlienTunnelVariants.Auric then
        self:SetModel(TunnelEntrance.kModelNameShadow, kAnimationGraph)
    else
        self:SetModel(TunnelEntrance.kModelName, kAnimationGraph)
    end

end

TunnelEntrance.kTunnelInfestationRadius = kInfestationRadius
function TunnelEntrance:GetInfestationRadius()
    return TunnelEntrance.kTunnelInfestationRadius
end

function TunnelEntrance:GetIsInfested()
    return self:GetTechId() == kTechId.InfestedTunnel
end

function TunnelEntrance:GetInfestationMaxRadius()
    if self:GetIsInfested() then
        return TunnelEntrance.kTunnelInfestationRadius
    end

    return 0
end

function TunnelEntrance:GetStartingHealthScalar()
    return kTunnelStartingHealthScalar
end

function TunnelEntrance:GetCanAutoBuild()
    return self:GetGameEffectMask(kGameEffect.OnInfestation)
end

function TunnelEntrance:GetReceivesStructuralDamage()
    return true
end

function TunnelEntrance:GetMaturityRate()
    return kTunnelEntranceMaturationTime
end

function TunnelEntrance:GetMatureMaxHealth()
    if self:GetIsInfested() then
        return kMatureInfestedTunnelEntranceHealth
    end

    return kMatureTunnelEntranceHealth
end

function TunnelEntrance:GetMatureMaxArmor()
    if self:GetIsInfested() then
        return kMatureInfestedTunnelEntranceArmor
    end

    return kMatureTunnelEntranceArmor
end

function TunnelEntrance:GetIsWallWalkingAllowed()
    return false
end

function TunnelEntrance:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function TunnelEntrance:GetCanSleep()
    return true
end

function TunnelEntrance:GetHasOtherEntrance()
    return self.otherEntranceId ~= Entity.invalidId
end

function TunnelEntrance:GetOtherEntrance()
    if self.otherEntranceId ~= Entity.invalidId then
        return Shared.GetEntity(self.otherEntranceId)
    end
    return nil
end

function TunnelEntrance:SetOtherEntrance(otherEntranceEnt)

    -- Convert the entity to an id (or to invalid id if nil).
    local otherEntranceId = Entity.invalidId
    if otherEntranceEnt then
        otherEntranceId = otherEntranceEnt:GetId()
    end

    -- Skip if the other entrance is already setup.
    if otherEntranceId == self.otherEntranceId then
        return
    end

    local prevOtherEntrance = Shared.GetEntity(self.otherEntranceId)

    self.otherEntranceId = otherEntranceId

    -- Disconnect previous other entrance from us.
    if prevOtherEntrance then
        prevOtherEntrance:SetOtherEntrance(nil)
    end

    -- Have the other entrance set its 'other' entrance to this entrance.
    if otherEntranceEnt then
        otherEntranceEnt:SetOtherEntrance(self)
    end

end

function TunnelEntrance:GetCanBuildOtherEnd()
    return not self:GetHasOtherEntrance() and not self:GetIsCollapsing() and self:GetIsAlive()
end

function TunnelEntrance:GetCanTriggerCollapse()
    return self:GetIsBuilt() and not self:GetIsCollapsing() and not self:GetIsResearching() and self:GetIsAlive()
end

function TunnelEntrance:GetCanRelocate()
    return self:GetHasOtherEntrance()  and not self:GetIsCollapsing() -- and self:GetIsBuilt()
end

function TunnelEntrance:GetCanUpgradeToInfestedTunnel()
    local otherEntrance = self:GetOtherEntrance()
    if (otherEntrance and otherEntrance:GetIsResearching()) or self:GetIsResearching() then
        return false
    end

    return self:GetTechId() ~= kTechId.InfestedTunnel
end

function TunnelEntrance:GetTechButtons()

    local buttons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                      kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    if self:GetCanBuildOtherEnd() then
        buttons[1] = kTechId.TunnelExit
    end

    if self:GetCanTriggerCollapse() then
        buttons[8] = kTechId.TunnelCollapse
    end

    if self:GetCanRelocate() then
        buttons[2] = kTechId.TunnelRelocate
    end

    --if self:GetCanUpgradeToInfestedTunnel() then
    --    buttons[3] = kTechId.UpgradeToInfestedTunnel
    --end

    return buttons
end

function TunnelEntrance:GetTechAllowed(techId)
    local allowed = true
    local teamNumber = self:GetTeamNumber()
    local teamInfo = GetTeamInfoEntity(teamNumber)
    local canAfford = teamInfo:GetTeamResources() >= GetCostForTech(techId)

    if techId == kTechId.TunnelExit then
        local numHives = teamInfo:GetNumCapturedTechPoints()
        local numTunnels = Tunnel.GetLivingTunnelCount(teamNumber)

        allowed = numHives > numTunnels
    elseif techId == kTechId.UpgradeToInfestedTunnel then
        allowed = self:GetCanUpgradeToInfestedTunnel() and GetIsUnitActive(self)
    end

    return allowed, canAfford
end

function TunnelEntrance:GetSendDeathMessageOverride(messageViewerTeam, killer)

    -- Hide the message if it killed itself (collapse)
    if messageViewerTeam and self == killer then

        if messageViewerTeam.GetTeamType and messageViewerTeam:GetTeamType() ~= self:GetTeamType() then
            return false
        end
    end

    return true
end

function TunnelEntrance:PerformActivation(techId)

    local success = false
    local keepProcessing = true

    if techId == kTechId.TunnelCollapse then

        -- TODO(Salads): Replace the current icon for consumed in inventory_icons with the one in buildmenu.
        if self:GetCanTriggerCollapse() then
            self.consumed = true
            self:Kill(self)
        end
    end

    return success, keepProcessing

end

function TunnelEntrance:GetIsCollapsing()

    local tunnel = self:GetTunnelEntity()
    if not tunnel then
        return false
    end

    return tunnel:GetIsCollapsing()

end

function TunnelEntrance:GetIsConnected()
    return self.open
end

function TunnelEntrance:Interact()

    self.beingUsed = true
    self.clientBeingUsed = true
    self.timeLastInteraction = Shared.GetTime()

end

function TunnelEntrance:GetTunnelEntity()
    if self.tunnelId and self.tunnelId ~= Entity.invalidId then
        return Shared.GetEntity(self.tunnelId)
    end
end

function TunnelEntrance:GetFlinchIntensityOverride()
    if self:GetIsCollapsing() then
        return 1.0
    else
        return self.flinchIntensity
    end
end

if Server then

    function TunnelEntrance:OnEntityChange(oldId, newId)

        -- If the other entrance is destroyed, just remove it here.  Normally it would be removed
        -- when the entrance is killed, but it could be destroyed before being killed due to a
        -- round reset, for example.
        if self.otherEntranceId ~= Entity.invalidId and self.otherEntranceId == oldId then
            self.otherEntranceId = Entity.invalidId
        end

        -- The only reason the tunnel can be destroyed without this knowing about it first is due
        -- to a round reset.
        if self.tunnelId ~= Entity.invalidId and self.tunnelId == oldId then
            self.tunnelId = Entity.invalidId
        end

    end

    local function ComputeDestinationLocationId(self)

        local destLocationId = Entity.invalidId

        if self.open then

            local oppositeExit = self:GetOtherEntrance()
            if oppositeExit then
                local location = GetLocationForPoint(oppositeExit:GetOrigin())
                if location then
                    destLocationId = location:GetId()
                end
            end

        end

        return destLocationId

    end

    function TunnelEntrance:CheckForClogs()

        local clogs = GetEntitiesWithinRange("Clog", self:GetOrigin(), kClogSearchRadius)
        for i = 1, #clogs do
            if clogs[i] then
                local diff = self:GetOrigin() - clogs[i]:GetOrigin()
                if math.abs(diff.y) <= kClogEatHeight and Vector(diff.x, 0, diff.z):GetLengthSquared() < kClogEatRadiusSq then
                    return true
                end
            end
        end

        return false

    end

    function TunnelEntrance:UpdateConnectionEffects()
        local isConnected = self:GetIsConnected()
        if isConnected and not self.isPlayingConnectedEffects then
            self.isPlayingConnectedEffects = true
            self:TriggerEffects("tunnel_ambient")
        elseif self.isPlayingConnectedEffects and not isConnected then
            self:TriggerEffects("tunnel_ambient_stop")
        end
    end

    function TunnelEntrance:OnUpdate(deltaTime)

        ScriptActor.OnUpdate(self, deltaTime)

        local otherEntrance = self:GetOtherEntrance()
        self.open = otherEntrance and otherEntrance:GetIsBuilt() and not self:GetIsCollapsing()
        self.beingUsed = self.timeLastInteraction + 0.1 > Shared.GetTime()
        self.destLocationId = ComputeDestinationLocationId(self)

        self:UpdateConnectionEffects()

        -- temp fix: push AI units away to prevent players getting stuck
        if self:GetIsAlive() and ( not self.timeLastAIPushUpdate or self.timeLastAIPushUpdate + 1.4 < Shared.GetTime() ) then

            local baseYaw = 0
            self.timeLastAIPushUpdate = Shared.GetTime()

            for _, entity in ipairs(GetEntitiesWithMixinWithinRange("Repositioning", self:GetOrigin(), 1.4)) do

                if entity:GetCanReposition() then

                    entity.isRepositioning = true
                    entity.timeLeftForReposition = 1

                    baseYaw = entity:FindBetterPosition( GetYawFromVector(entity:GetOrigin() - self:GetOrigin()), baseYaw, 0 )

                    if entity.RemoveFromMesh ~= nil then
                        entity:RemoveFromMesh()
                    end

                end

            end

        end

        if self:CheckForClogs() then
            self.clogNearMouth = true
        end

    end

    function TunnelEntrance:GetDestroyOnKill()
        return false
    end

    -- Sets the Tunnel entity that this TunnelEntrance leads to.  Also handles informing the Tunnel entity.
    function TunnelEntrance:SetTunnel(tunnel)

        -- Get the id of the tunnel, or invalidId if nil.  Also validate the input (only accepts Tunnel or nil).
        local id
        if tunnel then
            assert(type(tunnel) == "userdata")
            assert(tunnel:isa("Tunnel"))
            id = tunnel:GetId()
        else
            assert(tunnel == nil)
            id = Entity.invalidId
        end

        -- Skip if the id is already set to this.
        if id == self.tunnelId then
            return
        end

        local prevTunnel = Shared.GetEntity(self.tunnelId)

        self.tunnelId = id

        if prevTunnel then
            prevTunnel:RemoveExit(self)
        end

        if tunnel then
            tunnel:AddExit(self)
        end

    end

    function TunnelEntrance:OnConstructionComplete()

        -- Just finished construction, so open animation should play (if it is open).  This is to prevent the open
        -- animation from playing when the tunnel comes into view.
        self.skipOpenAnimation = false

        -- If the tunnel entrance has another (completed) tunnel entrance, ensure a tunnel connects the two together.
        local otherEntrance = self:GetOtherEntrance()

        -- If the other side started the infestation research before this side finished building, we want to set our progress to match.
        if otherEntrance and otherEntrance:GetIsResearching() then
            self.researchProgress = otherEntrance.researchProgress
        end

        if otherEntrance and otherEntrance:GetIsBuilt() then

            assert(self:GetTunnelEntity() == nil) -- this TunnelEntrance should not already have a tunnel assigned to it.

            -- See if the other entrance already has a tunnel assigned to it (eg this is a relocate).
            local tunnel = otherEntrance:GetTunnelEntity()
            if not tunnel then

                -- Create a new tunnel since neither of the two entrances had one.
                tunnel = CreateEntity(Tunnel.kMapName, nil, self:GetTeamNumber())
                otherEntrance:SetTunnel(tunnel)

            end

            self:SetTunnel(tunnel)

        end

    end

    function TunnelEntrance:UpdateDestruction()

        local destructionAllowed = {allowed=true}
        self:GetDestructionAllowed(destructionAllowed)
        destructionAllowed = destructionAllowed.allowed

        if destructionAllowed then
            DestroyEntity(self)
            return false -- don't renew this check.
        else
            return true -- repeat this check again some time in the future
        end

    end

    function TunnelEntrance:OnKill(attacker, doer, point, direction)

        ScriptActor.OnKill(self, attacker, doer, point, direction)

        self:TriggerEffects("death")

        self:TriggerEffects("tunnel_ambient_stop")

        self:SetModel(nil)

        local team = self:GetTeam()
        if team then
            team:UpdateClientOwnedStructures(self:GetId())
        end

        -- Tell the other entrance we've died.
        self:SetOtherEntrance(nil)

        -- If a tunnel is killed (and it wasn't due to a relocation command), the tunnel begins to destabilize and
        -- eventually collapse.
        local tunnel = self:GetTunnelEntity()
        if tunnel and not self.killWithoutCollapse then
            tunnel:BeginCollapse()
        end

        -- Disconnect from the tunnel
        self:SetTunnel(nil)

        -- We need to wait for infestation to recede before we can actually destroy
        -- the entity.
        self:AddTimedCallback(TunnelEntrance.UpdateDestruction, kUpdateDestructionInterval)

        NotifyAlienBotCommanderOfTunnelDeath(self)

    end

    function TunnelEntrance:KillWithoutCollapse()

        GetTeamBrain(kTeam2Index):RemoveTunnelQueue(self:GetId())   --FIXME-BOT This will error if for any reason teamBrain is nil

        self.killWithoutCollapse = true
        self:Kill()

    end

end

function TunnelEntrance:GetHealthbarOffset()
    return 1
end

function TunnelEntrance:GetCanBeUsed(_, useSuccessTable)
    useSuccessTable.useSuccess = false
end


function TunnelEntrance:GetCanBeUsedConstructed()
    return false
end

function TunnelEntrance:OnConstruct(builder)
    if Server then

        local time = Shared.GetTime()
        local playSound = builder or self.lastAutoBuildTime + 3 < time

        if playSound then
            self.lastAutoBuildTime = time
            self:TriggerEffects("tunnel_building_pulse", {effecthostcoords = self:GetCoords()})
        end
    end
end

if Server then

    function TunnelEntrance:SuckinEntity(entity)

        if entity and HasMixin(entity, "TunnelUser") then

            local tunnelEntity = self:GetTunnelEntity()
            if tunnelEntity then

                -- Notify LOS mixin of the impending move (to prevent enemies scouted by this
                -- player from getting stuck scouted).
                if HasMixin(entity, "LOS") then
                    entity:MarkNearbyDirtyImmediately()
                end

                tunnelEntity:MovePlayerToTunnel(entity, self)
                entity:SetVelocity(Vector(0, 0, 0))

                if entity.OnUseGorgeTunnel then
                    entity:OnUseGorgeTunnel()
                end

            end

        end

    end

    function TunnelEntrance:OnEntityExited(entity)
        self.timeLastExited = Shared.GetTime()
        self:TriggerEffects("tunnel_exit_3D")
    end

end

function TunnelEntrance:OnUpdateAnimationInput(modelMixin)

    local sucking = self.beingUsed or (self.clientBeingUsed and self.timeLastInteraction and self.timeLastInteraction + 0.1 > Shared.GetTime())
    -- sucking will be nil when self.clientBeingUsed is nil. Handle this case here.
    sucking = sucking or false

    modelMixin:SetAnimationInput("open", self.open)
    modelMixin:SetAnimationInput("player_in", sucking)
    modelMixin:SetAnimationInput("player_out", self.timeLastExited + 0.2 > Shared.GetTime())
    modelMixin:SetAnimationInput("eat_clogs", self.clogNearMouth)
    modelMixin:SetAnimationInput("skip_open", self.skipOpenAnimation)

end

function TunnelEntrance:EatAClog()

    -- find the closest clog to tunnel origin, within the cylinder defined.
    local clogs = GetEntitiesWithinRange("Clog", self:GetOrigin(), kClogSearchRadius)
    local closest, closestDist
    for i=1, #clogs do
        if clogs[i] then
            local diff = self:GetOrigin() - clogs[i]:GetOrigin()
            if math.abs(diff.y) <= kClogEatHeight and Vector(diff.x, 0, diff.z):GetLengthSquared() < kClogEatRadiusSq then
                local distSq = diff:GetLengthSquared()
                if (closest == nil) or distSq < closestDist then
                    closest = clogs[i]
                    closestDist = distSq
                end
            end
        end
    end

    if closest then
        closest:Kill()
    end

    self.clogNearMouth = false

    return false

end

if Server then
    function TunnelEntrance:OnTag(tagName)

        if tagName == "eat_clog_start" then
            self:AddTimedCallback(TunnelEntrance.EatAClog, kClogEatTime)
        elseif tagName == "opened" then
            self.skipOpenAnimation = false
        end

    end
end

function TunnelEntrance:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.25, 0)
end

function TunnelEntrance:OnUpdateRender()

    local showDecal = self:GetIsVisible() and not self:GetIsCloaked() and self:GetIsAlive()

    if not self.decal and showDecal then
        self.decal = CreateSimpleInfestationDecal(1.9, self:GetCoords())
    elseif self.decal and not showDecal then
        Client.DestroyRenderDecal(self.decal)
        self.decal = nil
    end

end


function TunnelEntrance:GetDestinationLocationName()

    local location = Shared.GetEntity(self.destLocationId)
    if location then
        return location:GetName()
    end

end

function TunnelEntrance:OverrideHintString( hintString, forEntity )

    if not GetAreEnemies(self, forEntity) then
        local locationName = self:GetDestinationLocationName()
        if locationName and locationName~="" then
            return string.format(Locale.ResolveString( "TUNNEL_ENTRANCE_HINT_TO_LOCATION" ), locationName )
        end
    end

    return hintString

end

Shared.LinkClassToMap("TunnelEntrance", TunnelEntrance.kMapName, networkVars)




--Post Starts here

-- Infestation
local oldConstructionComplete=TunnelEntrance.OnConstructionComplete
local kBeginInfestationRadius=2
function TunnelEntrance:OnConstructionComplete()
    oldConstructionComplete(self)
    self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
end

function TunnelEntrance:GetInfestationMaxRadius()
    if self:GetIsInfested() then
        return TunnelEntrance.kTunnelInfestationRadius
    end

    return kBeginInfestationRadius
end

function TunnelEntrance:OnMaturityComplete()
    self:UpgradeToTechId(kTechId.InfestedTunnel)
    self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
end

function TunnelEntrance:OnResearchComplete(techId)

    local success = false

    if techId == kTechId.UpgradeToInfestedTunnel then
        self:UpgradeToTechId(kTechId.InfestedTunnel)
        self:SetDesiredInfestationRadius(self:GetInfestationMaxRadius())
    end

    return success
end
--


local baseOnUpdate = TunnelEntrance.OnUpdate
function TunnelEntrance:OnUpdate(deltaTime)
    baseOnUpdate(self,deltaTime)
    if Server then
        self.hasShiftUpgrade = GetHasTech(self,kTechId.ShiftTunnel)
        self.hasShadeUpgrade = GetHasTech(self,kTechId.ShadeTunnel)
        self.camouflaged = self.hasShadeUpgrade and not self:GetIsInCombat()
    end
end

function TunnelEntrance:GetIsCamouflaged()
    return self.camouflaged
end

function TunnelEntrance:GetCloakInfestation()
    return self.camouflaged
end

--Armor 
function TunnelEntrance:GetMatureMaxArmor()
    local hasCragUpgrade = GetHasTech(self,kTechId.CragTunnel)
    if self:GetIsInfested() then
        return hasCragUpgrade and kMatureCragInfestedTunnelEntranceArmor or kMatureInfestedTunnelEntranceArmor
    end

    return hasCragUpgrade and kMatureCragTunnelEntranceArmor or kMatureTunnelEntranceArmor
end


--Function to treat as hive
function TunnelEntrance:GetCystParentRange()
    return kHiveCystParentRange
end

if Server then
    function TunnelEntrance:GetDistanceToHive()
        return 0
    end

    function TunnelEntrance:AddChildCyst(child)
        
    end

    function TunnelEntrance:GetIsActuallyConnected()
        return true
    end
end
---