
function MarineTeam:InitTechTree()

    PlayingTeam.InitTechTree(self)

    -- Marine tier 1
    self.techTree:AddBuildNode(kTechId.CommandStation,            kTechId.None,                kTechId.None)

    self.techTree:AddBuildNode(kTechId.StandardStation,                kTechId.CommandStation,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.ArmorStation ,               kTechId.CommandStation,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.ExplosiveStation ,               kTechId.CommandStation,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.ElectronicStation ,               kTechId.CommandStation,                kTechId.None)
    self.techTree:AddTechInheritance(kTechId.CommandStation,kTechId.StandardStation)
    self.techTree:AddTechInheritance(kTechId.CommandStation,kTechId.ExplosiveStation)
    self.techTree:AddTechInheritance(kTechId.CommandStation,kTechId.ArmorStation)
    self.techTree:AddTechInheritance(kTechId.CommandStation,kTechId.ElectronicStation)

    self.techTree:AddBuildNode(kTechId.Extractor,                 kTechId.None,                kTechId.None)
    self.techTree:AddTechInheritance(kTechId.Extractor, kTechId.PoweredExtractor)
    self.techTree:AddBuildNode(kTechId.PoweredExtractor,          kTechId.Extractor,           kTechId.None)

    -- Count recycle like an upgrade so we can have multiples
    self.techTree:AddUpgradeNode(kTechId.Recycle, kTechId.None, kTechId.None)

    self.techTree:AddPassive(kTechId.Welding)
    self.techTree:AddPassive(kTechId.SpawnMarine)

    self.techTree:AddPassive(kTechId.CollectResources, kTechId.Extractor)
    self.techTree:AddPassive(kTechId.Detector)

    self.techTree:AddSpecial(kTechId.TwoCommandStations)
    self.techTree:AddSpecial(kTechId.ThreeCommandStations)

    -- When adding marine upgrades that morph structures, make sure to add to GetRecycleCost() also
    self.techTree:AddBuildNode(kTechId.InfantryPortal,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Sentry,                    kTechId.RoboticsFactory,     kTechId.None, true)
    self.techTree:AddBuildNode(kTechId.Armory,      kTechId.None)
    self.techTree:AddBuildNode(kTechId.ArmsLab,                kTechId.None)
    self.techTree:AddManufactureNode(kTechId.MAC,                 kTechId.RoboticsFactory,                kTechId.None,  true)

    self.techTree:AddBuyNode(kTechId.Pistol,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Rifle,                       kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Axe,                         kTechId.None,                kTechId.None)

    self.techTree:AddBuyNode(kTechId.SubMachineGun,               kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Revolver,                    kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Knife,                       kTechId.None,                kTechId.None)

    self.techTree:AddBuildNode(kTechId.SentryBattery,             kTechId.RoboticsFactory,      kTechId.None)

    self.techTree:AddOrder(kTechId.Defend)
    self.techTree:AddOrder(kTechId.FollowAndWeld)

    -- Commander abilities
    self.techTree:AddTargetedActivation(kTechId.MedPack)--,          kTechId.MilitaryProtocol)
    self.techTree:AddTargetedActivation(kTechId.AmmoPack)--,         kTechId.MilitaryProtocol)

    self.techTree:AddTargetedActivation(kTechId.Scan,             kTechId.Observatory)

    self.techTree:AddAction(kTechId.SelectObservatory)


    -- arms lab upgrades

    self.techTree:AddResearchNode(kTechId.Armor1,                 kTechId.ArmsLab)
    self.techTree:AddResearchNode(kTechId.Armor2,                 kTechId.Armor1, kTechId.None)
    self.techTree:AddResearchNode(kTechId.Armor3,                 kTechId.Armor2, kTechId.None)

    self.techTree:AddResearchNode(kTechId.Weapons1,               kTechId.ArmsLab)
    self.techTree:AddResearchNode(kTechId.Weapons2,               kTechId.Weapons1, kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons3,               kTechId.Weapons2, kTechId.None)

    -- Marine tier 2
    self.techTree:AddBuildNode(kTechId.AdvancedArmory,               kTechId.Armory,        kTechId.None)
    self.techTree:AddResearchNode(kTechId.PhaseTech,                    kTechId.Observatory,        kTechId.None)
    self.techTree:AddResearchNode(kTechId.MotionTrack,                    kTechId.Observatory,        kTechId.None)
    self.techTree:AddBuildNode(kTechId.PhaseGate,                    kTechId.PhaseTech,        kTechId.None, true)

    self.techTree:AddBuildNode(kTechId.Observatory,               kTechId.InfantryPortal,       kTechId.Armory)
    self.techTree:AddActivation(kTechId.DistressBeacon,           kTechId.Observatory)
    self.techTree:AddActivation(kTechId.ReversePhaseGate,         kTechId.None)

    self.techTree:AddResearchNode(kTechId.ShotgunTech,           kTechId.Armory)
    self.techTree:AddTargetedBuyNode(kTechId.Shotgun,            kTechId.ShotgunTech)
    self.techTree:AddTargetedActivation(kTechId.DropShotgun,     kTechId.ShotgunTech)

    --self.techTree:AddResearchNode(kTechId.CombatBuilderTech,kTechId.Armory)

    self.techTree:AddResearchNode(kTechId.MinesTech,            kTechId.Armory)
    self.techTree:AddTargetedBuyNode(kTechId.LayMines,          kTechId.MinesTech)
    self.techTree:AddTargetedActivation(kTechId.DropMines,      kTechId.MinesTech)

    self.techTree:AddResearchNode(kTechId.GrenadeTech,           kTechId.Armory)
    self.techTree:AddTargetedBuyNode(kTechId.ClusterGrenade,          kTechId.Armory,        kTechId.None)     --self.techTree:AddTargetedBuyNode(kTechId.ClusterGrenade,     kTechId.Armory, kTechId.GrenadeTech)
    self.techTree:AddTargetedBuyNode(kTechId.GasGrenade,         kTechId.Armory, kTechId.GrenadeTech)
    self.techTree:AddTargetedBuyNode(kTechId.PulseGrenade,       kTechId.Armory, kTechId.GrenadeTech)

    self.techTree:AddTargetedBuyNode(kTechId.Welder,          kTechId.Armory,        kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropWelder,   kTechId.Armory,        kTechId.None)
    self.techTree:AddTargetedBuyNode(kTechId.CombatBuilder, kTechId.MinesTech)
    self.techTree:AddTargetedActivation(kTechId.DropCombatBuilder,kTechId.MinesTech)

    -- Door actions
    -- self.techTree:AddBuildNode(kTechId.Door, kTechId.None, kTechId.None)
    -- self.techTree:AddActivation(kTechId.DoorOpen)
    -- self.techTree:AddActivation(kTechId.DoorClose)
    -- self.techTree:AddActivation(kTechId.DoorLock)
    -- self.techTree:AddActivation(kTechId.DoorUnlock)

    -- Marine tier 3
    self.techTree:AddUpgradeNode(kTechId.AdvancedArmoryUpgrade,  kTechId.Armory)
    self.techTree:AddTargetedActivation(kTechId.HeavyMachineGunTech,      kTechId.AdvancedArmory,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.AdvancedWeaponry,      kTechId.AdvancedArmory,      kTechId.None)
    -- self.techTree:AddTargetedActivation(kTechId.FlamethrowerTech,      kTechId.AdvancedArmory,      kTechId.None)

    self.techTree:AddTargetedBuyNode(kTechId.GrenadeLauncher, kTechId.AdvancedArmory)
    self.techTree:AddTargetedBuyNode(kTechId.HeavyMachineGun, kTechId.AdvancedArmory)
    self.techTree:AddTargetedBuyNode(kTechId.Flamethrower, kTechId.AdvancedArmory)
    self.techTree:AddTargetedActivation(kTechId.DropGrenadeLauncher,  kTechId.AdvancedArmory,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropHeavyMachineGun,     kTechId.AdvancedArmory,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropFlamethrower,  kTechId.AdvancedArmory,      kTechId.None)

    --Dude
    self.techTree:AddResearchNode(kTechId.MilitaryProtocol,                 kTechId.CommandStation)

    -- Standard
    self.techTree:AddUpgradeNode(kTechId.StandardSupply, kTechId.CommandStation)
    self.techTree:AddTargetedActivation(kTechId.CatPack, kTechId.StandardStation)
    self.techTree:AddResearchNode(kTechId.DragonBreath , kTechId.StandardStation)
    self.techTree:AddPassive(kTechId.LightMachineGunUpgrade , kTechId.StandardStation)
    
    self.techTree:AddBuyNode(kTechId.LightMachineGun,               kTechId.StandardStation)
    self.techTree:AddBuyNode(kTechId.LightMachineGunAcquire,       kTechId.StandardStation)
    
    -- Armor
    self.techTree:AddUpgradeNode(kTechId.ArmorSupply, kTechId.CommandStation)
    self.techTree:AddTargetedActivation(kTechId.NanoShield,kTechId.ArmorStation)
    self.techTree:AddPassive(kTechId.LifeSustain,kTechId.ArmorStation)
    self.techTree:AddResearchNode(kTechId.ArmorRegen,kTechId.ArmorStation)

    --Explosive
    self.techTree:AddUpgradeNode(kTechId.ExplosiveSupply, kTechId.CommandStation)
    self.techTree:AddTargetedActivation(kTechId.MineDeploy, kTechId.ExplosiveStation,kTechId.MinesTech)
    self.techTree:AddPassive(kTechId.MinesUpgrade, kTechId.ExplosiveStation,kTechId.MinesTech)
    self.techTree:AddResearchNode(kTechId.GrenadeLauncherUpgrade,kTechId.ExplosiveStation, kTechId.None)

    --Electronic
    self.techTree:AddUpgradeNode(kTechId.ElectronicSupply, kTechId.CommandStation)
    self.techTree:AddTargetedActivation(kTechId.PowerSurge, kTechId.ElectronicStation)
    self.techTree:AddPassive(kTechId.PoweredExtractorTech,kTechId.ElectronicStation)
    self.techTree:AddUpgradeNode(kTechId.PoweredExtractorUpgrade , kTechId.ElectronicStation)
    self.techTree:AddResearchNode(kTechId.MACEMPBlast,kTechId.ElectronicStation)

    self.techTree:AddBuildNode(kTechId.PrototypeLab,          kTechId.AdvancedArmory,              kTechId.None)


    self.techTree:AddBuildNode(kTechId.JetpackPrototypeLab ,               kTechId.PrototypeLab,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.ExosuitPrototypeLab ,               kTechId.PrototypeLab,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.CannonPrototypeLab ,               kTechId.PrototypeLab,                kTechId.None)
    self.techTree:AddTechInheritance(kTechId.PrototypeLab,kTechId.JetpackPrototypeLab)
    self.techTree:AddTechInheritance(kTechId.PrototypeLab,kTechId.ExosuitPrototypeLab)
    self.techTree:AddTechInheritance(kTechId.PrototypeLab,kTechId.CannonPrototypeLab)
    
    -- Jetpack
    self.techTree:AddUpgradeNode(kTechId.JetpackProtoUpgrade,           kTechId.PrototypeLab)
    self.techTree:AddTargetedActivation(kTechId.JetpackTech,      kTechId.JetpackPrototypeLab,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropJetpack,    kTechId.JetpackPrototypeLab,      kTechId.None)
    self.techTree:AddBuyNode(kTechId.Jetpack,                    kTechId.JetpackPrototypeLab)
    --self.techTree:AddResearchNode(kTechId.JetpackFuelTech,           kTechId.JetpackTech)

    --Cannon
    self.techTree:AddUpgradeNode(kTechId.CannonProtoUpgrade,           kTechId.PrototypeLab)
    self.techTree:AddTargetedActivation(kTechId.CannonTech,      kTechId.CannonPrototypeLab,      kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropCannon, kTechId.CannonPrototypeLab)
    self.techTree:AddBuyNode(kTechId.Cannon,   kTechId.CannonPrototypeLab)

    -- Exosuit
    self.techTree:AddUpgradeNode(kTechId.ExosuitProtoUpgrade,           kTechId.PrototypeLab)
    self.techTree:AddTargetedActivation(kTechId.ExosuitTech,      kTechId.ExosuitProtoUpgrade,      kTechId.None)
    self.techTree:AddBuyNode(kTechId.DualMinigunExosuit, kTechId.ExosuitPrototypeLab, kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DropDualMinigunExosuit,     kTechId.ExosuitPrototypeLab, kTechId.None)
    self.techTree:AddBuyNode(kTechId.DualRailgunExosuit, kTechId.ExosuitPrototypeLab, kTechId.CannonPrototypeLab)
    self.techTree:AddTargetedActivation(kTechId.DropDualRailgunExosuit,     kTechId.ExosuitPrototypeLab, kTechId.CannonPrototypeLab)
    
    -- Robotics factory menus
    self.techTree:AddMenu(kTechId.RoboticsFactoryARCUpgradesMenu)
    self.techTree:AddMenu(kTechId.RoboticsFactoryMACUpgradesMenu)

    self.techTree:AddMenu(kTechId.WeaponsMenu)
    self.techTree:AddMenu(kTechId.ProtosMenu)

    -- ARCs
    self.techTree:AddBuildNode(kTechId.RoboticsFactory,                    kTechId.InfantryPortal,    kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeRoboticsFactory,           kTechId.None,              kTechId.RoboticsFactory)
    self.techTree:AddBuildNode(kTechId.ARCRoboticsFactory,                 kTechId.None,              kTechId.RoboticsFactory)

    self.techTree:AddTechInheritance(kTechId.RoboticsFactory, kTechId.ARCRoboticsFactory)

    self.techTree:AddManufactureNode(kTechId.ARC,    kTechId.ARCRoboticsFactory,     kTechId.None, true)
    self.techTree:AddActivation(kTechId.ARCDeploy)
    self.techTree:AddActivation(kTechId.ARCUndeploy)

    --self.techTree:AddResearchNode(kTechId.DualMinigunTech,       kTechId.ExosuitTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.DualMinigunExosuit,    kTechId.DualMinigunTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.ClawRailgunExosuit,    kTechId.ExosuitTech, kTechId.None)
    --self.techTree:AddResearchNode(kTechId.DualRailgunTech,       kTechId.ExosuitTech, kTechId.TwoCommandStations)
    --self.techTree:AddResearchNode(kTechId.DualRailgunExosuit,    kTechId.DualMinigunTech, kTechId.TwoCommandStations)

    self.techTree:AddActivation(kTechId.SocketPowerNode,    kTechId.None,   kTechId.None)

    self.techTree:SetComplete()

    self.militaryProtocolTechNode = self.techTree:GetTechNode(kTechId.MilitaryProtocol)
    self.motionTrackTechNode = self.techTree:GetTechNode(kTechId.MotionTrack)
end


local baseOnInitialize = MarineTeam.Initialize
function MarineTeam:Initialize(teamName, teamNumber)
    self.clientOwnedStructures = { }
    self.timeLastMotionTrack = 0
    baseOnInitialize(self, teamName, teamNumber)
end


local function TickMotionTrack(self)

    if not self.motionTrackTechNode:GetResearched() then return end
    
    local now = Shared.GetTime()
    if now - self.timeLastMotionTrack < kMotionTrackInterval then return end
    self.timeLastMotionTrack = now
    
    for _, alien in ipairs(GetEntitiesForTeam("Alien", GetEnemyTeamNumber(self:GetTeamNumber()))) do
        if alien.SetDetected 
            and alien:GetVelocity():GetLength() > kMotionTrackMinSpeed     --Only track active ones
            and not GetHasCamouflageUpgrade(alien)      --Won't track camouflaged aliens
        then
            alien:SetDetected(true)
        end
    end
    
end

local baseUpdate = MarineTeam.Update
function MarineTeam:Update(timePassed)
    baseUpdate(self,timePassed)
    TickMotionTrack(self)
end

function MarineTeam:OnTeamKill(techId, bountyScore)

    local pRes = PlayingTeam.OnTeamKill(self,techId, bountyScore)
    if self.militaryProtocolTechNode:GetResearched() then
        local tRes = kMilitaryProtocolTeamResourcesPerKill[techId] or 0
        if tRes > 0 then
            self:AddTeamResources(tRes)  
        end
        
        pRes = pRes + (kMilitaryProtocolPlayerResourcesPerKill[techId] or 0)
    end
    
    return pRes
end

function MarineTeam:CollectTeamResources(teamRes,playerRes)
    if self.militaryProtocolTechNode:GetResearched() then
        playerRes = 0   --No player res now
    end

    PlayingTeam.CollectTeamResources(self,teamRes,playerRes)
end

function MarineTeam:GetResearchTimeFactor()
    return self.militaryProtocolTechNode:GetResearched() and kMilitaryProtocolResearchDurationMultiply or 1
end

function MarineTeam:ShouldHandleManualAlert()            --He can handle it himself
    return not self.militaryProtocolTechNode:GetResearched()
end

function MarineTeam:OnResearchComplete(structure, researchId)
    PlayingTeam.OnResearchComplete(self,structure,researchId)

    if researchId ~= kTechId.MilitaryProtocol then return end

    local gameInfo = GetGameInfoEntity()
    local teamIdx = self:GetTeamNumber()
    local commStructSkin = kMarineStructureVariants.Chroma
    local commExtractorSkin = kExtractorVariants.Chroma
    local commMacSkin = kMarineMacVariants.Chroma
    local commArcSkin = kMarineArcVariants.Chroma

    self.activeStructureSkin = commStructSkin
    local skinnedEnts = GetEntitiesWithMixinForTeam( "MarineStructureVariant", teamIdx )
    for i, ent in ipairs(skinnedEnts) do
        ent.structureVariant = commStructSkin
        ent:TriggerEffects("spawn", {effecthostcoords = ent:GetCoords()} )
    end
    gameInfo:SetTeamCosmeticSlot( teamIdx, kTeamCosmeticSlot1, commStructSkin )

    self.activeExtractorSkin = commExtractorSkin
    local skinnedEnts = GetEntitiesWithMixinForTeam( "ExtractorVariant", teamIdx )
    for i, ent in ipairs(skinnedEnts) do
        ent.structureVariant = commExtractorSkin
        ent:TriggerEffects("spawn", {effecthostcoords = ent:GetCoords()} )
    end
    gameInfo:SetTeamCosmeticSlot( teamIdx, kTeamCosmeticSlot2, commExtractorSkin )

    self.activeMacSkin = commMacSkin
    local skinnedEnts = GetEntitiesWithMixinForTeam( "MACVariant", teamIdx )
    for i, ent in ipairs(skinnedEnts) do
        ent.structureVariant = commMacSkin
        ent:TriggerEffects("spawn", {effecthostcoords = ent:GetCoords()} )
    end
    gameInfo:SetTeamCosmeticSlot( teamIdx, kTeamCosmeticSlot3, commMacSkin )

    self.activeArcSkin = commArcSkin
    local skinnedEnts = GetEntitiesWithMixinForTeam( "ARCVariant", teamIdx )
    for i, ent in ipairs(skinnedEnts) do
        ent.structureVariant = commArcSkin
        ent:TriggerEffects("spawn", {effecthostcoords = ent:GetCoords()} )
    end
    gameInfo:SetTeamCosmeticSlot( teamIdx, kTeamCosmeticSlot4, commArcSkin )
end

local cancelTechNode
local function DestroyMarineStructure(self,structure)
    if not cancelTechNode then
        cancelTechNode = self:GetTechTree():GetTechNode(kTechId.Cancel)
    end

    if structure:GetIsGhostStructure() then
        structure:PerformAction(cancelTechNode)
    elseif structure:GetCanDie() then
        structure.recycled = true
        structure:Kill()
    else
        DestroyEntity(structure)
    end
end

local baseOnResetComplete = MarineTeam.OnResetComplete
function MarineTeam:OnResetComplete()
    baseOnResetComplete(self)

    local locations = GetLocations()
    local initialTechPoint = self:GetInitialTechPoint()
    local initialTechPointName = initialTechPoint:GetLocationName()
    local locationGraph = GetLocationGraph()

    local resourcePoints = EntityListToTable(Shared.GetEntitiesWithClassname("ResourcePoint"))
    local resourceLocationNames = {}
    for i=1, #resourcePoints do
        local resourcePoint = resourcePoints[i]
        local location = GetLocationForPoint(resourcePoint:GetOrigin())
        if location then
            local resourcePointName = location:GetName()
            if not table.icontains(resourceLocationNames,resourcePointName) then
                table.insert(resourceLocationNames,resourcePointName)
            end
        end
    end

    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    for i = 1, 100 do math.random() end

    local locationsWithoutTechPoint = {}

    for i=1, #locations do
        local locationName = locations[i]:GetName()

        if locationGraph.techPointLocations:Contains(locationName) then
            if locationName == initialTechPointName then
                GetPowerPointForLocation(locationName):SetConstructionComplete()
            else
                DestroyPowerForLocation(locationName, true)
            end
        else
            if not table.icontains(locationsWithoutTechPoint,locationName) then
                table.insert(locationsWithoutTechPoint,locationName)
            end
        end
    end

    local locationsWithoutTechPointCount = table.count(locationsWithoutTechPoint)
    local destroyCount = math.floor(locationsWithoutTechPointCount * 0.3)
    table.shuffle(locationsWithoutTechPoint)
    for i = 1, locationsWithoutTechPointCount do
        local locationName = table.remove(locationsWithoutTechPoint)
        if i <= destroyCount then
            DestroyPowerForLocation(locationName, true)
        elseif not table.icontains(resourceLocationNames,locationName) then
            local powerPoint = GetPowerPointForLocation(locationName)
            if  powerPoint then
                powerPoint:SetConstructionComplete()
            end
        end
    end
end

local function RemoveMarineStructureFromClient(self, techId, clientId)

    local structureTypeTable = self.clientOwnedStructures[clientId]

    if structureTypeTable then

        if not structureTypeTable[techId] then

            structureTypeTable[techId] = { }
            return

        end

        local removeIndex = 0
        local structure = nil
        for index, id in ipairs(structureTypeTable[techId])  do

            if id then

                removeIndex = index
                structure = Shared.GetEntity(id)
                break

            end

        end

        if structure then

            -- Shared.Message("remove" .. tostring(structure:GetId()))
            table.remove(structureTypeTable[techId], removeIndex)

            DestroyMarineStructure(self,structure)
        end

    end

end

function MarineTeam:AddMarineStructure(player, structure,maxStructures)

    if player ~= nil and structure ~= nil then

        local clientId = Server.GetOwner(player):GetUserId()
        local structureId = structure:GetId()
        local techId = structure:GetTechId()

        if not self.clientOwnedStructures[clientId] then
            self.clientOwnedStructures[clientId] = { }
        end

        local structureTypeTable = self.clientOwnedStructures[clientId]

        if not structureTypeTable[techId] then
            structureTypeTable[techId] = { }
        end

        -- Shared.Message("insert" .. tostring(structureId))
        table.insertunique(structureTypeTable[techId], structureId)

        if maxStructures >= 0 and table.count(structureTypeTable[techId]) > maxStructures then
            RemoveMarineStructureFromClient(self, techId, clientId)
        end

    end
end

function MarineTeam:ClearMarineStructure(player)

    local clientId = Server.GetOwner(player):GetUserId()
    local clientTypedStructures = self.clientOwnedStructures[clientId]

    if not clientTypedStructures then
        return
    end

    for techId, structureList in pairs(clientTypedStructures) do
        local count = table.count(structureList)
        while count > 0 do      -- Why can't I simply use pairs?????????????
            for i, structureId in pairs(structureList) do

                table.remove(structureList,structureId)
                count = count-1
                local structure = structureId and Shared.GetEntity(structureId)
                if structure then
                    DestroyMarineStructure(self,structure)
                end
            end
        end
    end

    self.clientOwnedStructures[clientId]=nil
end


function MarineTeam:GetDroppedMarineStructures(player, techId)

    local owner = Server.GetOwner(player)

    if owner then

        local clientId = owner:GetUserId()
        local structureTypeTable = self.clientOwnedStructures[clientId]

        if structureTypeTable then
            return structureTypeTable[techId]
        end

    end

end

function MarineTeam:GetNumDroppedMarineStructures(player, techId)

    local structureTypeTable = self:GetDroppedMarineStructures(player, techId)
    return (not structureTypeTable and 0) or #structureTypeTable

end

function MarineTeam:UpdateClientOwnedStructures(oldEntityId)

    if oldEntityId then

        for clientId, structureTypeTable in pairs(self.clientOwnedStructures) do

            for techId, structureList in pairs(structureTypeTable) do

                for i, structureId in ipairs(structureList) do

                    if structureId == oldEntityId then

                        table.remove(structureList, i)
                        break

                    end

                end

            end

        end

    end

end


function MarineTeam:OnEntityChange(oldEntityId, newEntityId)

    PlayingTeam.OnEntityChange(self, oldEntityId, newEntityId)

    -- Check if the oldEntityId matches any client's built structure and
    -- handle the change.

    self:UpdateClientOwnedStructures(oldEntityId)

end