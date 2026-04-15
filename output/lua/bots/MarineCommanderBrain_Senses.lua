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
    
    s:Add("nearestPower", function(db)
    local bestDist = 1000
    local bestPower = nil
    local commandStations = db:Get("builtCommandStations")
    
    for _, cs in ipairs(commandStations) do
        local nearby = GetLocationGraph():GetDirectPathsForLocationName(cs:GetLocationName())
        local powers = GetEntities("PowerPoint")
        
        for _, power in ipairs(powers) do
            if nearby and nearby:Contains(power:GetLocationName()) and not power:GetIsBuilt() then
                local dist = (cs:GetOrigin() - power:GetOrigin()):GetLength()

                if dist < bestDist then
                    bestDist = dist
                    bestPower = power
                end
            end
        end
    end
    
    return {
        entity = bestPower,
        distance = bestDist
    }
end)

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
    
    s:Add("hasWelder", function(db)
    return function(marine)
        return marine:GetWeapon(Welder.kMapName) ~= nil
    end
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
    
    s:Add("damagedStructures", function(db)
    local teamNumber = db.bot:GetTeamNumber()
    local damagedStructures = {}

    for _, structure in ipairs(GetEntitiesWithMixinForTeam("Live", teamNumber)) do
        if structure:GetIsAlive() and structure:GetHealth() < structure:GetMaxHealth() then
            table.insert(damagedStructures, structure)
        end
    end

    return damagedStructures
    end)

    s:Add("hasArmsLab", function(db)
        return #db:Get("armsLabs") > 0
    end)

    s:Add("armsLabs", function(db)
        return GetEntitiesAliveForTeam("ArmsLab", db.bot:GetTeamNumber())
    end)

   -- Stelle sicher, dass diese Definition vorhanden ist, bevor die Sense "weaponCounts" aufgerufen wird
local kDroppedWeaponTechIds = set{
    kTechId.Shotgun,
    kTechId.GrenadeLauncher,
    kTechId.Flamethrower,
    kTechId.HeavyMachineGun
}

local kWeaponToDropTechIds ={
    [kTechId.Shotgun        ] = kTechId.DropShotgun,
    [kTechId.GrenadeLauncher] = kTechId.DropGrenadeLauncher,
    [kTechId.Flamethrower   ] = kTechId.DropFlamethrower,
    [kTechId.HeavyMachineGun] = kTechId.DropHeavyMachineGun
}

s:Add("weaponCounts", function(db)
    local result = { counts = IterableDict(), totalUpgradedWeapons = 0, numUpgradeableMarines = 0 }
    local nMarines = #db:Get("marines")
    local clipWeapons = db:Get("clipWeapons")

   -- print("Number of marines:", nMarines) -- Debug
   -- print("Clip weapons:", clipWeapons) -- Debug

    for _, weapon in ipairs(clipWeapons) do
        local weaponTechId = weapon:GetTechId()

      -- print("Checking weapon TechId:", weaponTechId) -- Debug

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
    
    --print("Result counts:", result.counts) -- Debug
    --print("Total upgraded weapons:", result.totalUpgradedWeapons) -- Debug
    --print("Number of upgradeable marines:", result.numUpgradeableMarines) -- Debug

    return result
end)

s:Add("groundWeapons", function(db)
    local result = {}
    local clipWeapons = db:Get("clipWeapons")

    -- Nur Waffen ber�cksichtigen, die der Commander droppen kann
    local droppable = {
        [kTechId.Shotgun] = true,
        [kTechId.GrenadeLauncher] = true,
        [kTechId.Flamethrower] = true,
        [kTechId.HeavyMachineGun] = true
    }

    for _, weapon in ipairs(clipWeapons) do
        local techId = weapon:GetTechId()

        -- Nur droppable Waffen pr�fen
        if droppable[techId] then

            -- Waffe liegt am Boden, wenn sie KEIN Parent hat
            -- (Parent = Marine oder Armory)
            if weapon:GetParent() == nil then
                table.insert(result, weapon)
            end
        end
    end

    return result
end)

s:Add("countMarines", function(db)
    local marineCount = 0
    local marines = db:Get("marines")
    for _, marine in ipairs(marines) do
        if marine:GetIsAlive() then
            marineCount = marineCount + 1
        end
    end
    return marineCount
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

  s:Add("bestArmoryForWeaponDrop", function(db)
    -- TODO(Bots): Cache in TeamBrain? (Using EntityChange)
    local result = { armoryEnt = nil, isAdvanced = nil }

    -- Engine f�gt neue Entit�ten am Ende des Arrays hinzu, daher sollten die �ltesten zuerst in der Liste stehen
    -- wenn GetEntities etc. aufgerufen wird
    local commandStations = db:Get("builtCommandStations")
    --print("Found command stations:", #commandStations) -- Debug

    for _, cs in ipairs(commandStations) do
        local numIPs = #GetEntitiesForTeamByLocation("InfantryPortal", db.bot:GetTeamNumber(), cs:GetLocationId())
        --print("Checking command station:", cs:GetId(), "Number of IPs:", numIPs) -- Debug

        if numIPs > 0 then -- Dies kann als "Hauptbasis" betrachtet werden
            local armoriesInLoc = GetEntitiesForTeamByLocation("Armory", db.bot:GetTeamNumber(), cs:GetLocationId())
            --print("Found armories in location:", #armoriesInLoc) -- Debug

            for _, armory in ipairs(armoriesInLoc) do
                local isAdvanced = armory:GetTechId() == kTechId.AdvancedArmory
                --print("Checking armory:", armory:GetId(), "Is advanced:", isAdvanced) -- Debug

                result.armoryEnt = armory
                result.isAdvanced = isAdvanced
                return result
            end
        end
    end

    --print("No valid armory found.") -- Debug
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

   s:Add("doubleResPoints", function(db)
    local doubleResPoints = {}
    local resPoints = db:Get("availResPoints")
    local extractors = db:Get("extractors")

    -- Print("Available ResPoints: " .. tostring(#resPoints))  -- Debugging-Ausgabe
    -- Print("Active Extractors: " .. tostring(#extractors))    -- Debugging-Ausgabe

    local allResPoints = {}

    -- Kombinieren der verf�gbaren ResPoints und aktiven Extractors
    for _, resPoint in ipairs(resPoints) do
        table.insert(allResPoints, resPoint)
    end
    for _, extractor in ipairs(extractors) do
        table.insert(allResPoints, extractor)
    end

    local locationMap = {}

    -- Gruppiere ResPoints nach LocationName
    for _, resPoint in ipairs(allResPoints) do
        local locationName = resPoint:GetLocationName()
        if locationName then
            if not locationMap[locationName] then
                locationMap[locationName] = {}
            end
            table.insert(locationMap[locationName], resPoint)
        else
            -- Print("Invalid location detected for resPoint")
        end
    end

    -- F�ge ResPoint-Paare hinzu, die sich am gleichen Standort befinden
    for locationName, resPoints in pairs(locationMap) do
        if #resPoints > 1 then
            for i = 1, #resPoints - 1 do
                for j = i + 1, #resPoints do
                    table.insert(doubleResPoints, {resPoints[i], resPoints[j]})
                    -- Print("Double ResPoints found: " .. resPoints[i]:GetLocationName() .. " and " .. resPoints[j]:GetLocationName())
                end
            end
        end
    end

    -- Print("Total Double ResPoints: " .. tostring(#doubleResPoints))
    return doubleResPoints
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
    
s:Add("incompleteStructures", function(db)
    local incompleteStructures = {}
    local mixinStructures = GetEntitiesWithMixinForTeam("Construct", db.bot:GetTeamNumber())
    for _, structure in ipairs(mixinStructures) do
        if structure:GetIsBuilt() == false then
            table.insert(incompleteStructures, structure)
        end
    end
    return incompleteStructures
    end)

    s:Add("macs", function(db)
        return GetEntitiesAliveForTeam("MAC", db.bot:GetTeamNumber())
    end)
    
    s:Add("arcs", function(db)
    return GetEntitiesAliveForTeam("ARC", db.bot:GetTeamNumber())
    end)
    
    s:Add("exos", function(db)
    return GetEntitiesForTeam("Exo", db.bot:GetTeamNumber())
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
    
    s:Add("techPoints", function(db)
    return GetEntities("TechPoint")
end)

    s:Add("Observatorys", function(db)
    local observatories = GetEntitiesAliveForTeam("Observatory", db.bot:GetTeamNumber())
    local completedObservatories = {}
    for _, obs in ipairs(observatories) do
        if obs:GetIsBuilt() then
            table.insert(completedObservatories, obs)
        end
    end
    return completedObservatories
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
    
    s:Add("numBuiltHives", function(db)
    local hives = GetEntitiesAliveForTeam("Hive", GetEnemyTeamNumber(db.bot))
    local count = 0
    for _, hive in ipairs(hives) do
        if hive:GetIsBuilt() then
            count = count + 1
        end
    end
    return count
end)

s:Add("techPhaseComplete", function(db)
    local bot = db.bot
    local brain = bot.brain
    local com = bot:GetPlayer()

    local nextTechStep = GetMarineComNextTechStep(bot, brain, com)
    return nextTechStep == kTechId.None
end)

s:Add("hasAdvancedArmory", function(db)
    local team = db.bot:GetTeamNumber()
    local units = GetEntitiesForTeam("Armory", team)

    for _, armory in ipairs(units) do
        if armory:GetTechId() == kTechId.AdvancedArmory then
            return true
        end
    end

    return false
end)

-- Pr�ft, ob eine RoboticsFactory mit ARC-Upgrade existiert
s:Add("hasUpgradedRoboticsFactory", function(db)
    local roboFactories = GetEntitiesAliveForTeam("RoboticsFactory", db.bot:GetTeamNumber())
    for _, f in ipairs(roboFactories) do
        if f:GetTechId() == kTechId.ARCRoboticsFactory then
            --db.bot:SendTeamMessage("ARC-Upgrade erkannt!", 10, false, true)
            return f
        end
    end
    return nil
end)

    s:Add("hasRoboticsFactoryInBase", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocationWithTechId("RoboticsFactory", db.bot:GetTeamNumber(), startingLocationId )
            if #units > 0 then
                return units[1]
            end
        end)
        
        s:Add("hasARCRoboticsFactoryInBase", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocationWithTechId("ARCRoboticsFactory", db.bot:GetTeamNumber(), startingLocationId )
            if #units > 0 then
                return units[1]
            end
        end)--]]

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


    s:Add("mainStandardStation", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local commandStationsInMainBase = GetEntitiesAliveForTeamByLocationWithTechId( "CommandStation", db.bot:GetTeamNumber(), startingLocationId ,kTechId.StandardStation)

        if #commandStationsInMainBase > 0 then
            return commandStationsInMainBase[1]
        end

    end)

    s:Add("mainJetpackLab", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocationWithTechId( "PrototypeLab", db.bot:GetTeamNumber(), startingLocationId, kTechId.JetpackPrototypeLab )
        if #units > 0 then
            return units[1]
        end
    end)

    s:Add("mainCannonLab", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocationWithTechId( "PrototypeLab", db.bot:GetTeamNumber(), startingLocationId, kTechId.CannonPrototypeLab )
        if #units > 0 then
            return units[1]
        end
    end)
    
    s:Add("mainExosuitLab", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocationWithTechId( "PrototypeLab", db.bot:GetTeamNumber(), startingLocationId, kTechId.ExosuitPrototypeLab )
        if #units > 0 then
            return units[1]
        end
    end)
    
    return s

end
