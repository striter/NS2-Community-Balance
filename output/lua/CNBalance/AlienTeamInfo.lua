-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/AlienTeamInfo.lua
--
-- AlienTeamInfo is used to sync information about a team to clients.
-- Only alien team players (and spectators) will receive the information about number
-- of shells, spurs or veils.
--
-- Created by Andreas Urwalek (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/TeamInfo.lua")
Script.Load("lua/AlienTunnelManager.lua")

class 'AlienTeamInfo' (TeamInfo)

AlienTeamInfo.kMapName = "AlienTeamInfo"

AlienTeamInfo.kLocationEntityTypes = { "Hive", "Spur", "Veil", "Shell", "Egg" }
AlienTeamInfo.kLifeformEntityTypes = {"Skulk","Prowler","Fade","Onos","Gorge","Lerk"}


local networkVars =
{
    isOriginForm = "boolean",
    canEvolveOriginForm = "boolean",
    
    numHives = "integer (0 to 10)",
    eggCount = "integer (0 to 120)",
    bioMassLevel = "integer (0 to 12)",
    bioMassAlertLevel = "integer (0 to 12)",
    maxBioMassLevel = "integer (0 to 12)",
    veilLevel = "integer (0 to 3)",
    spurLevel = "integer (0 to 3)",
    shellLevel = "integer (0 to 3)",
    
    shiftCount = "integer(0 to 32)",
    shadeCount = "integer(0 to 32)",
    cragCount = "integer(0 to 32)",
    shiftHiveBiomassPreserve = "integer (0 to 4)",
    shadeHiveBiomassPreserve = "integer (0 to 4)",
    cragHiveBiomassPreserve = "integer (0 to 4)",
    
    location1Id = "entityid",
    location2Id = "entityid",
    location3Id = "entityid",
    location4Id = "entityid",
    location5Id = "entityid",
    
    commanderLocationId = "entityid",
    commanderClassType = "integer (0 to 6)", --6 bit
    
    teamSkulkCount = "integer (0 to 32)",
    teamGorgeCount = "integer (0 to 32)",
    teamLerkCount = "integer (0 to 32)",
    teamFadeCount = "integer (0 to 32)",
    teamOnosCount ="integer (0 to 32)",
    teamProwlerCount = "integer (0 to 32)",
    
    location1EggCount = "integer (0 to 50)", --6 bits ea
    location2EggCount = "integer (0 to 50)",
    location3EggCount = "integer (0 to 50)",
    location4EggCount = "integer (0 to 50)",
    location5EggCount = "integer (0 to 50)",
    --Above is 30 bits per tick...
    
    location1EggsInCombat = "boolean",
    location2EggsInCombat = "boolean",
    location3EggsInCombat = "boolean",
    location4EggsInCombat = "boolean",
    location5EggsInCombat = "boolean",
    --5 bits per tick
    
    location1HiveBuilt = "float (0 to 1 by 0.01)", --5 bits ea
    location1HiveHealthScalar = "float (0 to 1 by 0.0625)", --5 bits ea
    location1HiveMaxHealth = string.format("integer (0 to %d)", LiveMixin.kMaxHealth + LiveMixin.kMaxArmor * kHealthPointsPerArmor), --13 bits
    location1HiveFlag = "integer (0 to 5)", --4 bits ea
    location1HiveInCombat = "boolean",
    
    location2HiveBuilt = "float (0 to 1 by 0.01)",
    location2HiveHealthScalar = "float (0 to 1 by 0.0625)",
    location2HiveMaxHealth = string.format("integer (0 to %d)", LiveMixin.kMaxHealth + LiveMixin.kMaxArmor * kHealthPointsPerArmor),
    location2HiveFlag = "integer (0 to 5)",
    location2HiveInCombat = "boolean",
    
    location3HiveBuilt = "float (0 to 1 by 0.01)",
    location3HiveHealthScalar = "float (0 to 1 by 0.0625)",
    location3HiveMaxHealth = string.format("integer (0 to %d)", LiveMixin.kMaxHealth + LiveMixin.kMaxArmor * kHealthPointsPerArmor),
    location3HiveFlag = "integer (0 to 5)",
    location3HiveInCombat = "boolean",
    
    location4HiveBuilt = "float (0 to 1 by 0.01)",
    location4HiveHealthScalar = "float (0 to 1 by 0.0625)",
    location4HiveMaxHealth = string.format("integer (0 to %d)", LiveMixin.kMaxHealth + LiveMixin.kMaxArmor * kHealthPointsPerArmor),
    location4HiveFlag = "integer (0 to 5)",
    location4HiveInCombat = "boolean",
    
    location5HiveBuilt = "float (0 to 1 by 0.01)",
    location5HiveHealthScalar = "float (0 to 1 by 0.0625)",
    location5HiveMaxHealth = string.format("integer (0 to %d)", LiveMixin.kMaxHealth + LiveMixin.kMaxArmor * kHealthPointsPerArmor),
    location5HiveFlag = "integer (0 to 5)",
    location5HiveInCombat = "boolean",

    tunnelManagerId = "entityid",
    --70 total, 20 bits for Flags, 25 for health scalar
    
    --190 addition bits per tick ...this is TOO much (roughly 23 bytes per alien player, per server tick)
}
    --[[
    location1ShellCount = "integer (0 to 8)", --4 bits ea
    location1SpurCount = "integer (0 to 8)",
    location1VeilCount = "integer (0 to 8)",
    
    location2ShellCount = "integer (0 to 8)",
    location2SpurCount = "integer (0 to 8)",
    location2VeilCount = "integer (0 to 8)",
    
    location3ShellCount = "integer (0 to 8)",
    location3SpurCount = "integer (0 to 8)",
    location3VeilCount = "integer (0 to 8)",
    
    location4ShellCount = "integer (0 to 8)",
    location4SpurCount = "integer (0 to 8)",
    location4VeilCount = "integer (0 to 8)",
    
    location5ShellCount = "integer (0 to 8)",
    location5SpurCount = "integer (0 to 8)",
    location5VeilCount = "integer (0 to 8)",
    --60 bits for above
    --]]

function AlienTeamInfo:OnCreate()

    TeamInfo.OnCreate(self)
    
    self.numHives = 0
    self.eggCount = 0
    self.bioMassLevel = 0
    self.bioMassAlertLevel = 0
    self.maxBioMassLevel = 0
    self.shiftHiveBiomassPreserve = 0
    self.shadeHiveBiomassPreserve = 0
    self.cragHiveBiomassPreserve = 0
    
    self.veilLevel = 0
    self.spurLevel = 0
    self.shellLevel = 0
    self.shiftCount = 0
    self.shadeCount = 0
    self.cragCount = 0
    
    self.location1Id = Entity.invalidId
    self.location2Id = Entity.invalidId
    self.location3Id = Entity.invalidId
    self.location4Id = Entity.invalidId
    self.location5Id = Entity.invalidId
    
    self.commanderLocationId = Entity.invalidId
    self.commanderClassType = 0
    
    self.location1EggCount = 0
    self.location2EggCount = 0
    self.location3EggCount = 0
    self.location4EggCount = 0
    self.location5EggCount = 0
    
    self.location1EggsInCombat = false
    self.location2EggsInCombat = false
    self.location3EggsInCombat = false
    self.location4EggsInCombat = false
    self.location5EggsInCombat = false
    --[[
    self.location1ShellCount = 0
    self.location1SpurCount = 0
    self.location1VeilCount = 0
    
    self.location2ShellCount = 0
    self.location2SpurCount = 0
    self.location2VeilCount = 0
    
    self.location3ShellCount = 0
    self.location3SpurCount = 0
    self.location3VeilCount = 0
    
    self.location4ShellCount = 0
    self.location4SpurCount = 0
    self.location4VeilCount = 0
    --]]
    self.location1HiveBuilt = 0
    self.location1HiveHealthScalar = 0
    self.location1HiveMaxHealth = 0
    self.location1HiveFlag = 0
    self.location1HiveInCombat = false
    
    self.location2HiveBuilt = 0
    self.location2HiveHealthScalar = 0
    self.location2HiveMaxHealth = 0
    self.location2HiveFlag = 0
    self.location2HiveInCombat = false
    
    self.location3HiveBuilt = 0
    self.location3HiveHealthScalar = 0
    self.location3HiveMaxHealth = 0
    self.location3HiveFlag = 0
    self.location3HiveInCombat = false
    
    self.location4HiveBuilt = 0
    self.location4HiveHealthScalar = 0
    self.location4HiveMaxHealth = 0
    self.location4HiveFlag = 0
    self.location4HiveInCombat = false
    
    self.location5HiveBuilt = 0
    self.location5HiveHealthScalar = 0
    self.location5HiveMaxHealth = 0
    self.location5HiveFlag = 0
    self.location5HiveInCombat = false

    self.tunnelManagerId = Entity.invalidId
    self.originForm = false
end

function AlienTeamInfo:OnInitialized()
    
    TeamInfo.OnInitialized(self)
    
    if Server then
        
        local techPoints = GetEntitiesMatchAnyTypes( { "TechPoint" } )
        local tpLocations = table.array(5)  --TODO Add global slot limiter
        
        if techPoints then
            for _, techPoint in ipairs(techPoints) do
                table.insert( tpLocations, techPoint.locationId )
            end
            
            self.location1Id = tpLocations[1]
            self.location2Id = tpLocations[2]
            self.location3Id = tpLocations[3]
            self.location4Id = tpLocations[4]
            self.location5Id = tpLocations[5]
        end
    end
    
    if Client then
    
        -- Notify GUI system when the alien team's egg count changes.
        self:AddFieldWatcher("eggCount",
            function(self2)
                GetGlobalEventDispatcher():FireEvent("OnEggCountChanged", self2.eggCount)
                return true
            end)
    
    end
    
end

function AlienTeamInfo:OnDestroy()
    TeamInfo.OnDestroy(self)

    local tunnelManager = self:GetTunnelManager()
    if tunnelManager then
        self.tunnelManagerId = nil
        DestroyEntity(tunnelManager)
    end
end

function AlienTeamInfo:SetWatchTeam(team)
    if team == self.team or not team then return end

    TeamInfo.SetWatchTeam(self, team)

    if Server then
        local teamNumber = self:GetTeamNumber()
        local tunnelManager = CreateEntity( "alientunnelmanager", Vector(100,100,100), teamNumber)
        tunnelManager:SetParent(self)

        tunnelManager:SetRelevancyDistance(Math.infinity)
        local mask = 0
        if teamNumber == kTeam1Index then
            mask = kRelevantToTeam1Commander
        elseif teamNumber == kTeam2Index then
            mask = kRelevantToTeam2Commander
        end
        tunnelManager:SetExcludeRelevancyMask(mask)

        self.tunnelManagerId = tunnelManager:GetId()
    end

end

function AlienTeamInfo:GetTunnelManager()
    if self.tunnelManagerId ~= Entity.invalidId then
        return Shared.GetEntity(self.tunnelManagerId)
    end
end

if Server then

    local function GetBuiltStructureCount(className, teamNum, locationId)
        local count = 0
        for _, structure in ipairs(GetEntitiesForTeam(className, teamNum)) do
            if structure:GetIsBuilt() and structure:GetIsAlive() then
                if locationId ~= nil then
                    if structure.locationId == locationId then
                        count = count + 1
                    end
                else
                    count = count + 1
                end
            end
        end
        
        return count
    end
    
    function AlienTeamInfo:Reset()
    
		TeamInfo.Reset( self ) 
		
        self.numHives = 0
        self.eggCount = 0
        self.bioMassLevel = 0
        self.bioMassAlertLevel = 0
        self.maxBioMassLevel = 0
        self.veilLevel = 0
        self.spurLevel = 0
        self.shellLevel = 0

        self.shiftHiveBiomassPreserve = 0
        self.shadeHiveBiomassPreserve = 0
        self.cragHiveBiomassPreserve = 0
        
        self.location1Id = Entity.invalidId
        self.location2Id = Entity.invalidId
        self.location3Id = Entity.invalidId
        self.location4Id = Entity.invalidId
        self.location5Id = Entity.invalidId
        
        self:ResetAllLocationSlotsData()
        
        local techPoints = GetEntitiesMatchAnyTypes( { "TechPoint" } )
        local tpLocations = table.array(5)  --TODO Add global slot limiter
        if techPoints then
            for _, techPoint in ipairs(techPoints) do
                table.insert( tpLocations, techPoint.locationId )
            end
            
            self.location1Id = tpLocations[1]
            self.location2Id = tpLocations[2]
            self.location3Id = tpLocations[3]
            self.location4Id = tpLocations[4]
            self.location5Id = tpLocations[5]
        end
        
    end
    
    function AlienTeamInfo:OnUpdate(deltaTime)
    
        TeamInfo.OnUpdate(self, deltaTime)
        
        local team = self:GetTeam()
        if team then    --???? How would there never be a team?
        
            self.isOriginForm = team:IsOriginForm()
            self.canEvolveOriginForm = team:CanEvolveOriginForm()
            self.numHives = team:GetNumHives()
            self.eggCount = team:GetActiveEggCount()
            self.maxBioMassLevel = Clamp(team:GetMaxBioMassLevel(), 0 , 12)

            if GetWarmupActive() then
                self.bioMassLevel = 12
                self.bioMassAlertLevel = 12
                self.veilLevel = 3
                self.spurLevel = 3
                self.shellLevel = 3
                self.shiftHiveBiomassPreserve = 4
                self.shadeHiveBiomassPreserve = 4
                self.cragHiveBiomassPreserve = 4
            else
                self.bioMassLevel = Clamp(team:GetBioMassLevel(), 0, 12)
                self.bioMassAlertLevel = Clamp(team:GetBioMassAlertLevel(), 0 , 12)
                self.shiftHiveBiomassPreserve = team:GetBioMassPreserve(kTechId.ShiftHive)
                self.shadeHiveBiomassPreserve = team:GetBioMassPreserve(kTechId.ShadeHive)
                self.cragHiveBiomassPreserve = team:GetBioMassPreserve(kTechId.CragHive)
                self.veilLevel = Clamp(GetBuiltStructureCount("Veil", team:GetTeamNumber()), 0, 3)
                self.spurLevel = Clamp(GetBuiltStructureCount("Spur", team:GetTeamNumber()), 0, 3)
                self.shellLevel = Clamp(GetBuiltStructureCount("Shell", team:GetTeamNumber()), 0, 3)
                self.shiftCount = GetBuiltStructureCount("Shift", team:GetTeamNumber())
                self.shadeCount = GetBuiltStructureCount("Shade", team:GetTeamNumber())
                self.cragCount = GetBuiltStructureCount("Crag", team:GetTeamNumber())
            end
        end
        
        self:ResetAllLocationSlotsData()
        self:UpdateCommanderData()
        self:UpdateAllLocationsSlotData()
        
        self:UpdateLifeformsData()
        
    end
    
    function AlienTeamInfo:UpdateCommanderData()
        
        local team = self:GetTeam()
        if team then
            local commander = team:GetCommander()
            if commander and commander.previousMapName ~= nil then

                --Type: 0-No Kham, 1-Skulk, 2-Gorge, 3-Lerk, 4-Fade, 5-Onos 6-Prowler
                if commander.previousMapName == "onos" then
                    self.commanderClassType = 1
                elseif commander.previousMapName == "fade" then
                    self.commanderClassType = 2
                elseif commander.previousMapName == "lerk" then
                    self.commanderClassType = 3
                elseif commander.previousMapName == "gorge" then
                    self.commanderClassType = 4
                elseif commander.previousMapName == "prowler" then
                    self.commanderClassType = 6
                else
                    self.commanderClassType = 5
                end
                self.commanderLocationId = commander.locationId

            else
                self.commanderLocationId = Entity.invalidId
                self.commanderClassType = 0
            end
        end
        
    end
    
    function AlienTeamInfo:ResetAllLocationSlotsData()
        
        self.commanderLocationId = Entity.invalidId
        self.commanderClassType = 0
        
        self.location1EggCount = 0
        self.location2EggCount = 0
        self.location3EggCount = 0
        self.location4EggCount = 0
        self.location5EggCount = 0
        
        self.location1EggsInCombat = false
        self.location2EggsInCombat = false
        self.location3EggsInCombat = false
        self.location4EggsInCombat = false
        self.location5EggsInCombat = false
        --[[
        self.location1ShellCount = 0
        self.location1SpurCount = 0
        self.location1VeilCount = 0
        
        self.location2ShellCount = 0
        self.location2SpurCount = 0
        self.location2VeilCount = 0
        
        self.location3ShellCount = 0
        self.location3SpurCount = 0
        self.location3VeilCount = 0
        
        self.location4ShellCount = 0
        self.location4SpurCount = 0
        self.location4VeilCount = 0
        
        self.location5ShellCount = 0
        self.location5SpurCount = 0
        self.location5VeilCount = 0
        --]]
        
        self.location1HiveBuilt = 0
        self.location1HiveHealthScalar = 0
        self.location1HiveMaxHealth = 0
        self.location1HiveFlag = 0
        self.location1HiveInCombat = false
        
        self.location2HiveBuilt = 0
        self.location2HiveHealthScalar = 0
        self.location2HiveMaxHealth = 0
        self.location2HiveFlag = 0
        self.location2HiveInCombat = false
        
        self.location3HiveBuilt = 0
        self.location3HiveHealthScalar = 0
        self.location3HiveMaxHealth = 0
        self.location3HiveFlag = 0
        self.location3HiveInCombat = false
        
        self.location4HiveBuilt = 0
        self.location4HiveHealthScalar = 0
        self.location4HiveMaxHealth = 0
        self.location4HiveFlag = 0
        self.location4HiveInCombat = false
        
        self.location5HiveBuilt = 0
        self.location5HiveHealthScalar = 0
        self.location5HiveMaxHealth = 0
        self.location5HiveFlag = 0
        self.location5HiveInCombat = false
        
    end
    
    function AlienTeamInfo:UpdateLocationEggCounts( locationId, inCombat )
        
        assert( type(locationId) == "number" )
        assert( type(inCombat) == "boolean" )
        
        if locationId == self.location1Id then
            self.location1EggCount = self.location1EggCount + 1
            self.location1EggsInCombat = inCombat or self.location1EggsInCombat
        elseif locationId == self.location2Id then
            self.location2EggCount = self.location2EggCount + 1
            self.location2EggsInCombat = inCombat or self.location2EggsInCombat
        elseif locationId == self.location3Id then
            self.location3EggCount = self.location3EggCount + 1
            self.location3EggsInCombat = inCombat or self.location3EggsInCombat
        elseif locationId == self.location4Id then
            self.location4EggCount = self.location4EggCount + 1
            self.location4EggsInCombat = inCombat or self.location4EggsInCombat
        elseif locationId == self.location5Id then
            self.location5EggCount = self.location5EggCount + 1
            self.location5EggsInCombat = inCombat or self.location5EggsInCombat
        end
        
        --Any of the desired ent-types can exist outside of techpoint locations
        --so, no errors when called and outside of location[id] bound
    end
    
    function AlienTeamInfo:UpdateLocationSlotHiveData( locationId, type, buildScalar, healthScalar, maxHealth, inCombat )
        
        -- 0-None, 1-Unbuilt, 2-Normal, 3-CragHive, 4-ShadeHive, 5-ShiftHive
        local hiveFlag = 0
        if type == kTechId.ShiftHive then
            hiveFlag = 3
        elseif type == kTechId.CragHive then
            hiveFlag = 4
        elseif type == kTechId.ShadeHive then
            hiveFlag = 5
        elseif buildScalar == 1 then
            hiveFlag = 2
        else
            hiveFlag = 1
        end
        
        if locationId == self.location1Id then
            self.location1HiveFlag = hiveFlag
            self.location1HiveHealthScalar = healthScalar
            self.location1HiveMaxHealth = maxHealth
            self.location1HiveBuilt = buildScalar
            self.location1HiveInCombat = inCombat
        elseif locationId == self.location2Id then
            self.location2HiveFlag = hiveFlag
            self.location2HiveHealthScalar = healthScalar
            self.location2HiveMaxHealth = maxHealth
            self.location2HiveBuilt = buildScalar
            self.location2HiveInCombat = inCombat
        elseif locationId == self.location3Id then
            self.location3HiveFlag = hiveFlag
            self.location3HiveHealthScalar = healthScalar
            self.location3HiveMaxHealth = maxHealth
            self.location3HiveBuilt = buildScalar
            self.location3HiveInCombat = inCombat
        elseif locationId == self.location4Id then
            self.location4HiveFlag = hiveFlag
            self.location4HiveHealthScalar = healthScalar
            self.location4HiveMaxHealth = maxHealth
            self.location4HiveBuilt = buildScalar
            self.location4HiveInCombat = inCombat
        elseif locationId == self.location5Id then
            self.location5HiveFlag = hiveFlag
            self.location5HiveHealthScalar = healthScalar
            self.location5HiveMaxHealth = maxHealth
            self.location5HiveBuilt = buildScalar
            self.location5HiveInCombat = inCombat
        end
        
    end
    
    function AlienTeamInfo:UpdateAllLocationsSlotData()
        
        local statusEnts = GetEntitiesMatchAnyTypesForTeam( AlienTeamInfo.kLocationEntityTypes, kTeam2Index )
        
        for _, entity in ipairs(statusEnts) do
            
            if entity:GetIsAlive() then
                if entity:isa("Hive") then
                    self:UpdateLocationSlotHiveData( 
                        entity.locationId, 
                        entity:GetTechId(), 
                        entity:GetBuiltFraction(), 
                        entity:GetHealthScalar(),
                        entity:GetMaxHealth(),
                        entity:GetIsInCombat()
                    )
                elseif entity:isa("Egg") then
                    self:UpdateLocationEggCounts( entity.locationId, entity:GetIsInCombat() )
                end
            end
            
        end
        
    end
    
    function AlienTeamInfo:UpdateLifeformsData()

        self.teamSkulkCount = 0
        self.teamGorgeCount = 0
        self.teamProwlerCount = 0
        self.teamLerkCount = 0
        self.teamFadeCount = 0
        self.teamOnosCount = 0

        local lifeformEntities = GetEntitiesMatchAnyTypesForTeam( AlienTeamInfo.kLifeformEntityTypes, kTeam2Index )

        for _, entity in ipairs(lifeformEntities) do
            if entity:isa("Skulk") and entity:GetIsAlive() then
                self.teamSkulkCount = self.teamSkulkCount + 1
            elseif entity:isa("Gorge") and entity:GetIsAlive() then
                self.teamGorgeCount = self.teamGorgeCount + 1
            elseif entity:isa("Prowler") and entity:GetIsAlive() then
                self.teamProwlerCount = self.teamProwlerCount + 1
            elseif entity:isa("Lerk") and entity:GetIsAlive() then
                self.teamLerkCount = self.teamLerkCount + 1
            elseif entity:isa("Fade") and entity:GetIsAlive() then
                self.teamFadeCount = self.teamFadeCount + 1
            elseif entity:isa("Onos") and entity:GetIsAlive() then
                self.teamOnosCount = self.teamOnosCount + 1
            end
        end
        
    end
    
end --End-ServerOnly

function AlienTeamInfo:GetSlotsLocationIds()
    return 
    { self.location1Id, self.location2Id, self.location3Id, self.location4Id, self.location5Id }
end

function AlienTeamInfo:GetLocationSlotData( locationId )
    
    assert(type(locationId) == "number")
    
    local slotData = 
    {
        isEmpty = false,
        eggCount = nil, eggInCombat = nil, 
        hiveHealthScalar = nil, hiveMaxHealth = nil, 
        hiveBuiltFraction = nil, hiveFlag = nil, hiveInCombat = nil,
        locationId = nil
    }

    if locationId == self.location1Id then

        slotData.eggCount = self.location1EggCount
        slotData.eggInCombat = self.location1EggsInCombat
        --slotData.shellCount = self.location1ShellCount
        --slotData.spurCount = self.location1SpurCount
        --slotData.veilCount = self.location1VeilCount
        slotData.hiveHealthScalar = self.location1HiveHealthScalar
        slotData.hiveMaxHealth = self.location1HiveMaxHealth
        slotData.hiveBuiltFraction = self.location1HiveBuilt
        slotData.hiveFlag = self.location1HiveFlag
        slotData.hiveInCombat = self.location1HiveInCombat
        slotData.locationId = locationId

    elseif locationId == self.location2Id then

        slotData.eggCount = self.location2EggCount
        slotData.eggInCombat = self.location2EggsInCombat
        --slotData.shellCount = self.location2ShellCount
        --slotData.spurCount = self.location2SpurCount
        --slotData.veilCount = self.location2VeilCount
        slotData.hiveHealthScalar = self.location2HiveHealthScalar
        slotData.hiveMaxHealth = self.location2HiveMaxHealth
        slotData.hiveBuiltFraction = self.location2HiveBuilt
        slotData.hiveFlag = self.location2HiveFlag
        slotData.hiveInCombat = self.location2HiveInCombat
        slotData.locationId = locationId

    elseif locationId == self.location3Id then

        slotData.eggCount = self.location3EggCount
        slotData.eggInCombat = self.location3EggsInCombat
        --slotData.shellCount = self.location3ShellCount
        --slotData.spurCount = self.location3SpurCount
        --slotData.veilCount = self.location3VeilCount
        slotData.hiveHealthScalar = self.location3HiveHealthScalar
        slotData.hiveMaxHealth = self.location3HiveMaxHealth
        slotData.hiveBuiltFraction = self.location3HiveBuilt
        slotData.hiveFlag = self.location3HiveFlag
        slotData.hiveInCombat = self.location3HiveInCombat
        slotData.locationId = locationId

    elseif locationId == self.location4Id then

        slotData.eggCount = self.location4EggCount
        slotData.eggInCombat = self.location4EggsInCombat
        --slotData.shellCount = self.location4ShellCount
        --slotData.spurCount = self.location4SpurCount
        --slotData.veilCount = self.location4VeilCount
        slotData.hiveHealthScalar = self.location4HiveHealthScalar
        slotData.hiveMaxHealth = self.location4HiveMaxHealth
        slotData.hiveBuiltFraction = self.location4HiveBuilt
        slotData.hiveFlag = self.location4HiveFlag
        slotData.hiveInCombat = self.location4HiveInCombat
        slotData.locationId = locationId

    elseif locationId == self.location5Id then

        slotData.eggCount = self.location5EggCount
        slotData.eggInCombat = self.location5EggsInCombat
        --slotData.shellCount = self.location5ShellCount
        --slotData.shellCount = self.location5SpurCount
        --slotData.shellCount = self.location5VeilCount
        slotData.hiveHealthScalar = self.location5HiveHealthScalar
        slotData.hiveMaxHealth = self.location5HiveMaxHealth
        slotData.hiveBuiltFraction = self.location5HiveBuilt
        slotData.hiveFlag = self.location5HiveFlag
        slotData.hiveInCombat = self.location5HiveInCombat
        slotData.locationId = locationId

    else

        slotData.isEmpty = true

    end
    
    return slotData
end

function AlienTeamInfo:GetChamberCount( chamberTechId )
    local chamberCount = 0
    
    if chamberTechId == kTechId.Shell then
        chamberCount = self.shellLevel
    elseif chamberTechId == kTechId.Spur then
        chamberCount = self.spurLevel
    elseif chamberTechId == kTechId.Veil then
        chamberCount = self.veilLevel
    end
    
    return chamberCount
end

function AlienTeamInfo:GetNumHives()
    return self.numHives
end

function AlienTeamInfo:GetBioMassLevel()
    return self.bioMassLevel
end

function AlienTeamInfo:GetBioMassAlertLevel()
    return self.bioMassAlertLevel
end

function AlienTeamInfo:GetMaxBioMassLevel()
    return self.maxBioMassLevel
end

function AlienTeamInfo:GetEggCount()
    return self.eggCount
end

Shared.LinkClassToMap("AlienTeamInfo", AlienTeamInfo.kMapName, networkVars)


if Client then
    
    local OnCommandDumpStatusSlotData = function()
        
        if Shared.GetCheatsEnabled() or Shared.GetTestsEnabled() then
            
            local teamInfo = GetTeamInfoEntity( kTeam2Index )
            local slotLocations = teamInfo:GetSlotsLocationIds()
            
            if slotLocations then
            
                for _, locationId in ipairs(slotLocations) do
                
                    local slotData = teamInfo:GetLocationSlotData( locationId )
                    
                    if slotData then
                        Log("\t Location[%d] - slotData:", locationId)
                        Log("\t\t locationId=%s", slotData.locationId)
                        Log("\t\t eggCount=%s", slotData.eggCount)
                        Log("\t\t eggInCombat=%s", slotData.eggInCombat)
                        Log("\t\t hiveHealthScalar=%s", slotData.hiveHealthScalar)
                        Log("\t\t hiveMaxHealth=%s", slotData.hiveMaxHealth)
                        Log("\t\t hiveBuiltFraction=%s", slotData.hiveBuiltFraction)
                        Log("\t\t hiveFlag=%s", slotData.hiveFlag)
                        Log("\t\t hiveInCombat=%s", slotData.hiveInCombat)
                    end
                    
                end
                
            end
            
        end
        
    end

    Event.Hook("Console_dumphivestatuses", OnCommandDumpStatusSlotData)

    local OnCommandDumpLifeformData = function()
        local teamInfo = GetTeamInfoEntity( kTeam2Index )
        Shared.Message(string.format("Skulk:%s\nGorge:%s\nProwler:%s\nLerk:%s\nFade:%s\nOnos:%s", 
                teamInfo.teamSkulkCount,teamInfo.teamGorgeCount,teamInfo.teamProwlerCount,teamInfo.teamLerkCount,teamInfo.teamFadeCount,teamInfo.teamOnosCount))
    end
    
    Event.Hook("Console_lifeformdata", OnCommandDumpLifeformData)
end

