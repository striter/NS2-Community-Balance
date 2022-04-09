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
Script.Load("lua/CommanderGlowMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/SupplyUserMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")

class 'WeaponCache' (ScriptActor)

WeaponCache.kMapName = "weaponcache"

WeaponCache.kModelName = PrecacheAsset("models/marine/weapon_cache/weapon_cache.model")
WeaponCache.kAnimationGraph = PrecacheAsset("models/marine/weapon_cache/weapon_cache.animation_graph")

-- Looping sound while using the armory
WeaponCache.kResupplySound = PrecacheAsset("sound/NS2.fev/marine/structures/armory_resupply")

--WeaponCache.kArmoryBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
WeaponCache.kAttachPoint = "Root"

--WeaponCache.kBuyMenuFlash = "ui/marine_buy.swf"
--WeaponCache.kBuyMenuTexture = "ui/marine_buymenu.dds"
--WeaponCache.kBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
local kLoginAndResupplyTime = 0.3
WeaponCache.kHealAmount = 12.5
WeaponCache.kRefillAmount = 0.5
WeaponCache.kResupplyInterval = .8
-- Players can use menu and be supplied by armor inside this range
WeaponCache.kResupplyUseRange = 2.5
WeaponCache.kSentryRange = 5

if Server then
    Script.Load("lua/Combat/WeaponCache_Server.lua")
elseif Client then
    Script.Load("lua/Combat/WeaponCache_Client.lua")
end

PrecacheAsset("models/marine/armory/health_indicator.surface_shader")
    
local networkVars =
{
    -- How far out the arms are for animation (0-1)
    loggedIn     = "boolean",
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
AddMixinNetworkVars(ObstacleMixin, networkVars)
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
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    
    --if Client then
      --  InitMixin(self, CommanderGlowMixin)
    --end

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
    -- False if the player that's logged into a side is only nearby, true if
    -- the pressed their key to open the menu to buy something. A player
    -- must use the armory once "logged in" to be able to buy anything.
    self.loginEastAmount = 0
    self.loginNorthAmount = 0
    self.loginWestAmount = 0
    self.loginSouthAmount = 0
    
    self.timeScannedEast = 0
    self.timeScannedNorth = 0
    self.timeScannedWest = 0
    self.timeScannedSouth = 0
    
    self.deployed = false
    
    -- self.isGhostStructure = false

end

-- Check if friendly players are nearby and facing armory and heal/resupply them
local function LoginAndResupply(self)

    self:UpdateLoggedIn()
    
    -- Make sure players are still close enough, alive, marines, etc.
    -- Give health and ammo to nearby players.
    
    -- if GetIsUnitActive(self) then Messes up the animation for some reason, Well, probably because
    -- unitedactive asks if the structure has power. In which case, it doesn't, but becaause we don't want the armory to 
    -- require power. It stills allows this, but the animation is in't sync. 
   
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
    
        self.loggedInArray = { false, false, false, false }
        
        -- Use entityId as index, store time last resupplied
        self.resuppliedPlayers = { }

        self:AddTimedCallback(LoginAndResupply, kLoginAndResupplyTime)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, InfestationTrackerMixin)
        InitMixin(self, SupplyUserMixin)
        
    elseif Client then
    
        self:OnInitClient()        
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end
    
    InitMixin(self, IdleMixin)
    
end

function WeaponCache:GetCanBeUsed(player, useSuccessTable)

    --if player:isa("Exo") then
        useSuccessTable.useSuccess = false
    --end
end

function WeaponCache:GetCanBeUsedConstructed()
    return false
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

    local techButtons = nil

    techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                    kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    -- Show button to upgraded to advanced armory
    --if self:GetTechId() == kTechId.WeaponCache and self:GetResearchingId() ~= kTechId.AdvancedArmoryUpgrade then
        --techButtons[kMarineUpgradeButtonIndex] = kTechId.AdvancedArmoryUpgrade
    --end

    return techButtons
    
end

function WeaponCache:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)
    
    --if techId == kTechId.HeavyRifleTech then
        --allowed = allowed and self:GetTechId() == kTechId.AdvancedArmory
    --end
    
    return allowed, canAfford

end

function WeaponCache:OnUpdatePoseParameters()

    --if GetIsUnitActive(self) < - Checks for power, doesn't sync correctly when we want it to work without power.
    --self:GetIsBuilt()
    if GetIsUnitActive(self) and self.deployed then
        
        if self.loginNorthAmount then
            self:SetPoseParam("log_n", self.loginNorthAmount)
        end
        
        if self.loginSouthAmount then
            self:SetPoseParam("log_s", self.loginSouthAmount)
        end
        
        if self.loginEastAmount then
            self:SetPoseParam("log_e", self.loginEastAmount)
        end
        
        if self.loginWestAmount then
            self:SetPoseParam("log_w", self.loginWestAmount)
        end
        
        if self.scannedParamValue then
        
            for extension, value in pairs(self.scannedParamValue) do
                self:SetPoseParam("scan_" .. extension, value)
            end
            
        end
        
    end
    
end

local function UpdateArmoryAnim(self, extension, loggedIn, scanTime, timePassed)
--[[
    local loggedInName = "log_" .. extension
    local loggedInParamValue = ConditionalValue(loggedIn, 1, 0)

    if extension == "n" then
        self.loginNorthAmount = Clamp(Slerp(self.loginNorthAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "s" then
        self.loginSouthAmount = Clamp(Slerp(self.loginSouthAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "e" then
        self.loginEastAmount = Clamp(Slerp(self.loginEastAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "w" then
        self.loginWestAmount = Clamp(Slerp(self.loginWestAmount, loggedInParamValue, timePassed * 2), 0, 1)
    end
    
    local scannedName = "scan_" .. extension
    self.scannedParamValue = self.scannedParamValue or { }
    self.scannedParamValue[extension] = ConditionalValue(scanTime == 0 or (Shared.GetTime() > scanTime + 3), 0, 1)
    ]]--
end

function WeaponCache:OnUpdate(deltaTime)

    if Client then
        self:UpdateArmoryWarmUp()
    end
    
    --f GetIsUnitActive(self) <- Checks for power. We want the armory to work without power!
    --self:GetIsBuilt() <-- does not check for power
    if GetIsUnitActive(self) and self.deployed then
    
        -- Set pose parameters according to if we're logged in or not
       -- UpdateArmoryAnim(self, "e", self.loggedInEast, self.timeScannedEast, deltaTime)
       -- UpdateArmoryAnim(self, "n", self.loggedInNorth, self.timeScannedNorth, deltaTime)
       -- UpdateArmoryAnim(self, "w", self.loggedInWest, self.timeScannedWest, deltaTime)
     --   UpdateArmoryAnim(self, "s", self.loggedInSouth, self.timeScannedSouth, deltaTime)
        
    end
    
    ScriptActor.OnUpdate(self, deltaTime)
    
end

function WeaponCache:GetReceivesStructuralDamage()
    return true
end

function WeaponCache:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

-- function WeaponCache:GetItemList(forPlayer)
    
--     local itemList = {   
--         kTechId.LayMines, 
--         kTechId.Shotgun,
--         kTechId.Welder,
--         kTechId.ClusterGrenade,
--         kTechId.GasGrenade,
--         kTechId.PulseGrenade
--     }
   --[[ 
    if self:GetTechId() == kTechId.AdvancedArmory then
    
        itemList = {   
            kTechId.LayMines,
            kTechId.Shotgun,
            kTechId.Welder,
            kTechId.ClusterGrenade,
            kTechId.GasGrenade,
            kTechId.PulseGrenade,
            kTechId.GrenadeLauncher,
            kTechId.Flamethrower,
        }
        
    end
    ]]--
    -- return itemList
    
-- end

function WeaponCache:GetHealthbarOffset()
    return 1.4
end 

-- if Server then
--     function Armory:OnTag(tagName)
--         if tagName == "deploy_end" then
--             self.deployed = true
--         end
--     end

-- end

Shared.LinkClassToMap("WeaponCache", WeaponCache.kMapName, networkVars)