
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/CommonAlienActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local kSkulkPressureEarlyNaturalsLimit = 1.5 -- 1:30 minutes into the round
local kSkulkPressureEnemyThreshold = 0.7

local kSkulkEarlyRetreatThreshold = 2.0

local kSkulkDodgeOscillation = 2.8

local kSkulkPheromoneWeights = {
    [kTechId.ThreatMarker] = 5.0,
    [kTechId.ExpandingMarker] = 2.0,
}

gBotDebug:AddBoolean("tunnels", false)

local function GetBestCoverPosition(bot, skulk, targetEnt)
    PROFILE("SkulkBrain - GetBestCoverPosition")

    local senses = bot.brain:GetSenses()
    local skulkPos = skulk:GetOrigin()

    local targetEntSize = HasMixin(targetEnt, "Extents") and targetEnt:GetMaxExtents()
    if not targetEntSize then return end

    local targetPos = targetEnt:GetOrigin()
    local nearestThreatData = senses:Get("nearestThreat")
    if not nearestThreatData.memory then return end

    local threatEnt = Shared.GetEntity(nearestThreatData.memory.entId)
    if not threatEnt then return end

    local threatPos = threatEnt:GetOrigin()
    local coverDir = (targetPos - threatPos):GetUnit()

    local targetEntRadius = targetEntSize:GetLengthXZ()
    return targetPos + (coverDir * targetEntRadius)

end

------------------------------------------
--  Handles things like using tunnels, walljumping, leaping etc
------------------------------------------
local function PerformMove( alienPos, targetPos, bot, brain, move )
    PROFILE("SkulkBrain - PerformMove")

    local postIgnore, targetDist, targetMove, entranceTunel = HandleAlienTunnelMove( alienPos, targetPos, bot, brain, move )
    if postIgnore then return end -- We are waiting for a tunnel pass-through, which requires staying still

    local moveDest = targetMove or targetPos

    local tooHigh = targetDist > 2.5 and targetDist < (moveDest.y - alienPos.y) * 1.5
    local tooLow = targetDist > 2.5 and targetDist < -(moveDest.y - alienPos.y) * 1.5
    local time = Shared.GetTime()
    
    if tooHigh then
        bot:GetMotion():SetDesiredViewTarget( moveDest + Vector(0,targetDist,0) )
        if math.random() < 0.1 then
            move.commands = AddMoveCommand( move.commands, Move.Jump )
        end
    end
    
    if tooLow then
        bot:GetMotion():SetDesiredViewTarget( moveDest  + Vector(0,-targetDist,0) )
        move.commands = AddMoveCommand( move.commands, Move.Crouch )
    end

    if tooHigh then
        local jitter = Vector(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.25
        bot:GetMotion():SetDesiredMoveDirection( (moveDest - alienPos):GetUnit() + jitter)
        move.commands = AddMoveCommand( move.commands, Move.Jump )
    end
    
    if not brain.isJammedUp and brain.kSkulkStuckFallTime + brain.lastStuckFallTime < time then

        local player = bot:GetPlayer()
        local isInCombat = (player.GetIsInCombat and player:GetIsInCombat())
        local isSneaking = player.movementModiferState and not isInCombat
        
        local disiredDiff = (moveDest-alienPos)
        if not isSneaking and disiredDiff:GetLengthSquared() > 25 and not tooHigh and
            player:GetVelocity():GetLengthXZ() / player:GetMaxSpeed() > 0.9 and
            Math.DotProduct(player:GetVelocity():GetUnit(), disiredDiff:GetUnit()) > 0.6 then
            
            if player.timeOfLastJump == nil or player.timeOfLastJump + .25 > Shared.GetTime() then
                move.commands = AddMoveCommand( move.commands, Move.Crouch )
            else
                move.commands = AddMoveCommand( move.commands, Move.Jump )
            end
            
        end

        if not isSneaking and disiredDiff:GetLengthSquared() > 9 and
            GetIsTechUnlocked(player, kTechId.Leap) and player:GetEnergy() / 100 > 0.8 and
            Math.DotProduct(player:GetVelocity():GetUnit(), disiredDiff:GetUnit()) > 0.6 then

            local viewDir = player:GetViewCoords().zAxis + Vector(0, 0.8, 0)
            bot:GetMotion():SetDesiredViewTarget( player:GetEyePos() + viewDir )

            -- leap, maybe?
            move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
        end

    else -- jammed up or stuck!
        -- Dont use MoveTarget, as alien bots could be in a tunnel (with no navmesh!)
        bot:GetMotion():SetDesiredMoveDirection( Vector(0,-1,0) )
        move.commands = RemoveMoveCommand( move.commands, Move.Jump )
        move.commands = AddMoveCommand( move.commands, Move.Crouch )
    end
end

-- Return an estimate of how well this bot is able to respond to a target based on its distance
-- from the target. Linearly decreates from 1.0 at 30 distance to 0.0 at 150 distance
local function EstimateSkulkResponseUtility(skulk, target)
    PROFILE("SkulkBrain - EstimateSkulkResponseUtility")

    local mloc = skulk:GetLocationName()
    local tloc = target:GetLocationName()

    if mloc == tloc then
        return 1.0
    end

    local dist = GetTunnelDistanceForAlien(skulk, target)
    return Clamp(1.0 - ( ( dist - 30.0 ) / 75.0 ), 0.0, 1.0)
end

------------------------------------------
--  More urgent == should really attack it ASAP
------------------------------------------
local function GetAttackUrgency(bot, player, mem)
    PROFILE("SkulkBrain - GetAttackUrgency")

    local teamBrain = bot.brain.teamBrain

    -- See if we know whether if it is alive or not
    local target = Shared.GetEntity(mem.entId)
    if not HasMixin(target, "Live") or not target:GetIsAlive() or (target.GetTeamNumber and target:GetTeamNumber() == bot:GetTeamNumber()) then
        return nil
    end

    -- for load-balancing
    local numOthers = teamBrain:GetNumOthersAssignedToEntity(player, mem.entId)

    -- Closer --> more urgent

    local closeBonus = 0

    -- Don't calculate tunnel distance for every single target memory, gets very expensive very quickly
    --local _, dist = GetTunnelDistanceForAlien(player, target)
    local dist = player:GetOrigin():GetDistance(target:GetOrigin())
    local isInCombat = HasMixin(player, "Combat") and player:GetIsInCombat()
    local isUnderFire = HasMixin(player, "Combat") and player:GetIsUnderFire()

    if dist < 20 then
        -- Do not modify numOthers here
        closeBonus = math.max(0, (dist * -0.1) + 2) -- minus .1 urgency per meter
        --closeBonus = 10/math.max(1.0, dist)
    end
    
    if target.GetHealthScalar and target:GetHealthScalar() < 0.3 then
        closeBonus = closeBonus + (0.3-target:GetHealthScalar()) * 3
    end
    
    ------------------------------------------
    -- Passives - not an immediate threat, but attack them if you got nothing better to do
    ------------------------------------------
    local passiveUrgencies =
    {
        [kMinimapBlipType.ARC] =                numOthers >= 2 and 0.4 or 0.95,
        [kMinimapBlipType.InfantryPortal] =     numOthers >= 3 and 0.5 or 0.9,
        [kMinimapBlipType.PhaseGate] =          numOthers >= 3 and 0.8 or 0.9,
        [kMinimapBlipType.CommandStation] =     numOthers >= 4 and 0.3 or 0.85,
        [kMinimapBlipType.Observatory] =        numOthers >= 2 and 0.2 or 0.8,
        [kMinimapBlipType.ArmsLab] =            numOthers >= 3 and 0.2 or 0.6,
        [kMinimapBlipType.PrototypeLab] =       numOthers >= 1 and 0.2 or 0.55,
        [kMinimapBlipType.Extractor] =          numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.Armory] =             numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.RoboticsFactory] =    numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.MAC] =                numOthers >= 1 and 0.2 or 0.4,
        [kMinimapBlipType.PowerPoint] =         numOthers >= 1 and 0.2 or 0.3,
    }

    if passiveUrgencies[ mem.btype ] ~= nil then
        -- ignore blueprints unless extractors or ccs, since those block your team
        if target.GetIsGhostStructure and target:GetIsGhostStructure() and
                (mem.btype ~= kMinimapBlipType.Extractor and mem.btype ~= kMinimapBlipType.CommandStation) then
            return nil
        end

        if not isInCombat then -- This can also help situations with structures blocking navmesh in a door, etc
            closeBonus = closeBonus * 3
        end

        -- If structure is almost dead, sacrifice ourselves to kill it
        local biteDamage = kBiteDamage
        local bitesTillTargetDeath = math.ceil(target:GetEHP() / biteDamage)
        local numBitesThresholdForSacrifice = 5

        if bitesTillTargetDeath <= numBitesThresholdForSacrifice then
            return 99999 -- just make sure we are the highest, we're gonna die anyways
        end

        local nearestThreat = bot.brain:GetSenses():Get("nearestThreat")
        local nearestThreatDistance = nearestThreat.distance
        -- If we're attacking a structure and a enemy is getting too close
        if nearestThreatDistance and nearestThreatDistance <= 8 then
            return nil
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
            [kMinimapBlipType.Exo] =                numOthers >= 4 and 0.4 or 1.6,
            [kMinimapBlipType.Marine] =             numOthers >= 2 and 0.4 or 1.5,
            [kMinimapBlipType.JetpackMarine] =      numOthers >= 1 and 0.4 or 1.4,
            [kMinimapBlipType.Sentry] =             numOthers >= 3 and 0.4 or 1.3
        }
        
        return activeUrgencies
    end

    -- Optimization: we only need to do visibilty check if the entity type is active
    -- So get the table first with 0 others
    local urgTable = EvalActiveUrgenciesTable(0)

    if urgTable[ mem.btype ] then

        -- For nearby active threats, respond no matter what - regardless of how many others are around
        if dist < 15 or isInCombat then
            numOthers = 0
        end
        
        urgTable = EvalActiveUrgenciesTable(numOthers)
        return urgTable[ mem.btype ] + closeBonus + ( dist < 20 and mem.threat or 0.0 )

    end
    
    return nil

end

local function PerformAttackEntity( eyePos, bestTarget, lastSeenPos, bot, brain, move )
    PROFILE("SkulkBrain - PerformAttackEntity")

    assert( bestTarget )
    local player = bot:GetPlayer()

    local sighted = false
    if not HasMixin(bestTarget, "LOS") then
        -- Print("attack target has no GetIsSighted: %s", bestTarget:GetClassName() )
        sighted = true
    else
        sighted = bestTarget:GetIsSighted()
    end
    
    local aimPos = sighted and GetBestAimPoint( bestTarget ) or (lastSeenPos + Vector(0,0.5,0))
    local doFire = false
    local distance = GetDistanceToTouch(eyePos, bestTarget)
    local time = Shared.GetTime()
    local isUsingTargetAsCover = false
    local coverPos
    
    local vel = bestTarget.GetVelocity and bestTarget:GetVelocity()
    local aimPosPlusVel = aimPos

    -- Only use target's velocity if target is moving at speed and not backpedaling
    if vel and vel:GetLength() > 4.0 then
        aimPosPlusVel = aimPos + vel * math.min(distance,1) / math.min(player:GetMaxSpeed(),5) * 3
    end

    local isDodgeable = bestTarget:isa("Player") or bestTarget:isa("MAC")
    local hasClearShot = distance < 45.0 and bot:GetBotCanSeeTarget( bestTarget )
    if hasClearShot then
        bot.lastFoughtEnemy = time
    end

    local skulkBiteRange = 1.4
    
    if distance < skulkBiteRange then
        doFire = true
        --bot:SendTeamMessage("Enemy contact!", 60)
    end
    
    local hasMoved = false
    
    if doFire then
        
        player:SetActiveWeapon(BiteLeap.kMapName)
        if isDodgeable then
             -- Attacking a player or babbler
            --local viewTarget = aimPos + Vector( math.random(), math.random(), math.random() ) * 0.3

            local xenoWeapon = player:GetWeapon(XenocideLeap.kMapName)

            local doXeno = xenoWeapon ~= nil
            if doXeno then
                if not xenoWeapon:GetIsXenociding() then
                    doXeno = brain:GetSenses():Get("hasXenoTargets")
                end
            end

            if doXeno then
                player:SetActiveWeapon(XenocideLeap.kMapName)
                move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
            elseif bot.aim then
                if bot.aim:UpdateAim(bestTarget, aimPos, kBotAccWeaponGroup.BiteLeap) then
					move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
				end
			else
				move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
            end
            
        else
            -- Attacking a structure
            if distance < 0.9 then  --TODO Read Skulk bite-range from balance data

                bot:GetMotion():SetDesiredViewTarget( aimPos )

                -- Take cover behind our structure target if necessary
                local nearestThreat = brain:GetSenses():Get("nearestThreat")

                if (nearestThreat.distance and nearestThreat.distance < 25) or player:GetIsUnderFire() then
                    coverPos = GetBestCoverPosition(bot, player, bestTarget)
                    isUsingTargetAsCover = coverPos ~= nil
                else -- Otherwise just stay still
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                end

            end
			move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
        end
    else
        if hasClearShot and bot.aim then
            bot.aim:UpdateAim(bestTarget, aimPos, kBotAccWeaponGroup.BiteLeap)
            if not bot.lastSeenEnemy then
                bot.lastSeenEnemy = Shared.GetTime()
            end
            if player:GetEnergy() > 60 and bot.lastSeenEnemy + 1 < Shared.GetTime() then
                player:SetActiveWeapon(Parasite.kMapName, true)
                move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
            end
        else -- sneaky
            bot.lastSeenEnemy = nil
            local isNotDetected =  not (player:GetIsDetected() or player:GetIsSighted())
            if isNotDetected and bot.sneakyAbility and distance < 20.0 and distance > 4.0 and isDodgeable and
                (not bot.lastFoughtEnemy or bot.lastFoughtEnemy + 10 < time) and not sighted then
                
                --bot:SendTeamMessage("I can hear enemys are near!", 60) --für mehr Spielgefühl/Spaß
                move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
            end
            
            
            PerformMove( eyePos, aimPos, bot, brain, move )
            hasMoved = true --???
        end
    end
    
    
    -- move at a player until we see them, then start pretending we're human and dodging
    if not hasClearShot or not bot:GetMotion().desiredViewTarget then
        PerformMove(eyePos, aimPos, bot, brain, move)
    elseif isDodgeable then

        -- Dirty hack: add "skulk dodging" if we're in LOS but not within bite range
        local sin = math.sin(Shared.GetTime() * kSkulkDodgeOscillation)
        local dir = (aimPosPlusVel - eyePos):GetUnit():CrossProduct(Vector(0, 1, 0))
        dir:Normalize()
        dir:Scale(sin * Clamp(distance / 2.5, 3.0, 7.0))

        -- Don't use the offset point if it is not on the same "connected pathing" as the target
        -- use a distance heuristic, if the offset is closer than the player's dist to pathing then assume it's on a different chunk of pathing
        -- fixes issues with trying to path "below" overhangs
        local playerPoint = Pathing.GetClosestPoint(aimPos) - aimPos
        local offsetPoint = Pathing.GetClosestPoint(aimPosPlusVel + dir) - aimPos

        if distance > 5 and (playerPoint:GetLength() * 1.5) < offsetPoint:GetLength() then

            PerformMove(eyePos, aimPosPlusVel + dir, bot, brain, move)
        else
        PerformMove(eyePos, aimPosPlusVel, bot, brain, move)
        end

    elseif isUsingTargetAsCover then
        PerformMove(eyePos, coverPos, bot, brain, move)
    end
    
        if bot.timeOfJump ~= nil and Shared.GetTime() - bot.timeOfJump < 0.5 then
        if bot.jumpOffset == nil then
            local botToTarget = GetNormalizedVectorXZ(marinePos - eyePos)
            local sideVector = botToTarget:CrossProduct(Vector(0, 1, 0))
            
            -- Zufällige Auswahl des Seitenvektors
            if math.random() < 0.5 then
                bot.jumpOffset = botToTarget + sideVector
            else
                bot.jumpOffset = botToTarget - sideVector
            end
            
            -- Zufällige Verzögerung vor der nächsten Aktion
            bot.nextActionTime = Shared.GetTime() + math.random() * 0.5
            
            -- Setzen des gewünschten Blickziels des Bots
            bot:GetMotion():SetDesiredViewTarget(bestTarget:GetEngagementPoint())
        end
        
        -- Zufällige Bewegungsrichtung nach dem Sprung
        if bot.nextActionTime ~= nil and Shared.GetTime() >= bot.nextActionTime then
            local randomDirection = Vector(math.random() - 0.5, 0, math.random() - 0.5):GetUnit()
            bot:GetMotion():SetDesiredMoveDirection(randomDirection)
        end
    end
end
    
    --[[Testkativierung
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
    --]]
    
local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        if not target:isa("Player") or GetDistanceToTouch(  eyePos, target ) < 15 then
            brain.teamBrain:UnassignBot(bot)
            brain.teamBrain:AssignBotToMemory(bot, mem)
             local chatMsg =  bot:SendTeamMessage( "Leap and bite all mankind! " .. target:GetMapName() .. " in " .. target:GetLocationName() )
            bot:SendTeamMessage(chatMsg, 60)
        end
        
        PerformAttackEntity( eyePos, target, mem.lastSeenPos, bot, brain, move )

    else
        assert(false)
    end

end

------------------------------------------
-- Skulk Brain Objective Validators
------------------------------------------

local kValidateDefendHive = function(bot, brain, skulk, action)
    if not IsValid(action.hive) then
        return false
    end

    return true
end

local kValidatePressureNaturals = function( bot, brain, skulk, action )
    local eHP = skulk:GetHealthScalar()

    -- Don't go pressuring naturals if we won't survive
    if eHP < 0.4 then
        return false
    end

    return true
end

local kValidateGuardHumans = function(bot, brain, skulk, action)
    local target = action.target

    if not IsValid(target) then
        -- brain:ResetGuardState()
        return false
    end

    if target.GetIsAlive and not target:GetIsAlive() then
        -- brain:ResetGuardState()
        return false
    end

    local dist = GetTunnelDistanceForAlien(skulk, action.target)

    if dist > 30.0 then
        -- brain:ResetGuardState()
        return false -- cancel if the human is too far away
    end

    --TODO Ideally check to ensure bot is within X _height_ of target (e.g. target didn't fall into Crevice, or climbed some weird geo crap)
    ----Not doing above will effectively "stall out" Guard Bots
    local currentPos = skulk:GetOrigin()
    --local targPosY = target:GetOrigin().y

    if dist <= 4.75 then
        --check if target is _not_ on nav-mesh, that's enough to say "yeah, they're in a vent. stop guarding"
        local closestPoint = Pathing.GetClosestPoint(target:GetOrigin())

        local groundPoint = Pathing.GetClosestPoint(currentPos)
        local maxDistOffPath = 0.65 --pulled from BotMotion
        local delta = groundPoint - bot:GetMotion().lastMovedPos
        local roughNextPoint = currentPos + bot:GetMotion().currMoveDir * delta:GetLength()    

        if (closestPoint - roughNextPoint):GetLengthXZ() > maxDistOffPath and (groundPoint - currentPos):GetLengthXZ() > 0.1 then
            -- Log("[%s] GuardedHuman - Target left nav-mesh ", skulk)
            return false
        end
    end

    return true
end

local kValidateRetreat = function(bot, brain, skulk, action)
    if not IsValid(action.hive) or not action.hive:GetIsAlive() then
        return false
    end

    return true
end

------------------------------------------
-- Skulk Brain Objective Executors
------------------------------------------

local kExecDefendHiveObjective = function(move, bot, brain, skulk, action)

    PerformMove(skulk:GetOrigin(), action.hiveOrigin, bot, brain, move)

    local tunnelDist = select(2, GetTunnelDistanceForAlien(skulk, action.hive))

    if tunnelDist < 7 or (action.hive:GetTimeOfLastDamage() or 0) + 20 < Shared.GetTime() then
        return kPlayerObjectiveComplete
    end

end

local kExecPressureNaturals = function(move, bot, brain, skulk, action)
    PROFILE("SkulkBrain - ExecPressureNaturals")

    local threatPos = action.threatGatewayPos
    local position = action.position

    brain.teamBrain:AssignPlayerToEntity(skulk, "assault-" .. action.location)

    if skulk:GetLocationName() == action.location and skulk:GetOrigin():GetDistance(threatPos) < 18.0 then

        bot:GetMotion():SetDesiredMoveTarget( nil )

        -- TODO: move to ambush position

        LookAroundAtTarget( bot, skulk, threatPos )

        local now = Shared.GetTime()

        if not action.idleStart then

            action.idleStart = now

        elseif action.idleStart + 30 < now then --orginal + 15
        --wait a short duration for any hostiles to come through or for any structures to be dropped, etc.

            CreateVoiceMessage( skulk, kVoiceId.AlienTaunt ) -- for fun
 
            return kPlayerObjectiveComplete

        end

    elseif skulk:GetLocationName() == action.location then
    -- move closer to the gateway we think hostiles will be coming through

        PerformMove( skulk:GetOrigin(), threatPos, bot, brain, move )

    else
    -- move to the entry gateway for the natural room

        PerformMove( skulk:GetOrigin(), position, bot, brain, move )

    end

end


local kExecGuardObjective = function(move, bot, brain, skulk, action)
    local target = action.target

    brain.teamBrain:UnassignBot(bot)
    brain.teamBrain:AssignBotToEntity( bot, target:GetId() )

    local touchDist = select(2, GetTunnelDistanceForAlien(skulk, target))
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

        LookAroundRandomly(bot, skulk)
    end

end

local kExecRetreatObjective = function(move, bot, brain, skulk, action)

    local hive = action.hive

    -- we are retreating, unassign ourselves from anything else, e.g. attack targets
    brain.teamBrain:UnassignBot(bot)

    local touchDist = GetDistanceToTouch( skulk:GetEyePos(), hive )
    if touchDist > 1.5 then
        bot:GetMotion():SetDesiredViewTarget( nil )
        PerformMove(skulk:GetEyePos(), hive:GetEngagementPoint(), bot, brain, move)
    else
        if skulk:GetIsUnderFire() then
            -- If under attack, we want to move away to other side of Hive
            local damageOrigin = skulk:GetLastTakenDamageOrigin()
            local hiveOrigin = hive:GetEngagementPoint()
            local retreatDir = (hiveOrigin - damageOrigin):GetUnit()
            local _, max = hive:GetModelExtents()
            local retreatPos = hiveOrigin + (retreatDir * max.x)
            bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
            PerformMove(skulk:GetEyePos(), hive:GetEngagementPoint(), bot, brain, move)

        else
            -- We're safe, just sit still
            bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveTarget( nil )
        end
    end

    if skulk:GetHealthScalar() > 0.95 then
        return kPlayerObjectiveComplete
    end

end

------------------------------------------
-- Skulk Brain Objectives
------------------------------------------

local kSkulkBrainObjectiveTypes = enum({
    "DefendHive",
    "Retreat",
    "RespondToThreat",
    "Evolve",
    "Pheromone",
    "GoToCommPing",
    "PressureEnemyNaturals",
    "GuardHumans"
})

local SkulkObjectiveWeights = MakeBotActionWeights(kSkulkBrainObjectiveTypes, 100)

kSkulkBrainObjectives =
{

    ------------------------------------------
    --  Defend Hive (It's under attack)
    ------------------------------------------
    function(bot, brain, skulk)
        --TODO Move this into CommonAlienActions
        PROFILE("SkulkBrain_Data:defend_hive")

        local name, weight = SkulkObjectiveWeights:Get(kSkulkBrainObjectiveTypes.DefendHive)

        local teamNumber = skulk:GetTeamNumber()
        -- TODO: should we do this when a hallucination?

        bot.hiveprotector = bot.hiveprotector or math.random()

        if bot.hiveprotector < 0.8 then
            return kNilAction
        end

        local hiveUnderAttack
        for _, hive in ipairs(GetEntitiesForTeam("Hive", teamNumber)) do
            if hive:GetIsAlive() and hive:GetHealthScalar() <= 0.9 and 
                hive:GetTimeOfLastDamage() and hive:GetTimeOfLastDamage() + 10 > Shared.GetTime() then
                hiveUnderAttack = hive
                break
            end
        end

        if not hiveUnderAttack then
            return kNilAction
        end

        local hiveOrigin = hiveUnderAttack:GetOrigin()
        local tunnelDist = select(2, GetTunnelDistanceForAlien(skulk, hiveUnderAttack))

        if tunnelDist < 7 then
            return kNilAction
        end

        return
        {
            name = name,
            weight = weight,
            hive = hiveUnderAttack,
            hiveOrigin = hiveOrigin,
            validate = kValidateDefendHive,
            perform = kExecDefendHiveObjective
        }

    end,

    ------------------------------------------
    -- Early-game Retreat
    ------------------------------------------
    function(bot, brain)
        PROFILE("SkulkBrain_Data:retreat")
        local name, weight = SkulkObjectiveWeights:Get(kSkulkBrainObjectiveTypes.Retreat)
        local player = bot:GetPlayer()
        local sdb = brain:GetSenses()

        local hiveData = sdb:Get("nearestHive")
        local hiveDist = hiveData and hiveData.distance or 200
        local hive = hiveData.entity
        local healthFraction = player:GetHealthScalar()

        -- If we are pretty close to the hive, stay with it a bit longer to encourage full-healing, etc.
        -- so pretend our situation is more dire than it is
        -- if hiveDist < Hive.kHealRadius * 0.815 and healthFraction < 0.9 then
        --     healthFraction = healthFraction / 4.0
        -- end

        if not hive or healthFraction > 0.4 or GetGameMinutesPassed() > kSkulkEarlyRetreatThreshold then
            return kNilAction
        end

        return {
            name = name,
            weight = weight,
            hive = hive,
            validate = kValidateRetreat,
            perform = kExecRetreatObjective
        }

    end,

    ------------------------------------------
    --  RespondToThreats
    ------------------------------------------
    CreateAlienRespondToThreatAction(SkulkObjectiveWeights, kSkulkBrainObjectiveTypes.RespondToThreat, PerformMove),

    ------------------------------------------
    --  Evolve
    ------------------------------------------
    CreateAlienEvolveAction(SkulkObjectiveWeights, kSkulkBrainObjectiveTypes.Evolve, kTechId.Skulk),

    ------------------------------------------
    -- Pheromone
    ------------------------------------------
    CreateAlienPheromoneAction(SkulkObjectiveWeights, kSkulkBrainObjectiveTypes.Pheromone, kSkulkPheromoneWeights, PerformMove),

    ------------------------------------------
    -- Investigate Commander Ping (Alert)
    ------------------------------------------
    CreateAlienGoToCommPingAction(SkulkObjectiveWeights, kSkulkBrainObjectiveTypes.GoToCommPing, PerformMove),

    ------------------------------------------
    --  Pressure Enemy Naturals
    ------------------------------------------
    function(bot, brain, skulk)

        local name, weight = SkulkObjectiveWeights:Get(kSkulkBrainObjectiveTypes.PressureEnemyNaturals)

        local teamBrain = GetTeamBrain(skulk:GetTeamNumber())
        local enemyTeam = GetEnemyTeamNumber(skulk:GetTeamNumber())
        local enemyTechpoint = GetTeamBrain(enemyTeam).initialTechPointLoc

        local locGraph = GetLocationGraph()

        -- Don't go pressuring naturals if we won't survive
        if skulk:GetHealthFraction() < 0.4 then
            return kNilAction
        end

        -- assume any "decent" player will know where the enemy spawned based on map knowledge
        local naturals = locGraph:GetNaturalRtsForTechpoint(enemyTechpoint)

        if not skulk:GetLocationName() or skulk:GetLocationName() == "" or not naturals or #naturals == 0 then
            return kNilAction
        end

        -- BOT-TODO: enable once tested
        --if bot.aggroAbility < kSkulkPressureEnemyThreshold then --orginal deaktiviert
          --return kNilAction
         --end

        local roundTime = GetGameMinutesPassed()
        local maxBots = roundTime <= kSkulkPressureEarlyNaturalsLimit and 3 or 1
        
        -- Use goal rather than entity assignment to ensure bots in combat still count as being assigned to pressure naturals
        if teamBrain:GetNumOtherBotsWithGoal(bot, name) >= maxBots then
            return kNilAction
        end
        
        local bestDist = 999.0
        local bestNatural = nil
        local bestPos = nil
        
        -- Find the closest natural RT to us to go pressure
        for i = 1, #naturals do
            
            local natural = naturals[i]
            
            local gatewayInfo = locGraph:GetGatewayDistance(skulk:GetLocationName(), natural)
            
            if gatewayInfo then
                
                -- Don't go for naturals that already have a bot assigned to them or present
                local assigned = teamBrain:GetNumOthersAssignedToEntity(skulk, "assault-" .. natural)
                local isFriendlyPresent = GetLocationContention():GetLocationGroup(natural):GetNumAlienPlayers() > 0

                if assigned == 0 and not isFriendlyPresent then
                    local distance = select(2, GetTunnelDistanceForAlien(skulk, gatewayInfo.exitGatePos, natural))

                    if distance < bestDist then
                        bestDist = bestDist
                        bestNatural = natural
                        bestPos = gatewayInfo.exitGatePos
                    end

                end

            end

        end

        if not bestNatural then
            return kNilAction
        end

        -- Find the first gateway back to the enemy techpoint (to look at)
        local threatGateway = GetThreatGatewayForLocation(bestNatural, enemyTechpoint)

        -- Log("[%s] wants to pressure natural %s of techpoint %s", skulk, bestNatural, enemyTechpoint)

        return {
            name = name,
            weight = weight,
            location = bestNatural,
            position = bestPos,
            threatGatewayPos = threatGateway,
            validate = kValidatePressureNaturals,
            perform = kExecPressureNaturals
        }

    end,  --RUSH ENEMY NATURALS

    -------------------------------------------
    -- Guard Player
    ------------------------------------------
    function(bot, brain, skulk)
        PROFILE("SkulkBrain_Data:guard_humans")

        local name, weight = SkulkObjectiveWeights:Get(kSkulkBrainObjectiveTypes.GuardHumans)
        local sdb = brain:GetSenses()

        local targetData = sdb:Get("nearestHuman")
        local target = targetData.player
        local dist = targetData.distance

        if not target or dist > 15 then
            return kNilAction
        end

        local targetId = target:GetId()
        local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( skulk, targetId )

        if ((numOthers == nil) or numOthers >= 1) then
            return kNilAction
        end

        --[[
		if bot.helpAbility then
			weight = weight + weight * bot.helpAbility
		end
        --]]

        return
        {
            name = name,
            weight = weight,
            target = target,
            validate = kValidateGuardHumans,
            perform = kExecGuardObjective
        }
    end,

    ------------------------------------------
    --  Explore
    ------------------------------------------
    CreateExploreAction( 1, 
        function(pos, targetPos, bot, brain, move)
            PerformMove(pos, targetPos, bot, brain, move)
        end
    ),

}


------------------------------------------
-- Skulk action executors
------------------------------------------

local kExecAttackAction = function(move, bot, brain, skulk, action)
    PerformAttack(skulk:GetEyePos(), action.bestMem, bot, brain, move)
end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------

local kSkulkBrainActionTypes = enum({
    "Attack",
    --???
})

local SkulkActionWeights = MakeBotActionWeights(kSkulkBrainActionTypes, 10)

kSkulkBrainActions =
{
    
    ------------------------------------------
    -- Debug Idle
    ------------------------------------------
    --[[
    function(bot, brain)
        return { name = "debug idle", weight = 0.001,
                perform = function()
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                    -- there is nothing obvious to do.. figure something out
                    -- like go to the marines, or defend 
                end }
    end,
    --]]

    --[[
        McG: This would need to be dramatically different to work. In other words, all Skulks should be "sneaky"
        during the early game, peak->parasite->duck/retreat, sort of thing. Otherwise, skulk bots will just be
        target practice for any Marine players.
    --]]

    ------------------------------------------
    -- Attack
    ------------------------------------------
    function(bot, brain, skulk)
        PROFILE("SkulkBrain_Data:attack")

        local name = "attack"

        local memories = GetTeamMemories(skulk:GetTeamNumber())

        local bestUrgency, bestMem = GetMaxTableEntry( memories, 
                function( mem )
                    return GetAttackUrgency( bot, skulk, mem )
                end)

        local weapon = skulk:GetActiveWeapon()
        local eHP = skulk:GetHealthScalar()
        local canAttack = weapon ~= nil and (weapon:isa("BiteLeap") or weapon:isa("Parasite") or weapon:isa("XenocideLeap"))

        local weight = 0.0

        if canAttack and bestMem ~= nil then

            local dist = 0.0
            local attackTargetEnt = Shared.GetEntity(bestMem.entId)
            if attackTargetEnt ~= nil then
                dist = select(2, GetTunnelDistanceForAlien(skulk, attackTargetEnt))
            else
                dist = select(2, GetTunnelDistanceForAlien(skulk, bestMem.lastSeenPos))
            end

            if dist <= 50 then
                weight = 8
            end

            -- Don't attack things far away if we're on low-health in early game
            if GetGameMinutesPassed() < kSkulkEarlyRetreatThreshold and eHP < 0.4 and dist > 12 then
                weight = 0
            end

            weight = weight + weight * (bot.aggroAbility or 0)
        end

        return 
        { 
            name = name, 
            weight = weight,
            bestMem = bestMem,
            perform = kExecAttackAction
        }
    end,

    CreateAlienInterruptAction()

}

------------------------------------------
--  
------------------------------------------
function CreateSkulkBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("allThreats", function(db, skulk)
            local team = skulk:GetTeamNumber()
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

    CreateAlienThreatSense(s, EstimateSkulkResponseUtility)

    s:Add("hasXenoTargets", function(db, skulk)
        local team = skulk:GetTeamNumber()
        local memories = GetTeamMemories( team )

        local filteredMemories = FilterTableEntries(memories, function(mem)
            local ent = Shared.GetEntity( mem.entId )

            if ent:isa("Player") and skulk:GetOrigin():GetDistanceSquared(ent:GetOrigin()) < 25 then
                local isAlive = HasMixin(ent, "Live") and ent:GetIsAlive()
                local isEnemy = HasMixin(ent, "Team") and ent:GetTeamNumber() ~= team
                return isAlive and isEnemy
            else
                return false
            end
        end)

        return #filteredMemories > 1
    end)

    s:Add("nearestHuman", function(db, skulk)

            local players = GetEntitiesForTeam( "Player", skulk:GetTeamNumber() )

            local dist, player = GetMinTableEntry( players,
                function(player)
                    assert( player ~= nil )
                    if not player:GetIsVirtual() and player:GetAFKTime() < kBotGuardMaxAFKTime then
                        return select(2, GetTunnelDistanceForAlien(skulk, player))
                    end
                end)

            return {player = player, distance = dist}

        end)

    s:Add("nearestHive", function(db, skulk)

            local skulkPos = skulk:GetOrigin()
            local hives = GetEntitiesForTeam( "Hive", skulk:GetTeamNumber() )

            local dist, hive = GetMinTableEntry( hives,
                function(hive)
                    if hive:GetIsBuilt() then
                        return skulkPos:GetDistance(hive:GetOrigin())
                    end
                end)

            return {entity = hive, distance = dist}
        end)

    s:Add("nearestGorge", function(db, skulk)          --Only used for quick heal-ups
            local gorges = GetEntitiesForTeam( "Gorge", skulk:GetTeamNumber() )

            local dist, gorge = GetMinTableEntry( gorges,
                function(gorge)
                    if gorge:GetIsAlive() then
                        return select(2, GetTunnelDistanceForAlien(skulk, gorge))
                    end
                end)

            return
            {
                entity = gorge,
                distance = dist
            }
        end)

    s:Add("nearestThreat", function(db, skulk)
            local allThreats = db:Get("allThreats")

            local distance, nearestThreat = GetMinTableEntry( allThreats,
                function( mem )
                    local origin = mem.origin
                    local ent = Shared.GetEntity(mem.entId)
                    if origin == nil then
                        origin = ent:GetOrigin()
                    end
                    return select(2, GetTunnelDistanceForAlien(skulk, ent))
                end)

            return {distance = distance, memory = nearestThreat}
        end)

    s:Add("nearestTeammate", function(db, skulk)

            local players = GetEntitiesForTeam( "Player", skulk:GetTeamNumber() )

            local dist, player = GetMinTableEntry( players,
                function(player)
                    assert( player ~= nil )
                    return select(2, GetTunnelDistanceForAlien(skulk, player))
                end)

            return {player = player, distance = dist}

        end)

    CreateAlienCommPingSense(s)

    return s
end