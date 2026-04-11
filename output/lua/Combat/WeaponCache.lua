Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/Combat/MarineStructureMixin.lua")

class 'WeaponCache' (ScriptActor)

WeaponCache.kMapName = "weaponcache"

WeaponCache.kModelName = PrecacheAsset("models/marine/weapon_cache/weapon_cache.model")
WeaponCache.kAnimationGraph = PrecacheAsset("models/marine/weapon_cache/weapon_cache.animation_graph")

local kHealUpdateTime = 0.3
WeaponCache.kHealAmount = 12.5
WeaponCache.kRefillAmount = 0.5
WeaponCache.kResupplyInterval = 0.8
WeaponCache.kResupplyUseRange = 3.0
WeaponCache.kMaxUseableRange = 1.5

if Server then
    Script.Load("lua/Combat/WeaponCache_Server.lua")
elseif Client then
    Script.Load("lua/Combat/WeaponCache_Client.lua")
end

PrecacheAsset("models/marine/armory/health_indicator.surface_shader")
    
local networkVars =
{
    deployed = "boolean",
    showAura = "boolean",
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
AddMixinNetworkVars(SelectableMixin, networkVars)

AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(PowerConsumerMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function WeaponCache:OnCreate()
    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, CorrodeMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    InitMixin(self, ObstacleMixin)
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
    self.deployed = false
end

-- Simple healing callback - no login required
local function HealNearbyPlayers(self)
    if GetIsUnitActive(self) then
        self:ResupplyPlayers()
    end
    return true
end

function WeaponCache:OnInitialized()
    ScriptActor.OnInitialized(self)
    
    self:SetModel(WeaponCache.kModelName, WeaponCache.kAnimationGraph)
    
    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)

    if Server then    
        -- Use entityId as index, store time last resupplied
        self.resuppliedPlayers = { }
        self:AddTimedCallback(HealNearbyPlayers, kHealUpdateTime)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, InfestationTrackerMixin)
        InitMixin(self, MarineStructureMixin)
        
    elseif Client then
        self:OnInitClient()        
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
    end
    
    InitMixin(self, IdleMixin)
end

function WeaponCache:GetUsablePoints()
    return { self:GetOrigin() }
end


function WeaponCache:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = not player:isa("Exo")
end

function WeaponCache:GetCanBeUsedNew(player, useSuccessTable)
    useSuccessTable.useSuccess = not player:isa("Exo")
end

function WeaponCache:GetUseMaxRange()
    return WeaponCache.kMaxUseableRange
end

function WeaponCache:GetCanBeUsedConstructed(byPlayer)
    return not byPlayer:isa("Exo")
end
        
function WeaponCache:GetRequiresPower()
    return false
end

function WeaponCache:GetTechIfResearched(buildId, researchId)
    local techTree = nil
    if Server then
        techTree = self:GetTeam():GetTechTree()
    else
        techTree = GetTechTree()
    end
    ASSERT(techTree ~= nil)
    
    -- If we don't have the research, return it, otherwise return buildId
    local researchNode = techTree:GetTechNode(researchId)
    ASSERT(researchNode ~= nil)
    ASSERT(researchNode:GetIsResearch())
    return ConditionalValue(researchNode:GetResearched(), buildId, researchId)
end

function WeaponCache:GetTechButtons(techId)
    local techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    return techButtons
end

-- Item list for buy menu - grenades and mines only (weapons are cached)
function WeaponCache:GetItemList(forPlayer)
    local itemList = {   
        kTechId.LayMines, 
        kTechId.ClusterGrenade,
        kTechId.GasGrenade,
        kTechId.PulseGrenade
    }
    return itemList
end

function WeaponCache:GetTechAllowed(techId, techNode, player)
    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)
    return allowed, canAfford
end

function WeaponCache:OnUpdate(deltaTime)
    if Client then
        self:UpdateArmoryWarmUp()
    end
    
    ScriptActor.OnUpdate(self, deltaTime)
end

function WeaponCache:GetReceivesStructuralDamage()
    return true
end

function WeaponCache:GetHealthbarOffset()
    return 1.4
end 

Shared.LinkClassToMap("WeaponCache", WeaponCache.kMapName, networkVars)
