-- Copied most code from Nin's Rebirth

Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")


local kEvolutions = {
-- gorge is bugged as hell
    kTechId.Prowler,
    kTechId.Lerk,
    kTechId.Fade,
    kTechId.Onos
}

------------------------------------------
--  Handles things like using tunnels, walljumping, leaping etc
------------------------------------------
local function PerformMove( alienPos, targetPos, bot, brain, move )

        
    local dist = (targetPos - alienPos):GetLength()
    local tooHigh = dist > 2.5 and dist < (targetPos.y - alienPos.y) * 1.5
    local tooLow = dist > 2.5 and dist < -(targetPos.y - alienPos.y) * 1.5
    if tooHigh then
        bot:GetMotion():SetDesiredViewTarget( targetPos + Vector(0,dist,0) )
        if math.random() < 0.4 then
            move.commands = AddMoveCommand( move.commands, Move.Jump )
        end
    end
    
    if tooLow then
        bot:GetMotion():SetDesiredViewTarget( targetPos  + Vector(0,-dist,0) )
        move.commands = AddMoveCommand( move.commands, Move.Crouch )
    end

    if tooHigh then
        local jitter = Vector(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.25
        bot:GetMotion():SetDesiredMoveDirection( (targetPos - alienPos):GetUnit() + jitter)
        move.commands = AddMoveCommand( move.commands, Move.Jump )
    else
        bot:GetMotion():SetDesiredMoveTarget( targetPos )
    end
    
    
    local player = bot:GetPlayer()
    local isInCombat = (player.GetIsInCombat and player:GetIsInCombat())
    local isSneaking = player.movementModiferState and not isInCombat
    
    local disiredDiff = (targetPos-alienPos)
    if not isSneaking and disiredDiff:GetLengthSquared() > 25 and not tooHigh and
        player:GetVelocity():GetLengthXZ() / player:GetMaxSpeed() > 0.9 and
        Math.DotProduct(player:GetVelocity():GetUnit(), disiredDiff:GetUnit()) > 0.6 then
        if player.timeOfLastJump == nil or player.timeOfLastJump + .25 > Shared.GetTime() then
            move.commands = AddMoveCommand( move.commands, Move.Crouch )
        else
            move.commands = AddMoveCommand( move.commands, Move.Jump )
        end
        
    end
    if not isSneaking and disiredDiff:GetLengthSquared() < 900 and disiredDiff:GetLengthSquared() > 9 and
        Math.DotProduct(player:GetVelocity():GetUnit(), disiredDiff:GetUnit()) > 0.6 then
    
        -- leap, maybe?
        if player:GetEnergy() > 50 then
            move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
        end
    end
    
end

------------------------------------------
--  More urgent == should really attack it ASAP
------------------------------------------
local function GetAttackUrgency(bot, mem)

    local teamBrain = bot.brain.teamBrain

    -- See if we know whether if it is alive or not
    local target = Shared.GetEntity(mem.entId)
    if not HasMixin(target, "Live") or not target:GetIsAlive() or (target.GetTeamNumber and target:GetTeamNumber() == bot:GetTeamNumber()) then
        return nil
    end

    -- for load-balancing
    local numOthers = teamBrain:GetNumAssignedTo( mem,
            function(otherId)
                if otherId ~= bot:GetPlayer():GetId() then
                    return true
                end
                return false
            end)

    -- Closer --> more urgent

    local closeBonus = 0
    local player = bot:GetPlayer()
    local dist = player:GetOrigin():GetDistance( mem.lastSeenPos )
    local isInCombat = (player.GetIsInCombat and player:GetIsInCombat())

    if dist < 20 then
        -- Do not modify numOthers here
        closeBonus = 10/math.max(1.0, dist)
    end
    
    if target.GetHealthScalar and target:GetHealthScalar() < 0.3 then
        closeBonus = closeBonus + (0.3-target:GetHealthScalar()) * 3
    end

    ------------------------------------------
    -- Passives - not an immediate threat, but attack them if you got nothing better to do
    ------------------------------------------
    local passiveUrgencies =
    {
        [kMinimapBlipType.Crag] = numOthers >= 2           and 0.5 or 0.95, -- kind of a special case
        [kMinimapBlipType.SentryBattery] = numOthers >= 2  and 0.2 or 0.95,
        [kMinimapBlipType.Hive] = numOthers >= 6           and 0.5 or 0.85,
        [kMinimapBlipType.Harvester] = numOthers >= 2      and 0.8 or 0.9,
        [kMinimapBlipType.Egg] = numOthers >= 1            and 0.2 or 0.5,
        [kMinimapBlipType.Shade] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Shift] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Shell] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Veil] = numOthers >= 2           and 0.2 or 0.5,
        [kMinimapBlipType.Spur] = numOthers >= 2           and 0.2 or 0.5,
        [kMinimapBlipType.TunnelEntrance] = numOthers >= 1 and 0.4 or 0.5,
        -- from skulk
        [kMinimapBlipType.ARC] =                numOthers >= 2 and 0.4 or 0.9,
        [kMinimapBlipType.CommandStation] =     numOthers >= 4 and 0.3 or 0.85,
        [kMinimapBlipType.PhaseGate] =          numOthers >= 2 and 0.8 or 0.9,
        [kMinimapBlipType.Observatory] =        numOthers >= 2 and 0.2 or 0.8,
        [kMinimapBlipType.Extractor] =          numOthers >= 2 and 0.7 or 0.9,
        [kMinimapBlipType.InfantryPortal] =     numOthers >= 2 and 0.2 or 0.6,
        [kMinimapBlipType.PrototypeLab] =       numOthers >= 1 and 0.2 or 0.55,
        [kMinimapBlipType.Armory] =             numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.RoboticsFactory] =    numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.ArmsLab] =            numOthers >= 3 and 0.2 or 0.6,
        [kMinimapBlipType.MAC] =                numOthers >= 1 and 0.2 or 0.4,
    }
    
    if table.contains(kMinimapBlipType, "HadesDevice") then
        passiveUrgencies[kMinimapBlipType.HadesDevice] = numOthers >= 2  and 0.2 or 0.95
    end

    if bot.brain.debug then
        if mem.btype == kMinimapBlipType.Hive then
            Print("got Hive, urgency = %f", passiveUrgencies[mem.btype])
        end
    end
    

    if passiveUrgencies[ mem.btype ] ~= nil then
        -- ignore blueprints unless extractors or ccs, since those block your team
        if target.GetIsGhostStructure and target:GetIsGhostStructure() and 
            (mem.btype ~= kMinimapBlipType.Extractor and mem.btype ~= kMinimapBlipType.CommandStation) then
            return nil
        end
        
        if not isInCombat then
            closeBonus = closeBonus * 3
        end
        
        return passiveUrgencies[ mem.btype ] + closeBonus
    end

    ------------------------------------------
    --  Active threats - ie. they can hurt you
    --  Only load balance if we cannot see the target
    ------------------------------------------
    function EvalActiveUrgenciesTable(numOthers)
        local activeUrgencies =
        {
            [kMinimapBlipType.Embryo] = numOthers >= 1 and 0.1 or 1.0,
            [kMinimapBlipType.Hydra] = numOthers >= 2  and 0.1 or 2.0,
            [kMinimapBlipType.Whip] = numOthers >= 2   and 0.1 or 3.0,
            [kMinimapBlipType.Skulk] = numOthers >= 2  and 0.1 or 4.0,
            [kMinimapBlipType.Gorge] =  numOthers >= 2  and 0.1 or 3.0,
            [kMinimapBlipType.Drifter] = numOthers >= 1  and 0.1 or 1.0,
            [kMinimapBlipType.Lerk] = numOthers >= 1   and 0.1 or 5.0,
            [kMinimapBlipType.Fade] = numOthers >= 1   and 0.1 or 6.0,
            [kMinimapBlipType.Onos] =  numOthers >= 4  and 0.1 or 7.0,
            [kMinimapBlipType.Marine] = numOthers >= 2 and 0.1 or 6.0,
            [kMinimapBlipType.JetpackMarine] = numOthers >= 1 and 0.1 or 5.0,
            [kMinimapBlipType.Exo] =  numOthers >= 4  and 0.1 or 4.0,
            [kMinimapBlipType.Sentry]  = numOthers >= 3   and 0.1 or 5.0
        }
        if table.contains(kMinimapBlipType, "Prowler") then
            activeUrgencies[kMinimapBlipType.Prowler] = numOthers >= 2 and 0.1 or 4.0
        end
        
        return activeUrgencies
    end

    -- Optimization: we only need to do visibilty check if the entity type is active
    -- So get the table first with 0 others
    local urgTable = EvalActiveUrgenciesTable(0)

    if urgTable[ mem.btype ] then

        -- For nearby active threads, respond no matter what - regardless of how many others are around
        if dist < 15 or isInCombat then
            numOthers = 0
        end
        
        urgTable = EvalActiveUrgenciesTable(numOthers)
        return urgTable[ mem.btype ] + closeBonus

    end
    
    return nil

end


local function PerformAttackEntity( eyePos, bestTarget, lastSeenPos, bot, brain, move )

    assert( bestTarget )
    local player = bot:GetPlayer()

    local sighted 
    if not bestTarget.GetIsSighted then
        -- Print("attack target has no GetIsSighted: %s", bestTarget:GetClassName() )
        sighted = true
    else
        sighted = bestTarget:GetIsSighted()
    end
    
    local aimPos = sighted and GetBestAimPoint( bestTarget ) or (lastSeenPos + Vector(0,0.5,0))
    
    local doFire = false
    
    local distance = GetDistanceToTouch(eyePos, bestTarget)
    local time = Shared.GetTime()
        
    local targetPos = bestTarget:GetEngagementPoint()
    local isDodgeable = bestTarget:isa("Player") or bestTarget:isa("Babbler")
    local hasClearShot = distance < 45.0 and bot:GetBotCanSeeTarget( bestTarget )

    local aimPosPlusVel = aimPos + (bestTarget.GetVelocity and bestTarget:GetVelocity() or 0) * math.min(distance,1) / math.min(player:GetMaxSpeed(),5) * 3
       
    if hasClearShot then
        bot.lastFoughtEnemy = time
    end    
    
    if distance < 2.0 then
        doFire = true
    end
    
    --local hasMoved = false
    
    if doFire then
        
        player:SetActiveWeapon(BiteLeap.kMapName)    
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
        if isDodgeable then
             -- Attacking a player or babbler
            --local viewTarget = aimPos + Vector( math.random(), math.random(), math.random() ) * 0.3
            
            if bot.aim then
                local canBite = bot.aim:UpdateAim(target, aimPos)
            end
            
        else
            -- Attacking a structure
            if distance < 1.5 then
                -- Stop running at the structure when close enough
                bot:GetMotion():SetDesiredMoveTarget(nil)
                bot:GetMotion():SetDesiredViewTarget( aimPos )
            end
        end
    else
        if hasClearShot and bot.aim then
            bot.aim:UpdateAim(target, aimPos)
            if not bot.lastSeenEnemy then
                bot.lastSeenEnemy = Shared.GetTime()
            end
            if player:GetEnergy() > 50 and bot.lastSeenEnemy + 1 < Shared.GetTime() then
                player:SetActiveWeapon(Parasite.kMapName, true)
                move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
            end
        else
            bot.lastSeenEnemy = nil
            local isNotDetected =  not (player:GetIsDetected() or player:GetIsSighted())
            if isNotDetected and bot.sneakyAbility and distance < 20.0 and distance > 4.0 and isDodgeable and
                (not bot.lastFoughtEnemy or bot.lastFoughtEnemy + 10 < time) and not sighted then
                
                move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
            end
            
            --PerformMove( eyePos, aimPos, bot, brain, move )
            --hasMoved = true
            
            doFire = false
        end
    end
        
    local timeSinceDodge = bot.timeOfDodge ~= nil and (Shared.GetTime() - bot.timeOfDodge) or 1
    
    if hasClearShot and isDodgeable and math.random() * 0.6 < math.min(timeSinceDodge - 0.3, 1) then
        -- When approaching, try to jump sideways
        -- Try to dodge once every 0.3 to 1 second
        bot.timeOfDodge = Shared.GetTime()
        bot.dodgeOffset = nil
    end
    
    local isDodging = bot.timeOfDodge ~= nil and (Shared.GetTime() - bot.timeOfDodge < 0.28)
    
    if isDodging and bot.dodgeOffset == nil then
        local botToTarget = GetNormalizedVector(targetPos - eyePos)
        local sideVector = botToTarget:CrossProduct(Vector(0, 1, 0))
        local offsetMultiplier = doFire and 0.5 or 1.2
        if math.random() < 0.5 then
            bot.dodgeOffset = botToTarget + sideVector * (0.3 + offsetMultiplier * math.random())
        else
            bot.dodgeOffset = botToTarget - sideVector * (0.3 + offsetMultiplier * math.random())
        end    

        bot:GetMotion():SetDesiredMoveDirection( bot.dodgeOffset )
    end
    
    -- move at a player until we see them, then start pretending we're human and dodging
    if not hasClearShot or not bot:GetMotion().desiredViewTarget then
        PerformMove(eyePos, aimPos, bot, brain, move)
    elseif isDodgeable and not isDodging then
        PerformMove(eyePos, aimPosPlusVel, bot, brain, move)
    end
    --[[
    if bot.timeOfJump ~= nil and Shared.GetTime() - bot.timeOfJump < 0.5 then
        
        if bot.jumpOffset == nil then
            
            local botToTarget = GetNormalizedVectorXZ(marinePos - eyePos)
            local sideVector = botToTarget:CrossProduct(Vector(0, 1, 0))                
            if math.random() < 0.5 then
                bot.jumpOffset = botToTarget + sideVector
            else
                bot.jumpOffset = botToTarget - sideVector
            end            
            bot:GetMotion():SetDesiredViewTarget( bestTarget:GetEngagementPoint() )
            
        end
        
        bot:GetMotion():SetDesiredMoveDirection( bot.jumpOffset )
    end    
    ]]--
    
end

local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        if not target:isa("Player") or GetDistanceToTouch(  eyePos, target ) < 15 then
            brain.teamBrain:UnassignBot(bot)
            brain.teamBrain:AssignBotToMemory(bot, mem)
        end
        
        PerformAttackEntity( eyePos, target, mem.lastSeenPos, bot, brain, move )

    else
        assert(false)
    end

end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------
kSkulkBrainActions =
{
    
    ------------------------------------------
    --  
    ------------------------------------------
    function(bot, brain)
        return { name = "debug idle", weight = 0.001,
                perform = function(move)
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                    -- there is nothing obvious to do.. figure something out
                    -- like go to the marines, or defend 
                end }
    end,

    ------------------------------------------
    --  
    ------------------------------------------
    CreateExploreAction( 0.02, function(pos, targetPos, bot, brain, move)
            PerformMove(pos, targetPos, bot, brain, move)
    end ),
    
    ------------------------------------------
    --  Tries to evolve (if not a hallucination)
    ------------------------------------------
    function(bot, brain)
        local name = "evolve"

        local weight = 0.0
        local player = bot:GetPlayer()

        -- Hallucinations don't evolve
        if player.isHallucination then
            return { name = name, weight = weight,
                perform = function() end }
        end

        if not bot.lifeformEvolution then
            local pick = math.random(1, #kEvolutions)
            bot.lifeformEvolution = kEvolutions[pick]
        end

        local allowedToBuy = player:GetIsAllowedToBuy()

        local s = brain:GetSenses()
        local res = player:GetPersonalResources()
        
        local distanceToNearestThreat = s:Get("nearestThreat").distance
        local distanceToNearestHive = s:Get("nearestHive").distance
        local desiredUpgrades = {}
        
        if allowedToBuy and
           (distanceToNearestThreat == nil or distanceToNearestThreat > 20) and 
           (distanceToNearestHive == nil or distanceToNearestHive < 25) and 
           (player.GetIsInCombat == nil or not player:GetIsInCombat()) then
            
            -- Safe enough to try to evolve            
            
            local existingUpgrades = player:GetUpgrades()

            local avaibleUpgrades = player.lifeformUpgrades

            if not avaibleUpgrades then
                avaibleUpgrades = {}

                if bot.lifeformEvolution then
                    table.insert(avaibleUpgrades, bot.lifeformEvolution)
                end

                local kUpgradeStructureTable = AlienTeam.GetUpgradeStructureTable()
                for i = 1, #kUpgradeStructureTable do
                    local upgrades = kUpgradeStructureTable[i].upgrades
                    table.insert(avaibleUpgrades, table.random(upgrades))
                end

                player.lifeformUpgrades = avaibleUpgrades
            end

            local evolvingId = kTechId.Skulk

            -- Check lifeform
            local techId = avaibleUpgrades[1]
            local techNode = player:GetTechTree():GetTechNode(techId)
            local isAvailable = techNode and techNode:GetAvailable(player, techId, false)
            local cost = isAvailable and GetCostForTech(techId) or math.huge

            if res >= cost then
                res = res - cost
                evolvingId = techId
                existingUpgrades = {}

                table.insert(desiredUpgrades, techId)
            end

            -- Check upgrades
            for i = 2, #avaibleUpgrades do
                local techId = avaibleUpgrades[i]
                local techNode = player:GetTechTree():GetTechNode(techId)
                local isAvailable = techNode and techNode:GetAvailable(player, techId, false)
                local cost = isAvailable and LookupTechData(evolvingId, kTechDataUpgradeCost, 0) or math.huge
                
                if res >= cost and not table.icontains(existingUpgrades, techId) and
                        GetIsUpgradeAllowed(player, techId, existingUpgrades) and
                        GetIsUpgradeAllowed(player, techId, desiredUpgrades) then
                    res = res - cost
                    table.insert(desiredUpgrades, techId)
                end
            end
            
            if #desiredUpgrades > 0 then
                weight = 100.0
            end                                
        end
        
        return { name = name, weight = weight,
            perform = function(move)
                player:ProcessBuyAction( desiredUpgrades )
            end }
    
    end,
    
    --[[
    -- Save hives under attack
     ]]
    function(bot, brain)
        local skulk = bot:GetPlayer()
        local teamNumber = skulk:GetTeamNumber()

        bot.hiveprotector = bot.hiveprotector or math.random()

        local name = "hiveunderattack"
        if bot.hiveprotector < 0.8 then
            return { name = name, weight = 0,
                perform = function() end }
        end

        local hiveUnderAttack
        for _, hive in ipairs(GetEntitiesForTeam("Hive", teamNumber)) do
            if hive:GetIsAlive() and hive:GetHealthScalar() <= 0.9 and 
                hive:GetTimeOfLastDamage() and hive:GetTimeOfLastDamage() + 10 > Shared.GetTime() then
                hiveUnderAttack = hive
                break
            end
        end

        local hiveOrigin = hiveUnderAttack and hiveUnderAttack:GetOrigin()
        local botOrigin = skulk:GetOrigin()

        if hiveUnderAttack and botOrigin:GetDistanceSquared( hiveOrigin ) < 10 then
            hiveUnderAttack = nil
        end

        local weight = hiveUnderAttack and 1.5 or 0

        return { name = name, weight = weight,
            perform = function(move)
                PerformMove(botOrigin, hiveOrigin, bot, brain, move)
            end }

    end,


    ------------------------------------------
    --  
    ------------------------------------------
    function(bot, brain)
        local name = "attack"
        local skulk = bot:GetPlayer()
        local eyePos = skulk:GetEyePos()
        
        local memories = GetTeamMemories(skulk:GetTeamNumber())
        local bestUrgency, bestMem = GetMaxTableEntry( memories, 
                function( mem )
                    return GetAttackUrgency( bot, mem )
                end)
        
        local weapon = skulk:GetActiveWeapon()
        local canAttack = weapon ~= nil and (weapon:isa("BiteLeap") or weapon:isa("Parasite"))

        local weight = 0.0

        if canAttack and bestMem ~= nil then

            local dist = 0.0
            if Shared.GetEntity(bestMem.entId) ~= nil then
                dist = GetDistanceToTouch( eyePos, Shared.GetEntity(bestMem.entId) )
            else
                dist = eyePos:GetDistance( bestMem.lastSeenPos )
            end

            weight = EvalLPF( dist, {
                    { 0.0, EvalLPF( bestUrgency, {
                        { 0.0, 1.0 },
                        { 10.0, 25.0 }
                        })},
                    { 15.0, EvalLPF( bestUrgency, {
                            { 0.0, 0.5 },
                            { 10.0, 5.0 }
                            })},
                    { 45.0, 0.07 },
                    -- Never let it drop too low - ie. keep it around explore so that aggro bots can focus on being agressive
                    { 60.0, 0.01 } })
                    
            weight = weight + weight * (bot.aggroAbility or 0)
        end

        return { name = name, weight = weight,
            perform = function(move)
                PerformAttack( eyePos, bestMem, bot, brain, move )
            end }
    end,    

    ------------------------------------------
    --  
    ------------------------------------------
    function(bot, brain)
        local name = "pheromone"
        
        local skulk = bot:GetPlayer()
        local eyePos = skulk:GetEyePos()

        local pheromones = GetEntitiesForTeam( "Pheromone", skulk:GetTeamNumber())
        local bestPheromoneLocation = nil
        local bestValue = 0
        
        for p = 1, #pheromones do
        
            local currentPheromone = pheromones[p]
            if currentPheromone then
                local techId = currentPheromone:GetType()
                            
                if techId == kTechId.ExpandingMarker or techId == kTechId.ThreatMarker then
                
                    local location = currentPheromone:GetOrigin()
                    local locationOnMesh = Pathing.GetClosestPoint(location)
                    local distanceFromMesh = location:GetDistance(locationOnMesh)
                    
                    if distanceFromMesh > 0.001 and distanceFromMesh < 2 then
                    
                        local distance = eyePos:GetDistance(location)
                        
                        if currentPheromone.visitedBy == nil then
                            currentPheromone.visitedBy = {}
                        end
                                        
                        if not currentPheromone.visitedBy[bot] then
                        
                            if distance < 5 then 
                                currentPheromone.visitedBy[bot] = true
                            else   
            
                                -- Value goes from 5 to 10
                                local value = 5.0 + 5.0 / math.max(distance, 1.0) - #(currentPheromone.visitedBy)
                        
                                if value > bestValue then
                                    bestPheromoneLocation = locationOnMesh
                                    bestValue = value
                                end
                                
                            end    
                            
                        end    
                            
                    end
                    
                end
                        
            end
            
        end
        
        local weight = EvalLPF( bestValue, {
            { 0.0, 0.0 },
            { 10.0, 1.0 }
            })

        return { name = name, weight = weight,
            perform = function(move)
                PerformMove(pos, bestPheromoneLocation, bot, brain, move)
            end }
    end,

    ------------------------------------------
    --  
    ------------------------------------------
    function(bot, brain)
        local name = "order"

        local skulk = bot:GetPlayer()
        local pos = skulk:GetOrigin()
        local order = bot:GetPlayerOrder()

        local weight = 0.0
        if order ~= nil then
            weight = 3.0
			
			if skulk.isHallucination then
				wight = 500.0
			end
        end

        return { name = name, weight = weight,
            perform = function(move)
                if order then

                    local target = Shared.GetEntity(order:GetParam())

                    if target ~= nil and order:GetType() == kTechId.Attack then

                        PerformAttackEntity( skulk:GetEyePos(), target, order:GetLocation(), bot, brain, move )
                        
                    else

                        if brain.debug then
                            DebugPrint("unknown order type: %s", ToString(order:GetType()) )
                        end

                        PerformMove(pos, order:GetLocation(), bot, brain, move)

                    end
                end
            end }
    end,
    function(bot, brain)

        local name = "guardHumans"
        local skulk = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local weight = 0.0


        local targetData = sdb:Get("nearestHuman")
        local target = targetData.player
        local dist = targetData.distance
        local isBeingGuarded = brain.teamBrain:GetNumOthersAssignedToEntity( skulk:GetId(), bot )
        local isBored = bot.boredUntil and bot.boredUntil > Shared.GetTime()
        
        if target and dist < 15 and not isBeingGuarded and not isBored then
            local targetId = target:GetId()
            if targetId then
                local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( targetId, bot )
                if ((numOthers == nil) or numOthers >= 1) and not brain.teamBrain:GetIsBotAssignedTo( bot, {entId=targetId} ) then
                    weight = 0.0
                else
                    weight = 0.09 --  above explore
                end
            end
        end
        
        weight = weight + weight * (bot.helpAbility or 0)

        return { name = name, weight = weight,
            perform = function(move)
                if target then 
                
                    brain.teamBrain:UnassignBot(bot)
                    brain.teamBrain:AssignBotToEntity( bot, target:GetId() )

                    local touchDist = GetDistanceToTouch( skulk:GetEyePos(), target )
                    if touchDist > 5.0 then
						if touchDist < 10.0 and target.GetIsWallWalking and target:GetIsWallWalking() then
							PerformMove( skulk:GetOrigin(), target:GetEngagementPoint() + Vector(0, 2, 0), bot, brain, move )
						else
							PerformMove( skulk:GetOrigin(), target:GetEngagementPoint(), bot, brain, move )
                        end
                    elseif touchDist < 2.0 then
                        local diff = (skulk:GetOrigin() - target:GetEngagementPoint()):GetUnit() * 3
                        PerformMove( skulk:GetOrigin(), target:GetEngagementPoint() + diff, bot, brain, move )
                    else
                        bot:GetMotion():SetDesiredMoveTarget( nil )
                        if not bot.lastLookAround or bot.lastLookAround + 2 < Shared.GetTime() then
                            bot.lastLookAround = Shared.GetTime()
                            local viewTarget = GetRandomDirXZ()
                            viewTarget.y = math.random()
                            viewTarget:Normalize()
                            bot.lastLookTarget = skulk:GetEyePos()+viewTarget*30
                        end
                        if bot.lastLookTarget then
                            bot:GetMotion():SetDesiredViewTarget(bot.lastLookTarget)
                        end
                        if (not bot.lastCoveringTime or bot.lastCoveringTime < Shared.GetTime() - 120) and target:isa("Player") then
                            CreateVoiceMessage( bot:GetPlayer(), kVoiceId.MarineCovering )
                            bot.lastCoveringTime = Shared.GetTime()
                        end
                        
                    end
                    
                    
                end
            end }
    end,
    ------------------------------------------
    --  
    ------------------------------------------
    function(bot, brain)
        local name = "order"

        local skulk = bot:GetPlayer()
        local pos = skulk:GetOrigin()
        local order = bot:GetPlayerOrder()

        local weight = 0.0
        if order ~= nil then
            weight = 3.0
			
			if skulk.isHallucination then
				wight = 500.0
			end
        end

        return { name = name, weight = weight,
            perform = function(move)
                if order then

                    local target = Shared.GetEntity(order:GetParam())

                    if target ~= nil and order:GetType() == kTechId.Attack then

                        PerformAttackEntity( skulk:GetEyePos(), target, order:GetLocation(), bot, brain, move )
                        
                    else

                        if brain.debug then
                            DebugPrint("unknown order type: %s", ToString(order:GetType()) )
                        end

                        PerformMove(pos, order:GetLocation(), bot, brain, move)

                    end
                end
            end }
    end,    
    
    
    function( bot, brain )

        local name = "ping"
        local weight = 0.0
        local skulk = bot:GetPlayer()
        local db = brain:GetSenses()
        local pos = skulk:GetOrigin()

        local kPingLifeTime = 30.0
        local pingPos = db:Get("comPingPosition")

        if pingPos ~= nil and db:Get("comPingElapsed") ~= nil and db:Get("comPingElapsed") < kPingLifeTime then


            if brain.lastReachedPingPos ~= nil and pingPos:GetDistance(brain.lastReachedPingPos) < 1e-2 then
                -- we already reached this ping - ignore it
            elseif db:Get("comPingXZDist") > 5 then
                -- respond to ping with fairly high priority
                -- but allow direct orders to override
                weight = 1.5
            else
                -- we got close enough, remember to ignore this ping
                brain.lastReachedPingPos = db:Get("comPingPosition")
            end

        end

        return { name = name, weight = weight,
            perform = function(move)
                local pingPos = db:Get("comPingPosition")
                assert(pingPos ~= nil)
                PerformMove( pos, pingPos, bot, brain, move )
            end}

    end,

}

------------------------------------------
--  
------------------------------------------
function CreateSkulkBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("allThreats", function(db)
            local player = db.bot:GetPlayer()
            local team = player:GetTeamNumber()
            local memories = GetTeamMemories( team )
            return FilterTableEntries( memories,
                function( mem )                    
                    local ent = Shared.GetEntity( mem.entId )
                    
                    if ent:isa("Player") or ent:isa("Sentry") then
                        local isAlive = HasMixin(ent, "Live") and ent:GetIsAlive()
                        local isEnemy = HasMixin(ent, "Team") and ent:GetTeamNumber() ~= team                    
                        return isAlive and isEnemy
                    else
                        return false
                    end
                end)                
        end)

    s:Add("nearestHuman", function(db)

            local skulk = db.bot:GetPlayer()
            local skulkPos = skulk:GetOrigin()
            local players = GetEntitiesForTeam( "Player", skulk:GetTeamNumber() )

            local dist, player = GetMinTableEntry( players,
                function(player)
                    assert( player ~= nil )
                    if not player:GetIsVirtual() then
                        return skulkPos:GetDistance( player:GetOrigin() )
                    end
                end)

            return {player = player, distance = dist}

            end)
    s:Add("nearestHive", function(db)

            local skulk = db.bot:GetPlayer()
            local skulkPos = skulk:GetOrigin()
            local hives = GetEntitiesForTeam( "Hive", skulk:GetTeamNumber() )

            local dist, hive = GetMinTableEntry( hives,
                function(hive)
                    if hive:GetIsBuilt() then
                        return skulkPos:GetDistance( hive:GetOrigin() )
                    end
                end)

            return {entity = hive, distance = dist}
            end)
            
    s:Add("nearestThreat", function(db)
            local allThreats = db:Get("allThreats")
            local player = db.bot:GetPlayer()
            local playerPos = player:GetOrigin()
           
            local distance, nearestThreat = GetMinTableEntry( allThreats,
                function( mem )
                    local origin = mem.origin
                    if origin == nil then
                        origin = Shared.GetEntity(mem.entId):GetOrigin()
                    end
                    return playerPos:GetDistance(origin)
                end)

            return {distance = distance, memory = nearestThreat}
        end)
        
    s:Add("comPingElapsed", function(db)

            local skulk = db.bot:GetPlayer()
            local pingTime = GetGamerules():GetTeam(skulk:GetTeamNumber()):GetCommanderPingTime()

            if pingTime > 0 and pingTime ~= nil and pingTime < Shared.GetTime() then
                return Shared.GetTime() - pingTime
            else
                return nil
            end

            end)

    s:Add("comPingPosition", function(db)
            
            local skulk = db.bot:GetPlayer()
            local rawPos = GetGamerules():GetTeam(skulk:GetTeamNumber()):GetCommanderPingPosition()
            -- the position is usually up in the air somewhere, so pretend we did a commander pick to put it somewhere sensible
            local trace = GetCommanderPickTarget(
                db.bot:GetPlayer(), -- not right, but whatever
                rawPos,
                true, -- worldCoords Specified
                false, -- isBuild
                true -- ignoreEntities
                )

            if trace ~= nil and trace.fraction < 1 then
                return trace.endPoint
            else
                return  nil
            end

            end)
            
    s:Add("comPingXZDist", function(db)
            local skulk = db.bot:GetPlayer()
            if db:Get("comPingPosition") ~= nil then
                local delta = db:Get("comPingPosition") - skulk:GetOrigin()
                return delta:GetLengthXZ()
            end
            end)

    s:Add("nearestTeammate", function(db)

            local skulk = db.bot:GetPlayer()
            local skulkPos = skulk:GetOrigin()
            local players = GetEntitiesForTeam( "Player", skulk:GetTeamNumber() )

            local dist, player = GetMinTableEntry( players,
                function(player)
                    assert( player ~= nil )
                    local dist,_ = skulkPos:GetDistance( player:GetOrigin() )

                    return dist
                end)

            return {player = player, distance = dist}

            end)
            

    return s
end

-- are we running combat?
if kCombatVersion then

    local function GotRequirements(self, upgrade)
        
        if upgrade then
            local requirements = upgrade:GetRequirements()

            -- does this up needs other ups??
            if requirements then
                local requiredUpgrade = GetUpgradeFromId(requirements)
                if (self.combatUpgrades and #self.combatUpgrades > 0) then
                    for _, id in ipairs(self.combatUpgrades) do
                        if (tonumber(id) == requiredUpgrade:GetId()) then
                            return true
                        end  
                    end  
                else
                
                    return false
                    
                end 
            else
                return true
            end
        end
        return false
    end
    
    local function GotItemAlready(self, upgrade)

        if upgrade then 
            if (self.combatUpgrades and table.maxn(self.combatUpgrades) > 0) then
                for _, id in ipairs(self.combatUpgrades) do
                    if (tonumber(id) == upgrade:GetId()) then
                        return true
                    end  
                end  
            else        
                return false            
            end 
        end
        return false
        
    end
    local function CreateBuyCombatUpgradeAction(techId, weightIfCanDo)
    
        return function(bot, brain)

            local name = "combat_" .. EnumToString( kTechId, techId )
            local player = bot:GetPlayer()
            local sdb = brain:GetSenses()
            local resources = player:GetResources()
            local allUps = GetAllUpgrades("Marine")
            local upgrade = GetUpgradeFromTechId(techId)
            local cost = upgrade:GetLevels()
            local doable = GotRequirements(player, upgrade)  
            local hasUpgrade = player:GetHasCombatUpgrade(upgrade:GetId())  
            local weight = 0.0

            if doable and not hasUpgrade and resources >= cost then

                weight = weightIfCanDo

            end

            -- limit how often we can try to buy things
            if bot.lastCombatBuyAction and bot.lastCombatBuyAction + 10 > Shared.GetTime() then
                weight = 0
            end

            
            return {
                name = name, weight = weight,
                perform = function(move)
                    -- todo: support multiple upgrades at a time...?
                    -- Log("Trying to upgrade " .. upgrade:GetDescription())
                    local upgradeTable = {}
                    table.insert(upgradeTable, upgrade)
                    player:CoEnableUpgrade(upgradeTable)
                    
                    bot.lastCombatBuyAction = Shared.GetTime()
                    
                end }
        end
    end
    
    -- todo: don't block movement!!
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Carapace,      5.0 + math.random() ))
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Vampirism,     5.0 + math.random() ))
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Focus,         2.0 + math.random() ))
    
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Celerity,       4.0 + math.random() ))
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.BioMassTwo,     3.0 + math.random() ))
    
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Crush,          2.0 + math.random() ))
    --table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Adrenaline,     2.0 + math.random() ))
    --table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Regeneration,   1.5 + math.random() ))
    
    -- TODO: Make us choose?
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Lerk,     3.0 + math.random() ))
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Fade,     4.0 + math.random() ))
    table.insert(kSkulkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Onos,     5.0 + math.random() ))
end