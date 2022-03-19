-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Hallucination.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
--
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/RepositioningMixin.lua")
Script.Load("lua/SoftTargetMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

PrecacheAsset("cinematics/vfx_materials/hallucination.surface_shader")
local kHallucinationMaterial = PrecacheAsset( "cinematics/vfx_materials/hallucination.material")

class 'Hallucination' (ScriptActor)

Hallucination.kMapName = "hallucination"

Hallucination.kSpotRange = 15
Hallucination.kTurnSpeed  = 4 * math.pi
Hallucination.kDefaultMaxSpeed = 1

local networkVars =
{
    assignedTechId = "enum kTechId",
    moving = "boolean",
    attacking = "boolean",
    hallucinationIsVisible = "boolean",
    creationTime = "time"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

local gTechIdAttacking
local function GetTechIdAttacks(techId)
    
    if not gTechIdAttacking then
        gTechIdAttacking = {}
        gTechIdAttacking[kTechId.Prowler] = true
        gTechIdAttacking[kTechId.Skulk] = true
        gTechIdAttacking[kTechId.Gorge] = true
        gTechIdAttacking[kTechId.Lerk] = true
        gTechIdAttacking[kTechId.Fade] = true
        gTechIdAttacking[kTechId.Onos] = true
    end
    
    return gTechIdAttacking[techId]
    
end

local ghallucinateIdToTechId
function GetTechIdToEmulate(techId)

    if not ghallucinateIdToTechId then
    
        ghallucinateIdToTechId = {}
        ghallucinateIdToTechId[kTechId.HallucinateDrifter] = kTechId.Drifter
        ghallucinateIdToTechId[kTechId.HallucinateProwler] = kTechId.Prowler
        ghallucinateIdToTechId[kTechId.HallucinateSkulk] = kTechId.Skulk
        ghallucinateIdToTechId[kTechId.HallucinateGorge] = kTechId.Gorge
        ghallucinateIdToTechId[kTechId.HallucinateLerk] = kTechId.Lerk
        ghallucinateIdToTechId[kTechId.HallucinateFade] = kTechId.Fade
        ghallucinateIdToTechId[kTechId.HallucinateOnos] = kTechId.Onos
        
        ghallucinateIdToTechId[kTechId.HallucinateHive] = kTechId.Hive
        ghallucinateIdToTechId[kTechId.HallucinateWhip] = kTechId.Whip
        ghallucinateIdToTechId[kTechId.HallucinateShade] = kTechId.Shade
        ghallucinateIdToTechId[kTechId.HallucinateCrag] = kTechId.Crag
        ghallucinateIdToTechId[kTechId.HallucinateShift] = kTechId.Shift
        ghallucinateIdToTechId[kTechId.HallucinateHarvester] = kTechId.Harvester
        ghallucinateIdToTechId[kTechId.HallucinateHydra] = kTechId.Hydra
    
    end
    
    return ghallucinateIdToTechId[techId]

end

local gTechIdCanMove
local function GetHallucinationCanMove(techId)

    if not gTechIdCanMove then
        gTechIdCanMove = {}
        gTechIdCanMove[kTechId.Prowler] = true
        gTechIdCanMove[kTechId.Skulk] = true
        gTechIdCanMove[kTechId.Gorge] = true
        gTechIdCanMove[kTechId.Lerk] = true
        gTechIdCanMove[kTechId.Fade] = true
        gTechIdCanMove[kTechId.Onos] = true
        
        gTechIdCanMove[kTechId.Drifter] = true
        gTechIdCanMove[kTechId.Whip] = true
    end 
       
    return gTechIdCanMove[techId]

end

local gTechIdCanBuild
local function GetHallucinationCanBuild(techId)

    if not gTechIdCanBuild then
        gTechIdCanBuild = {}
        gTechIdCanBuild[kTechId.Gorge] = true
    end 
       
    return gTechIdCanBuild[techId]

end

local function GetEmulatedClassName(techId)
    return EnumToString(kTechId, techId)
end

-- model graphs should already be precached elsewhere
local gTechIdAnimationGraph
local function GetAnimationGraph(techId)

    if not gTechIdAnimationGraph then
        gTechIdAnimationGraph = {}
        gTechIdAnimationGraph[kTechId.Prowler] = "models/alien/prowler/prowler.animation_graph"
        gTechIdAnimationGraph[kTechId.Skulk] = "models/alien/skulk/skulk.animation_graph"
        gTechIdAnimationGraph[kTechId.Gorge] = "models/alien/gorge/gorge.animation_graph"
        gTechIdAnimationGraph[kTechId.Lerk] = "models/alien/lerk/lerk.animation_graph"
        gTechIdAnimationGraph[kTechId.Fade] = "models/alien/fade/fade.animation_graph"         
        gTechIdAnimationGraph[kTechId.Onos] = "models/alien/onos/onos.animation_graph"
        gTechIdAnimationGraph[kTechId.Drifter] = "models/alien/drifter/drifter.animation_graph"  
        
        gTechIdAnimationGraph[kTechId.Hive] = "models/alien/hive/hive.animation_graph"
        gTechIdAnimationGraph[kTechId.Whip] = "models/alien/whip/whip.animation_graph"
        gTechIdAnimationGraph[kTechId.Shade] = "models/alien/shade/shade.animation_graph"
        gTechIdAnimationGraph[kTechId.Crag] = "models/alien/crag/crag.animation_graph"
        gTechIdAnimationGraph[kTechId.Shift] = "models/alien/shift/shift.animation_graph"
        gTechIdAnimationGraph[kTechId.Harvester] = "models/alien/harvester/harvester.animation_graph"
        gTechIdAnimationGraph[kTechId.Hydra] = "models/alien/hydra/hydra.animation_graph"
        
    end
    
    return gTechIdAnimationGraph[techId]

end

local gTechIdMaxMovementSpeed
local function GetMaxMovementSpeed(techId)

    if not gTechIdMaxMovementSpeed then
        gTechIdMaxMovementSpeed = {}
        gTechIdMaxMovementSpeed[kTechId.Prowler] = 8
        gTechIdMaxMovementSpeed[kTechId.Skulk] = 8
        gTechIdMaxMovementSpeed[kTechId.Gorge] = 5.1
        gTechIdMaxMovementSpeed[kTechId.Lerk] = 9
        gTechIdMaxMovementSpeed[kTechId.Fade] = 7
        gTechIdMaxMovementSpeed[kTechId.Onos] = 7
        
        gTechIdMaxMovementSpeed[kTechId.Drifter] = 11
        gTechIdMaxMovementSpeed[kTechId.Whip] = 4
    
    end
    
    local moveSpeed = gTechIdMaxMovementSpeed[techId]
    
    return ConditionalValue(moveSpeed == nil, Hallucination.kDefaultMaxSpeed, moveSpeed)

end

local gTechIdMoveState
local function GetMoveName(techId)

    if not gTechIdMoveState then
        gTechIdMoveState = {}
        gTechIdMoveState[kTechId.Lerk] = "fly"
    
    end
    
    local moveState = gTechIdMoveState[techId]
    
    return ConditionalValue(moveState == nil, "run", moveState)

end

local function SetAssignedAttributes(self, hallucinationTechId)

    local model = LookupTechData(self.assignedTechId, kTechDataModel, Skulk.kModelName)
    local health = math.min(LookupTechData(self.assignedTechId, kTechDataMaxHealth, kSkulkHealth) * kHallucinationHealthFraction, kHallucinationMaxHealth)
    local armor = LookupTechData(self.assignedTechId, kTechDataMaxArmor, kSkulkArmor) * kHallucinationArmorFraction
    
    self.maxSpeed = GetMaxMovementSpeed(self.assignedTechId)    
    self:SetModel(model, GetAnimationGraph(self.assignedTechId))
    self:SetMaxHealth(health)
    self:SetHealth(health)
    self:SetMaxArmor(armor)
    self:SetArmor(armor)
    
    if self.assignedTechId == kTechId.Hive then
    
        local attachedTechPoint = self:GetAttached()
        if attachedTechPoint then
            attachedTechPoint:SetIsSmashed(true)
        end
    
    end
    
end

function Hallucination:OnCreate()
    
    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin, { kPlayFlinchAnimations = true })
    InitMixin(self, TeamMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, PathingMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, SoftTargetMixin)
    
    if Server then
    
        self.hallucinationIsVisible = true
        self.attacking = false
        self.moving = false
        self.assignedTechId = kTechId.Skulk

        InitMixin(self, SleeperMixin)
        
    end

    self:SetUpdates(true, kDefaultUpdateRate)
end

function Hallucination:OnInitialized()
    
    ScriptActor.OnInitialized(self)

    if Server then
    
        SetAssignedAttributes(self, kTechId.HallucinateSkulk)

        InitMixin(self, RepositioningMixin)

        self:SetPhysicsType(PhysicsType.Kinematic)
        
        InitMixin(self, MobileTargetMixin)
    
    end
    
    
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)
    
end

function Hallucination:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    
    if Client then
    
        if self.hallucinationMaterial then
        
            Client.DestroyRenderMaterial(self.hallucinationMaterial)
            self.hallucinationMaterial = nil
            
        end
    
    end

end

function Hallucination:GetIsFlying()
    return self.assignedTechId == kTechId.Drifter
end

function Hallucination:GetAssignedTechId()
    return self.assignedTechId
end    

function Hallucination:SetEmulation(hallucinationTechId)

    self.assignedTechId = GetTechIdToEmulate(hallucinationTechId)
    SetAssignedAttributes(self, hallucinationTechId)
    
        
    if not HasMixin(self, "MapBlip") then
        InitMixin(self, MapBlipMixin)
    end

end

function Hallucination:GetMaxSpeed()
    if self.assignedTechId == kTechId.Fade and not self.hallucinationIsVisible then
        return self.maxSpeed * 2
    end

    return self.maxSpeed
end

--[[
function Hallucination:GetSurfaceOverride()
    return "hallucination"
end
--]]

function Hallucination:GetCanReposition()
    return GetHallucinationCanMove(self.assignedTechId)
end
 
function Hallucination:OverrideGetRepositioningTime()
    return 0.4
end    

function Hallucination:OverrideRepositioningSpeed()
    return self.maxSpeed * 0.8
end

function Hallucination:OverrideRepositioningDistance()
    if self.assignedTechId == kTechId.Onos then
        return 4
    end
    
    return 1.5
end

function Hallucination:GetCanSleep()
    return self:GetCurrentOrder() == nil    
end

function Hallucination:GetTurnSpeedOverride()
    return Hallucination.kTurnSpeed
end

function Hallucination:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server then
        self:UpdateServer(deltaTime)
        UpdateHallucinationLifeTime(self)
    elseif Client then
        self:UpdateClient(deltaTime)
    end    
    
    self.moveSpeed = 1
    
    self:SetPoseParam("move_yaw", 90)
    self:SetPoseParam("move_speed", self.moveSpeed)

end

function Hallucination:OnOverrideDoorInteraction(inEntity)   
    return true, 4
end

function Hallucination:PerformActivation(techId, position, normal, commander)

    if techId == kTechId.DestroyHallucination then
    
        self:Kill()
        return true, true
        
    end
    
    return false, true
    
end

function Hallucination:GetIsMoving()
    return self.moving
end

function Hallucination:GetTechButtons(techId)

    return { kTechId.DestroyHallucination }
    
end

local function OnUpdateAnimationInputCustom(self, techId, modelMixin, moveState)

    if techId == kTechId.Lerk then
        modelMixin:SetAnimationInput("flapping", self:GetIsMoving())
    elseif techId == kTechId.Fade and not self.hallucinationIsVisible then
        modelMixin:SetAnimationInput("move", "blink")
    end

end

function Hallucination:OnUpdateAnimationInput(modelMixin)

    local moveState = "idle"
    
    if self:GetIsMoving() then
        moveState = GetMoveName(self.assignedTechId)
    end

    modelMixin:SetAnimationInput("built", self.assignedTechId == kTechId.Drifter)

    modelMixin:SetAnimationInput("move", moveState) 
    OnUpdateAnimationInputCustom(self, self.assignedTechId, modelMixin, moveState)

end

function Hallucination:GetIsMoveable()
    return true
end

function Hallucination:OnUpdatePoseParameters()
    self:SetPoseParam("grow", 1)    
end

if Server then

    function Hallucination:UpdateServer(deltaTime)
    
        if self.timeInvisible and not self.hallucinationIsVisible then
            self.timeInvisible = math.max(self.timeInvisible - deltaTime, 0)
            
            if self.timeInvisible == 0 then
            
                self.hallucinationIsVisible = true
            
            end
            
        end
            
        self:UpdateOrders(deltaTime)
    
    end
    
    function Hallucination:GetDestroyOnKill()
        return true
    end

    function Hallucination:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        self:TriggerEffects("death_hallucination")
        
    end
    --[[
    function Hallucination:OnScan()
        self:Kill()
    end
    --]]
    function Hallucination:GetHoverHeight()
    
        if self.assignedTechId == kTechId.Lerk or self.assignedTechId == kTechId.Drifter then
            return 1.5   
        else
            return 0
        end    
        
    end
    
    local function PerformSpecialMovement(self)
        
        if self.assignedTechId == kTechId.Fade then
            
            -- blink every now and then
            if not self.nextTimeToBlink then
                self.nextTimeToBlink = Shared.GetTime()
            end    
            
            local distToTarget = (self:GetCurrentOrder():GetLocation() - self:GetOrigin()):GetLengthXZ()
            if self.nextTimeToBlink <= Shared.GetTime() and distToTarget > 17 then -- 17 seems to be a good value as minimum distance to trigger blink

                self.hallucinationIsVisible = false
                self.timeInvisible = 0.5 + math.random() * 2
                self.nextTimeToBlink = Shared.GetTime() + 2 + math.random() * 8
            
            end
            
        end
    
    end
    
    function Hallucination:UpdateMoveOrder(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()
        ASSERT(currentOrder)
        
        self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), self:GetMaxSpeed(), deltaTime)
        
        if self:IsTargetReached(currentOrder:GetLocation(), kAIMoveOrderCompleteDistance) then
            self:CompletedCurrentOrder()
        else
        
            self:SetOrigin(GetHoverAt(self, self:GetOrigin()))
            PerformSpecialMovement(self)
            self.moving = true
            
        end
        
    end
    
    function Hallucination:UpdateAttackOrder(deltaTime)
    
        if not GetTechIdAttacks(self.assignedTechId) then
            self:ClearCurrentOrder()
            return
        end    
        
    end

    
    function Hallucination:UpdateBuildOrder(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()
        local techId = currentOrder:GetParam()
        local engagementDist = LookupTechData(techId, kTechDataEngagementDistance, 0.35)
        local distToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLengthXZ()
        
        if (distToTarget < engagementDist) then   
        
            local commander = self:GetOwner()
            if (not commander) then
                self:ClearOrders(true, true)
                return
            end
            
            local techIdToEmulate = GetTechIdToEmulate(techId)
            
            local origin = currentOrder:GetLocation()
            local trace = Shared.TraceRay(Vector(origin.x, origin.y + .1, origin.z), Vector(origin.x, origin.y - .2, origin.z), CollisionRep.Select, PhysicsMask.CommanderBuild, EntityFilterOne(self))
            local legalBuildPosition, position, attachEntity = GetIsBuildLegal(techIdToEmulate, trace.endPoint, 0, 4, self:GetOwner(), self)

            if (not legalBuildPosition) then
                self:ClearOrders()
                return
            end
            
            --[[ deprecated
            local createdHallucination = CreateEntity(Hallucination.kMapName, position, self:GetTeamNumber())
            if createdHallucination then
            
                createdHallucination:SetEmulation(techId)
                
                -- Drifter hallucinations are destroyed when they construct something
                if self.assignedTechId == kTechId.Drifter then
                    self:Kill()
                else
                
                    local costs = LookupTechData(techId, kTechDataCostKey, 0)
                    self:AddEnergy(-costs)
                    self:TriggerEffects("spit_structure")
                    self:CompletedCurrentOrder()
                
                end
                
            else--]]
            
                self:ClearOrders(true, true)
                return
                
            -- end
            
        else
            self:UpdateMoveOrder(deltaTime)
        end
        
    end
    
    function Hallucination:UpdateOrders(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()

        if currentOrder then
        
            if currentOrder:GetType() == kTechId.Move and GetHallucinationCanMove(self.assignedTechId) then
                self:UpdateMoveOrder(deltaTime)
            elseif currentOrder:GetType() == kTechId.Attack then
                self:UpdateAttackOrder(deltaTime)
            elseif currentOrder:GetType() == kTechId.Build and GetHallucinationCanBuild(self.assignedTechId) then
                self:UpdateBuildOrder(deltaTime)
            else
                self:ClearCurrentOrder()
            end
            
        else

            self.moving = false
            self.attacking = false

        end    
    
    end
    
end

function Hallucination:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.35, 0)
end

function Hallucination:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Hallucination:GetSendDeathMessage()
    return not self.consumed
end

if Client then

    function Hallucination:OnUpdateRender()
    
        PROFILE("Hallucination:OnUpdateRender")
    
        local showMaterial = not GetAreEnemies(self, Client.GetLocalPlayer())
    
        local model = self:GetRenderModel()
        if model then

            model:SetMaterialParameter("glowIntensity", 0)

            if showMaterial then
                
                if not self.hallucinationMaterial then
                    self.hallucinationMaterial = AddMaterial(model, kHallucinationMaterial)
                end
                
                self:SetOpacity(0, "hallucination")
            
            else
            
                if self.hallucinationMaterial then
                    RemoveMaterial(model, self.hallucinationMaterial)
                    self.hallucinationMaterial = nil
                end
                
                self:SetOpacity(1, "hallucination")
            
            end
            
        end
    
    end

    function Hallucination:UpdateClient(deltaTime)
    
        if self.clientHallucinationIsVisible == nil then
            self.clientHallucinationIsVisible = self.hallucinationIsVisible
        end    
    
        if self.clientHallucinationIsVisible ~= self.hallucinationIsVisible then
        
            self.clientHallucinationIsVisible = self.hallucinationIsVisible
            if self.hallucinationIsVisible then
                self:OnShow()
            else
                self:OnHide()
            end  
        end
    
        self:SetIsVisible(self.hallucinationIsVisible)
        
        if self:GetIsVisible() and self:GetIsMoving() then
            self:UpdateMoveSound(deltaTime)
        end
    
    end
    
    function Hallucination:UpdateMoveSound(deltaTime)
    
        if not self.timeUntilMoveSound then
            self.timeUntilMoveSound = 0
        end
        
        if self.timeUntilMoveSound == 0 then
        
            local surface = GetSurfaceAndNormalUnderEntity(self)            
            self:TriggerEffects("footstep", {classname = GetEmulatedClassName(self.assignedTechId), surface = surface, left = true, sprinting = false, forward = true, crouch = false})
            self.timeUntilMoveSound = 0.3
            
        else
            self.timeUntilMoveSound = math.max(self.timeUntilMoveSound - deltaTime, 0)     
        end
    
    end
    
    function Hallucination:OnHide()
    
        if self.assignedTechId == kTechId.Fade then
            self:TriggerEffects("blink_out")
        end
    
    end
    
    function Hallucination:OnShow()
    
        if self.assignedTechId == kTechId.Fade then
            self:TriggerEffects("blink_in")
        end
    
    end

end

Shared.LinkClassToMap("Hallucination", Hallucination.kMapName, networkVars)
