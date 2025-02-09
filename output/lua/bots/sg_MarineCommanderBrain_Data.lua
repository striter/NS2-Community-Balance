 Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local function CreateBuildStructureActionNearFurthestPower( techId, className, numExistingToWeightLPF,  maxDist)

    return function(bot, brain)

        local name = "build"..EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local coms = doables[techId]
        local targetPowernode = sdb:Get("powerNodeToFortify")

        
        if targetPowernode and coms ~= nil and #coms > 0 then
            assert( coms[1] == com )

            -- figure out how many exist already
            local existingEnts = GetEntitiesForTeamWithinRange( className, com:GetTeamNumber(),targetPowernode:GetOrigin(), maxDist + 1)
            weight = EvalLPF( #existingEnts, numExistingToWeightLPF )
        end
        
        if not targetPowernode then
            weight = 0
        end
        
        if (sdb:Get("gameMinutes") < 4) then
            weight = 0
        end
        


        return { name = name, weight = weight,
            perform = function(move)
                if targetPowernode then
                    local pos = GetRandomBuildPosition( techId, targetPowernode:GetOrigin(), maxDist )
                    if pos ~= nil then
                        brain:ExecuteTechId( com, techId, pos, com )
                    end
                end
            end }
    end

end


local kStationBuildDist = 20.0
local kPowerPointDist = 30.0
local kProtoDist = 5.0

local function CreateBuildNearStationAction( techId, className, numToBuild, weightIfNotEnough )

    return CreateBuildStructureAction(
            techId, className,
            {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
            },
            "CommandStation",
            kStationBuildDist )
end

local function CreateBuildNearStationActionLate( techId, className, numToBuild, weightIfNotEnough , lateTime)

    return CreateBuildStructureActionLate(
            techId, className,
            {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
            },
            "CommandStation",
            kStationBuildDist,
            lateTime)
end
local function CreateBuildNearEachPower( techId, className, numToBuild, weightIfNotEnough )

    return CreateBuildStructureActionForEach(
            techId, className,
            {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
            },
            "PowerPoint",
            kPowerPointDist )
end


local function CreateBuildNearEachProto( techId, className, numToBuild, weightIfNotEnough )

    return CreateBuildStructureActionForEach(
            techId, className,
            {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
            },
            "PrototypeLab",
            kProtoDist )
end


local function FortifyFront( techId, className, weightIfNotEnough, dist )
    local numToBuild = 1
    return CreateBuildStructureActionNearFurthestPower(
        techId, className,
        {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
        },
        dist)
end

local function GetPathToEnemyHive(origin)
    local hives = GetEntitiesForTeam("Hive", kAlienTeamType)
    if #hives<=0 then
        return nil
    end
    local hive = hives[math.random(#hives)]
    local pathPoints = PointArray()
    local reachable = Pathing.GetPathPoints(origin, hive, pathPoints)
    if not reachable or #pathPoints<=0 then
        return nil
    end
    return pathPoints
end
local wallTestDirs = {
    Vector(1,0,0),
    Vector(1,0,1),
    Vector(0,0,1),
    Vector(-1,0,1)
}
local testMax = 10
local function GetSmallestWallPoints(pathPoints)
    local leftSide, rightSide
    local minDist
    for _, point in ipairs(pathPoints) do
        for __, dir in wallTestDirs do
            local startPoint = point
            local endPoint  = point + dir * testMax
            local endPoint2 = point - dir * testMax
            local trace  = Shared.TraceRay(startPoint, endPoint, CollisionRep.Move, PhysicsMask.All, EntityFilterAll())
            local trace2 = Shared.TraceRay(startPoint, endPoint2,CollisionRep.Move, PhysicsMask.All, EntityFilterAll())
            if trace.fraction  > 0.05 and trace.fraction  <= 1 and 
               trace2.fraction > 0.05 and trace2.fraction <= 1 then
                local dist = (trace.endPoint - trace2.endPoint):GetLength()
                if not minDist or minDist > dist then
                    minDist = dist
                    leftSide = trace.endPoint
                    rightSide = trace.endPoint
                end
            end
        end
    end
    return leftSide, rightSide
end
local function GetTestablePoints(startPoint, pathPoints, maxPathDist)
    local splitPoints = SplitPathPoints(startPoint, pathPoints, 2)
    
    local newPoints = {}
    
    for index, point in ipairs(splitPoints) do
        if index > maxPathDist then
            break
        end
        table.insert(newPoints, point)
    end
    return newPoints
end

local function GetArmoryWallPosition(startOrigin)
    local pathToHive = GetPathToEnemyHive(startOrigin)
    if pathToHive then
        local testablePoints = GetTestablePoints(startOrigin, pathToHive, 15)
        local leftSide, rightSide = GetSmallestWallPoints(testablePoints)
        if leftSide ~= nil and rightSide ~= nil then
            return (leftSide + rightSide)*0.5
        end
    end
    return Vector(0,0,0)
end



local function GetIsWeldedByOtherMAC(self, target)

    if target then
    
        for _, mac in ipairs(GetEntitiesForTeam("MAC", self:GetTeamNumber())) do
        
            if self ~= mac then
            
                if mac.secondaryTargetId ~= nil and Shared.GetEntity(mac.secondaryTargetId) == target then
                    return true
                end
                
                local currentOrder = mac:GetCurrentOrder()
                local orderTarget = nil
                if currentOrder and currentOrder:GetParam() ~= nil then
                    orderTarget = Shared.GetEntity(currentOrder:GetParam())
                end
                
                if currentOrder and orderTarget == target and (currentOrder:GetType() == kTechId.FollowAndWeld or currentOrder:GetType() == kTechId.Weld or currentOrder:GetType() == kTechId.AutoWeld) then
                    return true
                end
                
            end
            
        end
        
    end
    
    return false
    
end

kMarineComBrainActions =
{
    CreateBuildNearStationAction( kTechId.ArmsLab        , "ArmsLab"        , 1 , 3.1) ,
    
    -- why does the bot commander sometimes think it can't build a proto???
    CreateBuildNearStationAction( kTechId.PrototypeLab   , "PrototypeLab"   , 1 , 15) ,
    CreateBuildNearStationActionLate( kTechId.ArmsLab        , "ArmsLab"        , 2 , 2.0, 2) ,
    CreateBuildNearStationActionLate( kTechId.Observatory    , "Observatory"    , 1 , 2.0, 3) ,
    CreateBuildNearStationActionLate( kTechId.Armory         , "Armory"         , 1 , 3.0 , 1.5),
    CreateBuildNearStationActionLate( kTechId.PhaseGate      , "PhaseGate"      , 1 , 3.0, 4) ,
    CreateBuildNearStationActionLate( kTechId.InfantryPortal , "InfantryPortal" , 4 , 0.2, 5.5) ,
    
    
    CreateBuildNearEachPower( kTechId.PhaseGate      , "PhaseGate"      , 1 , 0.2 ),
    CreateBuildNearEachPower( kTechId.Observatory    , "Observatory"    , 1 , 0.5 ),

    FortifyFront( kTechId.PrototypeLab   , "PrototypeLab"   , 2.2 , 6 ),
    FortifyFront( kTechId.Armory         , "Armory"         , 2   , 6 ),
    FortifyFront( kTechId.PhaseGate      , "PhaseGate"      , 2   , 6 ),
    FortifyFront( kTechId.RoboticsFactory, "RoboticsFactory", 1   , 6 ),
    
    
    -- Upgrades from structures
    CreateUpgradeStructureAction( kTechId.ExosuitTech           , 5.1 ) ,
    CreateUpgradeStructureAction( kTechId.AdvancedArmoryUpgrade , 3.5, kTechId.AdvancedArmory) ,
    
    CreateBuildNearStationActionLate( kTechId.RoboticsFactory, "RoboticsFactory", 1 , 0.2, 5) ,
    CreateUpgradeStructureActionLate( kTechId.UpgradeRoboticsFactory , 1.5 , nil, 6) ,
    
    CreateUpgradeStructureActionLate( kTechId.ShotgunTech           , 1.0 , nil,  6) ,
    CreateUpgradeStructureActionLate( kTechId.JetpackTech           , 2.9 , nil,  4) ,
    CreateUpgradeStructureActionLate( kTechId.MinesTech             , 0.2 , nil,  4) ,
    CreateUpgradeStructureActionLate( kTechId.HeavyMachineGunTech   , 1.1 , nil,  4) ,
    CreateUpgradeStructureActionLate( kTechId.GrenadeTech           , 0.3 , nil,  6) ,
    

    CreateUpgradeStructureAction( kTechId.PhaseTech , 2.0),
    

    CreateUpgradeStructureAction( kTechId.Weapons1 , 5.0 ) ,
    CreateUpgradeStructureAction( kTechId.Weapons2 , 4.0 ) ,
    CreateUpgradeStructureAction( kTechId.Weapons3 , 3.0 ) ,
    CreateUpgradeStructureAction( kTechId.Armor1   , 5.0 ) ,
    CreateUpgradeStructureAction( kTechId.Armor2   , 4.0 ) ,
    CreateUpgradeStructureAction( kTechId.Armor3   , 3.0 ) ,
    
    -- this doesn't actually upgrade, it just sockets everything at the start of the game.
    -- TODO: Don't socket the node in an inaccessable area.
    CreateUpgradeStructureAction( kTechId.SocketPowerNode, 1.0 ) ,

    function(bot, brain)

        local name = "commandstation"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local targetTP

        -- Find a cc slot!
        targetTP = sdb:Get("techPointToTake")

        if targetTP then
            weight = 1
        end
        
        if (sdb:Get("gameMinutes") < 6) then
            weight = 0
        end

        return { name = name, weight = weight,
            perform = function(move)
                if doables[kTechId.CommandStation] and targetTP then
                    local sucess = brain:ExecuteTechId( com, kTechId.CommandStation, targetTP:GetOrigin(), com )
                end
            end}
    end,
    
    
    function(bot, brain)

        local weight = 0
        local team = bot:GetPlayer():GetTeam()
        local numDead = team:GetNumPlayersInQueue()
        if numDead > 1 then
            weight = 5.0
        end

        return CreateBuildNearStationAction( kTechId.InfantryPortal , "InfantryPortal" , 4 , weight )(bot, brain)
    end,
    
    function(bot, brain)

        local name = "dropjetpacks"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local weight = 0
        local maxJetpacks = 10
        local team = bot:GetPlayer():GetTeam()
        
        local jetpacks = GetEntitiesForTeam("Jetpack", kMarineTeamType)
        
        local doables = sdb:Get("doableTechIds")
        if doables[kTechId.DropJetpack] then
            weight = EvalLPF( #jetpacks,
                    {
                    {0, 1.5},
                    {3, 0.5},
                    {10,0.0},
                    })
        end
        
        if #jetpacks > maxJetpacks then 
            weight = 0
        end
        
        local protoLabs = GetEntitiesForTeam("PrototypeLab", kMarineTeamType)
        if #protoLabs <= 0 then 
            weight = 0
        end
        local proto = protoLabs[math.random(#protoLabs)]
        if not proto or not proto:GetIsBuilt() or not proto:GetIsAlive() then
            weight = 0
        end
        
        return { name = name, weight = weight,
            perform = function(move)
                
                --if (sdb:Get("gameMinutes") < 5) then
                --    return
                --end
                local aroundPos = proto:GetOrigin()
                
                local targetPos = GetRandomSpawnForCapsule(0.4, 0.4, aroundPos, 0.01, kArmoryWeaponAttachRange * 0.5, EntityFilterAll(), nil)
                if targetPos then
                    local sucess = brain:ExecuteTechId(com, kTechId.DropJetpack, targetPos, com, proto:GetId())
                end
            end}
    end,
    
    
    function(bot, brain)

        local name = "dropmachineguns"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local weight = 0
        local maxMgs = 10
        local team = bot:GetPlayer():GetTeam()
        
        local mgs = GetEntitiesForTeam("HeavyMachineGun", kMarineTeamType)
        
        local doables = sdb:Get("doableTechIds")
        if doables[kTechId.DropHeavyMachineGun] then
            if (sdb:Get("gameMinutes") > 5 or team:GetTeamResources() > 120) then
                weight = EvalLPF( #mgs,
                    {
                    {0, 1.5},
                    {2, 0.2},
                    {10,0.01},
                    })
            end
        end
        if #mgs > maxMgs then 
            weight = 0
        end
        
        -- TODO: Make sure it's a marine and/or team 1...
        local aas = GetEntsWithTechId({kTechId.AdvancedArmory})
        if #aas <= 0 then 
            weight = 0
        end
        local armory = aas[math.random(#aas)]
        if not armory or not armory:GetIsBuilt() or not armory:GetIsAlive() then
            weight = 0
        end
        
        return { name = name, weight = weight,
            perform = function(move)
                if armory then
                    local aroundPos = armory:GetOrigin()
                    
                    local targetPos = GetRandomSpawnForCapsule(0.5, 0.5, aroundPos, 0.01, kArmoryWeaponAttachRange * 0.5, EntityFilterAll(), nil)
                    if targetPos then
                        local sucess = brain:ExecuteTechId(com, kTechId.DropHeavyMachineGun, targetPos, com, armory:GetId())
                    end
                end
            end}
    end,

    function(bot, brain)

        local name = "extractor"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local targetRP

        if doables[kTechId.Extractor] and 
            (sdb:Get("gameMinutes") < 4 or (not bot.nextRTDrop or bot.nextRTDrop < Shared.GetTime())) then

            targetRP = sdb:Get("resPointToTake")

            if targetRP ~= nil then
                weight = EvalLPF( sdb:Get("numExtractors"),
                    {
                        {0, 10.0},
                        {4, 8.0},
                        {6, 5.0},
                        {8, 4.0},
                        {16,3.0},
                        })

            end
        end

        return { name = name, weight = weight,
            perform = function(move)
                if targetRP ~= nil then
                    bot.nextRTDrop =  Shared.GetTime() + 2
                    local success = brain:ExecuteTechId( com, kTechId.Extractor, targetRP:GetOrigin(), com )
                end
            end}
    end,
    
    --[[
    function(bot, brain)

        local name = "buildWall"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local targetRP

        if doables[kTechId.Armory] and 
            (sdb:Get("gameMinutes") > 5 or (not bot.nextWallDrop or bot.nextWallDrop < Shared.GetTime())) then

            targetPos = sdb:Get("wallPosition")

            weight = 0

        end

        return { name = name, weight = weight,
            perform = function(move)
                if targetRP ~= nil then
                    bot.nextWallDrop =  Shared.GetTime() + 4
                    local success = brain:ExecuteTechId( com, kTechId.Extractor, targetRP:GetOrigin(), com )
                end
            end}
    end,
]]--
    function(bot, brain)

        local name = "droppacks"
        local com = bot:GetPlayer()
        local alertqueue = com:GetAlertQueue()

        --save times of having players last served to ignore spam
        bot.lastServedDropPack = bot.lastServedDropPack or {}

        local reactTechIds = {
            [kTechId.MarineAlertNeedAmmo] = kTechId.AmmoPack,
            [kTechId.MarineAlertNeedMedpack] = kTechId.MedPack,
            [kTechId.MarineAlertNeedOrder] = kTechId.Observatory
        }

        local techCheckFunction = {
            [kTechId.MarineAlertNeedAmmo] = function(target)
                local weapon = target:GetActiveWeapon()

                local ammoPercentage = 1
                if weapon and weapon:isa("ClipWeapon") then
                    local max = weapon:GetMaxAmmo()
                    if max > 0 then
                        ammoPercentage = weapon:GetAmmo() / max
                    end
                end

                return ammoPercentage
            end,
            [kTechId.MarineAlertNeedMedpack] = function(target)
                return target:GetHealthFraction() end,
            [kTechId.MarineAlertNeedOrder] = function(target)
                return #GetEntitiesForTeamWithinXZRange( "Observatory", com:GetTeamNumber(), target:GetOrigin(), Observatory.kDetectionRange) end,
        }

        local weight = 0.0
        local targetPos, targetId
        local techId

        local time = Shared.GetTime()

        for i, alert in ipairs(alertqueue) do
            local aTechId = alert.techId
            local targetTechId = reactTechIds[aTechId]
            local target
            if targetTechId and time - alert.time < 0.5 then
                target = Shared.GetEntity(alert.entityId)

                local lastServerd = bot.lastServedDropPack[alert.entityId]
                local servedTime = lastServerd and lastServerd.time or time
                local servedCount = lastServerd and lastServerd.count or 0

                --reset count if last served drop pack is more than 5 secs ago
                if servedCount > 0 and time - servedTime > 5 then
                    servedCount = 0
                    bot.lastServedDropPack[alert.entityId] = nil
                end

                if target and servedCount < 3 and time - servedTime < 2 then
                    local alertPiority = EvalLPF( techCheckFunction[aTechId](target),
                    {
                        {0, 6.0},
                        {0.5, 3.0},
                        {1, 0.0},
                    })

                    if alertPiority == 0 then
                        target = nil
                    elseif alertPiority > weight then
                        techId = targetTechId
                        weight = alertPiority
                        targetPos = target:GetOrigin() --Todo Add jitter to position
                        targetId = target:GetId()
                    end
                end
            end

            if not target then
                table.remove(alertqueue, i)
            end
        end

        com:SetAlertQueue(alertqueue)

        return { name = name, weight = weight,
            perform = function(move)
                if targetId then
                    if techId == kTechId.Observatory then
                        local pos = GetRandomBuildPosition( techId, targetPos, 5 )
                        if pos ~= nil then
                            brain:ExecuteTechId( com, techId, pos, com )
                        end
                    else
                        local sucess = brain:ExecuteTechId( com, techId, targetPos, com, targetId )
                        if sucess then
                            bot.lastServedDropPack[targetId] = bot.lastServedDropPack[targetId] or {}
                            local count = bot.lastServedDropPack[targetId].count or 0

                            bot.lastServedDropPack[targetId].time = Shared.GetTime()
                            bot.lastServedDropPack[targetId].count = count + 1
                        end
                    end
                end
            end}
    end,
    
    function(bot, brain)
        local name = "macs"
        local com = bot:GetPlayer()
        local team = bot:GetPlayer():GetTeam()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local macs = sdb:Get("macs")
        local structures = doables[kTechId.MAC]
        
        if not brain.lastMacScan or brain.lastMacScan < Shared.GetTime() - 5 then
            brain.lastMacScan = Shared.GetTime()
        
            for _, mac in ipairs(macs) do
                if not mac:GetHasOrder() then
                
                    local marines = GetEntitiesForTeamWithinRange("Player", com:GetTeamNumber(), mac:GetOrigin(), MAC.kOrderScanRadius * 1.5)
                    for _, marine in ipairs(marines) do
                        if not GetIsWeldedByOtherMAC(mac, marine) then
                            mac:GiveOrder(kTechId.FollowAndWeld, marine:GetId(), marine:GetOrigin(), nil, true, true)
                        end
                    end
                end
            end
        end
        
        -- for some reason the bot comm LOVES building macs
        if #macs < 10 and structures ~= nil then
            weight = EvalLPF( #macs,
                    {
                    {0, 0.5},
                    {2, 0.1},
                    {10,0.0},
                    })
        end

        return { name = name, weight = weight,
            perform = function(move)
            
                if structures == nil then return end
                local macs = sdb:Get("macs")
                if #macs < 10 then
                    -- choose a random host
                    local host = structures[ math.random(#structures) ]
                    if host and host:GetIsAlive() then
                        brain:ExecuteTechId( com, kTechId.MAC, Vector(0,0,0), host )
                    end
                end
            end}
    end,
    
    function(bot, brain)

        return { name = "idle", weight = 1e-5,
            perform = function(move)
                if brain.debug then
                    DebugPrint("idling..")
                end 
            end}
    end
}



-- support Jon's crazy mod
if table.contains(kTechId, "FlamethrowerTech") then

    table.insert(kMarineComBrainActions, CreateUpgradeStructureAction( kTechId.FlamethrowerTech   , 1.0+math.random() ))
    
end

if table.contains(kTechId, "GrenadeLauncherTech") then

    table.insert(kMarineComBrainActions, CreateUpgradeStructureAction( kTechId.GrenadeLauncherTech   , 1.0+math.random() ))
    
end
    


------------------------------------------
--  Build the senses database
------------------------------------------

function CreateMarineComSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("gameMinutes", function(db)
            return (Shared.GetTime() - GetGamerules():GetGameStartTime()) / 60.0
            end)

    s:Add("doableTechIds", function(db)
            return db.bot.brain:GetDoableTechIds( db.bot:GetPlayer() )
            end)

    s:Add("stations", function(db)
            return GetEntitiesForTeam("CommandStation", kMarineTeamType)
            end)
            
    s:Add("powernodes", function(db)
            local builtPowernodes = {}
            local allPowernodes = GetEntitiesForTeam("PowerPoint", kMarineTeamType)
            for _, pn in ipairs(allPowernodes) do
                
                if pn:GetIsBuilt() and pn:GetIsAlive() then
                    table.insert(builtPowernodes, pn)
                end
            end
            
            return builtPowernodes
            end)
     
    s:Add("wallPosition", function(db)
            local fortify = db:Get("powerNodeToFortify")
            if fortify then
            
            end
            return nil
            end)
            
    s:Add("arcs", function(db)
            return GetEntitiesForTeam("ARC", kMarineTeamType)
            end)
            
    s:Add("macs", function(db)
            return GetEntitiesForTeam("MAC", kMarineTeamType)
            end)
            
    s:Add("availResPoints", function(db)
            --return GetAvailableResourcePoints()
            return ResourcePointsWithPathToCC(GetAvailableResourcePoints(), db:Get("stations"))
            end)
            
    s:Add("numExtractors", function(db)
            return GetNumEntitiesOfType("ResourceTower", kMarineTeamType)
            end)

    s:Add("numInfantryPortals", function(db)
        return GetNumEntitiesOfType("InfantryPortal", kMarineTeamType)
    end)
    
    s:Add("techPointToTake", function(db)
        local tps = GetAvailableTechPoints()
            local hives = db:Get("stations")
            local dist, tp = GetMinTableEntry( tps, function(tp)
                return GetMinPathDistToEntities( tp, hives )
                end)
            return tp
            end)

    s:Add("powerNodeToFortify", function(db)
        local powernodes = db:Get("powernodes")
        local stations = db:Get("stations")
        local dist, power = GetMaxTableEntry( powernodes, function(power)
            return GetMaxPathDistToEntities( power, stations )
            end)
        return power
        end)
            
    s:Add("resPointToTake", function(db)
            local rps = db:Get("availResPoints")
            local stations = db:Get("stations")
            local dist, rp = GetMinTableEntry( rps, function(rp)
                return GetMinPathDistToEntities( rp, stations )
                end)
            return rp
            end)

    return s

end
