-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\InfantryPortal.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
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
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/SupplyUserMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/FilteredCinematicMixin.lua")

if Client then
    Script.Load("lua/GraphDrivenModel.lua")
end

class 'InfantryPortal' (ScriptActor)

local kSpinEffect = PrecacheAsset("cinematics/marine/infantryportal/spin.cinematic")
local kAnimationGraph = PrecacheAsset("models/marine/infantry_portal/infantry_portal.animation_graph")
local kHoloMarineModel = PrecacheAsset("models/marine/male/male_spawn.model")
local kMarineAnimationGraph = PrecacheAsset("models/marine/male/male.animation_graph")

local kHoloMarineMaterialname = PrecacheAsset("cinematics/vfx_materials/marine_ip_spawn.material")

if Client then
    PrecacheAsset("cinematics/vfx_materials/marine_ip_spawn.surface_shader")
end

InfantryPortal.kMapName = "infantryportal"

InfantryPortal.kModelName = PrecacheAsset("models/marine/infantry_portal/infantry_portal.model")

InfantryPortal.kAnimSpinStart = "spin_start"
InfantryPortal.kAnimSpinContinuous = "spin"

InfantryPortal.kUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/base_under_attack")
InfantryPortal.kIdleLightEffect = PrecacheAsset("cinematics/marine/infantryportal/idle_light.cinematic")

InfantryPortal.kTransponderUseTime = .5
local kUpdateRate = 0.25
InfantryPortal.kTransponderPointValue = 15
InfantryPortal.kLoginAttachPoint = "keypad"

local kPushRange = 3
local kPushImpulseStrength = 40

local networkVars =
{
    queuedPlayerId = "entityid",
    queuedPlayerModel = string.format("string (%d)", 128 ),
    queuedPlayerStartTime = "time",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
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
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(PowerConsumerMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

local function CreateSpinEffect(self)

    if not self.spinCinematic then
    
        self.spinCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.spinCinematic:SetCinematic(FilterCinematicName(kSpinEffect))
        self.spinCinematic:SetCoords(self:GetCoords())
        self.spinCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    end
    
    local marineVariant = Client.GetOptionInteger("marineVariant", kDefaultMarineVariant)
    local modelPath = ""
    
    if not self.fakeMarineModel and not self.fakeMarineMaterial then
    
        if self.queuedPlayerModel then
            modelPath = self.queuedPlayerModel
        else
            local sexType = string.lower(Client.GetOptionString("sexType", "Male"))
            modelPath = "models/marine/" .. sexType .. "/" .. sexType .. GetVariantModel(kMarineVariantsData, marineVariant)
        end

        local model = PrecacheAsset(modelPath)
        self.fakeMarineModel = CreateGraphDrivenModel(model, kMarineAnimationGraph)
        
        local coords = self:GetCoords()
        coords.origin = coords.origin + Vector(0, 0.4, 0)
        self.fakeMarineModel:SetCoords(coords)
        self.fakeMarineModel:SetAnimationInput("move", "idle")
        self.fakeMarineModel:SetAnimationInput("alive", true)
        self.fakeMarineModel:SetAnimationInput("body_yaw", 30)
        self.fakeMarineModel:SetAnimationInput("body_pitch", -8)

        self.fakeMarineModel:InstanceMaterials()
        self.fakeMarineModel:SetMaterialParameter("hiddenAmount", 0)
        self.fakeMarineModel:SetMaterialParameter("patchIndex", -2)
        
        self.fakeMarineMaterial = self.fakeMarineModel:AddMaterial(kHoloMarineMaterialname)

    end
    
    if self.clientQueuedPlayerId ~= self.queuedPlayerId then
        if self.fakeMarineModel then
            DestroyGraphDrivenModel(self.fakeMarineModel)
            self.fakeMarineModel = nil
            self.fakeMarineMaterial = nil
        end
        self.timeSpinStarted = self.queuedPlayerStartTime or Shared.GetTime()
        self.clientQueuedPlayerId = self.queuedPlayerId
    end
    
    if self.fakeMarineModel and self.fakeMarineMaterial then
        local spawnProgress = Clamp((Shared.GetTime() - self.timeSpinStarted) / kMarineRespawnTime, 0, 1)
        self.fakeMarineMaterial:SetParameter("spawnProgress", spawnProgress + 0.2)    -- Add a little so it always fills up
    end

end

local function DestroySpinEffect(self)

    if self.spinCinematic then
    
        Client.DestroyCinematic(self.spinCinematic)    
        self.spinCinematic = nil
    
    end
    
    if self.fakeMarineModel then
        DestroyGraphDrivenModel(self.fakeMarineModel)
        self.fakeMarineModel = nil
        self.fakeMarineMaterial = nil
    end

end

function InfantryPortal:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
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
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
        InitMixin(self, FilteredCinematicMixin)
    end
    
    if Server then
        self.timeLastPush = 0
    end
    
    self.queuedPlayerId = Entity.invalidId
    self.queuedPlayer = nil
    
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

local function StopSpinning(self)

    self:TriggerEffects("infantry_portal_stop_spin")
    self.timeSpinUpStarted = nil
    
end

local function PushPlayers(self)

    for _, player in ipairs(GetEntitiesWithinRange("Player", self:GetOrigin(), 0.5)) do

        if player:GetIsAlive() and HasMixin(player, "Controller") then

            player:DisableGroundMove(0.1)
            player:SetVelocity(Vector(GetSign(math.random() - 0.5) * 2, 3, GetSign(math.random() - 0.5) * 2))

        end
        
    end

end

local function InfantryPortalUpdate(self)

    self:FillQueueIfFree()
    
    if GetIsUnitActive(self) then
        
        local remainingSpawnTime = self:GetSpawnTime()
        if self.queuedPlayerId ~= Entity.invalidId then
        
            local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
            if queuedPlayer then
                self.queuedPlayer = queuedPlayer
                remainingSpawnTime = math.max(0, self.queuedPlayerStartTime + self:GetSpawnTime() - Shared.GetTime())
            
                if remainingSpawnTime < 0.3 and self.timeLastPush + 0.5 < Shared.GetTime() then
                
                    PushPlayers(self)
                    self.timeLastPush = Shared.GetTime()
                    
                end
                
            else
                
                self.queuedPlayerId = nil
                self.queuedPlayer = nil
                self.queuedPlayerStartTime = nil
                
            end

        end
    
        if remainingSpawnTime == 0 then
            self:FinishSpawn()
        end
        
        -- Stop spinning if player left server, switched teams, etc.
        if self.timeSpinUpStarted and self.queuedPlayerId == Entity.invalidId then
            StopSpinning(self)
        end
        
    end
    
    return true
    
end

function InfantryPortal:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)
    
    self:SetModel(InfantryPortal.kModelName, kAnimationGraph)
    
    if Server then
    
        self:AddTimedCallback(InfantryPortalUpdate, kUpdateRate)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, InfestationTrackerMixin)
        InitMixin(self, SupplyUserMixin)
        
    elseif Client then
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
    end
    
    InitMixin(self, IdleMixin)
    
end

function InfantryPortal:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    -- Put the player back in queue if there was one hoping to spawn at this now destroyed IP.
    if Server then
        self:RequeuePlayer()
    elseif Client then
    
        DestroySpinEffect(self)
        
        if self.fakeMarineModel then
            
            DestroyGraphDrivenModel(self.fakeMarineModel)
            self.fakeMarineModel = nil
            self.fakeMarineMaterial = nil
            
        end
        
    end
    
end

function InfantryPortal:GetNanoShieldOffset()
    return Vector(0, -0.1, 0)
end

function InfantryPortal:GetRequiresPower()
    return true
end

local function QueueWaitingPlayer(self)

    if self:GetIsAlive() and self.queuedPlayerId == Entity.invalidId then

        -- Remove player from team spawn queue and add here
        local team = self:GetTeam()
        local playerToSpawn = team:GetOldestQueuedPlayer()

        if playerToSpawn ~= nil then
            
            playerToSpawn:SetIsRespawning(true)
            team:RemovePlayerFromRespawnQueue(playerToSpawn)
            self.queuedPlayerId = playerToSpawn:GetId()
            if HasMixin(playerToSpawn, "MarineVariant") then
                self.queuedPlayerModel = playerToSpawn:GetVariantModel()
            end
            self.queuedPlayerStartTime = Shared.GetTime()

            self:StartSpinning()
            
            SendPlayersMessage({ playerToSpawn }, kTeamMessageTypes.Spawning)
            
            if Server then
                
                if playerToSpawn.SetSpectatorMode then
                    playerToSpawn:SetSpectatorMode(kSpectatorMode.Following)
                end
                
                playerToSpawn:SetFollowTarget(self)

            end
            
        end
        
    end

end

function InfantryPortal:GetReceivesStructuralDamage()
    return true
end

function InfantryPortal:GetSpawnTime()
    return kMarineRespawnTime
end

function InfantryPortal:OnReplace(newStructure)
    newStructure.queuedPlayerId = self.queuedPlayerId
    newEntityId.queuedPlayer = self.queuedPlayer
end

-- Spawn player on top of IP. Returns true if it was able to, false if way was blocked.
local function SpawnPlayer(self)

    if self.queuedPlayerId ~= Entity.invalidId then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        local team = queuedPlayer:GetTeam()
        
        -- Spawn player on top of IP
        local spawnOrigin = self:GetAttachPointOrigin("spawn_point")
        
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, queuedPlayer:GetAngles())
        if success then
            
            --local weapon = player:GetWeaponInHUDSlot(1)
            --if weapon then
            --    weapon.deployed = true -- start the rifle already deployed
            --    weapon.skipDraw = true
            --end
            
            player:SetCameraDistance(0)

            
            if HasMixin( player, "Controller" ) and HasMixin( player, "AFKMixin" ) then
                
                if player:GetAFKTime() > self:GetSpawnTime() - 1 then
                    
                    player:DisableGroundMove(0.1)
                    player:SetVelocity( Vector( GetSign( math.random() - 0.5) * 2.25, 3, GetSign( math.random() - 0.5 ) * 2.25 ) )
                    
                end
                
            end
            
            self.queuedPlayerId = Entity.invalidId
            self.queuedPlayerStartTime = nil
            
            player:ProcessRallyOrder(self)

            self:TriggerEffects("infantry_portal_spawn")

            SetPlayerStartingLocation(player)

            return true
            
        else
            Print("Warning: Infantry Portal failed to spawn the player")
        end
        
    end
    
    return false

end

function InfantryPortal:GetIsWallWalkingAllowed()
    return false
end 

-- Takes the queued player from this IP and placed them back in the
-- respawn queue to be spawned elsewhere.
function InfantryPortal:RequeuePlayer()

    if self.queuedPlayerId ~= Entity.invalidId then
    
        local player = Shared.GetEntity(self.queuedPlayerId)
        local team = self:GetTeam()
        if team then
            team:PutPlayerInRespawnQueue(Shared.GetEntity(self.queuedPlayerId))
        end
        player:SetIsRespawning(false)
        player:SetSpectatorMode(kSpectatorMode.Following)
        
    end
    
    -- Don't spawn player.
    self.queuedPlayerId = Entity.invalidId
    self.queuedPlayer = nil
    self.queuedPlayerStartTime = nil

end

if Server then

    function InfantryPortal:OnEntityChange(entityId, newEntityId)
    
        if self.queuedPlayerId == entityId then
        
            -- Player left or was replaced, either way
            -- they're not in the queue anymore
            self.queuedPlayerId = Entity.invalidId
            self.queuedPlayer = nil
            self.queuedPlayerStartTime = nil
            
        end
        
    end
    
    function InfantryPortal:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        StopSpinning(self)
        
        -- Put the player back in queue if there was one hoping to spawn at this now dead IP.
        self:RequeuePlayer()
        
    end
    
end

if Server then

    function InfantryPortal:FillQueueIfFree()

        if not GetWarmupActive() and GetIsUnitActive(self) then
        
            if self.queuedPlayerId == Entity.invalidId then
                QueueWaitingPlayer(self)
            end
            
        end
        
    end
    
    function InfantryPortal:FinishSpawn()
    
        SpawnPlayer(self)
        StopSpinning(self)
        self.timeSpinUpStarted = nil
        
    end
    
end

function InfantryPortal:StartSpinning()

    if self.timeSpinUpStarted == nil then
    
        self:TriggerEffects("infantry_portal_start_spin")
        self.timeSpinUpStarted = Shared.GetTime()
        
    end
    
end

function InfantryPortal:OnPowerOn()

    if self.queuedPlayerId ~= Entity.invalidId then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)        
        if queuedPlayer then
        
            queuedPlayer:SetRespawnQueueEntryTime(Shared.GetTime())            
            self:StartSpinning()
            
        end
        
    end
    
end

function InfantryPortal:OnPowerOff()

    -- Put the player back in queue if there was one hoping to spawn at this IP.
    StopSpinning(self)
    self:RequeuePlayer()
    
end

function InfantryPortal:GetDamagedAlertId()
    return kTechId.MarineAlertInfantryPortalUnderAttack
end

function InfantryPortal:OnUpdateAnimationInput(modelMixin)

    PROFILE("InfantryPortal:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("spawning", self.queuedPlayerId ~= Entity.invalidId)
    
end

function InfantryPortal:OnOverrideOrder(order)

    -- Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetRally)
    end
    
end

function GetInfantryPortalGhostGuides(commander)

    local entities = { }
    local ranges = { }

    local commandStations = GetEntitiesForTeam("CommandStation", commander:GetTeamNumber())
    local attachRange = LookupTechData(kTechId.InfantryPortal, kStructureAttachRange, 1)
    
    for _, commandStation in ipairs(commandStations) do
        if commandStation:GetIsBuilt() then
            ranges[commandStation] = attachRange
            table.insert(entities, commandStation)
        end
    end
    
    return entities, ranges

end

function GetCommandStationIsBuilt(techId, origin, normal, commander)

    -- check if there is a built command station in our team
    if not commander then
        return false
    end

    local spaceFree = GetHasRoomForCapsule(Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents), origin + Vector(0, 0.1 + Player.kYExtents, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls)
    
    --if spaceFree then
    --
    --    local cs = GetEntitiesForTeamWithinRange("CommandStation", commander:GetTeamNumber(), origin, 15)
    --    if cs and #cs > 0 then
    --
    --        local ccs = cs[1] -- Hmm...
    --        local ips = GetEntitiesForTeamWithinRange("InfantryPortal", commander:GetTeamNumber(), ccs:GetOrigin(), 15)
    --        if ips then
    --
    --            local ipCountValid = #ips < kMaxInfantryPortalsPerCommandStation
    --            local built = ccs:GetIsBuilt()
    --
    --            if ipCountValid and built then
    --                return true
    --            elseif not ipCountValid then
    --                return false, "INFANTRY_PORTAL_TOOMANYIPS"
    --            end
    --        end
    --
    --    end
    --
    --end
    

    return spaceFree

end

if Client then

    function InfantryPortal:OnFilteredCinematicOptionChanged()
        if self.spinCinematic then
            self.spinCinematic:SetCinematic(FilterCinematicName(kSpinEffect))
        end
    end

    function InfantryPortal:PreventSpinEffect(duration)
        self.preventSpinDuration = duration
        DestroySpinEffect(self)
    end

    function InfantryPortal:OnUpdate(deltaTime)

        PROFILE("InfantryPortal:OnUpdate")
        
        ScriptActor.OnUpdate(self, deltaTime)
        
        if self.preventSpinDuration then            
            self.preventSpinDuration = math.max(0, self.preventSpinDuration - deltaTime)         
        end

        local shouldSpin = GetIsUnitActive(self) and self.queuedPlayerId ~= Entity.invalidId and (self.preventSpinDuration == nil or self.preventSpinDuration == 0)
        
        if shouldSpin then
            CreateSpinEffect(self)
        else
            DestroySpinEffect(self)
        end
        
    end

end

function InfantryPortal:GetTechButtons()

    return {
        kTechId.SetRally, kTechId.SpawnMarine, kTechId.None, kTechId.None, 
        kTechId.None, kTechId.None, kTechId.None, kTechId.None,     
    }
    
end

function InfantryPortal:GetHealthbarOffset()
    return 0.5
end 

Shared.LinkClassToMap("InfantryPortal", InfantryPortal.kMapName, networkVars, true)

-- DEBUG
if Server then
    Event.Hook("Console_set_base_yaw", function(client, value)
    
        if not Shared.GetTestsEnabled() and not Shared.GetCheatsEnabled() then
            Log("set_base_yaw requires cheats or tests to be enabled.")
            return
        end
        
        value = tonumber(value) or 2
        
        local player = client:GetPlayer()
        if not player then
            Log("no player...")
            return
        end
    
        if not player.baseYaw then
            Log("player.baseYaw was nil!")
            return
        end
        
        Log("Setting baseYaw to %s", value)
        player.baseYaw = value
        
    end)
end
