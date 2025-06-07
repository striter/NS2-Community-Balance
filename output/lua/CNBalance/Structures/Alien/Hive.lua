-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Hive.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/DetectableMixin.lua")

Script.Load("lua/CommandStructure.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/CNBalance/Mixin/ElectrifyMixin.lua")
Script.Load("lua/CatalystMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MaturityMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/TeleportMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/BiomassMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/AlienStructureVariantMixin.lua")
Script.Load("lua/BiomassHealthMixin.lua")

class 'Hive' (CommandStructure)

local networkVars =
{
    extendAmount = "float (0 to 1 by 0.01)",
    bioMassLevel = "integer (0 to 6)",
    bioMassPreserve = "integer (0 to 6)",
    evochamberid = "entityid"
}

AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(CatalystMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(FireMixin, networkVars)
AddMixinNetworkVars(ElectrifyMixin, networkVars)
AddMixinNetworkVars(MaturityMixin, networkVars)
AddMixinNetworkVars(TeleportMixin, networkVars)
AddMixinNetworkVars(HiveVisionMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(AlienStructureVariantMixin, networkVars)

kResearchToHiveType =
{
    [kTechId.UpgradeToCragHive] = kTechId.CragHive,
    [kTechId.UpgradeToShadeHive] = kTechId.ShadeHive,
    [kTechId.UpgradeToShiftHive] = kTechId.ShiftHive,
}

Hive.kMapName = "hive"

PrecacheAsset("cinematics/vfx_materials/hive_frag.surface_shader")

Hive.kModelName = PrecacheAsset("models/alien/hive/hive.model")
local kAnimationGraph = PrecacheAsset("models/alien/hive/hive.animation_graph")

Hive.kWoundSound = PrecacheAsset("sound/NS2.fev/alien/structures/hive_wound")
-- Play special sound for players on team to make it sound more dramatic or horrible
Hive.kWoundAlienSound = PrecacheAsset("sound/NS2.fev/alien/structures/hive_wound_alien")

Hive.kIdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist.cinematic")
Hive.kL2IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev2.cinematic")
Hive.kL3IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev3.cinematic")
--Hive.kGlowEffect = PrecacheAsset("cinematics/alien/hive/glow.cinematic")

Hive.kSpecksEffect = PrecacheAsset("cinematics/alien/hive/specks.cinematic")
Hive.kSpecksEffectAbyss = PrecacheAsset("cinematics/alien/hive/specks_abyss.cinematic")
Hive.kSpecksEffectKodiak = PrecacheAsset("cinematics/alien/hive/specks_kodiak.cinematic")
Hive.kSpecksEffectReaper = PrecacheAsset("cinematics/alien/hive/specks_reaper.cinematic")
Hive.kSpecksEffectNocturne = PrecacheAsset("cinematics/alien/hive/specks_nocturne.cinematic")
Hive.kSpecksEffectUnearthed = PrecacheAsset("cinematics/alien/hive/specks_unearthed.cinematic")
Hive.kSpecksEffectToxin = PrecacheAsset("cinematics/alien/hive/specks_catpack.cinematic")
Hive.kSpecksEffectShadow = PrecacheAsset("cinematics/alien/hive/specks_shadow.cinematic")
Hive.kSpecksEffectAuric = PrecacheAsset("cinematics/alien/hive/specks_auric.cinematic")

Hive.kCompleteSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/hive_complete")
Hive.kUnderAttackSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/hive_under_attack")
Hive.kDyingSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/hive_dying")

Hive.kHealRadius = 12.7     -- From NS1
Hive.kHealthPercentage = .08
Hive.kHealthUpdateTime = 1

if Server then
    Script.Load("lua/Hive_Server.lua")
elseif Client then
    Script.Load("lua/Hive_Client.lua")
end

function Hive:OnCreate()

    CommandStructure.OnCreate(self)

    InitMixin(self, CloakableMixin)

    InitMixin(self, FireMixin)
    InitMixin(self,ElectrifyMixin)
    InitMixin(self, CatalystMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, MaturityMixin)
    InitMixin(self, TeleportMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, BiomassMixin)
    InitMixin(self, BiomassHealthMixin)

    self.extendAmount = 0

    if Server then

        self.biomassResearchFraction = 0

        self.cystChildren = { }

        self.lastImpulseFireTime = Shared.GetTime()

        self.timeOfLastEgg = Shared.GetTime()

        -- when constructed first level is added automatically
        self.bioMassLevel = 0
        self.bioMassPreserve = 0

        -- init this to -1, otherwise it defaults to 0 between OnCreate() and OnInitialized()
        self.evochamberid = -1

        self.timeLastReceivedARCDamage = 0

        self:UpdateIncludeRelevancyMask()

    elseif Client then
        -- For mist creation
        self:SetUpdates(true, kDefaultUpdateRate)
    end

end

function Hive:OnInitialized()

    InitMixin(self, InfestationMixin)

    CommandStructure.OnInitialized(self)

    -- Pre-compute list of egg spawn points.
    if Server then

        self:SetModel(Hive.kModelName, kAnimationGraph)

        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        InitMixin(self, StaticTargetMixin)

        local evochamber = CreateEntity( "evolutionchamber", self:GetOrigin(), self:GetTeamNumber())
        self.evochamberid = evochamber:GetId()
        evochamber:SetOwner( self )

    elseif Client then

        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)

        self.glowIntensity = ConditionalValue(self:GetIsBuilt(), 1, 0)

    end

    InitMixin(self, IdleMixin)

    --Must be init'd last
    if not Predict then
        self.setupStructureEffects = false
        self.startSpecsTime = Shared.GetTime() + 5 --delay so network data can propagate
        InitMixin(self, AlienStructureVariantMixin)
    end

end

local kSpecksSkinMap =
{
    [kAlienStructureVariants.Default] = Hive.kSpecksEffect,
    [kAlienStructureVariants.Abyss] = Hive.kSpecksEffectAbyss,
    [kAlienStructureVariants.Reaper] = Hive.kSpecksEffectReaper,
    [kAlienStructureVariants.Kodiak] = Hive.kSpecksEffectKodiak,
    [kAlienStructureVariants.Toxin] = Hive.kSpecksEffectToxin,
    [kAlienStructureVariants.Nocturne] = Hive.kSpecksEffectNocturne,
    [kAlienStructureVariants.Shadow] = Hive.kSpecksEffectShadow,
    [kAlienStructureVariants.Unearthed] = Hive.kSpecksEffectUnearthed,
    [kAlienStructureVariants.Auric] = Hive.kSpecksEffectAuric,
}
function Hive:UpdateStructureEffects()

    if Client and not self.setupStructureEffects and Shared.GetTime() > self.startSpecsTime then
        -- Create glowy "plankton" swimming around hive, along with mist and glow
        local coords = self:GetCoords()
        local specksFile = kSpecksSkinMap[self.structureVariant]

        self:AttachEffect(specksFile, coords)
        --self:AttachEffect(Hive.kGlowEffect, coords, Cinematic.Repeat_Loop)
        self.setupStructureEffects = true
    end

end

local kHelpArrowsCinematicName = PrecacheAsset("cinematics/alien/commander_arrow.cinematic")
PrecacheAsset("models/misc/commander_arrow_aliens.model")

if Client then

    function Hive:GetHelpArrowsCinematicName()
        return kHelpArrowsCinematicName
    end

end

function Hive:GetEvolutionChamber()
    return Shared.GetEntity( self.evochamberid )
end

function Hive:SetIncludeRelevancyMask(includeMask)

    includeMask = bit.bor(includeMask, kRelevantToTeam2Commander)
    CommandStructure.SetIncludeRelevancyMask(self, includeMask)

    -- make evolution chamber relevant whenever hive is relevant.
    local evoChamber = self:GetEvolutionChamber()
    if evoChamber then
        evoChamber:SetIncludeRelevancyMask(includeMask)
    end

end

function Hive:GetMaturityRate()
    return kHiveMaturationTime
end

function Hive:GetMatureMaxHealth()
    return kMatureHiveHealth
end

function Hive:GetMatureMaxArmor()
    return kMatureHiveArmor
end

function Hive:GetInfestationMaxRadius()
    return kHiveInfestationRadius
end

function Hive:GetMatureMaxEnergy()
    return kMatureHiveMaxEnergy
end

function Hive:OnCollision(entity)

    -- We may hook this up later.
    --[[
    -- if entity:isa("Player") and GetEnemyTeamNumber(self:GetTeamNumber()) == entity:GetTeamNumber() then
    --  self.lastTimeEnemyTouchedHive = Shared.GetTime()
    -- end
     ]]
end

function GetIsHiveTypeResearch(techId)
    return techId == kTechId.UpgradeToCragHive or techId == kTechId.UpgradeToShadeHive or techId == kTechId.UpgradeToShiftHive
end

function GetHiveTypeResearchAllowed(self, techId)

    local hiveTypeTechId = kResearchToHiveType[techId]
    return not GetHasTech(self, hiveTypeTechId) and not GetIsTechResearching(self, techId)

end

function Hive:GetInfestationRadius()
    return kHiveInfestationRadius
end

function Hive:GetCystParentRange()
    return kHiveCystParentRange
end

function Hive:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = CommandStructure.GetTechAllowed(self, techId, techNode, player)

    if techId == kTechId.ResearchBioMassTwo or techId == kTechId.RecoverBiomassTwo then
        allowed = allowed and self.bioMassLevel == 2
    elseif techId == kTechId.ResearchBioMassThree or techId == kTechId.RecoverBiomassThree then
        allowed = allowed and self.bioMassLevel == 3
    end

    return allowed, canAfford

end

local function CouldUseACommander(self)

    if GetGameInfoEntity():GetGameStarted() then
        local teamInfoEntity = GetTeamInfoEntity(self:GetTeamNumber())
        if teamInfoEntity and teamInfoEntity.isOriginForm then
            return false
        end
    end
    return true
end


function Hive:ConstructionTimeBonus()
    local teamInfoEntity = GetTeamInfoEntity(self:GetTeamNumber())
    if teamInfoEntity and teamInfoEntity.isOriginForm then
        return teamInfoEntity.bioMassLevel == 0 and 5 or 1
    end
    
    return 1
end

function Hive:GetBioMassLevel()
    return self.bioMassLevel * kHiveBiomass
end

function Hive:GetCanResearchOverride(techId)

    local allowed = true

    if GetIsHiveTypeResearch(techId) then
        allowed = GetHiveTypeResearchAllowed(self, techId)
    end

    return allowed and GetIsUnitActive(self)

end

function Hive:OnSighted(sighted)

    if sighted then
        local techPoint = self:GetAttached()
        if techPoint then
            techPoint:SetSmashScouted()
        end
    end

    CommandStructure.OnSighted(self, sighted)

end

function Hive:GetHealthbarOffset()
    return 0.8
end

-- Don't show objective after we become cloaked
function Hive:OnCloak()

    local attached = self:GetAttached()
    if attached then
        attached.showObjective = false
    end

end

function Hive:OverrideVisionRadius()
    return 20
end

function Hive:OnUpdatePoseParameters()
    self:SetPoseParam("extend", self.extendAmount)
end

--[[
 * Return true if a connected cyst parent is availble at the given origin normal. 
]]
function GetTechPointInfested(techId, origin)

    local attachEntity = GetNearestFreeAttachEntity(techId, origin, kStructureSnapRadius)

    return attachEntity and attachEntity:GetGameEffectMask(kGameEffect.OnInfestation)

end

-- return a good spot from which a player could have entered the hive
-- used for initial entry point for the commander
function Hive:GetDefaultEntryOrigin()
    return self:GetOrigin() + Vector(2,0,2)
end

function Hive:GetInfestationBlobMultiplier()
    return 5
end

Shared.LinkClassToMap("Hive", Hive.kMapName, networkVars)

class 'CragHive' (Hive)
CragHive.kMapName = Hive.kMapName
--Shared.LinkClassToMap("CragHive", CragHive.kMapName, { })

class 'ShadeHive' (Hive)
ShadeHive.kMapName = Hive.kMapName
--Shared.LinkClassToMap("ShadeHive", ShadeHive.kMapName, { })

class 'ShiftHive' (Hive)
ShiftHive.kMapName = Hive.kMapName
--Shared.LinkClassToMap("ShiftHive", ShiftHive.kMapName, { })

Script.Load("lua/CNBalance/Mixin/SupplyProviderMixin.lua")
function Hive:OnInitialized()

    InitMixin(self, InfestationMixin)

    CommandStructure.OnInitialized(self)

    -- Pre-compute list of egg spawn points.
    if Server then

        self:SetModel(Hive.kModelName, kAnimationGraph)

        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        InitMixin(self, StaticTargetMixin)

        local evochamber = CreateEntity( "evolutionchamber", self:GetOrigin(), self:GetTeamNumber())
        self.evochamberid = evochamber:GetId()
        evochamber:SetOwner( self )

        if Server then
            InitMixin(self, SupplyProviderMixin)
        end
        self.timeLastOriginformBiomassCheck = Shared.GetTime()
    elseif Client then

        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)

        self.glowIntensity = ConditionalValue(self:GetIsBuilt(), 1, 0)

    end

    InitMixin(self, IdleMixin)

    --Must be init'd last
    if not Predict then
        self.setupStructureEffects = false
        self.startSpecsTime = Shared.GetTime() + 5 --delay so network data can propagate
        InitMixin(self, AlienStructureVariantMixin)
    end

end


function Hive:GetTechButtons()

    local techButtons = { kTechId.ShiftHatch, kTechId.None, kTechId.None, kTechId.None, --kTechId.LifeFormMenu,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    
    local techId = self:GetTechId()
    if techId == kTechId.Hive then
        techButtons[5] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToCragHive), kTechId.UpgradeToCragHive, kTechId.None)
        techButtons[6] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToShadeHive), kTechId.UpgradeToShadeHive, kTechId.None)
        techButtons[7] = ConditionalValue(GetHiveTypeResearchAllowed(self, kTechId.UpgradeToShiftHive), kTechId.UpgradeToShiftHive, kTechId.None)
    elseif techId == kTechId.CragHive then
        techButtons[5] = kTechId.CragTunnel
        techButtons[6] = kTechId.DrifterRegeneration
        techButtons[7] = kTechId.CystCarapace
    elseif techId == kTechId.ShiftHive then
        techButtons[5] = kTechId.ShiftTunnel
        techButtons[6] = kTechId.DrifterCelerity
        techButtons[7] = kTechId.CystCelerity
    elseif techId == kTechId.ShadeHive then
        techButtons[5] = kTechId.ShadeTunnel
        techButtons[6] = kTechId.DrifterCamouflage
        techButtons[7] = kTechId.CystCamouflage
    end

    local alienTeamInfo = GetTeamInfoEntity(self:GetTeamNumber())
    local originFormTech = kTechId.OriginFormPassive
    if alienTeamInfo and alienTeamInfo.canEvolveOriginForm then
        originFormTech = kTechId.OriginForm
    end
    techButtons[8] = originFormTech

    if self.bioMassLevel < self.bioMassPreserve then
        if self.bioMassLevel <= 1 then
            techButtons[2] = kTechId.RecoverBiomassOne
        elseif self.bioMassLevel <= 2 then
            techButtons[2] = kTechId.RecoverBiomassTwo
        elseif self.bioMassLevel <= 3 then
            techButtons[2] = kTechId.RecoverBiomassThree
        end
    else
        if self.bioMassLevel <= 1 then
            techButtons[2] = kTechId.ResearchBioMassOne
        elseif self.bioMassLevel <= 2 then
            techButtons[2] = kTechId.ResearchBioMassTwo
        elseif self.bioMassLevel <= 3 then
            techButtons[2] = kTechId.ResearchBioMassThree
        end
    end
    
    return techButtons
    
end

if Server then
    local baseOnResearchComplete = Hive.OnResearchComplete
    function Hive:OnResearchComplete(researchId)
        baseOnResearchComplete(self,researchId)

        if researchId == kTechId.CragTunnel then        --Inform matured tunnel to update armor amount
            for _, tunnel in ipairs(GetEntitiesForTeam("TunnelEntrance", self:GetTeamNumber())) do
                tunnel:UpdateMaturity(true)
            end
        end
    end


    local baseOnUpdate = Hive.OnUpdate
    function Hive:OnUpdate(deltaTime)
        baseOnUpdate(self,deltaTime)
    end

    function Hive:OnResearchComplete(researchId)

        local success = false
        local hiveTypeChosen = false
        self.biomassResearchFraction = 0

        local hiveTechId = self:GetTechId()

        local team = self:GetTeam()
        if researchId == kTechId.ResearchBioMassOne 
                or researchId == kTechId.ResearchBioMassTwo 
                or researchId == kTechId.ResearchBioMassThree 
                or researchId == kTechId.ResearchBioMassFour 
                or researchId == kTechId.RecoverBiomassOne
                or researchId == kTechId.RecoverBiomassTwo
                or researchId == kTechId.RecoverBiomassThree
        then

            self.bioMassLevel = math.min(6, self.bioMassLevel + 1)
            team:GetTechTree():SetTechChanged()
            team:SetBioMassPreserve(hiveTechId,self.bioMassLevel)
            success = true

        elseif researchId == kTechId.UpgradeToCragHive then

            success = self:UpgradeToTechId(kTechId.CragHive)
            hiveTechId = kTechId.CragHive
            hiveTypeChosen = true

        elseif researchId == kTechId.UpgradeToShadeHive then

            success = self:UpgradeToTechId(kTechId.ShadeHive)
            hiveTechId = kTechId.ShadeHive
            hiveTypeChosen = true

        elseif researchId == kTechId.UpgradeToShiftHive then

            success = self:UpgradeToTechId(kTechId.ShiftHive)
            hiveTechId = kTechId.ShiftHive
            hiveTypeChosen = true

        end
        
        if success and hiveTypeChosen  then
            -- Let gamerules know for stat tracking.
            GetGamerules():SetHiveTechIdChosen(self, hiveTechId)
            team:SetBioMassPreserve(hiveTechId,self.bioMassLevel)    --Update it once by max
            self.bioMassPreserve = team:GetBioMassPreserve(hiveTechId)       --Collect biomass preserve after upgrade
        end

    end

    local kResearchTypeToHiveType =
    {
        [kTechId.UpgradeToCragHive] = kTechId.CragHive,
        [kTechId.UpgradeToShadeHive] = kTechId.ShadeHive,
        [kTechId.UpgradeToShiftHive] = kTechId.ShiftHive,
    }

    function Hive:UpdateResearch()

        local researchId = self:GetResearchingId()

        if kResearchTypeToHiveType[researchId] then

            local hiveTypeTechId = kResearchTypeToHiveType[researchId]
            local techTree = self:GetTeam():GetTechTree()
            local researchNode = techTree:GetTechNode(hiveTypeTechId)
            researchNode:SetResearchProgress(self.researchProgress)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))

        end

        if researchId == kTechId.ResearchBioMassOne 
                or researchId == kTechId.ResearchBioMassTwo
                or researchId == kTechId.ResearchBioMassThree
                or researchId == kTechId.RecoverBiomassOne
                or researchId == kTechId.RecoverBiomassTwo
                or researchId == kTechId.RecoverBiomassThree
        then
            self.biomassResearchFraction = self:GetResearchProgress()
        end

    end
    
    local baseOnInitialized = Hive.OnInitialized
    function Hive:OnInitialized()
        baseOnInitialized(self)
        local team = self:GetTeam()
        if team then
            team:OnDeadlockExtend(self:GetTechId())
        end
    end
    
    local baseOnKill = Hive.OnKill
    function Hive:OnKill(attacker, doer, point, direction)

        local techId = self:GetTechId()
        if table.contains(kResearchTypeToHiveType,techId) then
            local techTree = self:GetTeam():GetTechTree()
            local researchNode = techTree:GetTechNode(techId)
            researchNode:ClearResearching()
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", 0))
        end
        baseOnKill(self,attacker, doer, point, direction)
    end
    
    local function CreateDrifterEgg(self, comm)

        local mapName = LookupTechData(kTechId.DrifterEgg, kTechDataMapName)
        local direction = Vector(self:GetAngles():GetCoords().zAxis)
        local origin = self:GetOrigin() - direction * 3.2 - self:GetAngles():GetCoords().yAxis * 2.3
        --local extents = GetExtents(kTechId.DrifterEgg)
        --local origin = GetRandomSpawnForCapsule(extents.y, extents.x,self:GetOrigin() - direction * 3.2,0.01,0.5,EntityFilterAll())
        
        local builtEntity = CreateEntity(mapName, origin, self:GetTeamNumber())

        if builtEntity ~= nil then
            builtEntity:SetOwner(comm)
            builtEntity.hatchCallBack = function(drifter)
                if self:GetIsDestroyed() then return end
                drifter.hostHiveID = self:GetId()
                self.spawnedDrifterID = drifter:GetId()
            end 
        end
        
        return builtEntity
    end

    local baseOnCreate = Hive.OnCreate
    function Hive:OnCreate()
        baseOnCreate(self)
        --self.spawnedDrifterID = Entity.invalidId
        --self.freeDrifterCheck = Shared.GetTime()
    end
    
    local baseOnUpdate = Hive.OnUpdate
    function Hive:OnUpdate(deltaTime)
        baseOnUpdate(self,deltaTime)
        --local time = Shared.GetTime()
        --if self.freeDrifterCheck and time - self.freeDrifterCheck < 1 then return end
        --self.freeDrifterCheck = time
        --
        --if not GetGamerules():GetGameStarted() then return end
        --if not CouldUseACommander(self) then return end
        --if self:GetIsInCombat() then return end
        --if not GetIsUnitActive(self) then return end
        --
        --if self.spawnedDrifterID ~= Entity.invalidId then
        --    local drifter = Shared.GetEntity(self.spawnedDrifterID)
        --        if drifter == nil
        --            or (not drifter:isa("Drifter") and not drifter:isa("DrifterEgg") )
        --            or not drifter:GetIsAlive() then
        --        self.spawnedDrifterID = Entity.invalidId
        --    end
        --end
        --
        --if self.spawnedDrifterID == Entity.invalidId then
        --    self.spawnedDrifterID = CreateDrifterEgg(self):GetId()
        --end
    end

end

function Hive:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kHiveHealthPerPlayerAdd * extraPlayers
end



local baseGetCanBeUsedConstructed = Hive.GetCanBeUsedConstructed
function Hive:GetCanBeUsedConstructed(byPlayer)
    if not CouldUseACommander(self) then return end

    return baseGetCanBeUsedConstructed(self,byPlayer)
end

if Client then
    function Hive:OnUpdateRender()
        if not CouldUseACommander(self) then return end
        
        CommandStructure.OnUpdateRender(self)
    end
    
end 