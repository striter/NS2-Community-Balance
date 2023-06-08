-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\MAC.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- AI controllable flying robot marine commander can control. Used to build structures
-- and has other special abilities.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/Marine/EMPBlast.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/BuildingMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/MobileTargetMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/RepositioningMixin.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/SupplyUserMixin.lua")
Script.Load("lua/SoftTargetMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/WebableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/RolloutMixin.lua")
Script.Load("lua/MACVariantMixin.lua")

class 'MAC' (ScriptActor)

MAC.kMapName = "mac"

MAC.kModelName = PrecacheAsset("models/marine/mac/mac.model")
MAC.kAnimationGraph = PrecacheAsset("models/marine/mac/mac.animation_graph")

MAC.kConfirmSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/confirm")
MAC.kConfirm2DSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/confirm_2d")
MAC.kStartConstructionSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/constructing")
MAC.kStartConstruction2DSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/constructing_2d")
MAC.kStartWeldSound = PrecacheAsset("sound/NS2.fev/marine/structures/mac/weld_start")
MAC.kHelpingSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/help_build")
MAC.kPassbyMACSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/passby_mac")
MAC.kPassbyDrifterSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/passby_driffter")

MAC.kUsedSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/mac/use")

MAC.kElectrifiedThirdpersonMaterialName = "cinematics/vfx_materials/pulse_gre_elec.material"

local kJetsCinematic = PrecacheAsset("cinematics/marine/mac/jet.cinematic")
local kJetsSound = PrecacheAsset("sound/NS2.fev/marine/structures/mac/thrusters")

local kRightJetNode = "fxnode_jet1"
local kLeftJetNode = "fxnode_jet2"
MAC.kLightNode = "fxnode_light"
MAC.kWelderNode = "fxnode_welder"

-- Balance
MAC.kConstructRate = 0.4
MAC.kWeldRate = 0.5
MAC.kOrderScanRadius = 12
MAC.kRepairHealthPerSecond = 50
MAC.kHealth = kMACHealth
MAC.kArmor = kMACArmor
MAC.kMoveSpeed = 6
MAC.kHoverHeight = 0.5
MAC.kStartDistance = 3
MAC.kWeldDistance = 2
MAC.kBuildDistance = 2     -- Distance at which bot can start building a structure.
MAC.kSpeedUpgradePercent = (1 + kMACSpeedAmount)
-- how often we check to see if we are in a marines face when welding
-- Note: Need to be fairly long to allow it to weld marines with backs towards walls - the AI will
-- stop moving after a < 1 sec long interval, and the welding will be done in the time before it tries
-- to move behind their backs again
MAC.kWeldPositionCheckInterval = 1

-- how fast the MAC rolls out of the ARC factory. Standard speed is just too fast.
MAC.kRolloutSpeed = 2

MAC.kCapsuleHeight = 0.2
MAC.kCapsuleRadius = 0.5

-- Greetings
MAC.kGreetingUpdateInterval = 1
MAC.kGreetingInterval = 10
MAC.kGreetingDistance = 5
MAC.kUseTime = 2.0

MAC.kTurnSpeed = 3 * math.pi -- a mac is nimble
local networkVars =
{
    welding = "boolean",
    constructing = "boolean",
    moving = "boolean",
    empBlast = "boolean",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(WebableMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(MACVariantMixin, networkVars)

local function GetIsWeldedByOtherMAC(self, target)

    if target then

        for _, mac in ipairs(GetEntitiesForTeam("MAC", self:GetTeamNumber())) do

            if self ~= mac then

                if mac.secondaryTargetId ~= nil and Shared.GetEntity(mac.secondaryTargetId) == target then
                    return true
                end

                local currentOrder = mac:GetCurrentOrder()
                local orderTarget
                if currentOrder and currentOrder:GetParam() ~= nil then
                    orderTarget = Shared.GetEntity(currentOrder:GetParam())
                end

                if currentOrder and orderTarget == target and (currentOrder:GetType() == kTechId.FollowAndWeld or currentOrder:GetType() == kTechId.Weld or currentOrder:GetType() == kTechId.AutoWeld) then
                    return true
                end

            end

        end

    end

    return false

end

function MAC:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin, { kTriggeringEnabledDefault = true })
    InitMixin(self, ClientModelMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, BuildingMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin, { kPlayFlinchAnimations = true })
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, PathingMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, CorrodeMixin)
    --InitMixin(self, SoftTargetMixin)
    InitMixin(self, WebableMixin)
    InitMixin(self, ParasiteMixin)
    InitMixin(self, RolloutMixin)

    if Server then
        InitMixin(self, RepositioningMixin)
    elseif Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self:SetUpdates(true, kRealTimeUpdateRate)
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)

    self.empTriggeredTime = Shared.GetTime()
    self.empDetectionTime = Shared.GetTime()
end

function MAC:OnInitialized()

    ScriptActor.OnInitialized(self)

    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)

    if Server then

        self:UpdateIncludeRelevancyMask()

        InitMixin(self, SleeperMixin)
        InitMixin(self, MobileTargetMixin)
        InitMixin(self, SupplyUserMixin)
        InitMixin(self, InfestationTrackerMixin)

        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        self.jetsSound = Server.CreateEntity(SoundEffect.kMapName)
        self.jetsSound:SetAsset(kJetsSound)
        self.jetsSound:SetParent(self)

        self.leashedPosition = nil
        self.autoReturning = false

    elseif Client then

        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)

        -- Setup movement effects
        self.jetsCinematics = {}
        for index,attachPoint in ipairs({ kLeftJetNode, kRightJetNode }) do
            self.jetsCinematics[index] = Client.CreateCinematic(RenderScene.Zone_Default)
            self.jetsCinematics[index]:SetCinematic(kJetsCinematic)
            self.jetsCinematics[index]:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.jetsCinematics[index]:SetParent(self)
            self.jetsCinematics[index]:SetCoords(Coords.GetIdentity())
            self.jetsCinematics[index]:SetAttachPoint(self:GetAttachPointIndex(attachPoint))
            self.jetsCinematics[index]:SetIsActive(false)
        end

    end

    self.timeOfLastGreeting = 0
    self.timeOfLastGreetingCheck = 0
    self.timeOfLastChatterSound = 0
    self.timeOfLastWeld = 0
    self.timeOfLastConstruct = 0
    self.moving = false

    self:SetModel(MAC.kModelName, MAC.kAnimationGraph)

    InitMixin(self, IdleMixin)

    if not Predict then
        InitMixin(self, MACVariantMixin)
        self:ForceSkinUpdate()
    end

end

function MAC:OnEntityChange(oldId)

    if oldId == self.secondaryTargetId then

        self.secondaryOrderType = nil
        self.secondaryTargetId = nil

    end

end

local function GetAutomaticOrder(self)

    local target
    local orderType

    if self.timeOfLastFindSomethingTime == nil or Shared.GetTime() > self.timeOfLastFindSomethingTime + 1 then

        local currentOrder = self:GetCurrentOrder()
        local primaryTarget
        if currentOrder and currentOrder:GetType() == kTechId.FollowAndWeld then
            primaryTarget = Shared.GetEntity(currentOrder:GetParam())
        end

        if primaryTarget and (HasMixin(primaryTarget, "Weldable") and primaryTarget:GetWeldPercentage() < 1) and not primaryTarget:isa("MAC") then

            target = primaryTarget
            orderType = kTechId.AutoWeld

        else

            -- If there's a friendly entity nearby that needs constructing, constuct it.
            local constructables = GetEntitiesWithMixinForTeamWithinRange("Construct", self:GetTeamNumber(), self:GetOrigin(), MAC.kOrderScanRadius)
            for c = 1, #constructables do

                local constructable = constructables[c]
                if constructable:GetCanConstruct(self) then

                    target = constructable
                    orderType = kTechId.Construct
                    break

                end

            end

            if not target then

                -- Look for entities to heal with weld.
                local weldables = GetEntitiesWithMixinForTeamWithinRange("Weldable", self:GetTeamNumber(), self:GetOrigin(), MAC.kOrderScanRadius)
                for w = 1, #weldables do

                    local weldable = weldables[w]
                    -- There are cases where the weldable's weld percentage is very close to
                    -- 100% but not exactly 100%. This second check prevents the MAC from being so pedantic.
                    if weldable:GetCanBeWelded(self) and weldable:GetWeldPercentage() < 1 and not GetIsWeldedByOtherMAC(self, weldable) and not weldable:isa("MAC") then

                        target = weldable
                        orderType = kTechId.AutoWeld
                        break

                    end

                end

            end

        end

        self.timeOfLastFindSomethingTime = Shared.GetTime()

    end

    return target, orderType

end

function MAC:GetTurnSpeedOverride()
    return MAC.kTurnSpeed
end

function MAC:GetCanSleep()
    return self:GetCurrentOrder() == nil
end

function MAC:GetMinimumAwakeTime()
    return 5
end

function MAC:GetExtentsOverride()
    return Vector(MAC.kCapsuleRadius, MAC.kCapsuleHeight / 2, MAC.kCapsuleRadius)
end

function MAC:GetFov()
    return 360
end

function MAC:GetIsFlying()
    return true
end

function MAC:GetReceivesStructuralDamage()
    return true
end

function MAC:OnUse(player, elapsedTime, useSuccessTable)

    -- Play flavor sounds when using MAC.
    if Server then

        local time = Shared.GetTime()

        if self.timeOfLastUse == nil or (time > (self.timeOfLastUse + MAC.kUseTime)) then

            if player:isa("Marine") and player.variant and table.icontains( kRoboticMarineVariantIds, player.variant) then
                --MACs either don't like or don't recognize their larger kin...picky little buggers, aren't they.
                Server.PlayPrivateSound(player, MAC.kPassbyDrifterSoundName, self, 1.0, Vector(0, 0, 0))
            else
                Server.PlayPrivateSound(player, MAC.kUsedSoundName, self, 1.0, Vector(0, 0, 0))
            end

            self.timeOfLastUse = time

        end

    end

end

-- avoid the MAC hovering inside (as that shows the MAC through the factory top)
function MAC:GetHoverHeight()
    if self.rolloutSourceFactory then
        -- keep it low until it leaves the factory, then go back to normal hover height
        local h = MAC.kHoverHeight * (1.1 - self.cursor:GetRemainingDistance()) / 1.1
        return math.max(0, h)
    end
    return MAC.kHoverHeight
end

function MAC:OnOverrideOrder(order)

    local orderTarget
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end

    local isSelfOrder = orderTarget == self

    -- Default orders to unbuilt friendly structures should be construct orders
    if order:GetType() == kTechId.Default and GetOrderTargetIsConstructTarget(order, self:GetTeamNumber()) and not isSelfOrder then

        order:SetType(kTechId.Construct)

    elseif order:GetType() == kTechId.Default and orderTarget and orderTarget:isa("PowerPoint") and orderTarget:GetIsDisabled() then
        order:SetType(kTechId.Weld)

    elseif order:GetType() == kTechId.Default and GetOrderTargetIsWeldTarget(order, self:GetTeamNumber()) and not isSelfOrder and not GetIsWeldedByOtherMAC(self, orderTarget) then

        order:SetType(kTechId.FollowAndWeld)

    elseif (order:GetType() == kTechId.Default or order:GetType() == kTechId.Move) then

        -- Convert default order (right-click) to move order
        order:SetType(kTechId.Move)

    end

    if GetAreEnemies(self, orderTarget) then
        order.orderParam = -1
    end

end

function MAC:GetIsOrderHelpingOtherMAC(order)

    if order:GetType() == kTechId.Construct then

        -- Look for friendly nearby MACs
        local macs = GetEntitiesForTeamWithinRange("MAC", self:GetTeamNumber(), self:GetOrigin(), 3)
        for index, mac in ipairs(macs) do

            if mac ~= self then

                local otherMacOrder = mac:GetCurrentOrder()
                if otherMacOrder ~= nil and otherMacOrder:GetType() == order:GetType() and otherMacOrder:GetParam() == order:GetParam() then
                    return true
                end

            end

        end

    end

    return false

end

function MAC:OnOrderChanged()

    local order = self:GetCurrentOrder()

    if order then

        local owner = self:GetOwner()

        if not owner then
            local commanders = GetEntitiesForTeam("Commander", self:GetTeamNumber())
            if commanders and commanders[1] then
                owner = commanders[1]
            end
        end

        local currentComm = commanders and commanders[1] or nil

        -- Look for nearby MAC doing the same thing
        if self:GetIsOrderHelpingOtherMAC(order) then
            self:PlayChatSound(MAC.kHelpingSoundName)
            self.lastOrderLocation = order:GetLocation()
        elseif order:GetType() == kTechId.Construct then

            self:PlayChatSound(MAC.kStartConstructionSoundName)

            if currentComm then
                Server.PlayPrivateSound(currentComm, MAC.kStartConstruction2DSoundName, currentComm, 1.0, Vector(0, 0, 0))
            end
            self.lastOrderLocation = order:GetLocation()

        elseif order:GetType() == kTechId.Weld or order:GetType() == kTechId.AutoWeld then

            if order:GetLocation() ~= self.lastOrderLocation or self.lastOrderLocation == nil then

                self:PlayChatSound(MAC.kStartWeldSound)

                if currentComm then
                    Server.PlayPrivateSound(currentComm, MAC.kStartWeldSound, currentComm, 1.0, Vector(0, 0, 0))
                end

                self.lastOrderLocation = order:GetLocation()

            end

        else

            self:PlayChatSound(MAC.kConfirmSoundName)

            if currentComm then
                Server.PlayPrivateSound(currentComm, MAC.kConfirm2DSoundName, currentComm, 1.0, Vector(0, 0, 0))
            end

            self.lastOrderLocation = order:GetLocation()

        end

    end

end

function MAC:GetMoveSpeed()

    local maxSpeedTable = { maxSpeed = MAC.kMoveSpeed }
    if self.rolloutSourceFactory then
        maxSpeedTable.maxSpeed = MAC.kRolloutSpeed
    end
    self:ModifyMaxSpeed(maxSpeedTable)

    return maxSpeedTable.maxSpeed

end

local function GetBackPosition(self, target)

    if not target:isa("Player") then
        return None
    end

    local coords = target:GetViewAngles():GetCoords()
    local targetViewAxis = coords.zAxis
    targetViewAxis.y = 0 -- keep it 2D
    targetViewAxis:Normalize()
    local fromTarget = self:GetOrigin() - target:GetOrigin()
    local targetDist = fromTarget:GetLengthXZ()
    fromTarget.y = 0
    fromTarget:Normalize()

    local weldPos = None
    local dot = targetViewAxis:DotProduct(fromTarget)
    -- if we are in front or not sufficiently away from the target, we calculate a new weldPos
    if dot > 0.866 or targetDist < MAC.kWeldDistance - 0.5 then
        -- we are in front, find out back positon
        local obstacleSize = 0
        if HasMixin(target, "Extents") then
            obstacleSize = target:GetExtents():GetLengthXZ()
        end
        -- we do not want to go straight through the player, instead we move behind and to the
        -- left or right
        local targetPos = target:GetOrigin()
        local toMidPos = targetViewAxis * (obstacleSize + MAC.kWeldDistance - 0.1)
        local midWeldPos = targetPos - targetViewAxis * (obstacleSize + MAC.kWeldDistance - 0.4)
        local leftV = Vector(-targetViewAxis.z, targetViewAxis.y, targetViewAxis.x)
        local rightV = Vector(targetViewAxis.z, targetViewAxis.y, -targetViewAxis.x)
        local leftWeldPos = midWeldPos + leftV * 2
        local rightWeldPos = midWeldPos + rightV * 2
        --[[
        DebugBox(leftWeldPos+Vector(0,1,0),leftWeldPos+Vector(0,1,0),Vector(0.1,0.1,0.1), 5, 1, 0, 0, 1)
        DebugBox(rightWeldPos+Vector(0,1,0),rightWeldPos+Vector(0,1,0),Vector(0.1,0.1,0.1), 5, 1, 1, 0, 1)
        DebugBox(midWeldPos+Vector(0,1,0),midWeldPos+Vector(0,1,0),Vector(0.1,0.1,0.1), 5, 1, 1, 1, 1)       
        --]]
        -- take the shortest route
        local origin = self:GetOrigin()
        if (origin - leftWeldPos):GetLengthSquared() < (origin - rightWeldPos):GetLengthSquared() then
            weldPos = leftWeldPos
        else
            weldPos = rightWeldPos
        end
    end

    return weldPos

end
local function CheckBehindBackPosition(self, orderTarget)

    if not self.timeOfLastBackPositionCheck or Shared.GetTime() > self.timeOfLastBackPositionCheck + MAC.kWeldPositionCheckInterval then

        self.timeOfLastBackPositionCheck = Shared.GetTime()
        self.backPosition = GetBackPosition(self, orderTarget)

    end

    return self.backPosition
end

function MAC:ProcessWeldOrder(deltaTime, orderTarget, orderLocation, autoWeld)

    local time = Shared.GetTime()
    local canBeWeldedNow = false
    local orderStatus = kOrderStatus.InProgress

    -- It is possible for the target to not be weldable at this point.
    -- This can happen if a damaged Marine becomes Commander for example.
    -- The Commander is not Weldable but the Order correctly updated to the
    -- new entity Id of the Commander. In this case, the order will simply be completed.
    if orderTarget and HasMixin(orderTarget, "Weldable") then

        local toTarget = (orderLocation - self:GetOrigin())
        local distanceToTarget = toTarget:GetLength()
        canBeWeldedNow = orderTarget:GetCanBeWelded(self)

        local obstacleSize = 0
        if HasMixin(orderTarget, "Extents") then
            obstacleSize = orderTarget:GetExtents():GetLengthXZ()
        end

        local tooFarFromLeash = self.leashedPosition and Vector(self.leashedPosition - self:GetOrigin()):GetLength() > 30 or false

        if autoWeld and (distanceToTarget > 15 or tooFarFromLeash) then
            orderStatus = kOrderStatus.Cancelled
        elseif not canBeWeldedNow then
            orderStatus = kOrderStatus.Completed
        else
            local forceMove = false
            local targetPosition = orderTarget:GetOrigin()

            local closeEnoughToWeld = distanceToTarget - obstacleSize < MAC.kWeldDistance + 0.5
            local shouldMoveCloser = distanceToTarget - obstacleSize > MAC.kWeldDistance

            if closeEnoughToWeld then
                local backPosition = CheckBehindBackPosition(self, orderTarget)
                if backPosition then
                    forceMove = true
                    targetPosition = backPosition
                end
            end

            if shouldMoveCloser or forceMove then
                -- otherwise move towards it
                local hoverAdjustedLocation = GetHoverAt(self, targetPosition)
                local doneMoving = self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime)
                self.moving = not doneMoving
            else
                self.moving = false
            end

            -- Not allowed to weld after taking damage recently.
            if Shared.GetTime() - self:GetTimeLastDamageTaken() <= 1.0 then
                return kOrderStatus.InProgress
            end

            -- Weld target if we're close enough to weld and enough time has passed since last weld
            if closeEnoughToWeld and (time > self.timeOfLastWeld + MAC.kWeldRate) then
                orderTarget:OnWeld(self, MAC.kWeldRate)
                self.timeOfLastWeld = time
            end

        end

    else
        orderStatus = kOrderStatus.Cancelled
    end

    -- Continuously turn towards the target. But don't mess with path finding movement if it was done.
    if orderLocation and not self.moving then

        local toOrder = (orderLocation - self:GetOrigin())
        self:SmoothTurn(deltaTime, GetNormalizedVector(toOrder), 0)

    end

    return orderStatus

end

function MAC:ProcessMove(deltaTime, target, targetPosition, closeEnough)

    local hoverAdjustedLocation = GetHoverAt(self, targetPosition)
    local orderStatus = kOrderStatus.None
    local distance = (targetPosition - self:GetOrigin()):GetLength()
    local doneMoving = target ~= nil and distance < closeEnough

    if not doneMoving and self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime) then

        orderStatus = kOrderStatus.Completed
        self.moving = false

    else
        orderStatus = kOrderStatus.InProgress
        self.moving = true
    end

    return orderStatus

end

function MAC:PlayChatSound(soundName)   --FIXME This can be heard by Alien Comm without LOS ...switch to Team sound?

    if self.timeOfLastChatterSound == 0 or (Shared.GetTime() > self.timeOfLastChatterSound + 2) and self:GetIsAlive() then

        local team = self:GetTeam()
        team:PlayPrivateTeamSound(soundName, self:GetOrigin(), false, nil, false, nil)  --FIXME This seems to make it 2D Only (not positional)

        local enemyTeamNumber = GetEnemyTeamNumber(team:GetTeamNumber())
        local enemyTeam = GetGamerules():GetTeam(enemyTeamNumber)
        if enemyTeam ~= nil then  --SeenByTeam? ...not sure that exists
            team:PlayPrivateTeamSound(soundName, self:GetOrigin(), false, nil, false, nil)
        end
        --self:PlaySound(soundName)
        self.timeOfLastChatterSound = Shared.GetTime()
    end

end

-- Look for other MACs and Drifters to greet as we fly by
function MAC:UpdateGreetings()

    local time = Shared.GetTime()
    if self.timeOfLastGreetingCheck == 0 or (time > (self.timeOfLastGreetingCheck + MAC.kGreetingUpdateInterval)) then

        if self.timeOfLastGreeting == 0 or (time > (self.timeOfLastGreeting + MAC.kGreetingInterval)) then

            local ents = GetEntitiesMatchAnyTypes({"MAC", "Drifter"})
            for index, ent in ipairs(ents) do

                if (ent ~= self) and (self:GetOrigin() - ent:GetOrigin()):GetLength() < MAC.kGreetingDistance then

                    if GetCanSeeEntity(self, ent) then
                        if ent:isa("MAC") then
                            self:PlayChatSound(MAC.kPassbyMACSoundName)
                        elseif ent:isa("Drifter") then
                            self:PlayChatSound(MAC.kPassbyDrifterSoundName)
                        end

                        self.timeOfLastGreeting = time
                        break

                    end

                end

            end

        end

        self.timeOfLastGreetingCheck = time

    end

end

function MAC:GetCanBeWeldedOverride()
    return self.lastTakenDamageTime + 1 < Shared.GetTime()
end

function MAC:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, self:GetHoverHeight(), 0)
end

local function GetCanConstructTarget(self, target)
    return target ~= nil and HasMixin(target, "Construct") and GetAreFriends(self, target)
end

function MAC:ProcessConstruct(deltaTime, orderTarget, orderLocation)

    local time = Shared.GetTime()

    local toTarget = (orderLocation - self:GetOrigin())
    local distToTarget = toTarget:GetLengthXZ()
    local orderStatus = kOrderStatus.InProgress
    local canConstructTarget = GetCanConstructTarget(self, orderTarget)

    if self.timeOfLastConstruct == 0 or (time > (self.timeOfLastConstruct + MAC.kConstructRate)) then

        if canConstructTarget then

            local engagementDist = GetEngagementDistance(orderTarget:GetId())
            if distToTarget < engagementDist then

                if orderTarget:GetIsBuilt() then
                    orderStatus = kOrderStatus.Completed
                else

                    -- Otherwise, add build time to structure
                    orderTarget:Construct(MAC.kConstructRate * kMACConstructEfficacy, self)
                    self.timeOfLastConstruct = time

                end

            else

                local hoverAdjustedLocation = GetHoverAt(self, orderLocation)
                local doneMoving = self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime)
                self.moving = not doneMoving

            end


        else
            orderStatus = kOrderStatus.Cancelled
        end


    end

    -- Continuously turn towards the target. But don't mess with path finding movement if it was done.
    if not self.moving and toTarget then
        self:SmoothTurn(deltaTime, GetNormalizedVector(toTarget), 0)
    end

    return orderStatus

end

local function FindSomethingToDo(self)

    local target, orderType = GetAutomaticOrder(self)

    if target and orderType then
        if self.leashedPosition then
            local tooFarFromLeash = Vector(self.leashedPosition - target:GetOrigin()):GetLength() > 15
            if tooFarFromLeash then
                --DebugPrint("Strayed too far!")
                return false
            end
        else
            self.leashedPosition = GetHoverAt(self, self:GetOrigin())
            --DebugPrint("return position set "..ToString(self.leashedPosition))
        end
        self.autoReturning = false
        self.selfGivenAutomaticOrder = true
        return self:GiveOrder(orderType, target:GetId(), target:GetOrigin(), nil, true, true) ~= kTechId.None
    elseif self.leashedPosition and not self.autoReturning then
        self.autoReturning = true
        self.selfGivenAutomaticOrder = true
        self:GiveOrder(kTechId.Move, nil, self.leashedPosition, nil, true, true)
        --DebugPrint("returning to "..ToString(self.leashedPosition))
    end

    return false

end

function MAC:OnOrderGiven(order)

    -- Clear out secondary order when an order is explicitly given to this MAC.
    self.secondaryOrderType = nil
    self.secondaryTargetId = nil

    if (not self.selfGivenAutomaticOrder) or self.autoReturning then
        self.leashedPosition = nil
        self.autoReturning = false
    end
    self.selfGivenAutomaticOrder = nil

end

-- for marquee selection
function MAC:GetIsMoveable()
    return true
end

function MAC:ProcessFollowAndWeldOrder(deltaTime, orderTarget, targetPosition)

    local currentOrder = self:GetCurrentOrder()
    local orderStatus = kOrderStatus.InProgress

    if orderTarget and orderTarget:GetIsAlive() then

        local target, orderType = GetAutomaticOrder(self)

        if target and orderType then

            self.secondaryOrderType = orderType
            self.secondaryTargetId = target:GetId()

        end

        target = target ~= nil and target or ( self.secondaryTargetId ~= nil and Shared.GetEntity(self.secondaryTargetId) )
        orderType = orderType ~= nil and orderType or self.secondaryOrderType

        local forceMove = false
        if not orderType then
            -- if we don't have a secondary order, we make sure we move to the back of the player
            local backPosition = CheckBehindBackPosition(self, orderTarget)
            if backPosition then
                forceMove = true
                targetPosition = backPosition
            end
        end

        local distance = (self:GetOrigin() - targetPosition):GetLengthXZ()

        -- stop moving to primary if we find something to do and we are not too far from our primary
        if orderType and self.moveToPrimary and distance < 10 then
            self.moveToPrimary = false
        end

        local triggerMoveDistance = (self.welding or self.constructing or orderType) and 15 or 6

        if distance > triggerMoveDistance or self.moveToPrimary or forceMove then

            local closeEnough = forceMove and 0.1 or 2.5
            if self:ProcessMove(deltaTime, target, targetPosition, closeEnough) == kOrderStatus.InProgress then
                self.moveToPrimary = true
                self.secondaryTargetId = nil
                self.secondaryOrderType = nil
            else
                self.moveToPrimary = false
            end

        else
            self.moving = false
        end

        -- when we attempt to follow the primary target, dont interrupt with auto orders
        if not self.moveToPrimary then

            if target and orderType then

                local secondaryOrderStatus

                if orderType == kTechId.AutoWeld then
                    secondaryOrderStatus = self:ProcessWeldOrder(deltaTime, target, target:GetOrigin(), true)
                elseif orderType == kTechId.Construct then
                    secondaryOrderStatus = self:ProcessConstruct(deltaTime, target, target:GetOrigin())
                end

                if secondaryOrderStatus == kOrderStatus.Completed or secondaryOrderStatus == kOrderStatus.Cancelled then

                    self.secondaryTargetId = nil
                    self.secondaryOrderType = nil

                end

            end

        end

    else
        self.moveToPrimary = false
        orderStatus = kOrderStatus.Cancelled
    end

    return orderStatus

end

local function UpdateOrders(self, deltaTime)

    local currentOrder = self:GetCurrentOrder()
    if currentOrder ~= nil then

        local orderStatus = kOrderStatus.None
        local orderTarget = Shared.GetEntity(currentOrder:GetParam())
        local orderLocation = currentOrder:GetLocation()

        if currentOrder:GetType() == kTechId.FollowAndWeld then
            orderStatus = self:ProcessFollowAndWeldOrder(deltaTime, orderTarget, orderLocation)
        elseif currentOrder:GetType() == kTechId.Move then
            local closeEnough = 2.5
            orderStatus = self:ProcessMove(deltaTime, orderTarget, orderLocation, closeEnough)
            self:UpdateGreetings()

        elseif currentOrder:GetType() == kTechId.Weld or currentOrder:GetType() == kTechId.AutoWeld then
            orderStatus = self:ProcessWeldOrder(deltaTime, orderTarget, orderLocation, currentOrder:GetType() == kTechId.AutoWeld)
        elseif currentOrder:GetType() == kTechId.Build or currentOrder:GetType() == kTechId.Construct then
            orderStatus = self:ProcessConstruct(deltaTime, orderTarget, orderLocation)
        end

        if orderStatus == kOrderStatus.Cancelled then
            self:ClearCurrentOrder()
        elseif orderStatus == kOrderStatus.Completed then
            self:CompletedCurrentOrder()
        end

    end

end

local function TriggerEMPBlast(self)
    
    self.empTriggeredTime = Shared.GetTime()
    CreateEntity(EMPBlast.kMapName, self:GetOrigin(), self:GetTeamNumber())

end

function MAC:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    if Server and self:GetIsAlive() then

        -- assume we're not moving initially
        self.moving = false

        if not self:GetHasOrder() then
            FindSomethingToDo(self)
        else
            UpdateOrders(self, deltaTime)
        end

        self.constructing = Shared.GetTime() - self.timeOfLastConstruct < 0.5
        self.welding = Shared.GetTime() - self.timeOfLastWeld < 0.5

        if self.moving and not self.jetsSound:GetIsPlaying() then
            self.jetsSound:Start()
        elseif not self.moving and self.jetsSound:GetIsPlaying() then
            self.jetsSound:Stop()
        end

        local empBlastResearched = GetHasTech(self,kTechId.MACEMPBlast)
        self.empBlast = empBlastResearched and Shared.GetTime() - self.empTriggeredTime > kMACEmpBlastTriggerInterval
        if self.empBlast and Shared.GetTime() - self.empDetectionTime > kMACEmpBlastDetectInterval then
            self.empDetectionTime = Shared.GetTime()

            local ents = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kMACEmpBlastDetectRadius)
            for e = 1, #ents do
                local entity = ents[e]
                if entity:isa("Player") and entity:GetIsAlive() and not entity.electrified then
                    TriggerEMPBlast(self)
                    break;
                end
            end
        end
        
            -- client side build / weld effects
    elseif Client and self:GetIsAlive() then

        if self.constructing then

            if not self.timeLastConstructEffect or self.timeLastConstructEffect + MAC.kConstructRate < Shared.GetTime()  then

                self:TriggerEffects("mac_construct")
                self.timeLastConstructEffect = Shared.GetTime()

            end

        end

        if self.welding then

            if not self.timeLastWeldEffect or self.timeLastWeldEffect + MAC.kWeldRate < Shared.GetTime()  then

                self:TriggerEffects("mac_weld")
                self.timeLastWeldEffect = Shared.GetTime()

            end

        end

        if self:GetHasOrder() ~= self.clientHasOrder then

            self.clientHasOrder = self:GetHasOrder()

            if self.clientHasOrder then
                self:TriggerEffects("mac_set_order")
            end

        end

        if self.jetsCinematics then

            for id,cinematic in ipairs(self.jetsCinematics) do
                self.jetsCinematics[id]:SetIsActive(self.moving and self:GetIsVisible())
            end

        end

        if self.electrifiedClient ~= self.empBlast then
            self.electrifiedClient = self.empBlast

            local thirdpersonModel = self:GetRenderModel()
            if thirdpersonModel then

                if self.electrifiedClient then
                    self.electrifiedMaterial = AddMaterial(thirdpersonModel, MAC.kElectrifiedThirdpersonMaterialName)
                else
                    if RemoveMaterial(thirdpersonModel, self.electrifiedMaterial) then
                        self.electrifiedMaterial = nil
                    end
                end
            end
        end

    end
        

end


--if Server then
--    function MAC:OnKill()
--        local empBlastResearched = GetHasTech(self,kTechId.MACEMPBlast)
--        if empBlastResearched then
--            TriggerEMPBlast(self)
--        end
--    end
--end

function MAC:OnOrderComplete(order)
    if self.autoReturning then
        self.leashedPosition = nil
        self.autoReturning = false
        --DebugPrint("Arrived")
    end
end

function MAC:PerformActivation(techId, position, normal, commander)

    if techId == kTechId.MACEMP then

        local empBlast = CreateEntity(EMPBlast.kMapName, self:GetOrigin(), self:GetTeamNumber())
        return empBlast ~= nil, false

    end

    return ScriptActor.PerformActivation(self, techId, position, normal, commander)

end

function MAC:GetTechButtons(techId)

    return { kTechId.Move, kTechId.Stop, kTechId.Welding, kTechId.None,
             kTechId.None, kTechId.None, kTechId.None, kTechId.None }

end

function MAC:OnOverrideDoorInteraction(inEntity)
    -- MACs will not open the door if they are currently
    -- welding it shut
    if self:GetHasOrder() then
        local order = self:GetCurrentOrder()
        local targetId = order:GetParam()
        local target = Shared.GetEntity(targetId)
        if (target ~= nil) then
            if (target == inEntity) then
                return false, 0
            end
        end
    end
    return true, 4
end

function MAC:GetIdleSoundInterval()
    return 25
end

function MAC:UpdateIncludeRelevancyMask()
    SetAlwaysRelevantToCommander(self, true)
end

if Server then

    function MAC:GetCanReposition()
        return true
    end

    function MAC:OverrideRepositioningSpeed()
        return MAC.kMoveSpeed *.4
    end

    function MAC:OverrideRepositioningDistance()
        return 0.4
    end

    function MAC:OverrideGetRepositioningTime()
        return .5
    end

end

local function GetOrderMovesMAC(orderType)

    return orderType == kTechId.Move or
            orderType == kTechId.Build or
            orderType == kTechId.Construct or
            orderType == kTechId.Weld

end

function MAC:OnUpdateAnimationInput(modelMixin)

    PROFILE("MAC:OnUpdateAnimationInput")

    local move = "idle"
    local currentOrder = self:GetCurrentOrder()
    if currentOrder then

        if GetOrderMovesMAC(currentOrder:GetType()) then
            move = "run"
        end

    end
    modelMixin:SetAnimationInput("move",  move)

    local currentTime = Shared.GetTime()
    local activity = "none"
    if self.constructing or self.welding then
        activity = "build"
    end
    modelMixin:SetAnimationInput("activity", activity)

end

function MAC:GetShowHitIndicator()
    return false
end

function MAC:GetPlayIdleSound()
    return not self:GetHasOrder() and GetIsUnitActive(self)
end

function MAC:GetHealthbarOffset()
    return 1.4
end

function MAC:OnDestroy()

    Entity.OnDestroy(self)

    if Client then

        for id,cinematic in ipairs(self.jetsCinematics) do

            Client.DestroyCinematic(cinematic)
            self.jetsCinematics[id] = nil

        end

    end

end

Shared.LinkClassToMap("MAC", MAC.kMapName, networkVars, true)

if Server then

    local function OnCommandFollowAndWeld(client)

        if client ~= nil and Shared.GetCheatsEnabled() then

            local player = client:GetControllingPlayer()
            for _, mac in ipairs(GetEntitiesForTeamWithinRange("MAC", player:GetTeamNumber(), player:GetOrigin(), 10)) do
                mac:GiveOrder(kTechId.FollowAndWeld, player:GetId(), player:GetOrigin(), nil, false, false)
            end

        end

    end

    Event.Hook("Console_followandweld", OnCommandFollowAndWeld)

end

