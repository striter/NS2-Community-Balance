
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

------------------------------------------
--  Handles things like using tunnels, walljumping, leaping etc
--  Function not hooked up yet
------------------------------------------
local function PerformMove( alienPos, targetPos, bot, brain, move )

        
    local dist = (targetPos - alienPos):GetLength()
    local tooHigh = dist > 2.5 and dist < (targetPos.y - alienPos.y) * 1.5
    local tooLow = dist > 2.5 and dist < -(targetPos.y - alienPos.y) * 1.5
    if tooHigh then
        bot:GetMotion():SetDesiredViewTarget( targetPos + Vector(0,dist,0) )
        if math.random() < 0.1 then
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
    local isSneaking = player.GetCrouching and player:GetCrouching() and not isInCombat
    
    local disiredDiff = (targetPos-alienPos)

    if not isSneaking and disiredDiff:GetLengthSquared() > 36 and
        Math.DotProduct(player:GetVelocity():GetUnit(), disiredDiff:GetUnit()) > 0.86 then
    
        -- rappel, maybe?
        if player:GetEnergy() > 30 then
            move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
        end
    end
    
end

------------------------------------------
--  More urgent == should really attack it ASAP
------------------------------------------
local function GetAttackUrgency(bot, mem)

    -- See if we know whether if it is alive or not
    local ent = Shared.GetEntity(mem.entId)
    if not HasMixin(ent, "Live") or not ent:GetIsAlive() or (ent.GetTeamNumber and ent:GetTeamNumber() == bot:GetTeamNumber())  then
        return 0.0
    end
    
    local botPos = bot:GetPlayer():GetOrigin()
    local targetPos = ent:GetOrigin()
    local distance = botPos:GetDistance(targetPos)

    if mem.btype == kMinimapBlipType.PowerPoint then
        local powerPoint = ent
        if powerPoint ~= nil and powerPoint:GetIsSocketed() then
            return 0.55
        else
            return 0.0
        end    
    end
        
    local immediateThreats = {
        [kMinimapBlipType.Marine] = true,
        [kMinimapBlipType.JetpackMarine] = true,
        [kMinimapBlipType.Exo] = true,    
        [kMinimapBlipType.Sentry] = true,
        [kMinimapBlipType.Embryo] = true,
        [kMinimapBlipType.Hydra]  = true,
        [kMinimapBlipType.Whip]   = true,
        [kMinimapBlipType.Skulk]  = true,
        [kMinimapBlipType.Gorge]  = true,
        [kMinimapBlipType.Lerk]   = true,
        [kMinimapBlipType.Fade]   = true,
        [kMinimapBlipType.Onos]   = true        
    }
    
    if distance < 15 and immediateThreats[mem.btype] then
        -- Attack the nearest immediate threat (urgency will be 1.1 - 2)
        return 1.0 + 1 / math.max(distance, 1)
    end
    
    -- No immediate threat - load balance!
    local numOthers = bot.brain.teamBrain:GetNumAssignedTo( mem,
            function(otherId)
                if otherId ~= bot:GetPlayer():GetId() then
                    return true
                end
                return false
            end)

    --Other urgencies do not rank anything here higher than 1!
    local urgencies = {
        [kMinimapBlipType.ARC] =                numOthers >= 2 and 0.4 or 0.9,
        [kMinimapBlipType.CommandStation] =     numOthers >= 4 and 0.3 or 0.75,
        [kMinimapBlipType.PhaseGate] =          numOthers >= 2 and 0.2 or 0.9,
        [kMinimapBlipType.Observatory] =        numOthers >= 2 and 0.2 or 0.8,
        [kMinimapBlipType.Extractor] =          numOthers >= 2 and 0.2 or 0.7,
        [kMinimapBlipType.InfantryPortal] =     numOthers >= 2 and 0.2 or 0.6,
        [kMinimapBlipType.PrototypeLab] =       numOthers >= 1 and 0.2 or 0.55,
        [kMinimapBlipType.Armory] =             numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.RoboticsFactory] =    numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.ArmsLab] =            numOthers >= 3 and 0.2 or 0.9,
        [kMinimapBlipType.MAC] =                numOthers >= 1 and 0.2 or 0.8,
    }

    if urgencies[ mem.btype ] ~= nil then
        return urgencies[ mem.btype ]
    end

    return 0.0
    
end


local function PerformAttackEntity( eyePos, bestTarget, bot, brain, move )

    assert( bestTarget )

    local marinePos = bestTarget:GetOrigin()
    local randomOffset = Vector( math.random() * 0.5, math.random() * 0.35, math.random() * 0.5 )
    local doFire = false
    local isTooClose = false
    local yDiff = (eyePos-marinePos).y
    
    bot:GetMotion():SetDesiredMoveTarget( marinePos )
    local distance = eyePos:GetDistance(marinePos)
    
    if distance > 25.0 or not bot:GetBotCanSeeTarget( bestTarget ) then
        doFire = false
    elseif distance < 4.0 then
        bot:GetMotion():SetDesiredMoveTarget( nil )
        if bestTarget:isa("Player") then
            if math.random() < (0.45 + (0.6 / (distance + 0.1))) then
                -- too close - back away while firing
                bot:GetMotion():SetDesiredMoveDirection( -( marinePos-eyePos ) + randomOffset)
                isTooClose = true
            elseif math.random() < 0.5 then
                -- occasionally try to jump around and over the enemy
                bot:GetMotion():SetDesiredMoveDirection( randomOffset * 2)
            end            
        end
        doFire = math.random() > 0.1
    elseif distance < 12.0 then
        doFire = math.random() < (9.0 / distance)
        isTooClose = math.random() < (0.1334 + 4.0 / distance)
    elseif bot.GetIsInCombat and bot:GetIsInCombat() then
        doFire = true
    end
    
    if doFire then
        local target = bestTarget:GetEngagementPoint()

        if bestTarget:isa("Player") then
             -- Attacking a player
            target = target + Vector( math.random(), math.random(), math.random() ) * 0.4
            -- Occasionally jump
            if (yDiff < 2.0 and math.random() > 0.66) then
                move.commands = AddMoveCommand( move.commands, Move.Jump )
            end
        else
            -- Attacking a structure
            if GetDistanceToTouch(eyePos, bestTarget) < 4 then
                -- Stop running at the structure when close enough
                bot:GetMotion():SetDesiredMoveTarget(nil)
            --elseif distance > 3 and (math.random() < 0.5) then
            --    move.commands = AddMoveCommand( move.commands, Move.Jump )
            end
        end

        bot:GetMotion():SetDesiredViewTarget( target )
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
    else
        bot:GetMotion():SetDesiredViewTarget( nil )
        -- Occasionally  
        if bestTarget:isa("Player") and (math.random() < (bot:GetPlayer():GetIsOnGround() and 0.5 or 0)) then
            move.commands = AddMoveCommand( move.commands, Move.Jump )
        end        
    end    

    local timeSinceDodge = bot.timeOfDodge ~= nil and (Shared.GetTime() - bot.timeOfDodge) or 1

    if math.random() * 0.7 < math.min(timeSinceDodge - 0.3, 1) then
        -- When approaching, try to jump sideways
        bot.timeOfDodge = Shared.GetTime()
        bot.dodgeOffset = nil
        move.commands = AddMoveCommand( move.commands, Move.Jump )
    end
    
    if bestTarget:isa("Player") and bot.timeOfDodge ~= nil and (Shared.GetTime() - bot.timeOfDodge < 0.25) then
        if bot.dodgeOffset == nil then
            local botToTarget = isTooClose and GetNormalizedVectorXZ(-marinePos + eyePos) or GetNormalizedVectorXZ(marinePos - eyePos)
            local sideVector = botToTarget:CrossProduct(Vector(0, 1, 0))
            local offsetMultiplier = doFire and 0.2 or 0.4
            --when dodging, bias toward one side so bot is more likely to circle around a marine
            if math.random() < 0.55 then
                bot.dodgeOffset = botToTarget + sideVector * (0.3 + offsetMultiplier * math.random())
            else
                bot.dodgeOffset = botToTarget - sideVector * (0.4 + offsetMultiplier * math.random())
            end
            
            bot:GetMotion():SetDesiredViewTarget( bestTarget:GetEngagementPoint() )
            
        end
        bot:GetMotion():SetDesiredMoveDirection( bot.dodgeOffset )
        
    end
    
    
end

local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        PerformAttackEntity( eyePos, target, bot, brain, move )

    else
    
        -- mem is too far to be relevant, so move towards it
        bot:GetMotion():SetDesiredViewTarget(nil)
        bot:GetMotion():SetDesiredMoveTarget(mem.lastSeenPos)

    end
    
    brain.teamBrain:AssignBotToMemory(bot, mem)

end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------
kProwlerBrainActions =
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
    CreateExploreAction( 0.01, function(pos, targetPos, bot, brain, move)
                --bot:GetMotion():SetDesiredMoveTarget(targetPos)
                --bot:GetMotion():SetDesiredViewTarget(nil)
                PerformMove(pos, targetPos, bot, brain, move)
                end ),
    
    ------------------------------------------
    --  
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
        
        local s = brain:GetSenses()
        local res = player:GetPersonalResources()
        
        local distanceToNearestThreat = s:Get("nearestThreat").distance
        local desiredUpgrades = {}
        
        if allowedToBuy and
           (distanceToNearestThreat == nil or distanceToNearestThreat > 40) and 
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

            local evolvingId = kTechId.Prowler

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
        local prowler = bot:GetPlayer()
        local teamNumber = prowler:GetTeamNumber()

        bot.hiveprotector = bot.hiveprotector or math.random()

        local name = "hiveunderattack"
        if bot.hiveprotector < 0.5 then
            return { name = name, weight = 0,
                perform = function() end }
        end

        local hiveUnderAttack
        for _, hive in ipairs(GetEntitiesForTeam("Hive", teamNumber)) do
            if hive:GetHealthScalar() <= 0.7 then
                hiveUnderAttack = hive
                break
            end
        end

        local hiveOrigin = hiveUnderAttack and hiveUnderAttack:GetOrigin()
        local botOrigin = prowler:GetOrigin()

        if hiveUnderAttack and botOrigin:GetDistanceSquared( hiveOrigin ) < 10 then
            hiveUnderAttack = nil
        end

        local weight = hiveUnderAttack and 1.1 or 0.01

        return { name = name, weight = weight,
            perform = function(move)
                bot:GetMotion():SetDesiredMoveTarget(hiveOrigin)
                bot:GetMotion():SetDesiredViewTarget(nil)
            end }

    end,

    ------------------------------------------
    --  
    ------------------------------------------
    function(bot, brain)
        local name = "attack"
        local prowler = bot:GetPlayer()
        local eyePos = prowler:GetEyePos()
        
        local memories = GetTeamMemories(prowler:GetTeamNumber())
        local bestUrgency, bestMem = GetMaxTableEntry( memories, 
                function( mem )
                    return GetAttackUrgency( bot, mem )
                end)
        
        local weapon = prowler:GetActiveWeapon()
        local canAttack = weapon ~= nil and weapon:isa("VolleyRappel") or weapon:isa("AcidSpray")

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
                        { 0.0, 0.0 },
                        { 10.0, 25.0 }
                        })},
                    { 10.0, EvalLPF( bestUrgency, {
                            { 0.0, 0.0 },
                            { 10.0, 5.0 }
                            })},
                    { 100.0, 0.0 } })
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
        
        local prowler = bot:GetPlayer()
        local eyePos = prowler:GetEyePos()

        local pheromones = EntityListToTable(Shared.GetEntitiesWithClassname("Pheromone"))            
        local bestPheromoneLocation
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
                bot:GetMotion():SetDesiredMoveTarget(bestPheromoneLocation)
                bot:GetMotion():SetDesiredViewTarget(nil)
            end }
    end,

    ------------------------------------------
    --  
    ------------------------------------------
    function(bot, brain)
        local name = "order"

        local prowler = bot:GetPlayer()
        local order = bot:GetPlayerOrder()

        local weight = 0.0
        if order ~= nil then
            weight = 10.0
        end

        return { name = name, weight = weight,
            perform = function(move)
                if order then

                    local target = Shared.GetEntity(order:GetParam())

                    if target ~= nil and order:GetType() == kTechId.Attack then

                        PerformAttackEntity( prowler:GetEyePos(), target, bot, brain, move )
                        
                    else

                        if brain.debug then
                            DebugPrint("unknown order type: %s", ToString(order:GetType()) )
                        end

                        bot:GetMotion():SetDesiredMoveTarget( order:GetLocation() )
                        bot:GetMotion():SetDesiredViewTarget( nil )

                    end
                end
            end }
    end,    

    function(bot, brain)

        local name = "retreat"
        local player = bot:GetPlayer()
        local sdb = brain:GetSenses()

        if player.isHallucination then
            return { name = name, weight = 0.0,
            perform = function() end }
        end
        
        local hive = sdb:Get("nearestHive")
        local hiveDist = hive and player:GetOrigin():GetDistance(hive:GetOrigin()) or 0
        local healthFraction = sdb:Get("healthFraction")
        local inCombat = player.GetIsInCombat and player:GetIsInCombat()
        local lowEnergy = player:GetEnergy() < 15
        -- If we are pretty close to the hive, stay with it a bit longer to encourage full-healing, etc.
        -- so pretend our situation is more dire than it is
        if hiveDist < 4.0 and healthFraction < 0.9 then
            healthFraction = healthFraction / 3.0
        end

        local weight = 0.0

        if hive then

            weight = EvalLPF( healthFraction, {
                { 0.0, 20.0 },
                { 0.4, 10.0 },
                { 0.5, 4.0 },
                { 0.6, 2.0 },
                { 1.0, 0.0 }
            })
            
            -- defend the hive! don't retreat!
            if inCombat then
                weight = weight * 0.5
            end
            
            if lowEnergy then
                weight = weight + 1.0
            end
            
            if hiveDist < 10 then
                weight = weight * 0.1
            end
        end

        return { name = name, weight = weight,
            perform = function(move)
                if hive then

                    -- we are retreating, unassign ourselves from anything else, e.g. attack targets
                    brain.teamBrain:UnassignBot(bot)
                    
                    local eyePos = bot:GetPlayer():GetEyePos()
                    local touchDist = GetDistanceToTouch( eyePos, hive )
                    local now = Shared.GetTime()
                    if touchDist > 5 or inCombat then
                        bot:GetMotion():SetDesiredMoveTarget( hive:GetEngagementPoint() )                         
                        local timeSinceDodge = bot.timeOfDodge ~= nil and (now - bot.timeOfDodge) or 1
                        local jitter = GetNormalizedVectorXZ(hive:GetOrigin() - eyePos) + Vector((math.random()-0.5) * 0.8, 0, (math.random()-0.5) * 0.8)

                        -- zigzag movement and jump randomly to avoid damage
                        if math.random() < 0.16 + (inCombat and 0.16 or 0) then                        
                            bot:GetMotion():SetDesiredMoveDirection( jitter )
                            bot.timeOfDodge = now
                        end
                        
                        if bot:GetPlayer():GetIsOnGround() and math.random() > 0.5 then
                            -- angle upward before jumping, but don't twitch too often
                            --bot.jumpAngle = timeSinceDodge < 0.3 and bot.jumpAngle or math.random()
                            bot:GetMotion():SetDesiredMoveDirection( jitter + Vector(0, math.random(), 0))
                            move.commands = AddMoveCommand( move.commands, Move.Jump )
                            bot.timeOfDodge = now
                        end
                    else
                        -- sit and wait to heal
                        bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
                        bot:GetMotion():SetDesiredMoveTarget( nil )
                    end
                end

            end }

    end,
}

------------------------------------------
--  
------------------------------------------
function CreateProwlerBrainSenses()

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
        
    s:Add("nearestHive", function(db)

        local player = db.bot:GetPlayer()
        local playerPos = player:GetOrigin()
        local hives = GetEntitiesForTeam( "Hive", player:GetTeamNumber() )

        local builtHives = {}

        -- retreat only to built hives
        for _, hive in ipairs(hives) do

            if hive:GetIsBuilt() and hive:GetIsAlive() then
                table.insert(builtHives, hive)
            end

        end

        Shared.SortEntitiesByDistance(playerPos, builtHives)

        return builtHives[1]
    end)        

    s:Add("healthFraction", function(db)
        local player = db.bot:GetPlayer()
        return player:GetHealthScalar()
    end)
    
    return s
end
