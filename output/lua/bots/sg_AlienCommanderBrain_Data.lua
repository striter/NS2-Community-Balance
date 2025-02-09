Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local kHiveBuildDist = 15.0

local function CreateBuildNearHiveAction( techId, className, numToBuild, weightIfNotEnough )

    return CreateBuildStructureActionLate(
            techId, className,
            {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
            },
            "Hive",
            kHiveBuildDist,
            4            )
end

local function CreateBuildNearHiveActionWithReqHiveNum( techId, className, numToBuild, weightIfNotEnough, reqHiveNum )

    local createBuildStructure = CreateBuildStructureActionLate(
        techId, className,
        {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
        },
        "Hive",
        kHiveBuildDist ,
        4.5)

    return function(bot, brain)
        local action = createBuildStructure(bot, brain)

        local sdb = brain:GetSenses()
        if sdb:Get("numHives") < reqHiveNum then
            action.weight = 0.0
        end

        return action
    end
end

local function CreateUpgradeStructureActionAfterTime( techId, weightIfCanDo, existingTechId, delayTime )

    local createUpgradeStructure = CreateUpgradeStructureAction(techId, weightIfCanDo, existingTechId)
    return function (bot, brain)
        local action =  createUpgradeStructure(bot, brain)

        local sdb = brain:GetSenses()
        
        if sdb:Get("gameMinutes") < delayTime then
            action.weight = 0.0
        end

        return action
    end
end

local function UpgradeHiveAfterTime(techId, weightIfCanDo, time)
    local createUpgradeStructure = CreateUpgradeStructureAction(techId, weightIfCanDo, nil)
    return function (bot, brain)
        local action =  createUpgradeStructure(bot, brain)

        local sdb = brain:GetSenses()

        
        if sdb:Get("gameMinutes") < time then
            action.weight = 0.0
        end
        
        if brain.hiveMemories and brain.hiveMemories[techId] and Shared.GetTime() - brain.hiveMemories[techId] < kUpgradeHiveResearchTime then
            --Log("Tried to make a hive type but currently on timeout, setting weight to 0")
            action.weight = 0.0
        end
        
        local perform = action.perform
        action.perform = function(move)
            
            if not brain.hiveMemories then
                brain.hiveMemories = {}
            end
            
            if brain.hiveMemories[techId] and Shared.GetTime() - brain.hiveMemories[techId] < kUpgradeHiveResearchTime then
                --Log("Tried to make a hive type but currently on timeout, skipping creation of the new hive type")
                return
            else
                brain.hiveMemories[techId] = Shared.GetTime()
            end
            
            return perform(move)
        end
        return action
    end
end

local harvesterBuildDist = 20
local function CreateBuildNearEachHarvester( techId, className, numToBuild, weightIfNotEnough )

    return CreateBuildStructureActionForEach(
            techId, className,
            {
            {-1.0, weightIfNotEnough},
            {numToBuild-1, weightIfNotEnough},
            {numToBuild, 0.0}
            },
            "Harvester",
            harvesterBuildDist )
end

kAlienComBrainActions =
{
    UpgradeHiveAfterTime( kTechId.UpgradeToCragHive        , 0.9, 4 ) ,
    UpgradeHiveAfterTime( kTechId.UpgradeToShiftHive       , 1.0, 2 ) ,
    UpgradeHiveAfterTime( kTechId.UpgradeToShadeHive       , 0.9, 4 ) ,

    CreateUpgradeStructureAction( kTechId.BileBomb       , 3.5 ) ,
    CreateUpgradeStructureAction( kTechId.Leap       , 3.0 ) ,

    CreateUpgradeStructureAction( kTechId.Charge       , 3.0 ),
    CreateUpgradeStructureAction( kTechId.MetabolizeEnergy       , 2.0 ) ,
    CreateUpgradeStructureAction( kTechId.Umbra       , 1.0 ) ,
    CreateUpgradeStructureAction( kTechId.BoneShield       , 3.0 ) ,

    CreateUpgradeStructureAction( kTechId.MetabolizeHealth       , 2.0 ) ,
    CreateUpgradeStructureAction( kTechId.Stomp       , 3.0 ) ,

    CreateUpgradeStructureAction( kTechId.Xenocide       , 1.0 ) ,
    CreateUpgradeStructureAction( kTechId.Spores       , 1.0 ) ,
    CreateUpgradeStructureAction( kTechId.Stab       , 1.0 ) ,
    CreateUpgradeStructureActionAfterTime( kTechId.OnosEgg       , 0.1, nil, 8 ) ,

    --CreateUpgradeStructureAction( kTechId.WebTech       , 0.5 ) ,

    CreateBuildNearHiveActionWithReqHiveNum( kTechId.Shift , "Shift" , 2 , 0.1, 1 ),
    CreateBuildNearHiveActionWithReqHiveNum( kTechId.Crag  , "Crag"  , 2 , 0.1, 3 ),
    CreateBuildNearHiveActionWithReqHiveNum( kTechId.Shade , "Shade" , 2 , 0.1, 3 ),
    CreateBuildNearHiveActionWithReqHiveNum( kTechId.Whip  , "Whip"  , 2 , 0.1, 3 ),
    
    CreateBuildNearEachHarvester( kTechId.Whip  , "Whip"  , 1 , 0.3),
    CreateBuildNearEachHarvester( kTechId.Crag  , "Crag"  , 1 , 0.8),
    CreateBuildNearEachHarvester( kTechId.Shift , "Shift" , 1 , 0.5),
    CreateBuildNearEachHarvester( kTechId.Shade , "Shade" , 1 , 0.5),

    CreateBuildNearHiveAction( kTechId.Veil  , "Veil"  , 1 , 0.1),
    CreateBuildNearHiveAction( kTechId.Shell , "Shell" , 1 , 0.1),
    CreateBuildNearHiveAction( kTechId.Spur  , "Spur"  , 1 , 0.1),

    CreateBuildNearHiveActionWithReqHiveNum( kTechId.Veil  , "Veil"  , 3 , 2.0, 1 ),
    CreateBuildNearHiveActionWithReqHiveNum( kTechId.Shell , "Shell" , 3 , 2.0, 1 ),
    CreateBuildNearHiveActionWithReqHiveNum( kTechId.Spur  , "Spur"  , 3 , 2.0, 1 ),

    function(bot, brain)

        local name = "harvester"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local targetRP

        if doables[kTechId.Harvester] then

            targetRP = sdb:Get("resPointToTake")

            if targetRP then
            
                if (GetIsPointOnInfestation(targetRP:GetOrigin())) then
                    weight = 8
                else
                    
                    local hives = sdb:Get("hives")
                    if GetMinPathDistToEntities( targetRP, hives ) > 0 and GetMinPathDistToEntities( targetRP, hives ) < 55 then
                        Log(GetMinPathDistToEntities( targetRP, hives ))
                        weight = 10
                    else
                        weight = EvalLPF( sdb:Get("numHarvesters"),
                            {
                                {0, 10},
                                {10, 8},
                                {12, 6},
                                {16, 2}
                            })
                    end
                end
            end

        end

        return { name = name, weight = weight,
            perform = function(move)
                if targetRP then
                    brain:ExecuteTechId( com, kTechId.Harvester, targetRP:GetOrigin(), com )
                end
            end}
    end,

    function(bot, brain)

        local name = "mist"
        local com = bot:GetPlayer()
        local teamnumber = com:GetTeamNumber()
        local alertqueue = com:GetAlertQueue()

        local reactTechIds = {
            [kTechId.AlienAlertNeedMist] = kTechId.NutrientMist,
            [kTechId.AlienAlertStructureUnderAttack] = kTechId.NutrientMist,
            [kTechId.AlienAlertHarvesterUnderAttack] = kTechId.NutrientMist,
        }

        local techCheckFunction = {
            [kTechId.AlienAlertNeedMist] = function(target)
                local timeleft = target and target.gestationTime or 0 --get evolve time

                if #GetEntitiesForTeamWithinRange("NutrientMist", teamnumber, target:GetOrigin(), NutrientMist.kSearchRange) > 1 then
                    timeleft = 0
                end

                return EvalLPF( timeleft,
                    {
                        {0, 0.0},
                        {kSkulkGestateTime, 0.0},
                        {kLerkGestateTime, 5.0},
                        {kFadeGestateTime, 6.0},
                        {kOnosGestateTime, 7.0},

                    })
            end,
            [kTechId.AlienAlertStructureUnderAttack] = function(target)
                local position = target:GetOrigin()
                if GetIsPointOnInfestation(position) then
                    return 0.0
                end
                
                table.insert(brain.structuresInDanger, position)

                if #GetEntitiesForTeamWithinRange("NutrientMist", teamnumber, position, NutrientMist.kSearchRange) > 1 then
                    return 0.0
                end


                return 5.0

            end,
            [kTechId.AlienAlertHarvesterUnderAttack] = function(target)
                local position = target:GetOrigin()
                if GetIsPointOnInfestation(position) then
                    return 0.0
                end
                
                table.insert(brain.structuresInDanger, 1, position)

                if #GetEntitiesForTeamWithinRange("NutrientMist", teamnumber, position, NutrientMist.kSearchRange) > 1 then
                    return 0.0
                end


                return 6.0

            end,
        }

        local weight = 0.0
        local targetPos, targetId
        local techId

        local time = Shared.GetTime()

        for i, alert in ipairs(alertqueue) do
            local aTechId = alert.techId
            local targetTechId = reactTechIds[aTechId]
            local target
            if time - alert.time < 1 and targetTechId then
                target = Shared.GetEntity(alert.entityId)
                if target then
                    --Warning: This will cause an script error if one of the later items has a lower gestate time
                    local alertPiority = techCheckFunction[aTechId](target)

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
                    brain:ExecuteTechId( com, techId, targetPos, com, targetId )
                end
            end}
    end,

    function(bot, brain)

        local name = "cyst"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local weight = 0.0

        local rb = sdb:Get("resPointToInfest")
        local position = rb and rb:GetOrigin()

        --check for recyst
        if #brain.structuresInDanger > 0 then
            position = brain.structuresInDanger[1]
            brain.structuresInDanger = {}
            rb = nil
        end

        -- there is a res point ready to take, so do not build any more cysts to conserve TRes
        local cysts = position and GetEntitiesForTeamWithinRange("Cyst", com:GetTeamNumber(), position, kInfestationRadius) or {}
        local cyst = #cysts > 0 and cysts[1]
        if (not sdb:Get("resPointToTake") or not rp) and position and (not cyst or not cyst:GetIsActuallyConnected()) then
            weight = 5
        end
        

        return { name = name, weight = weight,
            perform = function(move)

                local extents = GetExtents(kTechId.Cyst)
                local cystPos = GetRandomSpawnForCapsule(extents.y, extents.x, position + Vector(0,1.5,0), 0.5, 3, EntityFilterAll(), GetIsPointOffInfestation)
                if not cystPos then
                    return
                end
                
                local trace = GetCommanderPickTarget(com, cystPos, true, true, false)

                if trace.fraction ~= 1 then
                    cystPos = trace.endPoint
                end
                
                local cystPoints, parent, normals, nbExistingCystUsed, existingCyst = GetCystPoints(cystPos, true, com:GetTeamNumber())

                local cost = (#cystPoints - nbExistingCystUsed + 1) * kCystCost
                
                local team = com:GetTeam()
                if cost <= team:GetTeamResources() and (team:GetTeamResources() > 42 or sdb:Get("gameMinutes") < 3) then
                    brain:ExecuteTechId( com, kTechId.Cyst, cystPos, com )
                end
            end }

    end,

    -- Trait upgrades
    CreateUpgradeStructureActionAfterTime( kTechId.ResearchBioMassOne , 5.0, nil, 1) ,
    CreateUpgradeStructureActionAfterTime( kTechId.ResearchBioMassTwo , 4.0, nil, 1) ,
    CreateUpgradeStructureActionAfterTime( kTechId.ResearchBioMassThree , 0.5, nil, 5) ,

    function(bot, brain)

        return { name = "idle", weight = 0.01,
            perform = function(move)
                if brain.debug then
                    DebugPrint("idling..")
                end
            end}
    end,

    function (bot, brain)
        local name ="eggs"
        local com = bot:GetPlayer()
        local team = com:GetTeam()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0

        if team:GetEggCount() == 0 and sdb:Get("gameMinutes") > 1 then
            weight = 11.0
        end

        return { name = name, weight = weight,
            perform = function(move)
                if doables[kTechId.ShiftHatch] then
                    brain:ExecuteTechId( com, kTechId.ShiftHatch, Vector(1,0,0), sdb:Get("hives")[1] )
                end
            end}
        end,

    function(bot, brain)
        local name = "drifters"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local drifters = sdb:Get("drifters")

        if sdb:Get("numDrifters") < 1 then
            weight = 2
        end

        local function IsBeingGrown(self, target)

            if target.hasDrifterEnzyme then
                return true
            end

            for _, drifter in ipairs(drifters) do

                if self ~= drifter then

                    local order = drifter:GetCurrentOrder()
                    if order and order:GetType() == kTechId.Grow then

                        local growTarget = Shared.GetEntity(order:GetParam())
                        if growTarget == target then
                            return true
                        end

                    end

                end

            end

            return false

        end

        for _, drifter in ipairs(sdb:Get("drifters")) do
            if not drifter:GetHasOrder() then
               -- find ungrown structures
               for _, structure in ipairs(GetEntitiesWithMixinForTeam("Construct", drifter:GetTeamNumber() )) do

                   if not structure:GetIsBuilt() and not IsBeingGrown(drifter, structure) and
                           (not structure.GetCanAutoBuild or structure:GetCanAutoBuild()) then

                       drifter:GiveOrder(kTechId.Grow, structure:GetId(), structure:GetOrigin(), nil, false, false)

                   end
               end
           end
        end

        return { name = name, weight = weight,
            perform = function(move)
                if doables[kTechId.DrifterEgg] then
                    local position = GetRandomBuildPosition(
                        kTechId.DrifterEgg, com:GetTeam():GetInitialTechPoint():GetOrigin(), 10
                    )
                    if position then
                        local buildPos = GetRandomBuildPosition( kTechId.DrifterEgg, com:GetTeam():GetInitialTechPoint():GetOrigin(), 10 )
                        if buildPos then
                            brain:ExecuteTechId( com, kTechId.DrifterEgg, buildPos, com )
                        end
                    end
                else
                    -- we cannot build a drifter yet - wait for res to build up
                end
            end}
    end,

    function(bot, brain)

        local name = "hive"
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local targetTP

        if sdb:Get("numHarvesters") >= sdb:Get("numHarvsForHive") 
            or sdb:Get("overdueForHive") or com:GetTeam():GetTeamResources() >= 100 then

            -- Find a hive slot!
            targetTP = sdb:Get("techPointToTake")

            if targetTP then
                weight = 5.5
            end
            if sdb:Get("numHives") >= 3 then
                weight = 0
            end
        end

        return { name = name, weight = weight,
            perform = function(move)
                if doables[kTechId.Hive] and targetTP then
                    local sucess = brain:ExecuteTechId( com, kTechId.Hive, targetTP:GetOrigin(), com )

                    if sucess then
                        --lets tell the team to protect it
                        CreatePheromone(kTechId.ThreatMarker, targetTP:GetOrigin(), com:GetTeamNumber())
                    end
                end
            end}
    end
}

------------------------------------------
--  Build the senses database
------------------------------------------

function CreateAlienComSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("gameMinutes", function(db)
            return (Shared.GetTime() - GetGamerules():GetGameStartTime()) / 60.0
            end)

    s:Add("doableTechIds", function(db)
            return db.bot.brain:GetDoableTechIds( db.bot:GetPlayer() )
            end)

    s:Add("hives", function(db)
            return GetEntitiesForTeam("Hive", kAlienTeamType)
            end)

    s:Add("cysts", function(db)
            return GetEntitiesForTeam("Cyst", kAlienTeamType)
            end)

    s:Add("drifters", function(db)
        return GetEntitiesForTeam("Drifter", kAlienTeamType)
    end)

    s:Add("numHarvesters", function(db)
            return GetNumEntitiesOfType("Harvester", kAlienTeamType)
            end)

    s:Add("numHarvsForHive", function(db)
            
            -- it's siege lol
            return 10
            
            --[[
            if db:Get("numHives") == 1 then
                return 4
            elseif db:Get("numHives") == 2 then
                return 6
            else
                return 8
            end
            
            return 0
            ]]--
            end)

    s:Add("overdueForHive", function(db)

            if db:Get("numHives") == 1 then
                return db:Get("gameMinutes") > 2
            elseif db:Get("numHives") == 2 then
                return db:Get("gameMinutes") > 3
            else
                return false
            end

            end)

    s:Add("numHives", function(db)
            return GetNumEntitiesOfType("Hive", kAlienTeamType)
            end)
    s:Add("numDrifters", function(db)
        return GetNumEntitiesOfType( "Drifter", kAlienTeamType ) + GetNumEntitiesOfType( "DrifterEgg", kAlienTeamType )
        end)

    s:Add("techPointToTake", function(db)
        local tps = GetAvailableTechPoints()
            local hives = db:Get("hives")
            local dist, tp = GetMinTableEntry( tps, function(tp)
                return GetMinPathDistToEntities( tp, hives )
                end)
            return tp
            end)

    -- RPs that are not taken, not necessarily good or on infestation
    s:Add("availResPoints", function(db)
            return ResourcePointsWithPathToCC(GetAvailableResourcePoints(), db:Get("hives"))
            --return GetAvailableResourcePoints()
            end)

    s:Add("resPointToTake", function(db)
            local rps = db:Get("availResPoints")
            local hives = db:Get("hives")
            local dist, rp = GetMinTableEntry( rps, function(rp)
                -- Check infestation
                if GetIsPointOnInfestation(rp:GetOrigin()) then
                    return GetMinPathDistToEntities( rp, hives )
                end
                return nil
                end)
            return rp
            end)

    s:Add("resPointToInfest", function(db)
            local rps = db:Get("availResPoints")
            local hives = db:Get("hives")
            local dist, rp = GetMinTableEntry( rps, function(rp)
                -- Check infestation
                if not GetIsPointOnInfestation(rp:GetOrigin()) then
                    return GetMinPathDistToEntities( rp, hives )
                end
                return nil
                end)
            return rp
            end)

    return s
end

------------------------------------------
--  
------------------------------------------


