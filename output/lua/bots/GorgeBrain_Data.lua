
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")
Script.Load("lua/Ballistics.lua")


local kGorgeMaxHealableSearchRange = 10.0



local function GetIdealHealingPosition(self, target)

    if not target:isa("Player") then
        return nil
    end
    
    local coords = target:GetViewAngles():GetCoords()
    local targetViewAxis = coords.zAxis
    targetViewAxis.y = 0 -- keep it 2D
    targetViewAxis:Normalize()
    local fromTarget = self:GetOrigin() - target:GetOrigin()
    local targetDist = fromTarget:GetLengthXZ()
    fromTarget.y = 0
    fromTarget:Normalize()
    
    local healPos = nil    
    local dot = targetViewAxis:DotProduct(fromTarget)    
    -- if we are in front or not sufficiently away from the target, we calculate a new healPos
    if dot > 0.866 or targetDist < kHealsprayRadius - 0.5 then
        -- we are in front, find out back positon
        local obstacleSize = 0
        if HasMixin(target, "Extents") then
            obstacleSize = target:GetExtents():GetLengthXZ()
        end
        -- we do not want to go straight through the player, instead we move behind and to the
        -- left or right
        local targetPos = target:GetOrigin()
        local toMidPos = targetViewAxis * (obstacleSize + kHealsprayRadius - 0.1)
        local midHealPos = targetPos - targetViewAxis * (obstacleSize + kHealsprayRadius - 0.4)
        local leftV = Vector(-targetViewAxis.z, targetViewAxis.y, targetViewAxis.x)
        local rightV = Vector(targetViewAxis.z, targetViewAxis.y, -targetViewAxis.x)
        local leftHealPos = midHealPos + leftV * 2
        local rightHealPos = midHealPos + rightV * 2
        
        -- take the shortest route
        local origin = self:GetOrigin()
        if (origin - leftHealPos):GetLengthSquared() < (origin - rightHealPos):GetLengthSquared() then
            healPos = leftHealPos
        else
            healPos = rightHealPos
        end
    end
    
    return healPos
        
end

--McG:
-- How much cost is there from doing bot:GetMotion() over and over, vs bot.motion? seems, _dumb_ to use accessor in this context
-- Also...how much is actually _gained_ by using an accessor? ...from what I see, this is just wasted function calls, vs simple direct memory(ref) access
--  ....we're not trying to build an API here, some hard-coded things are fine.
local function PerformMove( alienPos, targetPos, bot, brain, move )

    local postIgnore, targetDist, targetMove, entranceTunel = HandleAlienTunnelMove( alienPos, targetPos, bot, brain, move )
    if postIgnore then return end -- We are waiting for a tunnel pass-through, which requires staying still

    local dist = targetDist
    local tooHigh = dist > 2.5 and dist < (targetMove.y - alienPos.y) * 1.5      --FIXME This should be using Extents/JumpHeight

    if tooHigh then
        bot:GetMotion():SetDesiredViewTarget( targetMove + Vector(0,dist,0) )
        if math.random() < 0.25 then
            move.commands = AddMoveCommand( move.commands, Move.Jump )
        end
    end

    if tooHigh then
        local jitter = Vector(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.25
        bot:GetMotion():SetDesiredMoveDirection( (targetMove - alienPos):GetUnit() + jitter)
        move.commands = AddMoveCommand( move.commands, Move.Jump )
    else
        bot:GetMotion():SetDesiredMoveTarget( targetMove )
    end

    --TODO Need to add "oversteer" mod to view-target when sliding (aka Initial-D movement mode)

    local gorge = bot:GetPlayer()

    local slideEngLimit = 0.65
    local lookAheadSteps = 5    --TODO Ideally this would be tuned by some "path resolution" type global/lookup
    local slopeLimit = 16

    local isSlowSliding = (gorge:GetVelocity():GetLength() / gorge:GetMaxSpeed() < 1.15 )

    local energyPerct = gorge:GetEnergy() / 100

    local prevSlideState = brain.isSliding
    if brain.isSliding and isSlowSliding then
        brain.isSliding = false
        move.commands = RemoveMoveCommand( move.commands, Move.MovementModifier )   --just in case
    end

    local wantSlide = --TODO add slide-interval delay?
        energyPerct > slideEngLimit or ( brain.lastAction and brain.lastAction.name == "retreat" and gorge:GetIsUnderFire() )

    --Only re-test doing slide when energy and NOT releasing key-press this update
    if not brain.isSliding and not prevSlideState and wantSlide then
        --TODO This subroutine should probably be moved to BotMotion, surely other things could use path-slope info...
        local path = bot:GetMotion():GetPath()
        local curPointIdx = bot:GetMotion():GetPathIndex()
        
        local moveTarg = bot:GetMotion().desiredMoveTarget
        local goalDist = moveTarg ~= nil and (alienPos - moveTarg):GetLength() or -1

        if path ~= nil and curPointIdx > 0 and ( #path > lookAheadSteps and (goalDist > 10 and goalDist ~= -1) ) then  --TODO Tune path-len / goal-dist (ideally with contextual modifiers)
            local aggSlope, stepsDelta = GetPathSlope(path, curPointIdx, lookAheadSteps, alienPos.y)

            if aggSlope <= slopeLimit or stepsDelta <= slopeLimit then    --mostly flat or downwards
                brain.isSliding = true
            end
        end
    end
    
    if brain.isSliding then
        move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
    end
end


------------------------------------------
--  More urgent == should really attack it ASAP
------------------------------------------
local function GetAttackUrgency(bot, player, mem)

    if mem == nil then
        return nil
    end

    -- See if we know whether if it is alive or not
    local ent = Shared.GetEntity(mem.entId)
    if not HasMixin(ent, "Live") or not ent:GetIsAlive() or (ent:GetTeamNumber() == bot:GetTeamNumber()) then   --??wth? Why attack teammates?
        return 0.0
    end

    local botPos = player:GetOrigin()
    local targetPos = ent:GetOrigin()

    -- Don't calculate tunnel distance for every single target memory, gets very expensive very quickly
    --local distance = select(2, GetTunnelDistanceForAlien(player, ent))
    local distance = botPos:GetDistance(targetPos)
    
    local immediateThreats = 
    {
        [kMinimapBlipType.Marine] = true,
        [kMinimapBlipType.JetpackMarine] = true,
        [kMinimapBlipType.Exo] = true,
    }
    
    if distance <= 20 and immediateThreats[mem.btype] then   --Note: Gorge has much higher immediate threat distance
    -- Attack the nearest immediate threat (urgency will be 1.1 - 2)
        return 1 + 1 / math.max(distance, 1)
    end
    
    -- No immediate threat - load balance!
    local numOthers = bot.brain.teamBrain:GetNumAssignedTo( mem,
            function(otherId)
                if otherId ~= player:GetId() then
                    return true
                end
                return false
            end)
            
    local urgencies = 
    {
        -- Active threats
        [kMinimapBlipType.Marine] =             numOthers >= 4 and 0.6 or 1,
        [kMinimapBlipType.JetpackMarine] =      numOthers >= 4 and 0.7 or 1.1,
        [kMinimapBlipType.Exo] =                numOthers >= 6 and 0.8 or 1.2,
        [kMinimapBlipType.Sentry] =             numOthers >= 3 and 0.5 or 0.95,
        [kMinimapBlipType.ARC] =                numOthers >= 2 and 0.35 or 0.4,
        [kMinimapBlipType.MAC] =                numOthers >= 2 and 0.2 or 0.4,
        
        --[[
        -- Structures
        [kMinimapBlipType.ARC] =                numOthers >= 4 and 0.4 or 0.9,
        --[kMinimapBlipType.CommandStation] =     numOthers >= 8 and 0.3 or 0.85,
        [kMinimapBlipType.PhaseGate] =          numOthers >= 4 and 0.3 or 0.8,
        [kMinimapBlipType.Observatory] =        numOthers >= 3 and 0.3 or 0.75,
        [kMinimapBlipType.ArmsLab] =            numOthers >= 3 and 0.3 or 0.7,
        [kMinimapBlipType.Extractor] =          numOthers >= 3 and 0.2 or 0.7,
        [kMinimapBlipType.InfantryPortal] =     numOthers >= 3 and 0.2 or 0.6,
        [kMinimapBlipType.PrototypeLab] =       numOthers >= 3 and 0.2 or 0.55,
        [kMinimapBlipType.Armory] =             numOthers >= 3 and 0.2 or 0.5,
        [kMinimapBlipType.RoboticsFactory] =    numOthers >= 3 and 0.2 or 0.5,
        [kMinimapBlipType.MAC] =                numOthers >= 2 and 0.2 or 0.4,
        --]]
    }

    if urgencies[ mem.btype ] ~= nil then
        return urgencies[ mem.btype ]
    end

    return 0.0
    
end

--Note: this will skip-over immediate threats (compared to normal attack)
--So we need to be real careful of how this is used.
local function GetAttackStructuresUrgency(botPlayer, target)
    assert(target, "Error: Invalid target entitiy")
    
    if not HasMixin(target, "Live") or not target:GetIsAlive() or
            not target.GetTeamNumber or not botPlayer.GetTeamNumber or target:GetTeamNumber() == botPlayer:GetTeamNumber() then
        return 0
    end

    local _, blipType = target:GetMapBlipInfo()

    local urgencies =   --FIXME These should be augmented by ROUND-TIME and not num-attackers
    {
        -- Active threats
        [kMinimapBlipType.Exo] =                2.5,
        [kMinimapBlipType.Sentry] =             1.1,
        
        -- Structures
        [kMinimapBlipType.PhaseGate] =          1.0,
        [kMinimapBlipType.ARC] =                0.95,
        [kMinimapBlipType.Extractor] =          0.9,
        [kMinimapBlipType.Observatory] =        0.75,
        [kMinimapBlipType.ArmsLab] =            0.65,
        [kMinimapBlipType.CommandStation] =     0.6,
        [kMinimapBlipType.InfantryPortal] =     0.6,
        [kMinimapBlipType.PrototypeLab] =       0.55,
        [kMinimapBlipType.Armory] =             0.4,
        [kMinimapBlipType.MAC] =                0.4,
        [kMinimapBlipType.RoboticsFactory] =    0.2,

        [kMinimapBlipType.PowerPoint] =         0.3,    --TODO Add bump for ones IN Marine base(s)
    }

    if urgencies[ blipType ] ~= nil then
        return urgencies[ blipType ]
    end

    return 0
end
--[[
local function GetAttackStructuresUrgency(bot, mem)

    -- See if we know whether if it is alive or not
    local ent = Shared.GetEntity(mem.entId)
    if not HasMixin(ent, "Live") or not ent:GetIsAlive() or (ent.GetTeamNumber and ent:GetTeamNumber() == bot:GetTeamNumber()) then
        return 0.0
    end

    -- Use bot's reaction time for new memories... "Hey, that thing i saw is a enemy!"
    if Shared.GetTime() - mem.creationTime < bot.aim:GetReactionTime() then
        return nil
    end
    
    local botPos = bot:GetPlayer():GetOrigin()
    local targetPos = ent:GetOrigin()
    local distance = botPos:GetDistance(targetPos)

    if bot:GetPlayer():GetEnergy() <= kBileBombEnergyCost then
    --don't ever run dry, need reserve for evasion
        return 0
    end

    -- No immediate threat - load balance!
    local numOthers = 
        bot.brain.teamBrain:GetNumAssignedTo( mem,
            function(otherId)
                if otherId ~= bot:GetPlayer():GetId() then
                    return true
                end
                return false
            end
        )

    local urgencies =   --FIXME These should be augmented by ROUND-TIME and not num-attackers
    {
        -- Active threats
        [kMinimapBlipType.Exo] =                numOthers >= 6 and 0.8 or 2,
        [kMinimapBlipType.Sentry] =             numOthers >= 3 and 0.5 or 1.1,
        
        -- Structures
        [kMinimapBlipType.Extractor] =          numOthers >= 3 and 1.0 or 1,      --Note: bumped higher so non-base extractors will be attacked
        [kMinimapBlipType.ARC] =                numOthers >= 4 and 0.45 or 0.95,
        [kMinimapBlipType.PhaseGate] =          numOthers >= 4 and 0.2 or 0.9,
        [kMinimapBlipType.Observatory] =        numOthers >= 3 and 0.3 or 0.75,
        [kMinimapBlipType.ArmsLab] =            numOthers >= 3 and 0.4 or 0.65,
        [kMinimapBlipType.CommandStation] =     numOthers >= 8 and 0.2 or 0.6,
        [kMinimapBlipType.InfantryPortal] =     numOthers >= 3 and 0.2 or 0.6,
        [kMinimapBlipType.PrototypeLab] =       numOthers >= 3 and 0.2 or 0.55,
        [kMinimapBlipType.Armory] =             numOthers >= 3 and 0.2 or 0.4,
        [kMinimapBlipType.MAC] =                numOthers >= 2 and 0.2 or 0.4,
        [kMinimapBlipType.RoboticsFactory] =    numOthers >= 3 and 0.2 or 0.2,

        [kMinimapBlipType.PowerPoint] =         numOthers >= 2 and 0.1 or 0.25,
    }

    if urgencies[ mem.btype ] ~= nil then
        return urgencies[ mem.btype ]
    end

    return 0.0

end
--]]

local function GetBuildTargetPriority(target)

    if not target.GetMapBlipInfo then
        return 1.0 -- lowest priority
    end

    local _, blipType = target:GetMapBlipInfo()

    local urgencies =   --FIXME These should be augmented by ROUND-TIME and not num-attackers
    {
        [kMinimapBlipType.Hive] =               5,

        [kMinimapBlipType.Hydra] =              4,       --Ma toys
        --[kMinimapBlipType.BabblerEgg] =         3.75,

        [kMinimapBlipType.Harvester] =          3,      --Note: bumped higher so non-base extractors will be attacked
        [kMinimapBlipType.Crag] =               2.95,
        [kMinimapBlipType.Veil] =               2.75,
        [kMinimapBlipType.Shell] =              2.75,
        [kMinimapBlipType.Spur] =               2.75,
        [kMinimapBlipType.Shade] =              1.9,
        [kMinimapBlipType.Shift] =              1.75,
        [kMinimapBlipType.Whip] =               1,
    }

    if urgencies[ blipType ] ~= nil then
        return urgencies[ blipType ]
    end

    return 0

end


local function PerformAttackEntity( eyePos, bestTarget, lastSeenPos, bot, brain, move )
    assert(bestTarget)

    local targetPos = bestTarget:GetOrigin()
    local doFire = false
    local distance = (eyePos - targetPos):GetLength()
    local time = Shared.GetTime()
    local player = bot:GetPlayer()
    local playerPos = player:GetOrigin()

    local isDodgeable = bestTarget:isa("Player") or bestTarget:isa("MAC")
    local hasClearShot = distance <= 30.0 and bot:GetBotCanSeeTarget( bestTarget )      --FIXME Reduce/refactor this LOS check
    if hasClearShot then
        bot.lastFoughtEnemy = time
    end

    local shouldStrafe = false

    if distance > 30 then
        PerformMove(eyePos, targetPos, bot, brain, move)
    else

        local aimPos = hasClearShot and GetBestAimPoint( bestTarget ) or (lastSeenPos + Vector(0,0.25,0))
        --local aimPosPlusVel = aimPos + (bestTarget.GetVelocity and bestTarget:GetVelocity() or 0) * math.min(distance,1) / math.min(player:GetMaxSpeed(),5) * 3

        if player:GetIsUnderFire() then
            shouldStrafe = true
        end

        if distance <= 20 and distance > 16 and hasClearShot then
        --keep distance if possible

            bot:GetMotion():SetDesiredMoveTarget( nil )
            shouldStrafe = math.random() < 0.7 --orginal < 0.5

        elseif distance < 15 and distance > 5 and hasClearShot then

            local backDir = player:GetCoords().zAxis * -1   --FIXME incorrect
            local backPos = (player:GetOrigin():GetUnit() + backDir) * 1.5

            bot:GetMotion():SetDesiredMoveDirection(backPos)
            shouldStrafe = false

        end

        if distance <= 20 and hasClearShot then     --TODO Change to local glob?
            doFire = true
        end

        doFire = doFire and bot.aim and bot.aim:UpdateAim(bestTarget, aimPos, kBotAccWeaponGroup.Spit)  --aimPosPlusVel
        
        if doFire then

            player:SetActiveWeapon(SpitSpray.kMapName)
            move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )

            if shouldStrafe then

                if math.random() < 0.25 and player.timeOfLastJump == nil or player.timeOfLastJump + 1.5 > Shared.GetTime() then
                    bot.timeOfLastJump = time
                    move.commands = AddMoveCommand( move.commands, Move.Jump )
                end

                local strafeTarget = (eyePos - aimPos):CrossProduct(Vector(0,1,0))  --aimPosPlusVel
                strafeTarget:Normalize()
                
                -- numbers chosen arbitrarily to give some appearance of random juking
                --strafeTarget = strafeTarget * ConditionalValue( math.sin(time * 3.5 ) + math.sin(time * 2.2 ) > 0 , -1, 1)
                strafeTarget = strafeTarget * ConditionalValue( math.sin(time * 1.5 ) + math.sin(time * 1.1 ) > 0 , -1.25, 1.25)

                if strafeTarget:GetLengthSquared() > 0 and hasClearShot and player:GetIsInCombat() then 

                    bot:GetMotion():SetDesiredMoveDirection( strafeTarget )
                    bot:GetMotion():SetDesiredViewTarget( aimPos )  --aimPosPlusVel
                    player:SetActiveWeapon(BabblerAbility.kMapName)
                    move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )

                    if not player.timeOfLastJump or (player.timeOfLastJump + 2 > time and player.timeOfLastJump + 8 < time) then
                        player.timeOfLastJump = time
                        move.commands = AddMoveCommand(move.commands, Move.Jump)
                    end

                end

            end

        end

    end

end


local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then
        PerformAttackEntity( eyePos, target, mem.lastSeenPos, bot, brain, move )
                 local chatMsg =  bot:SendTeamMessage( "Spit and bile on humanity! " .. target:GetMapName() .. " in " .. target:GetLocationName() )
            bot:SendTeamMessage(chatMsg, 60)
    else
        -- mem is too far to be relevant, so move towards it
        bot:GetMotion():SetDesiredViewTarget(nil)
        bot:GetMotion():SetDesiredMoveTarget(mem.lastSeenPos)
    end
    
    brain.teamBrain:AssignBotToMemory(bot, mem)

end


local function PerformSendBabblers( eyePos, target, bot, brain, move )
end

local function PerformPlaceHydra( eyePos, target, bot, brain, move )
end

local function PerformPlaceBilemine( eyePos, target, bot, brain, move )
end

local function PerformPlaceWeb( eyePos, target, bot, brain, move )
end

--Note: for now, we're not going to place clogs, they "confuse" AI units too much (mainly, because they don't count as Path obstacles)


local kIdealBombardDist = 8
local kMaxDistBombard = 12 -- Max distance based on bombard speed=11m/s and gravity 9.81m/s^2 at 45 degrees


--Note: it is assumed this is NOT called until we're in range (or damn close to it)
local function BombardAttack( eyePos, mem, bot, brain, move )
    
    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        local targetPos = target.GetEngagementPoint and target:GetEngagementPoint() or target:GetOrigin()
        local targDist = ( eyePos - targetPos ):GetLength()
        local player = bot:GetPlayer()
        local shouldStrafe = false
        local time = Shared.GetTime()

        bot:GetMotion():SetDesiredViewTarget( targetPos )   --always keep tracking

        local doBomb = true
        local shouldStrafe = false
        
        if player:GetEnergy() <= kBileBombEnergyCost then
            doBomb = false --don't consume everything, save one-shot worth for reserve / get-away
        end

        bot:GetPlayer():SetActiveWeapon(BileBomb.kMapName, true)

        local gorgeVel = player:GetVelocity()

        --TODO Add support for ARC, Exos, and groups/clusters of marines
        local aimDir = Ballistics.GetAimDirection( eyePos, target:GetEngagementPoint(), kBilebombVelocity + gorgeVel:GetLength() )
        local aimTarg = aimDir + Vector( eyePos.x, eyePos.y, eyePos.z )

        doBomb = doBomb and bot.aim and bot.aim:UpdateAim(target, aimTarg, kBotAccWeaponGroup.Spit)

        local canSeeTarget = bot:GetBotCanSeeTarget( target )

        if not canSeeTarget and targDist < kMaxDistBombard then
            shouldStrafe = true
            doBomb = false
        end
        
        if doBomb and canSeeTarget then
        --Note: for things like jump+tiny-delay+bile-attack combos...we need complex action (e.g. sequence of key presses over X time ...key-patterns, etc. ...yeesh)
            move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
        end

        if targDist < kIdealBombardDist and canSeeTarget then

            if math.random() < 0.9 then
                local backDir = player:GetCoords().zAxis * -1
                --only move a litte each time, don't want to overshoot or back into a wall, etc.
                local backPos = (player:GetOrigin():GetUnit() + backDir) * 0.75

                bot:GetMotion():SetDesiredMoveDirection(backPos)
                shouldStrafe = false
            end                

        elseif not canSeeTarget then
        --we're in range, but we can't see from here, move closer

            bot:GetPlayer():SetActiveWeapon(SpitSpray.kMapName, true)   --just to make sure we're ready to fight
            bot:GetMotion():SetDesiredMoveTarget( target:GetOrigin() )
            shouldStrafe = false

        end

        if shouldStrafe then

            local strafeTarget = (eyePos - targetPos):CrossProduct(Vector(0,1,0))
            strafeTarget:Normalize()
        
            -- numbers chosen arbitrarily to give some appearance of random juking
            strafeTarget = strafeTarget * ConditionalValue( math.sin(time * 2.5 ) + math.sin(time * 1.2 ) > 0 , -1, 1)

            if strafeTarget:GetLengthSquared() > 0 then
                bot:GetMotion():SetDesiredMoveDirection(strafeTarget)
                bot:GetMotion():SetDesiredViewTarget(targetPos)
    
                if player:GetIsUnderFire() then
                    if not bot.lastJumpDodge or (bot.lastJumpDodge + 2 > time and bot.lastJumpDodge + 8 < time) then
                        bot.lastJumpDodge = time
                        move.commands = AddMoveCommand(move.commands, Move.Jump)
                    end
                end
            end

        end

    end

end

local function PerformHealSpray( gorge, healTarget, bot, brain, move )

    local targetPos = healTarget:GetOrigin()
    local eyePos = GetEntityEyePos(gorge)
    local doHeal = false
    local distance = eyePos:GetDistance( targetPos )
    local canSeeTarget = bot:GetBotCanSeeTarget( healTarget )

    --nudge a tiny bit closer to ensure it hits
    if distance < kHealsprayRadius - 0.15 and canSeeTarget then
        doHeal = true
        local idealHealSpot = GetIdealHealingPosition( gorge, healTarget )
        bot:GetMotion():SetDesiredMoveTarget( idealHealSpot )
    else
        PerformMove(eyePos, targetPos, bot, brain, move)
    end

    local aimPos = GetBestAimPoint( healTarget )
    local aimPosPlusVel = aimPos + (healTarget.GetVelocity and healTarget:GetVelocity() or 0) * math.min(distance,1) / math.min(gorge:GetMaxSpeed(),5) * 3
    --local healAim = Vector(0, 0.15, 0) + aimPosPlusVel --offset so we're not healing floors

    doHeal = doHeal and bot.aim and bot.aim:UpdateAim(healTarget, aimPosPlusVel, kBotAccWeaponGroup.Spit)

    if doHeal then
        --bot:GetMotion():SetDesiredMoveTarget(nil)
        bot:GetMotion():SetDesiredViewTarget( aimPosPlusVel )
        move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
    end

end

local kExecEvolveAction = function(move, bot, brain, gorge, action)
    gorge:ProcessBuyAction( action.desiredUpgrades )
end

local kExecAttackAction = function(move, bot, brain, gorge, action)
    brain.teamBrain:UnassignBot(bot)
    PerformAttack( gorge:GetEyePos(), action.bestMem, bot, brain, move )
end

local kExecBombardAction = function(move, bot, brain, gorge, action)
    local bestMem = action.bestMem
    local dist = action.dist
    local target = Shared.GetEntity(bestMem.entId)
    local eyePos = gorge:GetEyePos()

    if target then

        brain.teamBrain:AssignBotToEntity( bot, target:GetId() )

        local targPos = target.GetEngagementPoint and target:GetEngagementPoint() or target:GetOrigin()

        if dist > kMaxDistBombard then
        --extra distance padding because we want time to move into position, _and_ time to regen some energy
            bot:GetPlayer():SetActiveWeapon(SpitSpray.kMapName, true)   --just to make sure we're ready to fight
            PerformMove( eyePos, targPos, bot, brain, move )
        else
            BombardAttack( eyePos, bestMem, bot, brain, move )
        end

    else
    --We may not have a target, but we can move to last known location, assuming there is one
        if bestMem and bestMem.lastSeenPos then
            PerformMove( eyePos, bestMem.lastSeenPos, bot, brain, move )
        end
    end
end

local kExecHealAction = function(move, bot, brain, gorge, action)
    local healTarget = action.healTarget

    if healTarget then

        brain.teamBrain:UnassignBot(bot)
        brain.teamBrain:AssignBotToEntity( bot, healTarget:GetId() )

        PerformHealSpray( gorge, healTarget, bot, brain , move )

    end
end

local kExecPheromoneAction = function(move, bot, brain, gorge, action)
    bot:GetMotion():SetDesiredViewTarget(nil)
    PerformMove(gorge:GetEyePos(), action.bestPheromoneLocation, bot, brain, move)

    if action.bestDistance > 25 and bot:GetPlayer():GetSpeedScalar() > 0.9 then       --FIXME This needs to ensure it's == or faster than ground-speed
        move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
    end
end

local kExecOrderAction = function(move, bot, brain, gorge, action)
    local order = action.order

    if order then

        local target = Shared.GetEntity(order:GetParam())

        if target ~= nil and order:GetType() == kTechId.Attack then

            PerformAttackEntity( gorge:GetEyePos(), target, bot, brain, move )
            
        else

            if brain.debug then
                DebugPrint("unknown order type: %s", ToString(order:GetType()) )
            end

            bot:GetMotion():SetDesiredViewTarget( nil )
            PerformMove(gorge:GetEyePos(), order:GetLocation(), bot, brain, move)

        end
    end
end

local kExecRetreatAction = function(move, bot, brain, gorge, action)
    local hive = action.hive

    if hive and HasMixin(hive, "Live") and hive:GetIsAlive() then

        -- we are retreating, unassign ourselves from anything else, e.g. attack targets
        brain.teamBrain:UnassignBot(bot)

        local eyePos = gorge:GetEyePos()
        local hiveOrg = hive:GetEngagementPoint()

        if action.hiveDist < (Hive.kHealRadius * 0.3) then

            if gorge:GetIsUnderFire() then
                -- If under attack, we want to move away to other side of Hive
                local damageOrigin = gorge:GetLastTakenDamageOrigin()
                local retreatDir = (hiveOrg - damageOrigin):GetUnit()
                local _, max = hive:GetModelExtents()
                local retreatPos = hiveOrg + (retreatDir * max.x)

                bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
                bot:GetMotion():SetDesiredMoveTarget( retreatPos )
            else
                -- sit and wait to heal
                bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
                bot:GetMotion():SetDesiredMoveTarget( nil )
            end

        else
            PerformMove( gorge:GetOrigin(), hiveOrg, bot, brain, move )
        end

    else
        --TODO Random point/spot and heal-self  ..check for unbuilt Hives? (since we're a Gorge and all...)
    end
end

local kExecBuildAction = function(move, bot, brain, gorge, action)
    local target = action.target
    local dist = action.dist

    if target then 

        brain.teamBrain:UnassignBot(bot)
        brain.teamBrain:AssignBotToEntity( bot, target:GetId() )

        local targetPos = target:GetOrigin()
        local eyePos = GetEntityEyePos(gorge)

        if dist <= (kHealsprayRadius * 0.95) then
            PerformHealSpray( gorge, target, bot, brain , move )    --Build
        else
            --Handle moving TO objective, and special movement along the way
            PerformMove( gorge:GetOrigin(), targetPos, bot, brain, move )
        end
        bot:SendTeamMessage("I'll build the " .. target:GetMapName() .. " in " .. target:GetLocationName(), 120)

    end
end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------
kGorgeBrainActions =
{
    
    --[[
    TODO All Bots should have the ability to sit idle  (e.g. just built PowerPoint, waiting for Extractor drop  ...infest node, etc)
    function(bot, brain)
        return { name = "debug idle", weight = 0.001,
                perform = function(move)
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                    -- there is nothing obvious to do.. figure something out
                    -- like go to the marines, or defend
                end }
    end,
    --]]
    
--TODO Below should ideally be replaced with a "Find friend" & or, depending on Round-Time (and tech), move to Y to prepare for Z type thing
--TODO If we must have below, then at least trying to constrain it to "friendly territory", if possible.
    CreateExploreAction( 1,     --This is basically the last thing a Gorge should be doing
        function(pos, targetPos, bot, brain, move)
            PerformMove( pos, targetPos, bot, brain, move )
        end
    ),

    
    --TODO Need a "Fortify X Location" type action
    ---- This would utilize the Location-Grid + Location-Gateway data, to do things like placeing Hydras, Webds, and BileMines
    ------ In an IDEAL world...self would be AWARE of map choke points, for given starting positions, and fortify accordingly

    
    function(bot, brain, player)
        PROFILE("GorgeBrain_Data:evolve")
        local name = "evolve"

        local weight = 0.0

        -- Hallucinations don't evolve
        if player.isHallucination then
            return { name = name, weight = weight,
                perform = function() end }
        end

        local s = brain:GetSenses()
        local res = player:GetPersonalResources()

        local distanceToNearestThreat = s:Get("nearestThreat").distance
        local desiredUpgrades = {}

        if player:GetIsAllowedToBuy() and (distanceToNearestThreat == nil or distanceToNearestThreat > 40) and not player:GetIsInCombat() then

            -- Safe enough to try to evolve

            local existingUpgrades = player:GetUpgrades()

            local avaibleUpgrades = player.lifeformUpgrades

            if not avaibleUpgrades then
                avaibleUpgrades = {}

                local kUpgradeStructureTable = AlienTeam.GetUpgradeStructureTable()
                for i = 1, #kUpgradeStructureTable do
                    local upgrades = kUpgradeStructureTable[i].upgrades
                    table.insert(avaibleUpgrades, table.random(upgrades))
                end

                if player.lifeformEvolution then
                    table.insert(avaibleUpgrades, player.lifeformEvolution)
                end

                player.lifeformUpgrades = avaibleUpgrades
            end

            for i = 1, #avaibleUpgrades do
                local techId = avaibleUpgrades[i]
                local techNode = player:GetTechTree():GetTechNode(techId)

                local isAvailable = false
                local cost = 0
                if techNode ~= nil then
                    isAvailable = techNode:GetAvailable(player, techId, false)
                    cost = LookupTechData(techId, kTechDataGestateName) and GetCostForTech(techId) or LookupTechData(kTechId.Gorge, kTechDataUpgradeCost, 0)
                end

                if not player:GetHasUpgrade(techId) and isAvailable and res - cost > 0 and
                        GetIsUpgradeAllowed(player, techId, existingUpgrades) and
                        GetIsUpgradeAllowed(player, techId, desiredUpgrades) then
                    res = res - cost
                    table.insert(desiredUpgrades, techId)
                end
            end

            if #desiredUpgrades > 0 then
                weight = 10.0
            end
        end

        return 
        {
            name = name, 
            weight = weight,
            desiredUpgrades = desiredUpgrades,
            perform = kExecEvolveAction
        }

    end,    --EVOLVE

    function(bot, brain, gorge)
        PROFILE("GorgeBrain_Data:attack")

        local name = "attack"
        local sdb = brain:GetSenses()
        local threat = sdb:Get("nearestThreat")
        local weight = 3.0
        local bestUrgency = GetAttackUrgency(bot, gorge, threat.memory)
        local bestMem = threat.memory
        
        if bestMem ~= nil then

            --check weapon, as to not disrupt bombard
            local weapon = gorge:GetActiveWeapon()
            local canAttack = weapon ~= nil and weapon:isa("SpitSpray")
            
            --local target = Shared.GetEntity(bestMem.entId) --unused
            local eHP = gorge:GetHealthScalar()
            
            if canAttack then    --check weapon so we don't ignore/disrupt Bombardment
            
                if gorge:GetIsUnderFire() then
                    weight = 3.0
                end

                weight = weight + ( bot.aggroAbility or 0 )

                local dist = threat.distance
                if bestUrgency ~= nil then

                    weight = bestUrgency
                    weight = weight * 20 / dist    --bias to closest / near out ideal range
                    weight = weight * eHP          --reduce per our health

                else
                    weight = 0.0    --basically invalid target
                end
                
            end

        else
            weight = 0.0
        end

        return 
        {
            name = name,
            weight = weight,
            fastUpdate = true,
            bestMem = bestMem,
            perform = kExecAttackAction
        }
    end,    --ATTACK

    function(bot, brain, gorge)
        PROFILE("GorgeBrain - Bombard")

        local name = "bombard"
        local weight = 2.5

        local sdb = brain:GetSenses()
        local bileTargData = sdb:Get("nearestBilebombTarget")
        local bestMem = bileTargData and bileTargData.memory or nil
        local dist = bileTargData and bileTargData.distance or -1
        local gorge = bot:GetPlayer()

        if not bileTargData then
            return kNilAction
        end

        if GetWarmupActive() then
            weight = 0
        else

            if bestMem == nil then
                weight = 0

            else

                --Log("Have memory...weighting Bombard action")
                --Log("\t memory: %s", ToString(bestMem) )
                local target = Shared.GetEntity(bestMem.entId)
                local eHP = gorge:GetHealthScalar() -- current / max, or [0-1] percentage

                local techTree = GetTechTree(gorge:GetTeamNumber())
                if techTree and techTree:GetHasTech(kTechId.BileBomb, true) then
        
                    local targetUrgency = GetAttackStructuresUrgency(gorge, target)

                    weight = weight + (targetUrgency ~= nil and targetUrgency or 0)
                    weight = (weight + ( bot.aggroAbility or 0 )) - (1 - eHP) --decrease, the less eHP we have
        
                    --dampening heavily if we're being attacked, or losing health
                    if gorge:GetIsUnderFire() then
                        --reduce if we're being shot, so Attack/Retreat have higher chances
                        weight = (weight * 0.25) * eHP
                    end
                
                else
                    weight = 0
                end

            end

        end

        return 
        {
            name = name, 
            weight = weight,
            fastUpdate = true,
            bestMem = bestMem,
            dist = dist,
            perform = kExecBombardAction
        }

    end,    --BOMBARD

--TODO See about potentially looking for targets that are being Mysted (structures) and help them via Healspray (see weapons/aliens/healspraymixin.lua at ~160)

    function(bot, brain, gorge)
        PROFILE("GorgeBrain - Heal")

        local name = "heal"
        local sdb = brain:GetSenses()
        local weight = 3.0
        local healData = sdb:Get("nearestHealable")
        local healTarget = healData and healData.target or nil
        local healDist = healData and healData.distance or -1

        local potentialHealTarget = 
            healTarget and 
            healTarget ~= gorge and 
            healDist ~= -1 and
            ( healDist > 0 and healDist <= kGorgeMaxHealableSearchRange )

        if potentialHealTarget then

            local targHpScaler = healTarget:GetHealthScalar()
            local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( gorge, healTarget:GetId() )

            if numOthers == nil or numOthers < 1 and targHpScaler < 1.08 then --orginal targHpScaler < 0.85

                local numOnSelf = brain.teamBrain:GetNumOthersAssignedToEntity( gorge, gorge:GetId() )
                --Check that healTarget is not healing us, otherwise when in combat, Gorges will be stuck(logically) and just try to tank all damange(dumb)
                if numOnSelf ~= nil and numOnSelf >= 1 and gorge:GetIsUnderFire() and healTarget:isa("Gorge") then

                    --If we don't "block" Gorge from healing each other, they pair-off and try to heal-tank while stationary. Dumb
                    --TODO Need to fetch if BEING healed by healTarget, and weight to 0 if true, otherwise, do as normal
                    weight = 0.0    --HACK

                else

                    --safety check
                    if healDist <= 0 then
                        healDist = 0.1  --to avoid errors
                    end

                    --bias to nearest. Healing should be _high_ priority so no LPF bs
                    weight = math.abs( kGorgeMaxHealableSearchRange - math.log(healDist) )
                    weight = weight + bot.helpAbility
                    
                    local targClass = healTarget:GetClassName()

                    --higher eHP weighted lower, effectively
                    weight = weight - (targHpScaler * 1.25)

                    --TODO change to reference table (ClassName dip)    
                    if targClass == "Hive" and targHpScaler < 0.6 then
                        weight = weight * 1.3

                    elseif targClass == "Hive" and targHpScaler < 0.25 then
                        weight = weight * 25
                        
                    elseif targClass == "Onos" then
                        weight = weight * 1.2
    
                    elseif targClass == "Fade" then
                        weight = weight * 1.125
    
                    elseif targClass == "Lerk" then
                        weight = weight * 1.1

                    elseif targClass == "Skulk" then
                    --down-weight Skulks some compared to everthing else
                        weight = weight + 0.5

                    elseif targClass == "Gorge" then
                    --zero out all weight to now healing other Gorges, because it creates too many feedback loops
                        weight = weight * 0.01

                    end
                    
                    if healTarget.isOnFire == true then 
                        weight = weight + 0.25
                    end

                end

            end
        
        else
            weight = 0.0
        end
        
        return 
        {
            name = name,
            weight = weight,
            fastUpdate = true,
            healTarget = healTarget,
            perform = kExecHealAction
        }
    end, -- HEAL NEAREST LIVE-FRIENDLY TARGET

    --[[    TODO
                This shouldn't be added unless the Onos understand its got a Gorge buddy?

    function(bot, brain, gorge)

        local name = "escortOnos"
        local sdb = brain:GetSenses()
        local weight = 0.0
        local targetData = sdb:Get("nearestOnos")
        local target = targetData and targetData.target or nil
        local dist = targetData and targetData.distance or -1
        
        
        if target and dist ~= 0 and dist < 15 then
            local targetId = target:GetId()
            if targetId then
                local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( gorge, targetId )
                if ((numOthers == nil) or numOthers >= 1) and not brain.teamBrain:GetIsAssignedToEntity( gorge, targetId ) then
                    weight = 0.0
                else
                    weight = weight + weight + bot.helpAbility + 0.1
                end
            end
        end
        

        if target and dist ~= -1 then



        end

        return 
        {
            name = name, 
            weight = weight,
            perform = 
                function(move)
                    if target then 
                    
                        brain.teamBrain:UnassignBot(bot)
                        brain.teamBrain:AssignBotToEntity( bot, target:GetId() )

                        local touchDist = GetDistanceToTouch( gorge:GetEyePos(), target )
                        if touchDist > 5.0 then
                            
                            PerformMove( gorge:GetOrigin(), target:GetEngagementPoint(), bot, brain, move )
                            
                        elseif touchDist < 2.0 then
                            local diff = (gorge:GetOrigin() - target:GetEngagementPoint()):GetUnit() * 3.5
                            PerformMove( gorge:GetOrigin(), target:GetEngagementPoint() + diff, bot, brain, move )

                        elseif touchDist > 12.0 then

                            --move.commands = AddMoveCommand( move.commands, Move.MovementModifier )          --FIXME Move to PerformMove
                            PerformMove( gorge:GetOrigin(), target:GetEngagementPoint(), bot, brain, move )

                        else
                            bot:GetMotion():SetDesiredMoveTarget( nil )

                            if not bot.lastLookAround or bot.lastLookAround + 2 < Shared.GetTime() then
                                bot.lastLookAround = Shared.GetTime()
                                local viewTarget = GetRandomDirXZ()
                                viewTarget.y = math.random()
                                viewTarget:Normalize()
                                bot.lastLookTarget = gorge:GetEyePos() + viewTarget * 30
                            end
                            
                            if bot.lastLookTarget then
                                bot:GetMotion():SetDesiredViewTarget(bot.lastLookTarget)
                            end
                            
                        end

                    else
                        brain.teamBrain:UnassignBot(bot)
                        bot:GetMotion():SetDesiredMoveTarget(nil)
                    end
                end 
        }
    end,    --ESCORT NEAREST ONOS
    --]]

    function(bot, brain, gorge)
        PROFILE("GorgeBrain_Data:pheromone")

        local name = "pheromone"        --TODO weight up Expanding for Gorge (assume its placement means building), but support all
        local eyePos = gorge:GetEyePos()

        local pheromones = EntityListToTable(Shared.GetEntitiesWithClassname("Pheromone"))            
        local bestPheromoneLocation = nil
        local bestValue = 0
        local bestDistance = -1
        
        for p = 1, #pheromones do
        
            local currentPheromone = pheromones[p]
            if currentPheromone then
                local techId = currentPheromone:GetType()
                
                if techId == kTechId.ExpandingMarker then   --or techId == kTechId.ThreatMarker
                
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
                                local tunnelDist = select(2, GetTunnelDistanceForAlien(gorge, location))
                                local value = 5.0 + 5.0 / math.max(tunnelDist, 1.0) - #(currentPheromone.visitedBy)
                        
                                if value > bestValue then
                                    bestPheromoneLocation = locationOnMesh
                                    bestValue = value
                                    bestDistance = tunnelDist
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

        return 
        {
            name = name, 
            weight = weight,
            bestPheromoneLocation = bestPheromoneLocation,
            bestDistance = bestDistance,
            perform = kExecPheromoneAction
        }
    end,    --PHEROMONES


    function(bot, brain, gorge)            ---?? Does this apply to OrdeSelfMixin thing?
    PROFILE("GorgeBrain_Data:order")
        local name = "order"

        local order = bot:GetPlayerOrder()

        local weight = 0.0
        if order ~= nil then
            weight = 15.0
        end

        return 
        {
            name = name, 
            weight = weight,
            order = order,
            perform = kExecOrderAction
        }
    end,    --ORDERS

    --TODO This needs to adjust and look for Hive OR Crag, but bias Crag if Hive further
    function(bot, brain, gorge)    --FIXME Need this to perform backpeddle when in combat for X time, then turn and run?
        PROFILE("GorgeBrain_Data:retreat")

        local name = "retreat"
        local sdb = brain:GetSenses()
        local weight = 1.0

        local nearPlayers = sdb:Get("nearbyPlayers")

        --[[
        local cragData = sdb:Get("nearestCrag")
        local crag = cragData and cragData.crag or nil
        local cragDist = cragData and cragData.distnace or -1
        --]]

        local hiveData = sdb:Get("nearestHive")
        local hiveDist = hiveData and hiveData.distance or 200
        local hive = hiveData and hiveData.hive or nil
        local enemies = nearPlayers and nearPlayers.enemies or 0
        local friends = nearPlayers and nearPlayers.friends or 0
        local eHP = gorge:GetHealthScalar()

        if eHP < 0.925 then     --FIXME Rebalance weight

            -- If we are pretty close to the hive, stay with it a bit longer to encourage full-healing, etc.
            -- so pretend our situation is more dire than it is
            if hiveDist < (Hive.kHealRadius * 0.25) and eHP < 0.8 then
                eHP = eHP / 3.0
                weight = weight + eHP
            end
            
            if friends == 0 and gorge:GetIsInCombat() then 
                --Always increase when we're on our own
                weight = weight * 2 + ( eHP * 1.5 )
            end
            
            if eHP <= 0.8 then
                --weight higher, fewer friends we have with a dampener
                weight = weight * 2 + ( (enemies - friends) * 0.25 )
            end

            if eHP < 0.75 then
                --significanlty increae weight the lower out eHP
                weight = weight + ( weight * (1 - eHP) * 1.5 )
            end

            if hive then

                --scale down as Hive nears, but dampen as health lowers
                weight = weight * 2 + math.abs(eHP - math.log(hiveDist))

                --if gorge.GetIsInCombat and gorge:GetIsInCombat() then
                --    weight = weight * 2 + (1 - eHP)
                --end

            end

        else
            weight = 0.0
        end

        return 
        {
            name = name, 
            weight = weight,
            fastUpdate = true,
            hive = hive,
            hiveDist = hiveDist,
            perform = kExecRetreatAction
        }

    end,    --RETREATING

    function(bot, brain, gorge)
        PROFILE("GorgeBrain - Build")

        local name = "build"
        local sdb = brain:GetSenses()
        local weight = 1.0
        local buildData = sdb:Get("nearestBuildable")
        local target = buildData and buildData.target or nil
        local dist = buildData and buildData.distance or -1

        if target and dist ~= -1 and not gorge:GetIsInCombat() then

            weight = weight + (weight * bot.helpAbility)

            local targetId = target:GetId()
            if targetId then
				local isAssigned = brain.teamBrain:GetIsAssignedToEntity( gorge, targetId )
                local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( gorge, targetId )

                if target:isa("Cyst") and not target:CanBeBuilt() then
                --don't waste time on unconnected cysts
                    weight = 0

                elseif numOthers ~= nil and numOthers > 0 and not target:isa("Hive") then
                --Spread out, don't want our fatties clumping
                    weight = 0

                else
                    --increase weight by class-type
                    local typePrio = GetBuildTargetPriority(target)   --TODO Pre-sort buildables by this value

                    weight = weight + 1 + typePrio
                    
                    -- but with a close bonus
                    if dist <= 15 or isAssigned then
                        weight = weight + (15 / dist)
                    end
                end
            else
                weight = 0
            end
        else
            weight = 0
        end

        return 
        {
            name = name, 
            weight = weight,
            target = target,
            dist = dist,
            perform = kExecBuildAction
        }
    end,    --BUILDER

}

------------------------------------------
--
------------------------------------------
function CreateGorgeBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("allThreats", function(db, gorge)
            local team = gorge:GetTeamNumber()
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

    s:Add("nearestThreat", function(db, gorge)
            local allThreats = db:Get("allThreats")
            local playerPos = gorge:GetOrigin()
            
            local distance, nearestThreat = GetMinTableEntry( allThreats,
                function( mem )
                    local origin = mem.origin
                    local ent = Shared.GetEntity(mem.entId)
                    if origin == nil then
                        origin = ent:GetOrigin()
                    end
                    return select(2, GetTunnelDistanceForAlien(gorge, ent or origin))
                end)

            return 
            {
                distance = distance, 
                memory = nearestThreat
            }
        end)

    s:Add("nearestBuildable", function(db, gorge)

            local targets = (GetEntitiesWithMixinForTeam("Construct", gorge:GetTeamNumber()))

            local dist, target = GetMinTableEntry( targets,
                function(target)
                    assert( target ~= nil )
                    --[[
                    TODO
                        - Should add filtering for what's Infested and isn't
                        - Ideally, this should filter based on what's cysted (e.g. infested, _now_)
                    --]]
                    if not target:GetIsBuilt() and (not HasMixin(target, "Live") or target:GetIsAlive()) then
                        return select(2, GetTunnelDistanceForAlien(gorge, target))
                    end
                end)

            return 
            {
                target = target, 
                distance = dist
            }

        end)
        
        s:Add("allBileAbleTargets", function(db, gorge) 
    local team = gorge:GetTeamNumber() 
    local memories = GetTeamMemories( team )

        return FilterTableEntries( memories,
            function( mem )                    
                local ent = Shared.GetEntity( mem.entId )
                
                --Entferne die Zeilen, die Marines und PowerPoints ausschließen.
                if HasMixin(ent, "Corrode") then
                --if HasMixin(ent, "Corrode") then
                    local isAlive = HasMixin(ent, "Live") and ent:GetIsAlive()
                    local isEnemy = HasMixin(ent, "Team") and ent:GetTeamNumber() ~= team                    
                    
                    if HasMixin(ent, "Construct") then
                        --Passe die Zeile an, die die Konstruktion berücksichtigt
                        --return isAlive and isEnemy and ent:GetIsBuilt()    
                        return isAlive and isEnemy and ent:GetIsBuilt()
                    end

                    return isAlive and isEnemy
                else
                    return false
                end
            end)                
    end)

    --[[s:Add("allBileAbleTargets", function(db, gorge)  --orginal
            local team = gorge:GetTeamNumber()
            local memories = GetTeamMemories( team )

            return FilterTableEntries( memories,
                function( mem )                    
                    local ent = Shared.GetEntity( mem.entId )
                    
                    --For now, we don't want to bile Marines, because that will conflict with Attack action
                    --For now, ignore power nodes, not worth the edge-cases  -- TODO deal with edgey-nodes...
                    if HasMixin(ent, "Corrode") and ( not ent:isa("PowerPoint") and not ent:isa("Marine") ) then
                        local isAlive = HasMixin(ent, "Live") and ent:GetIsAlive()
                        local isEnemy = HasMixin(ent, "Team") and ent:GetTeamNumber() ~= team                    
                        
                        if HasMixin(ent, "Construct") then
                            return isAlive and isEnemy and ent:GetIsBuilt()    
                        end

                        return isAlive and isEnemy
                    else
                        return false
                    end
                end)                
        end)--]]

    s:Add("nearestBilebombTarget", function(db, gorge)

            local allTargets = db:Get("allBileAbleTargets")

            local distance, nearestTarget = GetMinTableEntry( allTargets,
                function( mem )
                    local origin = mem.lastSeenPos
                    local target = Shared.GetEntity(mem.entId)
                    if origin == nil then
                        origin = target:GetOrigin()
                    end
                    return select(2, GetTunnelDistanceForAlien(gorge, target or origin))
                end)

            return 
            {
                distance = distance, 
                memory = nearestTarget
            }

        end)

    --[[
    s:Add("nearestOnos", function(db, gorge)       --TODO Bias it towards actual players

            local gorgePos = gorge:GetOrigin()
            local oni = GetEntitiesWithMixinForTeam( "Onos", gorge:GetTeamNumber() )

            local dist, onos = GetMinTableEntry( oni,
                function(onos)
                    if onos and onos.GetIsAlive and onos:GetIsAlive() then
                        return (gorgePos - onos:GetOrigin()):GetLength()
                    end
                end)

            return 
            {
                target = onos, 
                distance = dist
            }
        end)
    --]]

    s:Add("nearestHive", function(db, gorge)       --TODO Things like this should be a common function across all AlienBots, not duplicated code, over and over. Just bloats memory usage
            local hives = GetEntitiesForTeam( "Hive", gorge:GetTeamNumber() )

            local dist, hive = GetMinTableEntry( hives,
                function(hive)
                    if hive and hive:GetIsBuilt() then
                        return select(2, GetTunnelDistanceForAlien(gorge, hive))
                    end
                end)

            return 
            {
                hive = hive, 
                distance = dist
            }
        end)

    s:Add("nearestCrag", function(db, gorge)       --TODO Things like this should be a common function across all AlienBots, not duplicated code, over and over
            local crags = GetEntitiesForTeam( "Crag", gorge:GetTeamNumber() )

            local dist, crag = GetMinTableEntry( crags,
                function(crag)
                    if crag and crag:GetIsBuilt() then
                        return select(2, GetTunnelDistanceForAlien(gorge, crag))
                    end
                end)

            return 
            {
                crag = crag, 
                distance = dist
            }
        end)

    s:Add("nearbyPlayers", function(db, gorge)
            local gorgePos = gorge:GetOrigin()
            local players = GetEntitiesWithMixinWithinRange( "ControllerMixin", gorgePos, 12 )
            local numFriends = 0
            local numHostile = 0
            local selfTeam = gorge:GetTeamNumber()

            for i = 1, #players do
                if players[i].teamNumber and players[i]:GetId() ~= gorge:GetId() then    --exclude ourselves
                    if players[i].teamNumber ~= selfTeam then
                        numHostile = numHostile + 1
                    else
                        numFriends = numFriends + 1
                    end
                end
            end

            return 
            {
                enemies = numHostile,
                friends = numFriends,
            }
        end)
        
    s:Add("nearestHealable", function(db, gorge)

        local gorgePos = gorge:GetOrigin()
        local targets = GetEntitiesWithMixinForTeamWithinRange( "Live", gorge:GetTeamNumber(), gorgePos, kGorgeMaxHealableSearchRange )     --Using PereiverMixin would make this quicker, probably?

        local healables = {}
        for i = 1, #targets do
            local healTarget = targets[i]

            local isValidHealable = 
            (
                ( healTarget.GetIsBuilt and healTarget:GetIsBuilt() ) or  
                ( healTarget:GetIsAlive() )
            )
            if isValidHealable then
                table.insert(healables, healTarget)
            end
        end

        local dist, target = GetMinTableEntry( healables,
            function(target)
                if target then
                    if target ~= gorge and target:GetIsHealable() and target:GetHealthScalar() < 1.0 then --orginal < 0.9
                        return select(2, GetTunnelDistanceForAlien(gorge, target))
                    end
                end
            end)

        return 
        {
            target = target, 
            distance = dist
        }

    end)


    return s
end
