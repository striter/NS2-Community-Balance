-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/MarineCommanderBrain_Senses.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Seperate file for marine commander bot's senses
-- Just easier to look at
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/bots/MarineCommanderBrain_Utility.lua")

------------------------------------------
--  Build the senses database
------------------------------------------

function CreateMarineComSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("activeMarines", function(db)
        local activeMarines = {}
        local marines = db:Get("marines")
        for _, marine in ipairs(marines) do
            if GetIsUnitActive(marine) then
                table.insert(activeMarines, marine)
            end
        end
        return activeMarines
    end)

    s:Add("numDeadPlayers", function(db)
        return GetGamerules():GetTeam(db.bot:GetTeamNumber()):GetNumDeadPlayers()
    end)

    s:Add("maxInfantryPortals", function(db)

        local ultimateMax = kMaxInfantryPortalsPerCommandStation
        local numPlayers = db:Get("numPlayersForTeam")
        local maxInfantryPortals = 1

        if db:Get("isEarlyGame") then -- Play catch-up, so only #ips we started with. Currently max of 2, so /shrug

            if numPlayers >= kSecondInitialInfantryPortalMinPlayerCount then
                maxInfantryPortals = 2
            else
                maxInfantryPortals = 1
            end

        else
            local playersPerIP = 3
            maxInfantryPortals = Clamp(math.floor(numPlayers / playersPerIP), 1, ultimateMax)
        end

        return maxInfantryPortals

    end)

    s:Add("isEarlyGame", function(db)
        return db:Get("gameMinutes") < 2
    end)

    s:Add("numExtractorsForRoundTime", function(db)

        local roundTimeMinutes = db:Get("gameMinutes")

        if roundTimeMinutes < 3 then
            return 4
        elseif roundTimeMinutes < 5 then
            return 6
        end

        return math.huge
    end)

    s:Add("numPlayersForTeam", function(db)
        return GetGamerules():GetTeam(db.bot:GetTeamNumber()):GetNumPlayers()
    end)

    s:Add("numResourcePoints", function(db)
        return #GetEntities("ResourcePoint")
    end)

    s:Add("extractorDecisionInfo", function(db)

        local resultTable = {}

        local nExtractors = #db:Get("extractors")
        local nEmptyResPoints = #db:Get("availResPoints")
        local commandStations = db:Get("builtCommandStations")
        local nTPRoomsWithRts = 0
        for _, cs in ipairs(commandStations) do
            local locationName = cs:GetLocationName()
            if GetLocationContention():GetIsLocationFullyFeaturedTechRoom(locationName) then
                nTPRoomsWithRts = nTPRoomsWithRts + 1
            end
        end

        return
        {
            numExtractors = nExtractors,
            numEmptyResPoints = nEmptyResPoints,
            numTPRoomsWithRts = nTPRoomsWithRts
        }

    end)

    s:Add("hasArmsLab", function(db)
        return #db:Get("armsLabs") > 0
    end)

    s:Add("armsLabs", function(db)
        return GetEntitiesAliveForTeam("ArmsLab", db.bot:GetTeamNumber())
    end)

    s:Add("weaponCounts", function(db)

        local result = { counts = IterableDict(), totalUpgradedWeapons = 0, numUpgradeableMarines = 0 }
        local nMarines = #db:Get("marines")
        local clipWeapons = db:Get("clipWeapons")

        for _, weapon in ipairs(clipWeapons) do
            local weaponTechId = weapon:GetTechId()
            if kDroppedWeaponTechIds[weaponTechId] then
                if result.counts[weaponTechId] then
                    result.counts[weaponTechId] = result.counts[weaponTechId] + 1
                else
                    result.counts[weaponTechId] = 1
                end
                result.totalUpgradedWeapons = result.totalUpgradedWeapons + 1
            end
        end

        result.numUpgradeableMarines = Clamp(nMarines - result.totalUpgradedWeapons, 0, nMarines)

        return result

    end)

    s:Add("clipWeapons", function(db)
        return GetEntities("ClipWeapon")
    end)

    s:Add("builtCommandStations", function(db)
        local builtCommandStations = {}
        local commandStations = GetEntitiesAliveForTeam("CommandStation", db.bot:GetTeamNumber())
        for _, commandStation in ipairs(commandStations) do
            if commandStation:GetIsBuilt() then
                table.insert(builtCommandStations, commandStation)
            end
        end
        return builtCommandStations
    end)

    s:Add("builtPhaseGates", function(db)
        local builtPhaseGates = {}
        local phaseGates = db:Get("phaseGates")
        for _, phaseGate in ipairs(phaseGates) do
            if phaseGate:GetIsBuilt() then
                table.insert(builtPhaseGates, phaseGate)
            end
        end
        return builtPhaseGates
    end)

    s:Add("phaseGates", function(db)
        return GetEntitiesForTeam("PhaseGate", db.bot:GetTeamNumber())
    end)

    s:Add("bestArmoryForWeaponDrop", function(db) -- TODO(Bots): Cache in TeamBrain? (Using EntityChange)

        local result = { armoryEnt = nil, isAdvanced = nil }

        -- Engine adds new ents to back of array, so oldest should be first in list
        -- when calling GetEntities etc
        local commandStations = db:Get("builtCommandStations")
        for _, cs in ipairs(commandStations) do
            local numIPs = #GetEntitiesForTeamByLocation("InfantryPortal", db.bot:GetTeamNumber(), cs:GetLocationId())
            if numIPs > 0 then -- This can be considered a "main base" location

                local armoriesInLoc = GetEntitiesForTeamByLocation("Armory", db.bot:GetTeamNumber(), cs:GetLocationId())
                for _, armory in ipairs(armoriesInLoc) do

                    local isAdvanced = armory:GetTechId() == kTechId.AdvancedArmory
                    result.armoryEnt = armory
                    result.isAdvanced = isAdvanced

                    return result

                end

            end
        end

        return result
    end)

    s:Add("builtArmories", function(db)
        local builtArmories = {}
        local armories = GetEntitiesAliveForTeam("Armory", db.bot:GetTeamNumber())
        for _, armory in ipairs(armories) do
            if armory:GetIsBuilt() then
                table.insert(builtArmories, armory)
            end
        end
        return builtArmories
    end)

    s:Add("prototypeLabs", function(db)
        return GetEntitiesAliveForTeam("PrototypeLab", db.bot:GetTeamNumber())
    end)

    s:Add("activeInfantryPortals", function(db)
        local activeInfantryPortals = {}
        local infantryPortals = db:Get("infantryPortals")
        for _, ip in ipairs(infantryPortals) do
            if GetIsUnitActive(ip) then
                table.insert(activeInfantryPortals, ip)
            end
        end
        return activeInfantryPortals
    end)

    s:Add("builtPrototypeLabs", function(db)
        local builtPrototypeLabs = {}
        local protoLabs = GetEntitiesAliveForTeam("PrototypeLab", db.bot:GetTeamNumber())
        for _, lab in ipairs(protoLabs) do
            if lab:GetIsBuilt() then
                table.insert(builtPrototypeLabs, lab)
            end
        end
        return builtPrototypeLabs
    end)

    s:Add("builtRoboticsFactories", function(db)
        local builtRoboFactories = {}
        local protoLabs = GetEntitiesAliveForTeam("RoboticsFactory", db.bot:GetTeamNumber())
        for _, lab in ipairs(protoLabs) do
            if lab:GetIsBuilt() then
                table.insert(builtRoboFactories, lab)
            end
        end
        return builtRoboFactories
    end)

    s:Add("gameMinutes", function(db)
        return (Shared.GetTime() - GetGamerules():GetGameStartTime()) / 60.0
    end)

    s:Add("doableTechIds", function(db)
        return db.bot.brain:GetDoableTechIds( db.bot:GetPlayer() )
    end)

    s:Add("stations", function(db)
        return GetEntitiesAliveForTeam("CommandStation", db.bot:GetTeamNumber())
    end)

    s:Add("enemyCommand", function(db)
        return GetEntitiesAliveForTeam("CommandStation", GetEnemyTeamNumber(db.bot:GetTeamNumber()))
    end)

    s:Add("marines", function(db)
        -- TODO: if marine:GetIsAlive() and not marine:GetIsInCombat() then
        return GetEntitiesAliveForTeam("Marine", db.bot:GetTeamNumber())
    end)

    s:Add("nonJPMarines", function(db)
        local marinesOrJPs = db:Get("marines")
        local nonJPMarines = {}
        for i = 1, #marinesOrJPs do
            local marine = marinesOrJPs[i]
            if not marine:isa("JetpackMarine") then
                table.insert(nonJPMarines, marine)
            end
        end
        return nonJPMarines
    end)

    s:Add("availResPoints", function(db)
        return GetAvailableResourcePoints()
    end)

    s:Add("extractors", function(db)
        return GetEntitiesAliveForTeam("ResourceTower", db.bot:GetTeamNumber())
    end)

    s:Add("infantryPortals", function(db)
        return GetEntitiesAliveForTeam("InfantryPortal", db.bot:GetTeamNumber())
    end)

    s:Add("ghostStructures", function(db)
        local ghostStructures = {}
        local mixinStructures = GetEntitiesWithMixinForTeam("GhostStructure", db.bot:GetTeamNumber())
        for _, structure in ipairs(mixinStructures) do
            if structure:GetIsGhostStructure() then
                table.insert(ghostStructures, structure)
            end
        end

        return ghostStructures
    end)

    s:Add("macs", function(db)
        return GetEntitiesAliveForTeam("MAC", db.bot:GetTeamNumber())
    end)

    s:Add("availTechPoints", function(db)
        return GetAvailableTechPoints()
    end)

    s:Add("pgTechPoints", function(db)

        local techPoints = GetEntities("TechPoint")
        local pgTechPoints = {}

        for _, techPoint in ipairs( techPoints) do

            local attachedEnt = techPoint:GetAttached()
            if not attachedEnt or attachedEnt:isa("CommandStation") then
                table.insert(pgTechPoints, techPoint)
            end

        end

        return pgTechPoints

    end)

    s:Add("safeTechPoints", function(db)

        local safeTechPoints = {}
        local techPoints = db:Get("pgTechPoints")
        for _, techPoint in ipairs(techPoints) do

            -- Ignore main base
            local isMainLocation = techPoint:GetLocationName() == db.bot.brain:GetStartingTechPoint()
            local isSafe = db.bot.brain:GetIsSafeToDropInLocation(techPoint:GetLocationName(), db.bot:GetTeamNumber(), db:Get("isEarlyGame"))

            if isSafe and not isMainLocation then

                if #GetEntitiesAliveForTeamWithinRange("Marine", db.bot:GetTeamNumber(), techPoint:GetOrigin(), kMarinesNearbyRange) > 0 then
                    table.insert(safeTechPoints, techPoint)
                end

            end

        end

        return safeTechPoints
    end)

    s:Add("techPointToTake", function(db)
        local tps = GetAvailableTechPoints()
        local stations = db:Get("stations")
        local dist, tp = GetMinTableEntry( tps, function(tp)
            return GetMinPathDistToEntities( tp, stations )
        end)
        return tp
    end)


    s:Add("resPointToTake", function(db)
        local rps = db:Get("availResPoints")
        local stations = db:Get("stations")
        local dist, rp = GetMinTableEntry( rps, function(rp)
            return GetMinPathDistToEntities( rp, stations )
        end)
        return rp
    end)

    s:Add("resPointWithNearbyMarines", function(db)
        local rps = db:Get("availResPoints")
        local marines = db:Get("marines")
        local dist, rp = GetMinTableEntry( rps, function(rp)
            return GetMinDistToEntities( rp, marines )
        end)

        if dist and dist < kMarinesNearbyRange then
            return rp
        end
    end)

    s:Add("enemyCommandWithNearbyMarines", function(db)
        local commands = db:Get("enemyCommand")
        local marines = db:Get("marines")
        local dist, command = GetMinTableEntry( commands, function(rp)
            return GetMinDistToEntities( command, marines )
        end)
        return {command = command, dist = dist}
    end)

    -- Senses for techpath handling

    s:Add("mainCommandStation", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local commandStationsInMainBase = GetEntitiesAliveForTeamByLocation( "CommandStation", db.bot:GetTeamNumber(), startingLocationId )

        if #commandStationsInMainBase > 0 then
            return commandStationsInMainBase[1]
        end

    end)

    s:Add("mainArmsLab", function(db)
        local startingLocationName = db.bot.brain:GetStartingTechPoint()
        local startingLocationId = Shared.GetStringIndex(startingLocationName or "")
        local units = GetEntitiesAliveForTeamByLocation( "ArmsLab", db.bot:GetTeamNumber(), startingLocationId )
        if #units > 0 then
            return units[1]
        end
    end)

    s:Add("mainArmory", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocation( "Armory", db.bot:GetTeamNumber(), startingLocationId )
        if #units > 0 then
            return units[1]
        end
    end)

    s:Add("mainObservatory", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocation( "Observatory", db.bot:GetTeamNumber(), startingLocationId )
        if #units > 0 then
            return units[1]
        end
    end)

    s:Add("mainPhaseGate", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocation( "PhaseGate", db.bot:GetTeamNumber(), startingLocationId )
        if #units > 0 then
            return units[1]
        end
    end)

    s:Add("mainAdvancedArmory", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocationWithTechId( "Armory", db.bot:GetTeamNumber(), startingLocationId, kTechId.AdvancedArmory )
        if #units > 0 then
            return units[1]
        end
    end)

    s:Add("mainPrototypeLab", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocation( "PrototypeLab", db.bot:GetTeamNumber(), startingLocationId )
        if #units > 0 then
            return units[1]
        end
    end)

    s:Add("forwardObservatories", function(db)

        local forwardObs = {}
        local startingLocationId = db.bot.brain:GetStartingLocationId()

        if startingLocationId ~= 0 then

            local observatories = GetEntitiesAliveForTeam("Observatory", db.bot:GetTeamNumber())
            for _, obs in ipairs(observatories) do
                local obsLocId = obs:GetLocationId()
                if obsLocId ~= 0 and startingLocationId ~= obsLocId then
                    table.insert(forwardObs, obs)
                end
            end

        end

        return forwardObs

    end)

    return s

end
