-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/AlienCommanderBrain_Senses.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Seperate file for alien commander bot's senses
-- Just easier to look at
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/bots/AlienCommanderBrain_Utility.lua")
Script.Load("lua/IterableDict.lua")

------------------------------------------
--  Build the senses database
------------------------------------------

local kBoneWallTargetClasses = set
{
    "Spur",
    "Veil",
    "Shell",
    "Hive",
    "TunnelEntrance"
}


local kBoneWallDoerIgnore = set
{
    "Flame",
    "Flamethrower",
    "NerveGasCloud",
    "ClusterGrenade",
    "ClusterFragment",
    "PulseGrenade",
    "ARC",
}

local function GetFirstSafeHiveForBiomassResearch(hiveTable)
    if not hiveTable then return end
    for _, hive in ipairs(hiveTable) do
        local hiveMightDie = hive:GetHealthScalar() < 0.4 and hive:GetIsInCombat()
        if not hiveMightDie then
            return hive
        end
    end
end

local kHiveUpgradeTechIds = set
{
    kTechId.UpgradeToCragHive,
    kTechId.UpgradeToShadeHive,
    kTechId.UpgradeToShiftHive,
}
local function GetisResearchingIdHiveUpgrade(researchId)
    return researchId ~= kTechId.None and kHiveUpgradeTechIds[researchId]
end

function CreateAlienComSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("hiveTypes", function(db)

        -- GetIsHiveTypeResearch
        -- GetHiveTypeResearchAllowed

        local allowedHiveUpgrades = {}

        local normalHives = {}
        local numNormalHives = 0
        local numCragHives = 0
        local numShadeHives = 0
        local numShiftHives = 0

        local hives = db:Get("hives")
        for _, hive in ipairs(hives) do

            local hiveTechId = hive:GetTechId()
            local researchId = hive:GetResearchingId()

            if hiveTechId == kTechId.Hive and not GetisResearchingIdHiveUpgrade(researchId) then
                table.insert(normalHives, hive)
                numNormalHives = numNormalHives + 1
            elseif hiveTechId == kTechId.CragHive or researchId == kTechId.UpgradeToCragHive then
                numCragHives = numCragHives + 1
            elseif hiveTechId == kTechId.ShadeHive or researchId == kTechId.UpgradeToShadeHive then
                numShadeHives = numCragHives + 1
            elseif hiveTechId == kTechId.ShiftHive or researchId == kTechId.UpgradeToShiftHive then
                numShiftHives = numCragHives + 1
            end

        end

        return
        {
            normalHives    = normalHives,
            numNormalHives = numNormalHives,
            numCragHives   = numCragHives,
            numShadeHives  = numShadeHives,
            numShiftHives  = numShiftHives,
        }

    end)

    s:Add("numVeils", function(db)
        return #GetEntitiesAliveForTeam("Veil", db.bot:GetTeamNumber())
    end)

    s:Add("numSpurs", function(db)
        return #GetEntitiesAliveForTeam("Spur", db.bot:GetTeamNumber())
    end)

    s:Add("numShells", function(db)
        return #GetEntitiesAliveForTeam("Shell", db.bot:GetTeamNumber())
    end)

    s:Add("isEarlyGame", function(db)
        return db:Get("gameMinutes") < 2
    end)

    s:Add("numHarvestersForRoundTime", function(db)

        local roundTimeMinutes = db:Get("gameMinutes")
        local numHives = #db:Get("hives")
        local hasMoreHives = numHives >= 2

        if roundTimeMinutes < 3 then
            return hasMoreHives and 5 or 4
        elseif roundTimeMinutes < 5 then
            return hasMoreHives and 7 or 6
        end

        return math.huge
    end)

    s:Add("cheapestBiomassUnit", function(db)
        local doables = db:Get("doableTechIds")
        local resultTable = { isValid = true }

        -- Since we use doables table, we
        -- don't need to check for biomass in progress in GetFirstSafeHiveForBiomassResearch

        local cheapestBiomassUpgrade = kTechId.ResearchBioMassOne
        local cheapestUnits = doables[cheapestBiomassUpgrade]
        local cheapestHive = GetFirstSafeHiveForBiomassResearch(cheapestUnits)
        if cheapestHive then
            resultTable.hiveEnt = cheapestHive
            resultTable.techId = cheapestBiomassUpgrade
            return resultTable
        end

        cheapestBiomassUpgrade = kTechId.ResearchBioMassTwo
        cheapestUnits = doables[cheapestBiomassUpgrade]
        cheapestHive = GetFirstSafeHiveForBiomassResearch(cheapestUnits)
        if cheapestHive then
            resultTable.hiveEnt = cheapestHive
            resultTable.techId = cheapestBiomassUpgrade
            return resultTable
        end

        cheapestBiomassUpgrade = kTechId.ResearchBioMassThree
        cheapestUnits = doables[cheapestBiomassUpgrade]
        cheapestHive = GetFirstSafeHiveForBiomassResearch(cheapestUnits)
        if cheapestHive then
            resultTable.hiveEnt = cheapestHive
            resultTable.techId = cheapestBiomassUpgrade
            return resultTable
        end

        resultTable.isValid = false
        return resultTable
    end)

    s:Add("harvesterDecisionInfo", function(db)

        local resultTable = {}

        local nHarvesters = db:Get("numHarvesters")
        local nEmptyResPoints = #db:Get("availResPoints")
        local hives = db:Get("hives")
        local nTPRoomsWithRts = 0
        for _, hive in ipairs(hives) do
            local locationName = hive:GetLocationName()
            if GetLocationContention():GetIsLocationFullyFeaturedTechRoom(locationName) then
                nTPRoomsWithRts = nTPRoomsWithRts + 1
            end
        end

        return
        {
            numHarvesters = nHarvesters,
            numEmptyResPoints = nEmptyResPoints,
            numTPRoomsWithRts = nTPRoomsWithRts
        }

    end)

    s:Add("researchEvolutionChamber", function(db)
        local resultEvoChamber
        local hives = GetEntitiesForTeam("Hive", db.bot:GetTeamNumber())
        for _, hive in ipairs(hives) do

            local hiveMightDie = hive:GetHealthScalar() < 0.4 and hive:GetIsInCombat()

            local evolutionChamber = hive:GetEvolutionChamber()
            if evolutionChamber and hive:GetIsBuilt() and
                evolutionChamber:GetResearchingId() == kTechId.None and
                not hiveMightDie then

                resultEvoChamber = evolutionChamber
                break

            end
        end
        return resultEvoChamber
    end)

    s:Add("researchBiomassHive", function(db)

        -- GetEvolutionChamber
        local resultHive
        local hives = GetEntitiesForTeam("Hive", db.bot:GetTeamNumber())
        for _, hive in ipairs(hives) do
            local hiveMightDie = hive:GetHealthScalar() < 0.4 and hive:GetIsInCombat()
            if not hiveMightDie and not hive:GetResearchingId() == kTechId.None then
                resultHive = hive
                break
            end
        end
        return resultHive
    end)

    s:Add("bonewallTarget", function(db)

        local bonewallTarget

        local friendlyEnts = GetEntitiesWithMixinForTeam("Combat", db.bot:GetTeamNumber())
        for _, ent in ipairs(friendlyEnts) do

            local isWhitelisted = kBoneWallTargetClasses[ent:GetClassName()]
            local isUnderFire = ent:GetIsUnderFire()

            if isWhitelisted and isUnderFire then

                local currentAttacker = ent:GetCurrentAttacker()
                local attackSourceValid =
                    currentAttacker and not currentAttacker:isa("ARC") and
                    GetAreEnemies(ent, currentAttacker) and
                    not kBoneWallDoerIgnore[ent:GetLastAttackerDoerClassName()]

                if attackSourceValid and (not bonewallTarget or bonewallTarget:GetHealthScalar() > ent:GetHealthScalar()) then
                    local timeCombatPhaseStart = ent:GetTimeCombatPhaseStart()
                    if timeCombatPhaseStart then -- can be nil if not in combat at this exact moment

                        local timeSinceCombatStart = Shared.GetTime() - timeCombatPhaseStart
                        local bonewallDelay = db.bot.brain.bonewallDelay
                        local delayPassed = timeSinceCombatStart > bonewallDelay
                        if delayPassed and #GetEntitiesForTeamWithinRange("BoneWall", db.bot:GetTeamNumber(), ent:GetOrigin(), 12) <= 0 then
                            bonewallTarget = ent
                        end

                    end

                end

            end

        end

        return bonewallTarget

    end)
    
s:Add("exoNearHive", function(db)

    local team = db.bot:GetTeamNumber()
    local enemyTeam = GetEnemyTeamNumber(team)

    local hives = GetEntitiesForTeam("Hive", team)
    local exos = GetEntitiesForTeam("Exo", enemyTeam)

    if #hives == 0 or #exos == 0 then
        return nil
    end

    for _, hive in ipairs(hives) do
        local hivePos = hive:GetOrigin()

        --------------------------------------------------------------------
        -- 1) EGG + EMBRYO CHECK
        --------------------------------------------------------------------
        local eggs = GetEntitiesForTeam("Egg", team)
        local embryos = GetEntitiesForTeam("Embryo", team)

        local eggCount = 0
        local embryoCount = 0

        for _, egg in ipairs(eggs) do
            if (egg:GetOrigin() - hivePos):GetLength() <= 20 then
                eggCount = eggCount + 1
            end
        end

        for _, emb in ipairs(embryos) do
            if (emb:GetOrigin() - hivePos):GetLength() <= 20 then
                embryoCount = embryoCount + 1
            end
        end

        -- ? Wenn KEINE Eier UND KEINE Embryos ? EXO-Fang deaktivieren
        if eggCount == 0 and embryoCount == 0 then
            return nil
        end

        --------------------------------------------------------------------
        -- 2) ALIEN-ERKENNUNGSLISTE (Gorge ignorieren)
        --------------------------------------------------------------------
        local aliens = GetEntitiesForTeam("Player", team)
        local otherLifeformsNearby = false

        for _, alien in ipairs(aliens) do
            if alien:GetIsAlive() then
                local dist = (alien:GetOrigin() - hivePos):GetLength()

                if dist <= 20 then
                    local class = alien:GetClassName()

                    if class ~= "Gorge" then
                        if class == "Skulk" or
                           class == "Lerk"  or
                           class == "Fade"  or
                           class == "Onos" then
                            otherLifeformsNearby = true
                            break
                        end
                    end
                end
            end
        end

        if otherLifeformsNearby then
            return nil
        end

        --------------------------------------------------------------------
        -- 3) EXO-PRÜFUNG (nur wenn KEINE anderen Lifeforms + Eier/Embryos vorhanden)
        --------------------------------------------------------------------
        for _, exo in ipairs(exos) do
            local exoPos = exo:GetOrigin()
            local dist = (exoPos - hivePos):GetLength()

            if dist <= 15 then
                hive.exoEntity = exo
                hive.exoPos = exoPos
                return hive
            end
        end
    end

    return nil
end)

    s:Add("gameMinutes", function(db)
        return (Shared.GetTime() - GetGamerules():GetGameStartTime()) / 60.0
    end)

    s:Add("doableTechIds", function(db)
        return db.bot.brain:GetDoableTechIds( db.bot:GetPlayer() )
    end)

    s:Add("hives", function(db)
        return GetEntitiesAliveForTeam("Hive", db.bot:GetTeamNumber())
    end)

    s:Add("crags", function(db)
        return GetEntitiesAliveForTeam("Crag", db.bot:GetTeamNumber())
    end)

    s:Add("hivesAndLocations", function(db)
        local result = UnorderedSet()
        local hives = db:Get("hives")
        for _, hive in ipairs(hives) do

            local locId = hive:GetLocationId()
            if locId and locId ~= 0 then
                result:Add({hive, locId})
            end

        end
        return result
    end)

    s:Add("mainHive", function(db)

        local mainHive
        local startingLocationId = db.bot.brain:GetStartingLocationId()
        local hives = db:Get("hives")
        for _, hive in ipairs(hives) do
            if hive:GetLocationId() == startingLocationId then
                mainHive = hive
                break
            end
        end

        return mainHive

    end)

    s:Add("builtHives", function(db)
        local builtHives = {}
        local hives = db:Get("hives")

        for _, hive in ipairs(hives) do
            if hive:GetIsBuilt() then
                table.insert(builtHives, hive)
            end
        end

        return builtHives
    end)

    s:Add("numUnbuiltHives", function(db)
        local hives = db:Get("hives")
        local numUnbuiltHives = 0

        for _, hive in ipairs(hives) do
            if not hive:GetIsBuilt() then
                numUnbuiltHives = numUnbuiltHives + 1
            end
        end

        return numUnbuiltHives
    end)

    s:Add("firstBuiltAndSafeHive", function(db)
        local hives = db:Get("hives")
        local safeHive

        local brain = db.bot.brain

        for _, hive in ipairs(hives) do
            if hive:GetIsBuilt() then

                local hiveLocationName = hive:GetLocationName()
                if hiveLocationName and hiveLocationName ~= "" then
                    if brain and brain:GetIsSafeToDropInLocation(hiveLocationName, db.bot:GetTeamNumber(), db:Get("isEarlyGame")) then
                        safeHive = hive
                        break
                    end
                end

            end
        end

        return safeHive
    end)

    s:Add("cysts", function(db)
        return GetEntitiesAliveForTeam("Cyst", db.bot:GetTeamNumber())
    end)

    s:Add("drifters", function(db)
        return GetEntitiesAliveForTeam("Drifter", db.bot:GetTeamNumber())
    end)

    s:Add("numHarvesters", function(db)
        return GetNumEntitiesOfType("Harvester", db.bot:GetTeamNumber())
    end)

    s:Add("harvesters", function(db)
        return GetEntitiesAliveForTeam("Harvester", db.bot:GetTeamNumber())
    end)

    s:Add("unbuiltHarvesters", function(db)
        local unbuiltHarvesters = {}
        local harvesters = db:Get("harvesters")
        for _, harvester in ipairs(harvesters) do
            if not harvester:GetIsBuilt() then
                table.insert(unbuiltHarvesters, harvester)
            end
        end
        return unbuiltHarvesters
    end)

    s:Add("numHarvsForHive", function(db)

        if GetNumHives() == 1 then
            return 4
        elseif GetNumHives() == 2 then
            return 6
        else
            return 8
        end

        return 0

    end)

    s:Add("overdueForHive", function(db)

        if GetNumHives() == 1 then
            return GetGameMinutesPassed() > 7
        elseif GetNumHives() == 2 then
            return GetGameMinutesPassed() > 14
        else
            return false
        end

    end)

    s:Add("numTunnelEntrances", function(db)
        return GetNumEntitiesOfType("TunnelEntrance", db.bot:GetTeamNumber())
    end)

    s:Add("allTunnelEntrances",
            function(db)
                return GetEntitiesAliveForTeam("TunnelEntrance", kTeam2Index)
            end
    )

    s:Add("numDrifters", function(db)
        return GetNumEntitiesOfType( "Drifter", db.bot:GetTeamNumber() ) + GetNumEntitiesOfType( "DrifterEgg", db.bot:GetTeamNumber() )
    end)

    s:Add("techPointToContaminate", function(db)

        local tps = {}
        for _,tp in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do

            local attached = tp:GetAttached()
            if attached and attached.GetTeamNumber and attached:GetTeamNumber() ~= db.bot:GetTeamNumber() then
                table.insert( tps, tp )
            end

        end

        local cysts = db:Get("cysts")
        local dist, tp = GetMinTableEntry( tps, function(tp)
            return GetMinDistToEntities( tp, cysts )
        end)
        return tp
    end)

    s:Add("connectedTunnelEntrances", function(db)
        local connectedTunnelEntrances = {}
        local tunnelEntrances = db:Get("allTunnelEntrances")
        for _, tunnelEntrance in ipairs(tunnelEntrances) do

            if tunnelEntrance:GetIsBuilt() and
                    tunnelEntrance:GetIsConnected() and
                    not tunnelEntrance.killWithoutCollapse and
                    tunnelEntrance:GetOtherEntrance() ~= nil then

                table.insert(connectedTunnelEntrances, tunnelEntrance)

            end
        end

        return connectedTunnelEntrances
    end)

    s:Add("biomassLevel", function(db)

        local teamInfo = GetTeamInfoEntity(db.bot:GetTeamNumber())
        if teamInfo and teamInfo.GetBioMassLevel then
            return teamInfo:GetBioMassLevel()
        end

        return 0

    end)

    s:Add("techPointToTake", function(db)

        local tps = db:Get("availTechPoints")
        local avail_tps = {}
        for i, tp in ipairs(tps) do -- search through list of available techpoints

            local tpLocationName = tp:GetLocationName()

            -- Make sure we have something friendly before accepting
            local isSafe = db.bot.brain:GetIsSafeToDropHiveInLocation(tpLocationName, db.bot:GetTeamNumber(), db:Get("isEarlyGame"), false)
            --local hasConnectedTunnel = GetLocationHasTunnelEntrance(db:Get("connectedTunnelEntrances"), tp:GetLocationId())

            if isSafe then
                table.insert(avail_tps, tp)
            end
        end

        local hives = db:Get("hives")
        local dist, tp = GetMinTableEntry( avail_tps, function(tp)
            return GetMinDistToEntities( tp, hives )
        end)
        return tp

    end)

    s:Add("techPointToTakeInfest", function(db)

        local tps = db:Get("availTechPoints")
        local avail_tps = {}
        for i, tp in ipairs(tps) do -- search through list of available techpoints

            local tpLocationName = tp:GetLocationName()

            -- As long as no enemy players, try to infest it
            local isSafe = db.bot.brain:GetIsSafeToDropHiveInLocation(tpLocationName, db.bot:GetTeamNumber(), db:Get("isEarlyGame"), true)
            --local hasConnectedTunnel = GetLocationHasTunnelEntrance(db:Get("connectedTunnelEntrances"), tp:GetLocationId())

            if isSafe then
                table.insert(avail_tps, tp)
            end
        end

        local hives = db:Get("hives")
        local dist, tp = GetMinTableEntry( avail_tps, function(tp)
            return GetMinDistToEntities( tp, hives )
        end)
        return tp

    end)
    
s:Add("doubleResPoints", function(db)
    local doubleResPoints = {}
    local notCystedResPoints = db:Get("availResPoints")
    local harvesters = db:Get("harvesters")
    local tunnelEntrances = db:Get("allTunnelEntrances")

    -- Kombinieren der zystierten ResPoints und aktiven Harvesters
    local allResPoints = {}
    for _, resPoint in ipairs(notCystedResPoints) do
        table.insert(allResPoints, resPoint)
    end
    for _, harvester in ipairs(harvesters) do
        table.insert(allResPoints, harvester)
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
        end
    end

    -- Füge ResPoint-Paare hinzu, die sich am gleichen Standort befinden und keine Tunnel haben
    for locationName, resPoints in pairs(locationMap) do
        if #resPoints > 1 then
            for i = 1, #resPoints - 1 do
                for j = i + 1, #resPoints do
                    local hasTunnel = false
                    for _, tunnel in ipairs(tunnelEntrances) do
                        if tunnel:GetLocationName() == locationName then
                            hasTunnel = true
                            break
                        end
                    end
                    if not hasTunnel then
                        table.insert(doubleResPoints, {resPoints[i], resPoints[j]})
                        --Print("Double ResPoints found: " .. resPoints[i]:GetLocationName() .. " and " .. resPoints[j]:GetLocationName())  -- Debugging-Ausgabe
                    end
                end
            end
        end
    end

    --Print("Total Double ResPoints: " .. tostring(#doubleResPoints))  -- Debugging-Ausgabe
    return doubleResPoints
end)
s:Add("doubleResNoShade", function(db)
    -- Debugging-Ausgabe
    local doubleResPoints = {}
    local cystedResPoints = db:Get("cystedAvailResPoints")
    local harvesters = db:Get("harvesters")

    if not cystedResPoints then
        return doubleResPoints
    end

    if not harvesters then
        return doubleResPoints
    end

    -- Alle Ressourcenknoten und Harvester sammeln
    local allResPoints = {}
    for _, resPoint in ipairs(cystedResPoints) do
        table.insert(allResPoints, resPoint)
    end
    for _, harvester in ipairs(harvesters) do
        table.insert(allResPoints, harvester)
    end

    -- Doppelte ResPoints finden, die im selben Standort sind und nicht mehr als 15 Einheiten auseinanderliegen
    for i = 1, #allResPoints - 1 do
        for j = i + 1, #allResPoints do
            local resPoint1 = allResPoints[i]
            local resPoint2 = allResPoints[j]
            local distanceBetweenPoints = (resPoint1:GetOrigin() - resPoint2:GetOrigin()):GetLength()

            if resPoint1:GetLocationId() == resPoint2:GetLocationId() and distanceBetweenPoints <= 15 then
                table.insert(doubleResPoints, {resPoint1, resPoint2})
                -- Debugging-Ausgabe: Double ResPoints gefunden
            end
        end
    end

    -- Debugging-Ausgabe: Gesamtanzahl der Double ResPoints
    return doubleResPoints
end)

   s:Add("safeTechPointNoTunnel", function(db)
    local safeTPNoTunnels = {}
    local safeTechPoints = db:Get("safeTechPoints")
    local tunnelEntrances = db:Get("allTunnelEntrances")
    local enemyTeamNumber = GetEnemyTeamNumber(db.bot:GetTeamNumber())
    local enemyBaseLocation = GetTeamBrain(enemyTeamNumber).initialTechPointLoc

    --[[ Zuerst die Doppel-Resourcen-Punkte prüfen
    local doubleResPoints = db:Get("doubleResPoints")
    for _, resPair in ipairs(doubleResPoints) do
        local resPoint1 = resPair[1]
        local resPoint2 = resPair[2]
        if not GetLocationHasTunnelEntrance(tunnelEntrances, resPoint1:GetLocationId()) and
           not GetLocationHasTunnelEntrance(tunnelEntrances, resPoint2:GetLocationId()) then
            table.insert(safeTPNoTunnels, resPoint1)
            table.insert(safeTPNoTunnels, resPoint2)
        end
    end--]]

    -- Falls keine Doppel-Resourcen-Punkte verfügbar sind, prüfen wir die TechPoints
    if #safeTPNoTunnels == 0 then
        for _, tp in ipairs(safeTechPoints) do
            if not GetLocationHasTunnelEntrance(tunnelEntrances, tp:GetLocationId()) then
                if tp:GetLocationName() ~= enemyBaseLocation then
                    table.insert(safeTPNoTunnels, tp)
                end
            end
        end
    end

    local mainHive = db:Get("mainHive")

    if not mainHive then
        -- z.B. wenn das Haupt-Hive zerstört wurde
        return safeTPNoTunnels[1]
    else
        -- Filter den nächsten TP heraus
        local dist, tp = GetMinTableEntry(safeTPNoTunnels, function(tp)
            return tp:GetOrigin():GetDistanceTo(mainHive:GetOrigin())
        end)

        return tp
    end
end)

    s:Add("unConnectedTunnelEntrance", function(db)

        local unConnectedTunnelEntrance
        local tunnelEntrances = db:Get("allTunnelEntrances")
        for _, tunnelEntrance in ipairs(tunnelEntrances) do
            if not GetIsTunnelEntranceValidForTravel(tunnelEntrance) then
                unConnectedTunnelEntrance = tunnelEntrance
                break
            end
        end

        return unConnectedTunnelEntrance

    end)

    s:Add("safeTechPoints", function(db)

        local safeTechPoints = {}
        local techPoints = GetEntities("TechPoint")
        for _, techPoint in ipairs(techPoints) do

            -- Ignore main base
            local isMainLocation = techPoint:GetLocationName() == db.bot.brain:GetStartingTechPoint()
            local isSafe = db.bot.brain:GetIsSafeToDropInLocation(techPoint:GetLocationName(), db.bot:GetTeamNumber(), db:Get("isEarlyGame"))

            if isSafe and not isMainLocation then
                table.insert(safeTechPoints, techPoint)
            end

        end

        return safeTechPoints

    end)

    s:Add("safeTechPointsWithMain", function(db)

        local safeTechPoints = {}
        local techPoints = GetEntities("TechPoint")
        for _, techPoint in ipairs(techPoints) do

            local isSafe = db.bot.brain:GetIsSafeToDropInLocation(techPoint:GetLocationName(), db.bot:GetTeamNumber(), db:Get("isEarlyGame"))

            if isSafe then
                table.insert(safeTechPoints, techPoint)
            end

        end

        return safeTechPoints

    end)

    s:Add("safeHives", function(db)

        local safeHives = {}
        local hives = db:Get("hives")
        for _, hive in ipairs(hives) do
            if db.bot.brain:GetIsSafeToDropInLocation(hive:GetLocationName(), db.bot:GetTeamNumber(), db:Get("isEarlyGame")) then
                table.insert(safeHives, hive)
            end
        end

        return safeHives

    end)

    s:Add("techPointToTakeEmergency", function(db)

        local tps = db:Get("availTechPoints")
        local avail_tps = {}
        for i, tp in ipairs(tps) do -- search through list of available techpoints
            table.insert(avail_tps, tp)
        end
        local cysts = db:Get("cysts")
        local dist, tp = GetMinTableEntry( avail_tps, function(tp)
            return GetMinDistToEntities( tp, cysts )
        end)
        return tp

    end)

    s:Add("numResourcePoints", function(db)
        return #GetEntities("ResourcePoint")
    end)

    -- RPs that are not taken, not necessarily good or on infestation
    s:Add("availResPoints", function(db)

        local rps = {}
        for _,rp in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do

            local attached = rp:GetAttached()
            if not attached or (attached:isa("Extractor") and attached:GetIsGhostStructure()) then
                table.insert( rps, rp )
            end

        end
        return rps

    end)

    s:Add("cystedAvailResPoints", function(db)
        local rps = db:Get("availResPoints")
        local cystedEmptyResPoints = {}
        for _, resPoint in ipairs(rps) do
            if GetCystForPoint(db, resPoint:GetOrigin()) or GetIsPointOnInfestation(resPoint:GetOrigin()) then
                table.insert(cystedEmptyResPoints, resPoint)
            end
        end
        return cystedEmptyResPoints
    end)

    s:Add("availTechPoints", function(db)
        return GetAvailableTechPoints()
    end)

    s:Add("cystedAvailTechPoints", function(db)

        local techPoints = db:Get("availTechPoints")
        local cystedAvailTechPoints = {}

        for _, techPoint in ipairs(techPoints) do
            if GetCystForPoint(db, techPoint:GetOrigin()) then
                table.insert(cystedAvailTechPoints, techPoint)
            end
        end

        return cystedAvailTechPoints
    end)

    s:Add("hivesByLocation", function(db)

        local hivesByLocation = IterableDict()
        local hives = db:Get("hives")
        for _, hive in ipairs(hives) do

            local hiveLocationName = hive:GetLocationName()
            if hiveLocationName ~= "" then

                if not hivesByLocation[hiveLocationName] then
                    hivesByLocation[hiveLocationName] = {}
                end

                table.insert(hivesByLocation[hiveLocationName], hive)

            end

        end

        return hivesByLocation

    end)

    s:Add("availableSafeHiveResNode", function(db)

        local availSafeHiveResNode
        local rps = db:Get("availResPoints")
        local hivesByLocation = db:Get("hivesByLocation")

        for _, resNode in ipairs(rps) do

            local isHiveNode = hivesByLocation[resNode:GetLocationName()] ~= nil
            local isSafe = db.bot.brain:GetIsSafeToDropInLocation(resNode:GetLocationName(), db.bot:GetTeamNumber(), db:Get("isEarlyGame"))

            if isHiveNode and isSafe then
                availSafeHiveResNode = resNode
                break
            end

        end

        return availSafeHiveResNode

    end)

    s:Add("tunnelsByLocation", function(db)

        local tunnelsByLocation = IterableDict()
        local tunnelEntrances = db:Get("allTunnelEntrances")
        for _, tunnelEntrance in ipairs(tunnelEntrances) do

            local tunnelLocationName = tunnelEntrance:GetLocationName()
            if tunnelLocationName ~= "" then

                if not tunnelsByLocation[tunnelLocationName] then
                    tunnelsByLocation[tunnelLocationName] = {}
                end

                table.insert(tunnelsByLocation[tunnelLocationName], tunnelEntrance)

            end

        end

        return tunnelsByLocation

    end)

    s:Add("availableSafeTunnelResNode", function(db)

        local availSafeTunnelResNode
        local rps = db:Get("availResPoints")
        local tunnelsByLocation = db:Get("tunnelsByLocation")

        for _, resNode in ipairs(rps) do

            local hasTunnel = tunnelsByLocation[resNode:GetLocationName()] ~= nil
            local isSafe = db.bot.brain:GetIsSafeToDropInLocation(resNode:GetLocationName(), db.bot:GetTeamNumber(), db:Get("isEarlyGame"))

            if hasTunnel and isSafe then

                if GetIsTunnelEntranceValidForTravel(tunnelsByLocation[resNode:GetLocationName()][1]) then
                    availSafeTunnelResNode = resNode
                    break
                end

            end

        end

        return availSafeTunnelResNode

    end)

    s:Add("resPointToTake", function(db)
        local rps = db:Get("availResPoints")

        local safeHiveResNode = db:Get("availableSafeHiveResNode")
        if safeHiveResNode then return safeHiveResNode end

        local safeTunnelResNode = db:Get("availableSafeTunnelResNode")
        if safeTunnelResNode then return safeTunnelResNode end

        local closestToEnts = {}
        table.addtable(db:Get("hives"), closestToEnts)
        table.addtable(db:Get("allTunnelEntrances"), closestToEnts)

        local enemyTeam = GetEnemyTeamNumber(db.bot:GetTeamNumber())
        local enemyTechpoint = GetTeamBrain(enemyTeam).initialTechPointLoc
        local enemyNaturals = GetLocationGraph():GetNaturalRtsForTechpoint(enemyTechpoint)

        local dist, rp = GetMinTableEntry( rps, function(rp)

            -- Avoid placing harvesters at enemy "naturals" until a certain time has passed
            local rpLocationName = rp:GetLocationName()
            local isEnemyNaturalLocation =
            rpLocationName and rpLocationName ~= "" and
                    enemyNaturals and
                    enemyNaturals:Contains(rpLocationName) and
                    db:Get("gameMinutes") < 5

            -- Check infestation
            if not isEnemyNaturalLocation and
                    db.bot.brain:GetIsSafeToDropInLocation(rp:GetLocationName(), db.bot:GetTeamNumber(), db:Get("isEarlyGame")) then
                return GetMinPathDistToEntities( rp, closestToEnts )
            end
            return nil
        end)

        return rp

    end)
    
    s:Add("techPoints", function(db)
    local techPoints = {}
    for _, tp in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
        table.insert(techPoints, tp)
    end
    return techPoints
    end)

    s:Add("whips", function(db)
        return GetEntitiesAliveForTeam("Whip", db.bot:GetTeamNumber())
    end)

    return s
end