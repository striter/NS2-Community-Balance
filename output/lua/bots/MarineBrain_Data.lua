
Script.Load("lua/bots/BotDebug.lua")
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/CommonMarineActions.lua")
Script.Load("lua/bots/BrainSenses.lua")
Script.Load("lua/bots/BotAim.lua")


local kMarineTakeTerritoryRange = 75
local kMarineAwaitEarlyResDropLimit = 1
local kMarinePressureEarlyNaturalsLimit = 1.5
local kMarineChaseLostMemoryTime = 5
local kMarineImmediateThreatThreshold = 1.0
local kMarineEvalImmediateThreatTime = 1.0
local kDefaultMarineEnagementRange = 10
local kMarineOnGuardChaseThreatTime = 0.8
local kMarinePressureEnemyThreshold = 0.7

------------------------------------------
--  Data includes values, but also functions.
--  We put them in this file so we can easily hotload it and iterate live.
--  Nothing in this file should affect other game state, except where it is used.
------------------------------------------

local GetPhaseDistanceForMarine = GetPhaseDistanceForMarine

------------------------------------------
--  Handles things like using phase gates
------------------------------------------
local function PerformMove( marinePos, targetPos, bot, brain, move, isUseMove, sprintOverride )
    PROFILE("MarineBrain - PerformMove")

    local marine = bot:GetPlayer()
    local teamBrain = brain.teamBrain
    local dist, gate = GetPhaseDistanceForMarine( bot:GetPlayer(), targetPos, brain.lastGateId )

    if dist > 10 and sprintOverride ~= false then
    --sprint as often as possible
        --TODO For Veteran personas, switch to welder/axe for moar-sp3eDz
        move.commands = AddMoveCommand(move.commands, Move.MovementModifier)
    end

    GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Phase Gate", gate and gate:GetId() or "None")
    
    --This is done in order to ensure consistent and smooth interaction with gates. Otherwise,
    --Marines can get "stuck" on the side of a gate, because they stupidly just move in a straight-line
    --McG: Be very, very careful when touching anything in this conditional statement...lest you unleash an edge-case hell-hole...
    if gate ~= nil then

        local gatePos = gate:GetOrigin()

        teamBrain:AddPlayerToPGQueue(gate:GetId(), marine:GetId())

        local distanceToGate = GetBotWalkDistance(bot:GetPlayer(), gate)
        if distanceToGate > 15 then -- Don't bother with micro-adjustments if we too far
            bot:GetMotion():SetDesiredMoveTarget( gatePos )
            bot:GetMotion():SetDesiredViewTarget( nil )
        else

            -- We're close enough to the phase gate, try and
            -- do our phase-gate entry if we're next in line

            -- We are in "close enough to wait" distance, do nothing until it's our turn.
            if distanceToGate <= 7 then

                if teamBrain:GetIsNextForPGQueue(marine:GetId()) then

                    GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(),
                            kBotDebugSection.ActionWeight,
                            "PG Status",
                            "Our turn! Moving to gate...")

                    local offset = 1.315    --Front/Rear points from gate origin (facing)
                    local toGateFrontPoint = gate:GetOrigin() + gate:GetCoords().zAxis * offset
                    local toGateRearPoint = gate:GetOrigin() + -gate:GetCoords().zAxis * offset

                    local frontPathPoint = Pathing.GetClosestPoint(toGateFrontPoint)
                    local rearPathPoint = Pathing.GetClosestPoint(toGateRearPoint)

                    local frontPointMeshDist = frontPathPoint:GetDistance(toGateFrontPoint)
                    local isFrontPointValid = frontPointMeshDist > 0.001 or frontPointMeshDist < 0.5

                    local rearPointMeshDist = rearPathPoint:GetDistance(rearPathPoint)
                    local isRearPointValid = rearPointMeshDist > 0.001 or rearPointMeshDist < 0.5

                    local gateFrontDist = (toGateFrontPoint - marinePos):GetLength()
                    local gateRearDist = (toGateRearPoint - marinePos):GetLength()

                    local gateToPos
                    if isFrontPointValid and isRearPointValid then
                        gateToPos = ( gateFrontDist < gateRearDist and frontPathPoint or rearPathPoint )
                    else
                        gateToPos = (isFrontPointValid and frontPathPoint) or
                                    (isRearPointValid and rearPathPoint) or
                                    gate:GetOrigin()
                    end

                    local gatePosDist = GetBotWalkDistance(marine, gateToPos, gate:GetLocationName())
                    if gatePosDist > offset and not brain.phaseGateMovingDir then
                        bot:GetMotion():SetDesiredMoveTarget( gateToPos )
                    else

                        brain.phaseGateMovingDir = true
                        --slow down, _try_ not to spaz

                        move.commands = RemoveMoveCommand(move.commands, Move.MovementModifier) --for "safety"

                        --Move in direction from nearest TO-GATE point (front/rear) forward toward origin and slightly past it
                        local moveDir = (gate:GetOrigin() - marinePos):GetUnit()

                        --This is such a train-wreck ....so, we HAVE to set a move-target, otherwise bad edge-cases happen
                        --And we HAVE to set the move-direction, because Bots have a mental break-down if a Point is off nav-mesh
                        --Which...ALL PG _phase-triggers_ will always be off nav-mesh. Man this is so clunky.
                        bot:GetMotion():SetDesiredMoveDirection( moveDir )
                        bot:GetMotion():SetDesiredViewTarget( gate:GetOrigin() )

                    end

                else

                    GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(),
                            kBotDebugSection.ActionWeight,
                            "PG Status",
                            "Waiting for turn")

                    -- Stay still, not our turn
                    bot:GetMotion():SetDesiredMoveTarget( nil )

                    -- Look at next in queue
                    local nextEntId = teamBrain:GetNextInQueue(gate:GetId())
                    local nextEnt = nextEntId and Shared.GetEntity(nextEntId)
                    if nextEnt then
                        bot:GetMotion():SetDesiredViewTarget( nextEnt:GetEyePos() )
                    end

                end

            else -- Get to "close enough to wait" distance, so just move normally toward it
                bot:GetMotion():SetDesiredMoveTarget( gatePos )
                bot:GetMotion():SetDesiredViewTarget( nil )
            end

        end

        brain.lastGateId = gate:GetId()

    else

        brain.phaseGateMovingDir = false
        teamBrain:RemovePlayerFromPGQueue(marine:GetId())
        bot:GetMotion():SetDesiredMoveTarget( targetPos )
        bot:GetMotion():SetDesiredViewTarget( nil )
        brain.lastGateId = nil  --very important this gets cleared
        
        -- do a jump... we're probably stuck
        if dist < 1.5 and math.abs(marinePos.y - targetPos.y) > 1.0 then
            move.commands = AddMoveCommand(move.commands, Move.Jump)
        end
        
        --TODO Review & revise below, those won't maintain flight...needs to be like Gorge slide + energy management (fuel)
        if marine:isa("JetpackMarine") and marine:GetFuel() > 0.91 and (not marine:GetIsOnGround() or marine:GetFuel() > 0.96) then

            -- Jetpackers shouldn't use thrusters if they are trying to build something and they're close to it
            if not isUseMove or (isUseMove and dist >= 5) then
                move.commands = AddMoveCommand(move.commands, Move.Jump)
                move.commands = AddMoveCommand(move.commands, Move.Crouch)
            end

        end

    end

end

local function SwitchToPrimary(marine)
    local primaryWeapon = marine:GetWeaponInHUDSlot(1)
    if primaryWeapon then
    --check for existence of weapon, just in case odd dropping behavior occurred
        marine:SetActiveWeapon(primaryWeapon:GetMapName(), true)
    end
end

local function SwitchToWelder(marine)
    local welder = marine:GetWeapon( Welder.kMapName )
    if welder then
        marine:SetActiveWeapon(Welder.kMapName, true)
    end
end

local function SwitchToPistol(marine)
    local weapon = marine:GetWeapon( Pistol.kMapName )
    if weapon and weapon:GetAmmo() / weapon:GetMaxAmmo() > 0.0 then
        marine:SetActiveWeapon(Pistol.kMapName, true)
    else
        SwitchToPrimary(marine) --BOT-TODO  Review. pistol isn't ACTUALLY swapped in this scenario, why is this here?
    end
end

local function SwitchToMelee(marine)
    local weapon = marine:GetWeaponInHUDSlot(3)
    if weapon then
        marine:SetActiveWeapon(weapon:GetMapName(), true)
    end
end

local function SwitchToMine(marine)
    local weapon = marine:GetWeaponInHUDSlot(4)
    if weapon then
        marine:SetActiveWeapon(weapon:GetMapName(), true)
    end
end

local function SwitchToHandGrenade(marine)
    local weapon = marine:GetWeaponInHUDSlot(5)
    if weapon then
        marine:SetActiveWeapon(weapon:GetMapName(), true)
    end
end

local function SwitchToExploreWeapon(marine, senses)

    local primaryClipFraction = senses:Get("clipFraction")
    if primaryClipFraction > 0 then
        SwitchToPrimary(marine)
        return
    end

    local secondaryClipFraction = senses:Get("pistolClipFraction")
    if secondaryClipFraction > 0 then
        SwitchToPistol(marine)
        return
    end

    SwitchToMelee(marine)

end

local kMarineWeaponEngagementRanges = nil

--Note: Be sure and make sure the desired Weapon, for callee context, is set before this is called
--TODO Review and look into potentially moving ALL weapon range values into Balance (or similar) instead of defined LOCALLY in the damned weapon files
local function GetEffectiveRangeForWeapon(marine)
    local weapon = marine:GetActiveWeapon()
    if weapon then

        if not kMarineWeaponEngagementRanges then
        --nasty hack, FIXME, weapon map names not in scope at script-load time
            kMarineWeaponEngagementRanges = {}
            kMarineWeaponEngagementRanges[Rifle.kMapName] = 22
            kMarineWeaponEngagementRanges[Pistol.kMapName] = 22
            kMarineWeaponEngagementRanges[Shotgun.kMapName] = 12
            kMarineWeaponEngagementRanges[Flamethrower.kMapName] = 7
            kMarineWeaponEngagementRanges[HeavyMachineGun.kMapName] = 22
            kMarineWeaponEngagementRanges[GrenadeLauncher.kMapName] = 20
            kMarineWeaponEngagementRanges[Welder.kMapName] = 1.5
            kMarineWeaponEngagementRanges[Axe.kMapName] = 1.5
        end

        local weaponMapName = weapon:GetMapName()
        if kMarineWeaponEngagementRanges[weaponMapName] then
            return kMarineWeaponEngagementRanges[weaponMapName]
        end
    end
    return kDefaultMarineEnagementRange
end

local function PerformAttackStructure( eyePos, target, lastSeenPos, bot, brain, move )
    PROFILE("MarineBrain - PerformAttackStructure")

    assert(target ~= nil )

    local player = bot:GetPlayer()
    local time = Shared.GetTime()
    
    local sighted 
    if not target.GetIsSighted then
        sighted = true
    else
        sighted = target:GetIsSighted()     --??? How does this make sense for BOTS, they're ServerWorld ONLY
    end

    local aimPos = sighted and GetBestAimPoint( target ) or (lastSeenPos + Vector(0,0.1,0))
    local dist = (eyePos - target:GetOrigin()):GetLength() --GetDistanceToTouch(eyePos, target)
    local doFire = false
    
    -- Avoid doing expensive vis check if we are too far
    local hasClearShot = false
    local idealWeapRange = GetEffectiveRangeForWeapon(player)
    local upperWepRange = idealWeapRange
    local lowerBound = idealWeapRange * 0.3
    local lowerWepRange = lowerBound > 1.25 and lowerBound or 1.25  --help welding
    local weaponType = player:GetActiveWeapon():GetMapName()

    if dist <= 35 then
        hasClearShot = bot:GetBotCanSeeTarget( target )
    end

    if weaponType == GrenadeLauncher.kMapName or weaponType == ClusterGrenadeThrower.kMapName  then
        dist = math.max(0, dist - (HasMixin(target, "Extents") and target:GetExtents():GetLengthXZ() or 0))
    end

    if not hasClearShot then
        PerformMove( eyePos, aimPos, bot, brain, move )

    else

        if dist < upperWepRange then
            doFire = true
        end

        if weaponType == GrenadeLauncher.kMapName and dist <= lowerWepRange then
        --backwards, until distance where we won't blow ourselves to bits
            doFire = false
            bot:GetMotion():SetDesiredViewTarget(aimPos)
            local facing = player:GetViewAngles():GetCoords().zAxis
            bot:GetMotion():SetDesiredMoveDirection(-facing)    --FIXME Need some more spatial checks here...could just back into a wall forever...
            if math.random() < 0.185 then
                --TODO randomly strafe left/right for X dist (factor of distTo?)
            end
            --Log(" [PerformAttackStructure] In range with LOS, reposition, TOO CLOSE")
        end

        if doFire then
            --BOT-FIXME GLs need to take self vs target height diff into account, badly. Otherwise it'll blow itself up if a cyst is on a platform, etc.
            if weaponType == GrenadeLauncher.kMapName then

                --local offset = (target:isa("Cyst") or target:isa("Egg") or target:isa("Embryo") ) and Vector(0,0,0) or Vector(0,0.35,0)
                local aimDir = Ballistics.GetAimDirection( eyePos, target:GetEngagementPoint(), GrenadeLauncher.kGrenadeSpeed + player:GetVelocity():GetLength() ) 
                local aimTarg = aimDir + Vector( eyePos.x, eyePos.y, eyePos.z )

                doFire = bot.aim and bot.aim:UpdateAim(target, aimTarg, kBotAccWeaponGroup.Bullets) --TODO Make GL/Balistic acc grp

            elseif target:isa("Embryo") then
                bot:GetMotion():SetDesiredViewTarget( aimPos )

            else
                doFire = bot.aim:UpdateAim(target, aimPos, kBotAccWeaponGroup.Bullets)

            end
            
            -- clear move target here so it can be overridden later while firing if target is a whip
            bot:GetMotion():SetDesiredMoveTarget( nil )
            bot:GetMotion():SetDesiredMoveDirection( nil )

        end

        --FIXME This needs a thing similar to Use Positions ....just static offsets (which could be randomly rotated, etc.)
        if target:isa("Whip") and dist <= Whip.kRange * 1.2 then    --FIXME Need to pull the dist value from balance or Whip, etc.
            --??? find nav spot X away that has LOS ....yikes...AND not in range of OTHER Whips, etc...shit...
            bot:GetMotion():SetDesiredViewTarget(aimPos)
            local facing = player:GetViewAngles():GetCoords().zAxis
            bot:GetMotion():SetDesiredMoveDirection(-facing)    --FIXME Need some more spatial checks here...could just back into a wall forever...
        end

        if doFire then

            move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
            bot.lastAimPos = aimPos
            brain.lastShootingTime = Shared.GetTime()
            
        end

    end

end


local kApproachDistOffset = 1.2
local kApproachDistancesPadChecks = 
{
    Vector( kApproachDistOffset, 0, 0 ),    --N
    Vector( 0, 0, -kApproachDistOffset ),   --S
    Vector( 0, 0, kApproachDistOffset ),    --E
    Vector( -kApproachDistOffset, 0, 0 ),   --W
}

local function PerformAttackEntity( eyePos, target, lastSeenPos, bot, brain, move )
    PROFILE("MarineBrain - PerformAttackEntity")

    assert(target ~= nil )

    local player = bot:GetPlayer()
    local time = Shared.GetTime()
    
    local sighted 
    if not target.GetIsSighted then
        -- Print("attack target has no GetIsSighted: %s", target:GetClassName() )
        sighted = true
    else
        sighted = target:GetIsSighted()
    end
    
    local aimPos = sighted and GetBestAimPoint( target ) or (lastSeenPos + Vector(0,0.1,0))
    local dist = GetDistanceToTouch( eyePos, target )
    local doFire = false
    local shouldStrafe = false
    local isDodgeable = target:isa("Player") or target:isa("Babbler")
        
    --local aimPosPlusVel = aimPos + (target.GetVelocity and target:GetVelocity() or 0) * math.min(dist,1) / math.min(player:GetMaxSpeed(),5) * 3

    -- Avoid doing expensive vis check if we are too far
    local hasClearShot = false
    if dist < 32.5 then
        hasClearShot = bot:GetBotCanSeeTarget( target )
    end

    local activeWepIdealRange = GetEffectiveRangeForWeapon(player)

    local approachRange = activeWepIdealRange
    if brain.lastAttackApproachRange == -1 then
    --reset to "default"
        brain.lastAttackApproachRange = activeWepIdealRange * 0.5  --treat as radius
    end

    if not hasClearShot then 

        if dist > brain.lastAttackApproachRange then
            PerformMove( eyePos, aimPos, bot, brain, move )

        else
                    
            local pathIdx = bot:GetMotion():GetPathIndex()
            local pathPoints = bot:GetMotion():GetPath()
            
            if pathPoints ~= nil and #pathPoints > 0 then
                local mOrg = player:GetOrigin()
                local steps = 9
                if steps + pathIdx > #pathPoints then
                --auto-clamp so we don't need to deal with nil
                    steps = #pathPoints
                end
                
                local tick = 1
                local lookAheadDelta = {}
                local curApproachDist = brain.lastAttackApproachRange
                --backwards, so we're starting from the target

            --FIXME/TODO What this needs to do is form an arc, angle (interior of arc facing target)
            --around near-end path points. Thus, strafing in semi-circles towards a valid attack angle...as is, below still just closes range.
            ----Worth noting, the same method could be reused, but inverted to strafe AWAY from  close-range attackers
                for i = #pathPoints - 1, (#pathPoints - (steps + 1)), -1 do   --don't use end point, for obvious reasons

                    local pd = pathPoints[i]
                    local ptD = (pd - aimPos):GetLength()

                    if ptD < curApproachDist and ptD > curApproachDist * 0.5 then
                    --we're inside out ideal range, make this our approach point
                        newMoveTarg = pd
                        break
                    end

                    curApproachDist = math.floor(curApproachDist * 0.9)
            
                    tick = tick + 1
                    if tick >= steps then
                        break
                    end

                end

                brain.lastAttackApproachRange = curApproachDist
            end

            newMoveTarg = Pathing.FindRandomPointAroundCircle( newMoveTarg == nil and aimPos or newMoveTarg, brain.lastAttackApproachRange, 1.5 )

            --FIXME Marine needs to understand if target is approaching or leaving (heading vec, compared to ours)

            bot:GetMotion():SetDesiredViewTarget( aimPos )
            bot:GetMotion():SetDesiredMoveTarget( newMoveTarg )
            --shouldStrafe = true
            
            doFire = false

        end

    else
    --LOS, by deduction, try to find ideal spot

        bot.lastSeenEnemy = time

        local dir = GetNormalizedVectorXY( target:GetOrigin() - player:GetOrigin() )
        local dot = target.GetVelocity and GetNormalizedVectorXZ(target:GetVelocity()):DotProduct(dir) or 0

        if dist <= 40 and dist > activeWepIdealRange and dot > 0.5 then
            bot:GetMotion():SetDesiredMoveTarget( nil ) --halt and let them come to us

        elseif dist > activeWepIdealRange then

            shouldStrafe = true
            doFire = true

        elseif dist > 6.5 then

            if isDodgeable then
                bot:GetMotion():SetDesiredMoveTarget( nil )
                bot:GetMotion():SetDesiredMoveDirection( player:GetViewCoords().zAxis * -1 )
                shouldStrafe = true
            end

            doFire = true

        else
            shouldStrafe = true
            doFire = true
            bot:GetMotion():SetDesiredViewTarget( aimPos )
        end
        
        local noAimClasses = { "Clog", "Babbler", "Cyst" } -- "Drifter"
        if doFire and table.icontains(noAimClasses, target:GetClassName()) and hasClearShot then
        -- this is a hack because there's a bug somewhere...
            doFire = true
            shouldStrafe = false    --doing so just mucks up the aim
            aimPos = target:GetEngagementPoint()
            bot:GetMotion():SetDesiredViewTarget( aimPos )

            --stop moving and kill
            bot:GetMotion():SetDesiredMoveTarget( nil )
            bot:GetMotion():SetDesiredMoveDirection( nil )
        else
            doFire = doFire and bot.aim:UpdateAim(target, aimPos, kBotAccWeaponGroup.Bullets)

        end

        local weapon = player:GetActiveWeapon()

        if weapon and weapon:GetMapName() == GrenadeLauncher.kMapName then

            -- fall back if we have a grenade launcher and we'd blow ourselves up
            if dist < 5.5 then
                doFire = false
                shouldStrafe = false

                bot:GetMotion():SetDesiredMoveTarget( nil )
                bot:GetMotion():SetDesiredMoveDirection(player:GetViewCoords().zAxis * -1)
            end

        end

    end

    local retreating = false
    --[[
    --FIXME Why is this here? This should NOT be done this way.....it's bloat in this context. We should return out and halt current acitons, not duplicate another action

    local retreating = false
    local sdb = brain:GetSenses()
    local minFraction = math.min( player:GetHealthFraction(), sdb:Get("ammoFraction") )
    local armory = sdb:Get("nearestArmory").armory

    -- retreat! Ignore previous move order, but keep our aim
    if armory and minFraction < 0.3 and isDodgeable then
        local touchDist = GetDistanceToTouch( eyePos, armory )
        if touchDist > 0.5 then
            PerformMove(player:GetOrigin(), armory:GetEngagementPoint(), bot, brain, move)
        else
            -- sit and wait to heal, ammo, etc. 
            brain.retreatTargetId = nil
            bot:GetMotion():SetDesiredViewTarget( armory:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveTarget( nil )
            doFire = false
        end

        retreating = true
    end
    --]]

    if shouldStrafe then
    -- good distance, or panic mode. strafe with some regularity, but somewhat random

        local strafeTarget = (eyePos - aimPos):CrossProduct(Vector(0,1,0))
        strafeTarget:Normalize()
        
        -- numbers chosen arbitrarily to give some appearance of random juking
        strafeTarget = strafeTarget * ConditionalValue( math.sin(time * 2.2 ) + math.sin(time * 3.75 ) > 0 , -1, 1)
        --BOT-TODO Above needs to be a LOT more reactive/dynamic (e.g. look at target's velocity, etc.)
        
        if strafeTarget:GetLengthSquared() > 0 then

            bot:GetMotion():SetDesiredMoveDirection(strafeTarget)

            if player:isa("JetpackMarine") then     --TODO Revie/Revise

                if (player:GetFuel() > 0.3 or not player:GetIsOnGround()) then
                    if not brain.lastJumpDodge or brain.lastJumpDodge + 2 < time or dist < 9.0 then
                        brain.lastJumpDodge = Shared.GetTime()
                        move.commands = AddMoveCommand(move.commands, Move.Jump)
                    end
                end

            else

                --Don't randomly jump when enemy is 15+ meters away
                if dist < 6 and brain.lastJumpDodge + 2 < time then
                    brain.lastJumpDodge = Shared.GetTime()
                    move.commands = AddMoveCommand(move.commands, Move.Jump)
                end

            end

        end

    end

    if doFire then
    
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
        bot.lastAimPos = aimPos
        brain.lastShootingTime = Shared.GetTime()
        
        if (not bot.lastHostilesTime or bot.lastHostilesTime < Shared.GetTime() - 45) and isDodgeable then
            CreateVoiceMessage( player, kVoiceId.MarineHostiles )
            local chatMsg =  bot:SendTeamMessage( "Enemy contact! " .. target:GetMapName() .. " in " .. target:GetLocationName() )
            bot:SendTeamMessage(chatMsg, 60)
            bot.lastHostilesTime = Shared.GetTime()
        end
        
    else
    
        if (brain.lastShootingTime and brain.lastShootingTime > Shared.GetTime() - 0.5) then
            -- blindfire at same old spot
            if bot.lastAimPos then
                bot:GetMotion():SetDesiredViewTarget( bot.lastAimPos  )
                move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
            end
            
        elseif not retreating and dist < 15.0  then
            if not bot.lastAimCheatTime or bot.lastAimCheatTime + 0.5 < Shared.GetTime() then
                bot.lastAimCheatTime = Shared.GetTime()
                bot.lastAimPos = aimPos
            end

            if bot.lastAimPos then
                bot:GetMotion():SetDesiredViewTarget(bot.lastAimPos)
            end
        else
            bot.lastAimPos = nil
        end

    end

    -- Draw a red line to show what we are trying to attack
    if gBotDebug:Get("debugall") or brain.debug then

        if doFire then
            DebugLine( eyePos, aimPos, 0.0,   1,0,0,1, true)
        else
            DebugLine( eyePos, aimPos, 0.0,   1,0.5,0,1, true)
        end

    end
    
end

local function PerformAttack( eyePos, mem, bot, brain, move ) 
    assert( mem )

    local target = Shared.GetEntity(mem.entId)
    assert(target ~= nil)

    if target:isa("Player") then
        PerformAttackEntity( eyePos, target, mem.lastSeenPos, bot, brain, move )
    else
        PerformAttackStructure( eyePos, target, mem.lastSeenPos, bot, brain, move )
    end 

end

local kDefaultUseRange = 1.35
local kMoveUseRange = 1.05

--Use positions:
--      x
--   x [t] x
--      x
local kMarineDefaultUsePositions = 
{
    Vector(kMoveUseRange,  0, 0),  -- West
    Vector(0,              0, -kMoveUseRange), -- North   
    Vector(0,              0,  kMoveUseRange),  -- South
    Vector(-kMoveUseRange, 0, 0)  -- East
}

--Use positions:
--   x  x  x
--     [t]
local kMarinePowerPointUsePositions = 
{
    Vector(0,              0, kMoveUseRange),
    Vector( kMoveUseRange, 0, kMoveUseRange),
    Vector(-kMoveUseRange, 0, kMoveUseRange),
}

local function PerformMoveToUsePosition( marine, target, bot, brain, move )
    PROFILE("MarineBrain - PerformMoveToUsePosition")
    assert(target)

    local targCoords = target:GetCoords()
    local usePositions = nil
    local slotIdx = 1

    if target:isa("PowerPoint") then
        usePositions = kMarinePowerPointUsePositions
    else
        usePositions = kMarineDefaultUsePositions
    end

    -- cache which 'side' of the target we want to attempt to approach
    if brain.lastUseTargetId == target:GetId() and brain.lastUseTargetSide then

        slotIdx = brain.lastUseTargetSide

    else

        slotIdx = math.random(1, #usePositions)

        brain.lastUseTargetId = target:GetId()
        brain.lastUseTargetSide = slotIdx

    end

    local useGoalDist = GetBotWalkDistance(marine, target)

    if useGoalDist < 5 then
    --remove sprint, to increase position accuracy
        move.commands = RemoveMoveCommand( move.commands, Move.MovementModifier )
    end

    if useGoalDist > kPlayerUseRange then
    --Only move if we're outside use-range, regardless of "ideal" position. Stops jitter/spaz movement

        local worldUsePosition = target:GetOrigin() + targCoords:TransformVector(usePositions[slotIdx])
        PerformMove( marine:GetOrigin(), worldUsePosition, bot, brain, move, true ) -- isUseMove is for jetpacks so they can build smoothly
    end

end

local function PerformUse(marine, target, bot, brain, move)
    PROFILE("MarineBrain - PerformUse")

    assert(target)
    local usePos = target:GetEngagementPoint()
    local dist = GetDistanceToTouch(marine, target)     --BOT-FIXME This does NOT take into account the orientation of target (hence why Robo causes problems!)

    local hasClearShot = dist < 5 and bot:GetBotCanSeeTarget( target )
    
    if not hasClearShot or math.random() < 0.01 then
    -- cannot see it yet - keep moving
        PerformMoveToUsePosition( marine, target, bot, brain, move )

    elseif dist < (target.GetUseMaxRange and target:GetUseMaxRange() or kPlayerUseRange) then
        -- close enough to just use
        bot:GetMotion():SetDesiredViewTarget( usePos )
        bot:GetMotion():SetDesiredMoveTarget( nil )
        move.commands = AddMoveCommand( move.commands, Move.Use )

    else
        PerformMoveToUsePosition( marine, target, bot, brain, move )
    end

end

local function PerformWeld(marine, target, bot, brain, move)    --BOT-FIXME Needs to use same UsePosition when not welding player, otherwise, try to get behind them
    PROFILE("MarineBrain - PerformWeld")

    assert(target)
    
    local dist = GetDistanceToTouch(marine:GetEyePos(), target)
    local isPlayer = target:isa("Player")
    local hasClearShot = dist < 5 and bot:GetBotCanSeeTarget( target )
    local weldPercent = (target.GetWeldPercentage and target:GetWeldPercentage())
    local wasWelded = weldPercent ~= brain.lastWeldPercent or (not brain.lastWeldTime or brain.lastWeldTime < Shared.GetTime() - 2)

    if not hasClearShot then
    -- cannot see it yet - keep moving
        PerformMoveToUsePosition( marine, target, bot, brain, move )

    elseif dist < 2.4 and wasWelded then
    -- close enough to just PrimaryAttack

        bot:GetMotion():SetDesiredViewTarget( target:GetEngagementPoint() )
        bot:GetMotion():SetDesiredMoveTarget( nil )
        
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
        
        if (not bot.lastCoveringTime or bot.lastCoveringTime < Shared.GetTime() - 45) and isPlayer then
            CreateVoiceMessage( bot:GetPlayer(), kVoiceId.MarineCovering )
            bot.lastCoveringTime = Shared.GetTime()
        end
        
    else
        PerformMoveToUsePosition( marine, target, bot, brain, move )

        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
        
        if isPlayer and not target:GetIsVirtual() then
            bot:SendTeamMessage("Let me weld you, " .. target:GetName(), 70)
        end
    end
    
    if not brain.lastWeldTime or brain.lastWeldTime < Shared.GetTime() - 2 then
        brain.lastWeldPercent = weldPercent
        brain.lastWeldTime = Shared.GetTime()
    end
    
    -- no need not to sprint...  McG: NOT true...why sprint
    move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
    
end

local function GetIsUseOrder(order)
    return order:GetType() == kTechId.Construct 
            or order:GetType() == kTechId.AutoConstruct
            or order:GetType() == kTechId.Build
end

local function HasGoodWeapon(marine)
    local primaryWep = marine:GetWeaponInHUDSlot(1)
    if not primaryWep then return false end

    local goodWeps = {'Shotgun','HeavyMachineGun','Flamethrower','GrenadeLauncher','Cannon'}
    return table.icontains( goodWeps, primaryWep:GetClassName() )
    --[[
    return 
        marine:GetWeapon( Shotgun.kMapName ) or 
        marine:GetWeapon( HeavyMachineGun.kMapName ) or 
        marine:GetWeapon( Flamethrower.kMapName ) or
        marine:GetWeapon( GrenadeLauncher.kMapName )
    --]]
end

-- Return an estimate of how well this bot is able to respond to a target based on its distance
-- from the target. Linearly decreates from 1.0 at 30 distance to 0.0 at 150 distance
local function EstimateBotResponseUtility(marine, target)
    local mloc = marine:GetLocationName()
    local tloc = target:GetLocationName()

    if mloc == tloc then
        return 1.0
    end

    local dist = GetBotWalkDistance(marine, target)
    if dist <= 30.0 then
        return 1.0
    else
        return math.max(0.0, 1.0 - ( (dist - 30.0) / 120.0 ))
    end
end

local kMinePriority = {
    [kMinimapBlipType.Extractor] = 1,
    [kMinimapBlipType.Observatory] = 2,
    [kMinimapBlipType.PhaseGate] = 3,
    [kMinimapBlipType.InfantryPortal] = 4
}

---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
--  Objective Actions 

local kMarineBrainObjectiveActionTypesOrderScale = 100

--Note: all of these action can be overridden by kMarineBrainActionTypes, but when no kMarineBrainActionTypes is set
--then these take precendence. Thus, granting a "planning/decision" step, and then a "reaction" step for Marine bots.
local kMarineBrainObjectiveTypes = enum({
    "FollowOrders",
    "RespondToThreat",
    "TakeTerritory",
    "HealByNearestArmory",
    "Retreat",
    "DefendNearbyStructures",
    "RespondToLowThreat",
    "BuyWelder",
    "RepairPower",
    "BuildStructure",
    "PlaceMines",
    "GotoCommPing",
    "BuyExo",
    "BuyWeapons",
    "BuyJetpack",
    "BuyHandGrenades",
    "PressureEnemyNaturals",
    "BuyMines",
    "GuardNearestHuman",
    "GuardNearestExo",
    "AwaitEarlyResPlacement",
})

local MarineObjectiveWeights = MakeBotActionWeights(kMarineBrainObjectiveTypes, kMarineBrainObjectiveActionTypesOrderScale)

local function GetMarineObjectiveBaselineWeight( actionId )
    assert(kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes[actionId]], "Error: Invalid MarineBrain action-id passed")

    local totalActions = #kMarineBrainObjectiveTypes
    local actionOrderId = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes[actionId]] --numeric index, not string

    --invert numeric index value and scale, the results in lower value, the higher the index. Which means
    --the Enum of actions is shown and used in a natural order (i.e. order of enum value declaration IS the priority)
    local actionWeightOrder = totalActions - (actionOrderId - 1)
    
    --final action base-line weight value
    return actionWeightOrder * kMarineBrainObjectiveActionTypesOrderScale
end


-------------------------------------------------
-- Objective Validators

local kValidateRespondToThreats = function( bot, brain, marine, action )
    if not action.threat then
        return false
    end

    local sdb = brain:GetSenses()

    -- bail-out if we cannot possibly hope to engage and defeat the threat
    if sdb:Get("ammoFraction") < 0.15 or marine:GetHealthFraction() < 0.2 then
        return false
    end

    ---@type TeamBrain.Memory
    local memory = action.threat

    -- if the entity doesn't exist, the threat is dead
    local target = Shared.GetEntity(memory.entId)
    if not target then
        return false
    end

    -- if the threat doesn't have a memory in the team brain anymore, go check it out anyways if it was recent
    -- (if the threat finished biting a structure it won't be "known" after a short delay, but we should still secure the area)
    local hasMem = brain.teamBrain:GetMemoryOfEntity(memory.entId)
    if hasMem or memory.lastSeenTime + kMarineChaseLostMemoryTime > Shared.GetTime() then
        return true
    end

    return false
end

local kValidateTakeTerritory = function( bot, brain, marine, action )

    -- structure we're attempting to destroy to take territory is dead
    if not Shared.GetEntity(action.threat.entId) then
        return false
    end

    -- we've lost the memory of this structure, abort
    if not brain.teamBrain:GetMemoryOfEntity(action.threat.entId) then
        return false
    end

    local numAssigned = brain.teamBrain:GetNumOtherBotsWithGoalDetails(bot, action.name, "location", action.location)
    -- Too many bots assigned, bail out!
    if numAssigned >= 2 then
        return false
    end

    local sdb = brain:GetSenses()

    if sdb:Get("ammoFraction") < 0.15 then
        return false
    end

    if marine:GetHealthFraction() < 0.2 then
        return false
    end

    return true
end

local kValidateHealByNearestArmory = function( bot, brain, marine, action )
    if not IsValid(action.armory) then
        return false
    end

    local s = brain:GetSenses()
    local ammoFrac = s:Get("ammoFraction")

    -- use GetHealthFraction to ignore armor (which isn't restored by an armory)
    if ammoFrac >= 0.925 and marine:GetHealthFraction() >= 0.98 then
        return false
    end

    return true
end

local kValidateRetreat = function( bot, brain, marine, action )
    local sdb = brain:GetSenses()
    local ammoFrac = sdb:Get("ammoFraction")

    -- even if healed most of the way, need to ensure we're rearmed
    if not marine:GetIsUnderFire() and (marine:GetHealthFraction() <= 0.6 or ammoFrac < 0.4) then
        return true
    end

    if not IsValid(action.armory) then
        return false
    end

    return false
end

local kValidateDefendNearbyStructures = function( bot, brain, marine, action )
    if not IsValid(action.defendTarget) or not action.defendTarget:GetIsAlive() then
        return false
    end

    if marine:GetHealthFraction() < 0.2 then
        return false
    end

    return true
end

local kValidateBuildStructure = function( bot, brain, marine, action )
    -- cancel if the build target no longer exists or if others have snapped it up
    if not IsValid(action.target) or brain.teamBrain:GetNumOthersAssignedToEntity( marine, action.target:GetId() ) >= 2 then
        brain.teamBrain:UnassignPlayer(marine)
        return false
    end

    return true
end

local kValidatePlaceMines = function( bot, brain, marine, action )
    if not IsValid(action.structure) or not marine:GetWeaponInHUDSlot(4) then
        return false
    end

    return true
end

local kValidateGoToPing = function( bot, brain, marine, action )
    local sdb = brain:GetSenses()
    local ammoFrac = sdb:Get("ammoFraction")
    if marine:GetHealthScalar() > 0.2 and ammoFrac > 0.15 then
        return true
    end
    return false
end

local kValidateRepairPower = function( bot, brain, marine, action )
    if IsValid(action.powernode) and action.powernode:GetIsDisabled() then
        return true
    end
    return false
end

local kValidateBuyTechId = function( bot, brain, marine, action )
    if not IsValid(action.structure) then
        return false
    end

    if action.limit then
        return brain.teamBrain:GetNumOthersAssignedToEntity(marine, "tech-" .. action.buyId) < action.limit
    end

    return true
end

local kValidateBuyWeapons = function( bot, brain, marine, action )
--Clear out purchase goal if No applicable armory found. Because it was either recycled or destroyed. Thus our buy decision may no longer be valid
    if not IsValid(action.targetArmory) then
        brain.activeWeaponPurchaseTechId = nil
        return false
    end

    return brain.activeWeaponPurchaseTechId ~= nil
end

local kValidateGuardNearestHuman = function( bot, brain, marine, action )
    local target = action.target

    if not IsValid(target) then
        brain:ResetGuardState()
        return false
    end

    if target.GetIsAlive and not target:GetIsAlive() then
        brain:ResetGuardState()
        return false
    end

    if brain:GetSenses():Get("ammoFraction") <= 0.05 then
        return false
    end

    local dist = GetPhaseDistanceForMarine(marine, target, brain.lastGateId) --FIXME This is NOT checking dist, OR...not running often enough to do what's intended

    if dist > 30.0 then
        brain:ResetGuardState()
        return false -- cancel if the human is too far away
    end

    local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( marine, target:GetId() )
    if numOthers and numOthers >= 1 then
    --someone else if guarding now, fail out
        brain:ResetGuardState()
        return false
    end

    --TODO Ideally check to ensure bot is within X _height_ of target (e.g. target didn't fall into Crevice, or climbed some weird geo crap)
    ----Not doing above will effectively "stall out" Guard Bots
    local currentPos = marine:GetOrigin()
    local targPosY = target:GetOrigin().y
    local curPosY = currentPos.y
    
    if dist <= 4.75 then
        --check if target is _not_ on nav-mesh and crouching, that's enough to say "yeah, they're in a vent. stop guarding"
        local closestPoint = Pathing.GetClosestPoint(target:GetOrigin())
        
        local groundPoint = Pathing.GetClosestPoint(currentPos)
        local maxDistOffPath = 0.65 --pulled from BotMotion
        local targetCrouching = false
        local delta = groundPoint - bot:GetMotion().lastMovedPos
        local roughNextPoint = currentPos + bot:GetMotion().currMoveDir * delta:GetLength()    

        if target.GetCrouching then
            targetCrouching = target:GetCrouching()
        end

        if targetCrouching and (closestPoint - roughNextPoint):GetLengthXZ() > maxDistOffPath and (groundPoint - currentPos):GetLengthXZ() > 0.1 then
            --Log(" GuardedHuman - Target left nav-mesh ")
            return false
        end

    elseif math.abs(curPosY - targPosY) > 8.5 then
    --Player has gone and done player things, out of valid guard-range now
        return false

    end

    return true
end

local kValidateFollowOrders = function( bot, brain, marine, action )

    return IsValid(action.order)
end

local kValidateAwaitEarlyResDrop = function( bot, brain, marine, action )
    local roundMinutesPassed = GetGameMinutesPassed()
    if roundMinutesPassed > action.limit then
        return false
    end

    if action.resNode and action.resNode:GetAttached() then
        return false
    end

    return true
end

local kValidatePressureNaturals = function( bot, brain, marine, action )
    local sdb = brain:GetSenses()

    local ammoFraction = sdb:Get("ammoFraction")
    local healthFraction = marine:GetHealthFraction()

    -- Don't go pressuring naturals if we won't survive
    if ammoFraction < 0.2 or healthFraction < 0.4 then
        return false
    end

    return true
end

-------------------------------------------------
-- Objective Executors

local kExecFollowOrder = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecFollowOrder")

    local order = action.order

    brain.teamBrain:UnassignPlayer(marine)
    local target = Shared.GetEntity(order:GetParam())

    if target ~= nil then
    --Object contextual orders: Build Armory, Weld Node, Defend Marine, etc.

        if order:GetType() == kTechId.Attack then
            brain.teamBrain:AssignPlayerToEntity( marine, target:GetId() )
            PerformAttackEntity( marine:GetEyePos(), target, order:GetLocation(), bot, brain, move )

        --Build, AutoConstruct, Construct is a "Use" Order
        elseif GetIsUseOrder(order) then
            brain.teamBrain:AssignPlayerToEntity( marine, target:GetId() )
            if GetDistanceToTouch( marine:GetOrigin(), target ) > kDefaultUseRange then
                PerformMoveToUsePosition( marine, target, bot, brain, move )
            else
                PerformUse( marine, target, bot, brain , move )
            end
        elseif order:GetType() == kTechId.Weld or order:GetType() == kTechId.AutoWeld then
            SwitchToWelder(marine)

            brain.teamBrain:AssignPlayerToEntity( marine, target:GetId() )
            PerformUse( marine, target, bot, brain , move )

            local weapon = marine:GetActiveWeapon()

            if weapon and weapon:GetMapName() == Welder.kMapName then
                move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)
            end

        --TODO Add more specific types (e.g. Defend)
        else
            PerformMove( marine:GetOrigin(), order:GetLocation(), bot, brain, move )

        end

    else
    --MoveTo, Defend world-point, etc.

        if order:GetType() == kTechId.Move then
            PerformMove( marine:GetOrigin(), order:GetLocation(), bot, brain, move )

        --TODO Add more specific Types (e.g. Attack, Defend, Etc.)

        else
        --Effectively an "Unknown Order" type
            --TODO Add debug-logging of unknown
            PerformMove( marine:GetOrigin(), order:GetLocation(), bot, brain, move )
        end

    end

    if marine:GetCurrentOrder() ~= order then
        -- Log("%s completed order %s", marine, order)
        return kPlayerObjectiveComplete
    end

end

local kExecRespondToThreats = function(move, bot, brain, marine, action)
    local memory = action.threat

    brain.teamBrain:UnassignPlayer(marine)
    brain.teamBrain:AssignPlayerToEntity(marine, action.key)

    PerformMove( marine:GetOrigin(), memory.lastSeenPos, bot, brain, move )

    --sprint to get there in time!
    move.commands = AddMoveCommand(move.commands, Move.MovementModifier)

    if marine:GetOrigin():GetDistance(memory.lastSeenPos) < 5 then
        return kPlayerObjectiveComplete
    end
end

local kExecTakeTerritory = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecTakeTerritory")

    brain.teamBrain:UnassignPlayer(marine)
    brain.teamBrain:AssignPlayerToEntity(marine, "assault-" .. action.threat.entId)

    PerformMove(marine:GetOrigin(), action.threatPos, bot, brain, move)

    if marine:GetOrigin():GetDistance(action.threatPos) < 6 then
        return kPlayerObjectiveComplete
    end

end

local kExecHealByNearestArmory = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecHealByNearestArmory")

    local armory = action.armory

    local touchDist = GetDistanceToTouch( marine:GetEyePos(), armory )
    if touchDist < 1.55 then
        bot:GetMotion():SetDesiredViewTarget( armory:GetEngagementPoint() )
        bot:GetMotion():SetDesiredMoveTarget( nil )
    else
        --TODO Ideally, read orientation of armory, and find "empty NSEW slot", this would need to be done as we approach an armory, not after we're in Use range.
        PerformMove( marine:GetOrigin(), armory:GetEngagementPoint(), bot, brain, move )
    end

end

local kExecRetreat = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecRetreat")

    local armory = action.armory

    -- we are retreating, unassign ourselves from anything else, e.g. attack targets

    brain.teamBrain:UnassignPlayer(marine)

    local touchDist = GetDistanceToTouch( marine:GetEyePos(), armory )
    if touchDist > 1.35 then                            
        PerformMoveToUsePosition( marine, armory, bot, brain, move )
    else
        return kPlayerObjectiveComplete
    end

end

local kExecRepairPower = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecRepairPower")

    local powernode = action.powernode

    brain.teamBrain:UnassignPlayer(marine)
    brain.teamBrain:AssignPlayerToEntity( marine, powernode:GetId() )

    PerformUse(marine, powernode, bot, brain, move)

    if not action.powernode:GetIsDisabled() then
        return kPlayerObjectiveComplete
    end
end

local kExecPlaceMines = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecPlaceMines")

    brain.teamBrain:UnassignPlayer(marine)
    brain.teamBrain:AssignPlayerToEntity( marine, action.key )

    SwitchToMine(marine)

    if marine:GetOrigin():GetDistance( action.pos ) > kDefaultUseRange then
        PerformMove( marine:GetOrigin(), action.pos, bot, brain, move )

    else
        -- jitter position in case we can't drop a mine directly on the point anyways
        -- local pos = action.pos + Vector(math.random() - 0.5, 0, math.random() - 0.5)
        -- pos = Pathing.GetClosestPoint(pos)

        bot:GetMotion():SetDesiredMoveTarget( nil )
        bot:GetMotion():SetDesiredViewTarget( action.pos )

        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )

        local mines = marine:GetWeaponInHUDSlot(4)

        -- if we can't place, ignore
        if not mines or not select(3, mines:GetPositionForStructure(marine)) then
            return kPlayerObjectiveComplete
        end
    end

end

local kExecBuyWeapons = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecBuyWeapons")

    local targetArmory = action.targetArmory

    -- Since player "use" process does a trace, using a "eyepos" to "touch" direct calculation
    -- will be slightly larger, which can get bots stuck.
    -- Instead we use origin to avoid bloating the distance returned.
    local touchDist = GetDistanceToTouch( marine, targetArmory )
    if touchDist >= targetArmory:GetUseMaxRange() then

        if brain.debug then 
            DebugPrint("going towards armory at %s", ToString(targetArmory:GetEngagementPoint())) 
        end

        PerformMoveToUsePosition( marine, targetArmory, bot, brain, move )

    else

        bot:GetMotion():SetDesiredViewTarget( targetArmory:GetEngagementPoint() )
        bot:GetMotion():SetDesiredMoveTarget( nil )
        if brain.activeWeaponPurchaseTechId ~= nil then
            -- Log("Marine-%s Attempting to Buy [%s]", marine:GetId(), kTechId[brain.activeWeaponPurchaseTechId])  --string version
        end
        marine:ProcessBuyAction({ brain.activeWeaponPurchaseTechId })
        brain.activeWeaponPurchaseTechId = nil

    end

end

--WARNING: Tuned values! Changing below will very likely yield undesired "wiggle/jitter" behavior from Guarding bot
local kGuardDesiredDistanceMin = 3.85
local kGuardDesiredDistanceMax = 5
local kGuardCrouchApproachTime = 3
local gs_B = 0.02  --dampening coefficient. Larger value increase dampening (thus come to rest faster)
local gs_K = 2   --spring tightness, higher means tension increases at greater rate (i.e. Guard moves more often)
local gs_D = kGuardDesiredDistanceMax
local gs_MoveThreshold = 15

local kExecGuardNearestHuman = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecGuardNearestHuman")

    local target = action.target                    
    local time = Shared.GetTime()
    local targetId = target:GetId()
    local diffTargetThanLast = false

    if brain.lastGuardEntId == Entity.invalidId or brain.lastGuardEntId ~= targetId then
    --reset guard internals
        brain:ResetGuardState()
        brain.lastGuardEntId = targetId
        diffTargetThanLast = true
    end

    SwitchToPrimary(marine)

    if not brain.teamBrain:GetIsAssignedToEntity( marine, targetId ) then
        brain.teamBrain:UnassignPlayer(marine)
        brain.teamBrain:AssignPlayerToEntity( marine, targetId )
    end

    local isCrouching = false
    local isJumping = false

    --Note: "press" and "release" of these keys are handled in MarineBrain:Update()
    if target.GetCrouching and target:GetCrouching() then 
    --McG: note, we intentionally do not check touchDist here, because not making sound takes precedence
        isCrouching = true

        brain.lastGuardStateMimicTime = time
        brain.lastGuardStateMimicKey = Move.Crouch

        if brain.timeTargetCrouchStart == 0 then
            brain.timeTargetCrouchStart = time
        end

    elseif target.GetIsSprinting and target:GetIsSprinting() then 
        brain.lastGuardStateMimicTime = time
        brain.lastGuardStateMimicKey = Move.MovementModifier

    elseif target.GetIsJumping and target:GetIsJumping() then
        isJumping = true

    end

    if not isCrouching then
        brain.timeTargetCrouchStart = 0
    end

    --Note: we have to use walk-dist, so it'll utilize PGs
    local marineOrg = marine:GetOrigin()
    local targDist = GetBotWalkDistance( marineOrg, target )
    local targetVel = target:GetVelocity():GetLengthXZ()

    --shape desired distance based on Sneak active
    local desiredDist = 
        brain.lastGuardStateMimicKey == Move.Crouch and
        math.floor(gs_D * 0.5) or
        gs_D

    local crouchApproach = false
    if targetVel == 0 and isCrouching and brain.timeTargetCrouchStart + kGuardCrouchApproachTime < time and targDist > desiredDist then
    --Note: below distance is a bit misleading, because it's going to be filtered/constrained by the Nav-Mesh verts. The bot is going to move to
    -- the closets nav-mesh vert within said distance. Therefore, this distance WILL be variable per map, and location in maps. Impossible to fix.
        desiredDist = 2.075  --get in range for boost
        crouchApproach = true
    end

    --TODO Add Flashlight mimic (e.g. if the player turns theirs off, we should turn the Bot's off, when in Guard-state)

    local desiredDistMin = isCrouching and targetVel == 0 and kGuardDesiredDistanceMin * 0.75 or kGuardDesiredDistanceMin
    local inDesiredGuardDist = targDist < desiredDist and targDist > desiredDistMin

    --simple virtual "spring" binding Target with Guard
    local gs_relV = marine:GetVelocity():GetLength() - target:GetVelocity():GetLength()
    local gs_T = Vector()
    VectorCopy(marineOrg, gs_T)
    VectorSetLength( gs_T, desiredDist ) --displacement

    -- Ultra simple spring model with dampening: F = -k( (|x| - d) * ( x / |x| ) ) - bv
    local gs_Fn = -gs_K * ( ( targDist - desiredDist ) * ( gs_T / targDist ) ) - (gs_B * gs_relV)
    local gs_F = gs_Fn:GetLengthSquared()
    
    local withinMaxDr = desiredDist * 0.75
    local insideRange = withinMaxDr > desiredDistMin + 0.125 and withinMaxDr or desiredDist
    local closeRangeSpringThresh = 500

    if targDist > insideRange or crouchApproach then
    --only move when our "spring" is in 'tension', but only do so when withing a "move" value

        local moveThresh = isCrouching and gs_MoveThreshold * 0.5 or gs_MoveThreshold
        local guardMinRange = desiredDistMin - 0.15

        if gs_F > moveThresh and targetVel > 0 and targDist > guardMinRange and gs_F < closeRangeSpringThresh then
            PerformMove( marineOrg, target:GetEngagementPoint(), bot, brain, move, false, brain.lastGuardStateMimicKey == Move.MovementModifier )
            
        elseif (targetVel == 0 and gs_F > moveThresh and targDist > guardMinRange and gs_F < closeRangeSpringThresh) or (crouchApproach and targDist > desiredDist) then
        --yes, this is dumb, but we need both _explicit_ conditions for Bot to break-out of "wobble" scenarios
            PerformMove( marineOrg, target:GetEngagementPoint(), bot, brain, move, false, brain.lastGuardStateMimicKey == Move.MovementModifier )

        elseif gs_F < 1.1 or targetVel < 1 then
            bot:GetMotion():SetDesiredMoveTarget( nil )

        end

    elseif targDist < 1.55 and not isCrouching and targDist > 1.105 and not isJumping then 
    --Marine bots are true bros...they help boost into vents. Thanks bot BRAH!
        local avoidGoal = nil
        local targViewAngCoords = target:GetViewAngles():GetCoords()
        local marineViewAngCoords = marine:GetViewAngles():GetCoords()
        local forTarget_MarineInView = IsPointInCone( marineOrg, target:GetEyePos(), targViewAngCoords.zAxis, math.rad(42) )
        local forMarine_TargetInView = IsPointInCone( target:GetOrigin(), marine:GetEyePos(), marineViewAngCoords.zAxis, math.rad(75) )

        local targetWep = target:GetActiveWeapon()
        local marineArmor = marine:GetArmorScalar()
        local forTarget_WelderActive = targetWep and targetWep:GetMapName() == Welder.kMapName and targetWep.welding ~= nil and targetWep.welding == true

        if forTarget_MarineInView and forMarine_TargetInView then
        --Target is looking at us, and we're also facing target
            avoidGoal = marineOrg + marineViewAngCoords.zAxis * -28
            --avoidGoal = avoidGoal + marineViewAngCoords.xAxis * ( 28 * (math.random(0,1) < 0.5 and -1 or 1) )

        elseif not forMarine_TargetInView and forTarget_MarineInView then
        --Target is looking at us and we're not facing target, move forward
            avoidGoal = marineOrg + targViewAngCoords.zAxis * 12

        else
        --Note: Try move behind to target, but this will sometimes Bot will cross over player's view
            avoidGoal = target:GetOrigin() + targViewAngCoords.zAxis * -18
            
        end
        
        if forTarget_WelderActive and marineArmor < 1 then
            avoidGoal = nil
        end

        --constrain to nav-mesh...don't want people pushing a FRIENDLY bot off a ledge...
        --they do that well enough on their own, thank you.
        if avoidGoal ~= nil then
            avoidGoal = Pathing.GetClosestPoint( avoidGoal )
        end
        
        bot:GetMotion():SetDesiredMoveTarget( avoidGoal )
        
    else

        --TODO Read Location gateways, and look at them, most of the time...
        
        if targDist > desiredDistMin - 0.25 then
        --Only randomly look around when player away from us, otherwise we may suddenly
        --change our look at, thus the close-avoid behavior

            bot:GetMotion():SetDesiredMoveTarget( nil )

            if brain.lastGuardLookAroundTime + math.random(3, 6.5) < time then
                brain.lastGuardLookAroundTime = time

                local viewTarget = GetRandomDirXZ()
                viewTarget.y = 0 --math.random(-0.03, 0.035)
                viewTarget:Normalize()

                brain.lastGuardRandLookTarget = marine:GetEyePos() + viewTarget * 30
            end

            if brain.lastGuardRandLookTarget then
                bot:GetMotion():SetDesiredViewTarget(brain.lastGuardRandLookTarget)

            end

        end

        --Only play so often, but never play more than once for the same player, nor when that player is trying to be sneaky
        if brain.lastGuardStateMimicKey ~= Move.Crouch and diffTargetThanLast and brain.lastCoveringAlertTime == 0 then
        --Notify the player we're guarding them. Also, don't do so if the player is crouching (sneaking)
            CreateVoiceMessage( marine, kVoiceId.MarineCovering )            
            brain.lastCoveringAlertTime = time
        end

    end

end

local kExecGotoCommPing = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecGotoCommPing")

    local pingPos = action.pingPos
    PerformMove( marine:GetOrigin(), pingPos, bot, brain, move )

    if (marine:GetOrigin() - pingPos):GetLengthXZ() < 5 then
        brain.lastReachedPingPos = pingPos
        return kPlayerObjectiveComplete
    end
end

local kExecDefendNearbyStructures = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecDefendNearbyStructures")

    local defendTarget = action.defendTarget

    local kCloseEnoughRange = kInfestationRadius -- This should also be close enough to "check" the structure for lifeforms
    local walkDistance = GetBotWalkDistance(defendTarget, marine)
    local now = Shared.GetTime()

    if walkDistance < kCloseEnoughRange then
        brain.defendStructureCorrodedIds[defendTarget:GetId()] = now
        return kPlayerObjectiveComplete
    end

    -- Someone else has completed this action
    if (brain.defendStructureCorrodedIds[defendTarget:GetId()] or 0) + 5 > now then
        return kPlayerObjectiveComplete
    end

    PerformMove(marine:GetOrigin(), defendTarget:GetOrigin(), bot, brain, move)

end

local kExecBuildStructure = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecBuildStructure")

    brain.teamBrain:UnassignPlayer(marine)

    local target = action.target
    if target:GetIsBuilt() then
        return kPlayerObjectiveComplete
    end

    brain.teamBrain:AssignPlayerToEntity( marine, action.key )

    PerformMove( marine:GetOrigin(), target:GetOrigin(), bot, brain, move )

    --BOT-TODO Improve, this is too generic/dry (no, not "Beige-Flavor text", but something better that this)
    --BOT-FIXME Need to properly format the names ...some MapName value has _ instead if spaces, and all are lowercased
    local chatMsg = ( "I'll build the " .. target:GetMapName() .. " in " .. target:GetLocationName() )

    bot:SendTeamMessage(chatMsg, 120)

    if marine:GetOrigin():GetDistance(target:GetOrigin()) < 5 then
        return kPlayerObjectiveComplete
    end

end

local kExecBuyTechId = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecBuyTechId")

    local structure = action.structure

    brain.teamBrain:AssignPlayerToEntity(marine, "tech-" .. action.buyId)

    -- Since player "use" process does a trace, using a "eyepos" to "touch" direct calculation
    -- will be slightly larger, which can get bots stuck.
    -- Instead we use origin to avoid bloating the distance returned.
    local touchDist = GetDistanceToTouch( marine, structure )
    if touchDist > structure:GetUseMaxRange() then
        PerformMoveToUsePosition( marine, structure, bot, brain, move )
    else

        local buyId = action.buyId

        brain.buyTargetId = nil
        bot:GetMotion():SetDesiredViewTarget( structure:GetEngagementPoint() )
        bot:GetMotion():SetDesiredMoveTarget( nil )
        
        -- Log("[%s] Attempting to Buy [%s]", marine, kTechId[buyId])  --string version
        marine:ProcessBuyAction({ buyId })
        SwitchToPrimary(marine)

        -- this is a hack because you can't buy an exo if there's a jetpack at your feet
        -- bot:GetMotion():SetDesiredMoveTarget( structure:GetEngagementPoint() )

        -- Allow rate-limiting mine purchases
        if action.updateKey then
            brain[action.updateKey] = Shared.GetTime()
        end

        return kPlayerObjectiveComplete

    end

end

local kExecAwaitEarlyResPlacement = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecAwaitEarlyResPlacement")

    local awaitableResNode = action.resNode

    brain.teamBrain:AssignPlayerToEntity( marine, awaitableResNode:GetId() )

    if GetBotWalkDistance(marine, awaitableResNode) < 6 then

        bot:GetMotion():SetDesiredMoveTarget( nil )

        local time = Shared.GetTime()

        if brain.lastCommanderRequestTime + brain.kCommanderRequestRateTime < time then
            if math.random(0,1) < 0.5 then
                CreateVoiceMessage( marine, kVoiceId.MarineRequestStructure )
                brain.lastCommanderRequestTime = time + math.random(0.25, 1.5) --cheese, but adds variance
            end
        end

        if action.threatGatewayPos then
            -- Look at where we most expect hostiles to enter from
            LookAroundAtTarget( bot, marine, action.threatGatewayPos )
        else -- fallback, should never be taken
            LookAroundRandomly( bot, marine )
        end

    else
        PerformMove( marine:GetOrigin() , awaitableResNode:GetOrigin(), bot, brain, move)
    end

end

local kExecPressureNaturals = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecPressureNaturals")

    local threatPos = action.threatGatewayPos
    local position = action.position

    brain.teamBrain:AssignPlayerToEntity(marine, "assault-" .. action.location)

    if marine:GetLocationName() == action.location and marine:GetOrigin():GetDistance(threatPos) < 18.0 then

        bot:GetMotion():SetDesiredMoveTarget( nil )

        LookAroundAtTarget( bot, marine, threatPos )

        local now = Shared.GetTime()

    --TODO Try selecting random point around RT (on mesh ofc), and reselect it every X time...this should not impact idle timer
    --e.g. Like "patroling" area
        if not action.idleStart then

            action.idleStart = now

        elseif action.idleStart + 30 < now then --orginal + 15
        --wait a short duration for any hostiles to come through or for any structures to be dropped, etc.

            CreateVoiceMessage( marine, kVoiceId.MarineTaunt ) -- for fun
            return kPlayerObjectiveComplete

        end

    elseif marine:GetLocationName() == action.location then
    -- move closer to the gateway we think hostiles will be coming through

        PerformMove( marine:GetOrigin(), threatPos, bot, brain, move )

    else

        PerformMove( marine:GetOrigin(), position, bot, brain, move )

    end

end


kMarineBrainObjectiveActions =
{
    
    function(bot, brain, marine)    --BOT-TODO Add FULL support for All possible Commander Issue-able orders!
    --McG: This action needs to have a LOT of thought put into it...we run the Risk of making Marine bots a BITCH to command effeciently if not done properly!
        PROFILE("MarineBrain - FollowOrder") 

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.FollowOrders]
        local order = bot:GetPlayerOrder()
        local teamBrain = bot.brain.teamBrain
        local weight = 0

        if order ~= nil then

            local targetId = order:GetParam()
            local target = Shared.GetEntity(targetId)

            weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.FollowOrders )

            if target ~= nil and GetIsUseOrder(order) then

                -- Because construct orders are often given by the auto-system, do not necessarily obey them -- Load-balance them
                local numOthers = teamBrain:GetNumOthersAssignedToEntity( marine, targetId )

                if (numOthers ~= nil and numOthers > 1) or order:GetType() == kTechId.AutoConstruct then
                -- There is already a construct action, this could override intended behavior
                    weight = 0
                end

            end

        end
        
        return
        {
            name = name,
            weight = weight,
            fastUpdate = true,  --TODO Review if this is needed, filter by Order-Attack, or similar
            order = order,
            validate = kValidateFollowOrders,
            perform = kExecFollowOrder
        }
    end, -- FOLLOW ORDERS (Attack/Build/Move)

    function(bot, brain, marine)
        PROFILE("MarineBrain - RespondToThreats")

        local name = "RespondToThreats"
        local weight = 0.0

        local highestThreat = brain:GetSenses():Get("highestThreat")
        local memory = highestThreat.memory
        local threat = highestThreat.threat
        local key = nil

        if memory then
            -- assume if we have a high threat value it's something very important (e.g. upgrade chamber)
            -- and we should respond to it *immediately*
            if threat > kMarineImmediateThreatThreshold then
                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.RespondToThreat )
            elseif threat > 0.0 then
                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.RespondToLowThreat )
            end

            key = "respond-" .. memory.entId
        end

        return
        {
            name = name,
            weight = weight,
            threat = memory,
            key = key,
            validate = kValidateRespondToThreats,
            perform = kExecRespondToThreats
        }

    end, -- RESPOND TO STRATEGIC THREATS

    function(bot, brain, marine) 
        PROFILE("MarineBrain - TakeTerritory")
        -- Log("MarineBrain - TakeTerritory")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.TakeTerritory]
        local teamBrain = GetTeamBrain(marine:GetTeamNumber())
        local sdb = brain:GetSenses()
        local structureThreat = nil
        local threat = nil
        local threatPos = nil
        local threatLoc = nil

        local weight = 0
        local mainAmmoFrac = sdb:Get("ammoFraction")

        --We need to check and filter some weapons, as they're drastically less effective against structures
        --HMGs are crap at structure damage, so don't waste ammo
        local primaryWep = marine:GetWeaponInHUDSlot(1)
        --local handGrenade = marine:GetWeaponInHUDSlot(5)

        local validStructureAttack = primaryWep and primaryWep:GetMapName() ~= HeavyMachineGun.kMapName
        --local validStructureAttack = handGrenade and handGrenade:GetMapName() ~= PulseGrenadeThrower.kMapName

        if mainAmmoFrac > 0.2 and marine:GetHealthFraction() > 0.2 and validStructureAttack then
            structureThreat = sdb:Get("biggestStructureThreat")
        end

        if structureThreat then

            threat = structureThreat.memory
            threatPos = structureThreat.memory.lastSeenPos
            threatLoc = structureThreat.memory.lastSeenLoc

            local numOthers = teamBrain:GetNumOthersAssignedToEntity(marine, threat.entId)
            local numAssigned = teamBrain:GetNumOtherBotsWithGoalDetails(bot, name, "location", threatLoc)

            -- include bots assigned to PressureEnemyNaturals as well
            numAssigned = numAssigned + teamBrain:GetNumOthersAssignedToEntity(marine, "assault-" .. threatLoc)

            -- Prioritize buddying-up with another bot attacking this structure, even if we have to travel a ways
            local dist = structureThreat.distance * (numAssigned == 1 and 0.8 or 1.0)

            if (numOthers <= 1 or numAssigned <= 2) and dist <= kMarineTakeTerritoryRange then

                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.TakeTerritory )

            end

        end

        return 
        {
            name = name,
            weight = weight,
            threat = threat,
            threatPos = threatPos,
            location = threatLoc,
            validate = kValidateTakeTerritory,
            perform = kExecTakeTerritory
        }
    end, -- MOVE TOWARDS BIGGEST STRUCTURE THREAT

    function(bot, brain, marine)
        PROFILE("MarineBrain - HealByNearestArmory")
        -- Log("MarineBrain - HealByNearestArmory")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.HealByNearestArmory]
        local sdb = brain:GetSenses()
        local hpFrac = marine:GetHealthFraction()
        local weight = 0

        local armoryData = sdb:Get("nearestArmory")

        local armory = armoryData and armoryData.armory or nil
        local armoryDist = armoryData and armoryData.distance or -1


        if hpFrac < 1 then

            --Don't do this if we're really far away from an armory
            if armory and armoryDist < 30 then
                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.HealByNearestArmory )
                weight = weight + (1 - hpFrac)  --more urgent lower HP
            else
                weight = 0
            end

        --Bingo ammo, RTB
        elseif sdb:Get("ammoFraction") == 0 and armory then --don't check distance
            weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.HealByNearestArmory )
            --Need to significantly boot priority in this context, otherwise we'll never go fetch ammo
            weight = weight * kMarineBrainObjectiveActionTypesOrderScale

        end

        return
        {
            name = name,
            weight = weight,
            armory = armory,
            validate = kValidateHealByNearestArmory,
            perform = kExecHealByNearestArmory
        }
    end, -- HEAL AT NEARBY ARMORY

    function(bot, brain, marine)
        PROFILE("MarineBrain - Retreat")
        -- Log("MarineBrain - Retreat")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.Retreat]
        local sdb = brain:GetSenses()
        local weight = 0
        local armoryGoal = sdb:Get("nearestArmory")
        local armory
        local armoryDist
        local ammoFrac = sdb:Get("ammoFraction")
        
        if armoryGoal.armory ~= nil then

            local minFraction = math.min( marine:GetHealthFraction(), ammoFrac )
            armory = armoryGoal.armory
            armoryDist = armoryGoal.distance

            if armoryDist < 2.0 and minFraction < 0.8 then
            -- If we are pretty close to the armory, stay with it a bit longer to encourage full-healing, etc.
            -- so pretend our situation is more dire than it is
                minFraction = minFraction / 3.0
            end

            if not marine:GetIsUnderFire() and minFraction <= 0.2 then
                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.Retreat )

            elseif ammoFrac == 0 then
            --we're bingo ammo, always retreat
                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.Retreat )

            end

        end

        return 
        { 
            name = name, 
            weight = weight,
            armory = armory,
            validate = kValidateRetreat,
            perform = kExecRetreat
        }
    end, -- RETREAT

    function( bot, brain, marine )
        PROFILE("MarineBrain - GotoCommPing")
        -- Log("MarineBrain - GotoCommPing")

        local name, weight = MarineObjectiveWeights:Get(kMarineBrainObjectiveTypes.GotoCommPing)
        local db = brain:GetSenses()

        local kPingLifeTime = 30.0
        local pingTime = db:Get("comPingElapsed")
        local pingPos

        -- Don't go for a ping if we're at low health or ammo
        local ammoFrac = db:Get("ammoFraction")
        if marine:GetHealthScalar() <= 0.2 or ammoFrac <= 0.15 then
            return kNilAction
        end

        if pingTime ~= nil and pingTime < kPingLifeTime then

            pingPos = db:Get("comPingPosition")

            if not pingPos then
            -- ping is invalid
                return kNilAction

            elseif brain.lastReachedPingPos ~= nil and pingPos:GetDistance(brain.lastReachedPingPos) < 1e-2 then
            -- we already reached this ping - ignore it
                return kNilAction

            end

        else
            return kNilAction
        end

        return 
        { 
            name = name, 
            weight = weight,
            pingPos = pingPos,
            validate = kValidateGoToPing,
            perform = kExecGotoCommPing
        }
    end, -- GOTO COMM PING

    function(bot, brain, marine)
        PROFILE("MarineBrain - DefendNearbyStructures")
        -- Log("MarineBrain - DefendNearbyStructures")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.DefendNearbyStructures]
        local weight = 0
        local defendTarget
        local marinePos = marine:GetOrigin()
        local kTimeCorrodedCheck = 10 -- Time to ignore alert after getting close enough to detect any possible lifeforms

        if not GetWarmupActive() then
            local nearStructuresDamaged = marine:GetTeam().brain:GetFilteredAlertsWithinRange( 
                marinePos, 
                40, 
                function(alert) 
                    return alert.techId == kTechId.MarineAlertStructureUnderAttack
                end
            )

            local clearLastDefendTarget = false

            if #nearStructuresDamaged > 0 then

                --sort by distance to self
                table.sort( nearStructuresDamaged, 
                    function(a, b) 
                        return
                            GetBotWalkDistance(marine,Shared.GetEntity(a.entId) or a.pos)
                            <
                            GetBotWalkDistance(marine,Shared.GetEntity(b.entId) or b.pos)
                    end
                )

                local defendTargetEntId = nearStructuresDamaged[1].entId
                defendTarget = Shared.GetEntity(defendTargetEntId)

                if defendTarget and defendTarget.GetHealthScalar then

                    local tNow = Shared.GetTime()
                    local applyWeight = false

                    local timeLastDiscoveredCorroded = brain.defendStructureCorrodedIds[defendTargetEntId]
                    local recentlyCheckedCorroded =
                            timeLastDiscoveredCorroded and
                            defendTarget.isCorroded and
                            (tNow - timeLastDiscoveredCorroded) <= kTimeCorrodedCheck

                    if not recentlyCheckedCorroded then
                        weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.DefendNearbyStructures )
                        weight = weight + (1 - defendTarget:GetHealthScalar())
                    end

                end
            end

        end

        --BOT-TODO This should issue a Defend order to self for Target! ...maybe not, as we'd need to expire the defend order
        --BOT-FIXME Need this action to "stick" until self is very close to target...otherwise, jitter

        return
        {
            name = name,
            weight = weight,
            -- fastUpdate = true,
            defendTarget = defendTarget,
            validate = kValidateDefendNearbyStructures,
            perform = kExecDefendNearbyStructures
        }

    end, --DEFEND NEARBY STRUCTURES

    function(bot, brain, marine)
        PROFILE("MarineBrain - BuildStructure")
        -- Log("MarineBrain - BuildStructure")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.BuildStructure]
        local sdb = brain:GetSenses()
        local weight = 0
        local key = nil

        local targetData = sdb:Get("nearestBuildable")
        local target = targetData and targetData.target or nil
        local dist = targetData and targetData.distance or 25000

        --distance limiter in order to prevent running clear across the goddamned map to build something
        --BOT-TODO: bots should calculate "most important" weight based on room-distance to individual buildable
        if target and dist < 150 then

            local targetId = target:GetId()
            local targetLoc = target:GetLocationName()

            key = "reserve-" .. targetId

            weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.BuildStructure )

            local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( marine, targetId )
            local numGoing = brain.teamBrain:GetNumOthersAssignedToEntity( marine, key )

            -- Log("[%s] build structure %s (%s), %d already assigned", marine, target, targetLoc, numOthers)

            --TODO Need to look at build % of targets (pre-sort step), and order based on closest to built, thus, more things finish faster

            --Don't return for structures in our main base, the next spawners will (hopefully) get it while they're there
            local isMainBase = ( not targetLoc or targetLoc == "" or targetLoc == brain.teamBrain.initialTechPointLoc )

            -- Don't go build if there are already people there building or multiple going
            if numOthers >= 1 or numGoing >= 2 or isMainBase then
                weight = 0
                target = nil
            end
        end

        return
        {
            name = name,
            weight = weight,
            target = target,
            key = key,
            validate = kValidateBuildStructure,
            perform = kExecBuildStructure
        }
    end, -- MOVE TO NEAREST BUILDABLE

    function(bot, brain, marine)
        PROFILE("MarineBrain - PlaceMines")
        -- Log("MarineBrain - PlaceMines")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.PlaceMines]
        local teamBrain = GetTeamBrain( marine:GetTeamNumber() )
        local weight = 0
        local key = nil

        local nearbyMemories = teamBrain:GetMemoriesAtLocation(marine:GetLocationName(), marine:GetTeamNumber())
        local numMines = 0
        local wantedMines = 0
        local bestWeight = 0
        local bestStructure = nil
        local bestPos = nil

        local hasMine = marine:GetWeaponInHUDSlot(4) ~= nil

        if not hasMine then
            return kNilAction
        end

        for _, mem in ipairs(nearbyMemories) do

            local t = mem.btype

            if t == kMinimapBlipType.Extractor or t == kMinimapBlipType.InfantryPortal or t == kMinimapBlipType.PhaseGate or t == kMinimapBlipType.Observatory then
                -- one mine for each structure and two for the gate (may not be placed on those structures specifically)
                wantedMines = wantedMines + (t == kMinimapBlipType.PhaseGate and 2 or 1)

                local numAssigned = teamBrain:GetNumAssignedToEntity("mine-" .. mem.entId)
                local sweight = kMinePriority[t]

                if sweight > bestWeight and numAssigned < 1 then
                    bestWeight = sweight
                    bestStructure = Shared.GetEntity(mem.entId)
                end
            end

            -- assume it's a mine
            if t == kMinimapBlipType.SensorBlip then
                numMines = numMines + 1
            end

        end

        -- hard cap how many mines we want in main base
        if marine:GetLocationName() == teamBrain.initialTechPointLoc then
            wantedMines = 4
        end

        if bestStructure and numMines < wantedMines then

            local ang = math.random() * math.pi * 2
            local kPlaceDist = bestStructure:GetExtents():GetLengthXZ() + 1.25

            local point = Vector(math.sin(ang) * kPlaceDist, 0, math.cos(ang) * kPlaceDist) + bestStructure:GetOrigin()
            bestPos = Pathing.GetClosestPoint(point)

            weight = GetMarineObjectiveBaselineWeight(kMarineBrainObjectiveTypes.PlaceMines)
            key = "mine-" .. bestStructure:GetId()
        else
            return kNilAction
        end

        return 
        {
            name = name, 
            weight = weight, 
            fastUpdate = true,
            structure = bestStructure,
            pos = bestPos,
            key = key,
            validate = kValidatePlaceMines,
            perform = kExecPlaceMines
        }

    end, -- PLACE MINES

    function(bot, brain, marine)
        PROFILE("MarineBrain - BuyWelder")
        -- Log("MarineBrain - BuyWelder")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.BuyWelder]
        local sdb = brain:GetSenses()
        local weight = 0
        local armoryData = sdb:Get("nearestArmory")
        local armory = armoryData.armory
        local armoryDist = armoryData.distance
        local resources = marine:GetResources()
        
        if not sdb:Get("welder") and (armory and armory:GetIsBuilt()) then
            if armoryDist < 50 and resources >= LookupTechData(kTechId.Welder, kTechDataCostKey) then
                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.BuyWelder )
            end
        end
        
        return 
        { 
            name = name, 
            weight = weight,
            structure = armory,
            buyId = kTechId.Welder,
            validate = kValidateBuyTechId,
            perform = kExecBuyTechId
        }

    end, -- PURCHASE WELDER

    function(bot, brain, marine)
        PROFILE("MarineBrain - BuyExo")
        -- Log("MarineBrain - BuyExo")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.BuyExo]
        local sdb = brain:GetSenses()

        local techTree = GetTechTree(marine:GetTeamNumber())

        if not techTree:GetIsTechAvailable(kTechId.DualMinigunExosuit) then
            return kNilAction
        end

        local weight = 0.0
        local resources = marine:GetResources()

        local globalBuyCapRatio = 1/3 -- How many exos are allowed (minigun or railgun) on the team at a time.
        local exoRailgunRatio = 1/3 -- How many railguns are allowed of the global cap
        local exoCounts = sdb:Get("exoCounts")

        local totalPlayers = GetGamerules():GetTeam(marine:GetTeamNumber()):GetNumPlayers()
        local totalExosAllowed = math.floor(totalPlayers * globalBuyCapRatio)
        local totalRailgunsAllowed = math.floor(totalExosAllowed * exoRailgunRatio)

        if not MarineBrain.kRailgunExoEnabled then
            totalRailgunsAllowed = 0
        end

        local shouldBuyExo = totalExosAllowed > 0 and
            totalExosAllowed > 0 and
            not marine:isa("JetpackMarine") and
            not HasGoodWeapon(marine) and
            resources >= LookupTechData(kTechId.DualMinigunExosuit, kTechDataCostKey) and
            totalExosAllowed - exoCounts.total > 0

        if not shouldBuyExo then
            return kNilAction
        end

        local buyId = kTechId.DualMinigunExosuit
        if totalRailgunsAllowed > 0 and techTree:GetIsTechAvailable(kTechId.DualRailgunExosuit) and math.random() > 0.5 then
            buyId = kTechId.DualRailgunExosuit -- Don't need many railguns, miniguns much more useful
        end

        local data = sdb:Get("nearestProto")
        local proto = data.proto
        local protoDist = data.distance

        if proto and protoDist then
            weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.BuyExo )

            if bot.wantsExo then
                weight = weight + 5 -- gimme gimme gimme
            end
        else
            return kNilAction
        end

        return
        {
            name = name,
            weight = weight,
            structure = proto,
            buyId = buyId,
            limit = (totalExosAllowed - exoCounts.total),
            validate = kValidateBuyTechId,
            perform = kExecBuyTechId
        }
    end, -- BUY EXO

    function(bot, brain, marine)
        PROFILE("MarineBrain - RepairPower")
        -- Log("MarineBrain - RepairPower")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.RepairPower]
        local sdb = brain:GetSenses()
        local weight = 0
        local powerInfo = sdb:Get("nearestPower")
        local powernode = powerInfo and powerInfo.entity or nil

        if powernode ~= nil and powernode:GetIsDisabled() and powernode:GetCanBeHealed() then

            --local locationEnt = powernode:GetLocationEntity()
            local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( marine, powernode:GetId() )
            local maxOthers = 1
            local shouldBuildPowernode = powernode:HasConsumerRequiringPower()

            if shouldBuildPowernode and (numOthers <= maxOthers) then
                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.RepairPower )
            end

        end

        return 
        { 
            name = name, 
            weight = weight,
            powernode = powernode,
            validate = kValidateRepairPower,
            perform = kExecRepairPower
        }
    end, -- REPAIR POWERNODE

    function(bot, brain, marine)    --BOT-TODO Review and revise this. It's really heavy handed for simple purchasing. Offload Unlock checks to TeamBrain, or similar
        PROFILE("MarineBrain - BuyWeapons")
        -- Log("MarineBrain - BuyWeapons")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.BuyWeapons]
        local sdb = brain:GetSenses()
        local primaryWep = marine:GetWeaponInHUDSlot(1)
        local weight = 0
        local targetArmory = nil
        local canAffordWeaponTechId = nil
        local roundTimeMinutes = GetGameMinutesPassed()

        local hasBoughtDesiredWeapon = primaryWep and primaryWep:GetTechId() == brain.activeWeaponPurchaseTechId

        if not hasBoughtDesiredWeapon and brain.activeWeaponPurchaseTechId ~= nil then
        --Update Armory position / target only (done in case of Recycle / Destroyed)

            local armoryGoal = sdb:Get("nearbyArmory")
            local armory = armoryGoal and armoryGoal.armory or nil
            targetArmory = armory
            --local isAdvArmory = targetArmory ~= nil and targetArmory:isa("AdvancedArmory") or false
            --
            --local wantAdvancedWeapon = brain.activeWeaponPurchaseTechId ~= kTechId.Shotgun 
            --
            --if wantAdvancedWeapon and not isAdvArmory then
            ----Only update if needed
            --    local advArmoryGoal = sdb:Get("nearbyAdvancedArmory")
            --    if advArmoryGoal and advArmoryGoal.armory then
            --        targetArmory = advArmoryGoal.armory
            --    else
            --    --Adv armory doesn't exist, or was destroyed, bail-out on this action
            --        wantNewWeapon = false
            --        targetArmory = nil
            --        weight = 0
            --    end
            --end

            if targetArmory then
                weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.BuyWeapons )
            end

        --We've not decided on a Weapon yet, so go through decision routine accounting for saving for JP/Exo
        else

            -- Find all the weapons available for purchase.
            local availableWeapons = { }
            local weapons = enum({
                kTechId.HeavyMachineGun,
                kTechId.Shotgun,
                kTechId.Flamethrower,
                kTechId.GrenadeLauncher,
                kTechId.Cannon,
            })

            local weaponTechs = 
            {
                [kTechId.Shotgun] = kTechId.ShotgunTech,
                [kTechId.Flamethrower] = kTechId.AdvancedWeaponry,
                [kTechId.GrenadeLauncher] = kTechId.AdvancedWeaponry,
                [kTechId.HeavyMachineGun] = kTechId.AdvancedWeaponry,
                [kTechId.Cannon] = kTechId.PrototypeLab,
            }

            local hasAnyOptions = false
            local techTree = GetTechTree(marine:GetTeamNumber())    --BOT-TODO This kind of thing could be cached in TeamBrain when Tech-Unlock message is triggered
            if techTree then
                for _, weaponTechId in ipairs(weapons) do
                    if techTree:GetIsTechAvailable(weaponTechs[weaponTechId], true) then
                        availableWeapons[#availableWeapons + 1] = weaponTechId
                        availableWeapons[weaponTechId] = true
                        hasAnyOptions = true
                    end
                end
            end
            
            --If nothing is unlocked, bail now, and only check if we've got a Rifle
            if primaryWep and primaryWep:GetMapName() == Rifle.kMapName and hasAnyOptions then

                -- See if the Marine can afford anything.
                local resources = marine:GetResources()

            --!!!!BOT-FIXME This MUST take into account at least some TeamBrain weight value of "We're pushing / We're getting fucked! / Etc." !!!!
            --        Because if a team is loosing and no JP/Exos are unlocked (e.g. Don't even have a Proto yet) ...then why bother saving?
            --        Doing it this way actually gives Aliens a bigger advantage after about minute 5 or so, scaling upwards the longer a round goes.
            --        ...the 'gotchya' of above is Bots SUCK at staying alive, thus not earning Pres while dead. But, that also spins back on
            --        the same points made. So....Marines perma-fucked?  ...I swear, we need to make Marine-Bots more skilled or something. They're
            --        fubared otherwise...that, or make Aliens more sucky?
                
                    
                if roundTimeMinutes > 2 then    --BOT-TODO Tune this, or just remove (although, logical purpose of it _IS_ valid...)
                --ignore thing which cannot be reached (Pres) within X timespan
                    
                --BOT-TODO Come up with a better way to select Exo/JPs ...using math.random() is HORRIBLE and devoid of contextuality...
                    if not bot.decidedIfSavingForExo then
                        bot.decidedIfSavingForExo = true
                        bot.wantsExo = math.random() < 0.4
                    end
                    
                    if not bot.decidedIfSavingForJetpack then
                        bot.decidedIfSavingForJetpack = true
                        bot.wantsJetpack = not bot.wantsExo and math.random() < 0.3
                    end
                    
                    
                    -- always try to reserve enough for an exo
                    if bot.wantsExo then
                        resources = resources - LookupTechData(kTechId.DualMinigunExosuit, kTechDataCostKey)
                    end
                    
                    if bot.wantsJetpack then
                        resources = resources - LookupTechData(kTechId.Jetpack, kTechDataCostKey)
                    end

                end
                
                --BOT-TODO Revise below, and use some kind of lookup table via TeamBrain (or similar) which marks what all other Marines have, try to bias towards to fill "gaps"
                for _, techId in ipairs(availableWeapons) do
                    
                    if resources >= LookupTechData(techId, kTechDataCostKey) then
                        
                        canAffordWeaponTechId = techId
                        --Continue checking the other weapons with a 50% chance each
                        if math.random() > 0.5 then     --BOT-FIXME This is fucking garbage...at a minimum it should use BotPersona ...at least that'll add SOME distribution (see PlayerBot_Server.lua - line 212)
                            break
                        end
                        
                    end
                    
                end
                
                --Set the desired Weapon, on next weight-compute time, the armory checks will be done
                --While this does effectively defer the this action, it reduces need/complexity to NOT check for armory this pass (since we cache desired TechID)
                brain.activeWeaponPurchaseTechId = canAffordWeaponTechId

            end

        end
        
        return 
        { 
            name = name, 
            weight = weight,
            --fastUpdate = true,
            targetArmory = targetArmory,
            validate = kValidateBuyWeapons,
            perform = kExecBuyWeapons
        }
    end, -- BUY WEAPONS

    function(bot, brain, marine)    --FIXME This should check for JPs on ground FIRST, then fail-over to purchase
        PROFILE("MarineBrain - BuyJetpack")
        -- Log("MarineBrain - BuyJetpack")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.BuyJetpack]
        local sdb = brain:GetSenses()

        local data = sdb:Get("nearestProto")
        local proto = data.proto
        local protoDist = data.distance
        local weight = 0
        local resources = marine:GetResources()
        
        local techTree = GetTechTree(marine:GetTeamNumber())
        
        if proto and protoDist and not marine:isa("JetpackMarine") and techTree:GetIsTechAvailable(kTechId.JetpackTech, true) and resources >= LookupTechData(kTechId.Jetpack, kTechDataCostKey) then
            weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.BuyJetpack )
                    
            if bot.wantsJetpack then
                weight = weight + 5 -- gimme gimme gimme
            end
        end
        
        return 
        { 
            name = name, 
            weight = weight,
            structure = proto,
            buyId = kTechId.Jetpack,
            validate = kValidateBuyTechId,
            perform = kExecBuyTechId
        }
    end, -- BUY JETPACK

    function(bot, brain, marine)
        PROFILE("MarineBrain - BuyMines")
        -- Log("MarineBrain - BuyMines")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.BuyMines]
        local sdb = brain:GetSenses()

        local data = sdb:Get("nearbyArmory")
        local armory = data.armory
        local weight = 0
        local resources = marine:GetResources()

        local techTree = GetTechTree(marine:GetTeamNumber())
        local lastBuyMines = brain.lastBoughtMines or 0.0

        -- Don't buy mines if we're saving for exos, we don't have enough money for an advanced weapon, or we've recently bought a mine
        local shouldBuyMines = (lastBuyMines + 60) < Shared.GetTime() and resources >= 20 and not bot.wantsExo

        if armory and techTree:GetHasTech(kTechId.MinesTech, true) and not marine:GetWeaponInHUDSlot(4) and (GetWarmupActive() or shouldBuyMines) then
            weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.BuyMines )
        end

        return
        {
            name = name,
            weight = weight,
            structure = armory,
            buyId = kTechId.LayMines,
            updateKey = 'lastBoughtMines',
            validate = kValidateBuyTechId,
            perform = kExecBuyTechId
        }
    end, -- BUY Mines
    
    function(bot, brain, marine)
    PROFILE("MarineBrain - BuyHandGrenades")
    -- Log("MarineBrain - BuyHandGrenades")

    local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.BuyHandGrenades]
    local sdb = brain:GetSenses()

    local data = sdb:Get("nearbyArmory")
    local armory = data.armory
    local weight = 0
    local resources = marine:GetResources()

    local techTree = GetTechTree(marine:GetTeamNumber())
    local lastBuyGrenades = brain.lastBoughtGrenades or 0.0

    -- Don't buy grenades if we're saving for exos or we've recently bought a grenade
    local shouldBuyGrenades = (lastBuyGrenades + 60) < Shared.GetTime() and resources >= 10 and not bot.wantsExo

    -- Declare buyId and assign a default value
    local buyId = kTechId.ClusterGrenade

    if armory and techTree:GetHasTech(kTechId.GrenadeTech, true) and not marine:GetWeaponInHUDSlot(5) and shouldBuyGrenades then
        weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.BuyHandGrenades )
        -- Choose a random type of grenade to buy
        local grenadeTypes = {kTechId.ClusterGrenade, kTechId.GasGrenade, kTechId.PulseGrenade}
        buyId = grenadeTypes[math.random(#grenadeTypes)]
    end

    return
    {
        name = name,
        weight = weight,
        structure = armory,
        buyId = buyId,
        updateKey = 'lastBoughtGrenades',
        validate = kValidateBuyTechId,
        perform = kExecBuyTechId
    }
end, -- BUY HandGrenades

    function(bot, brain, marine)
        PROFILE("MarineBrain - GuardNearestHuman")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.GuardNearestHuman]
        local sdb = brain:GetSenses()
        local weight = 0

        local targetData = sdb:Get("nearestHuman")
        local target = targetData and targetData.player or nil
        local dist = targetData and targetData.distance or 999
        local ammoFraction = sdb:Get("ammoFraction")
        
        if target ~= nil and dist < 15 and ammoFraction > 0.1 then
            local targetId = target.GetId and target:GetId() or nil

            if targetId then
                local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( marine, targetId )
                if numOthers and numOthers == 0 and not brain.teamBrain:GetIsAssignedToEntity( marine, targetId ) then
                    weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.GuardNearestHuman )
                end
            end
        end

        return 
        { 
            name = name, 
            weight = weight,
            fastUpdate = true,  --required for mimic stuff
            target = target,
            validate = kValidateGuardNearestHuman,
            perform = kExecGuardNearestHuman
        }
    end, -- GUARD HUMAN (MAINTAIN DIST, RANDOM LOOK AROUND)

    function(bot, brain, marine)
        PROFILE("MarineBrain - GuardNearestExo")

        local name = kMarineBrainObjectiveTypes[kMarineBrainObjectiveTypes.GuardNearestExo]
        local sdb = brain:GetSenses()
        local weight = 0

        local targetData = sdb:Get("nearestExo")
        local target = targetData and targetData.exo or nil
        local dist = targetData and targetData.distance or 999

        if target ~= nil and dist < 15 then
            local targetId = target.GetId and target:GetId() or nil

            if targetId then
                local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( marine, targetId )

                if numOthers and numOthers == 0 then    -- and not brain.teamBrain:GetIsAssignedToEntity( marine, targetId ) 
                    weight = GetMarineObjectiveBaselineWeight( kMarineBrainObjectiveTypes.GuardNearestExo )
                end
            end
        end

        return 
        { 
            name = name, 
            weight = weight,
            fastUpdate = true,  --required for mimic stuff
            target = target,
            validate = kValidateGuardNearestHuman, --reuse GuardNearestHuman internals
            perform = kExecGuardNearestHuman
        }
    end, -- GUARD EXO (MAINTAIN DIST, RANDOM LOOK AROUND)

    function(bot, brain, marine)
        --[[
        This action is only applicable when exploring, and move near a Res Node in the early game.
        The idea behind it is for Marines to build their naturals faster, instead of skipping past.
        --]]
        PROFILE("MarineBrain  -  AwaitEarlyResPlacement")

        local name, weight = MarineObjectiveWeights:Get(kMarineBrainObjectiveTypes.AwaitEarlyResPlacement)

        local awaitableResNode
        local threatGatewayPos

        local roundMinutesPassed = GetGameMinutesPassed() --returns decimal values (e.g. 63 second == 1.05), so use math.random to add minor variance
        local teamBrain = GetTeamBrain(marine:GetTeamNumber())
        local enemyTeamLoc = GetTeamBrain(GetEnemyTeamNumber(teamBrain.teamNumber)).initialTechPointLoc

        local limit = kMarineAwaitEarlyResDropLimit + math.random(0.01, 0.15)

        if roundMinutesPassed <= limit then
        --keep this behavior only to early-game

            local naturals = GetLocationGraph():GetNaturalRtsForTechpoint(teamBrain.initialTechPointLoc)
            local resNodes = GetEntities( "ResourcePoint" )

            for i = 1, #resNodes do

                local resNode = resNodes[i]
                local location = resNode:GetLocationName()
                local numOthers = teamBrain:GetNumOthersAssignedToEntity(marine, resNode:GetId())

                --Skip our starting techpoint and don't wait for nodes with structures attached (assume this or other bots will be assigned BuildStructure)
                if naturals and naturals:Contains(location) and not resNode:GetAttached() and numOthers == 0 then

                    --Determine which gateway hostiles would be most likely to enter this location from
                    threatGatewayPos = GetThreatGatewayForLocation(location, enemyTeamLoc)
                    awaitableResNode = resNode
                        break

                    end

                end

            end

        if not awaitableResNode then
            return kNilAction
        end

        return
        {
            name = name,
            weight = weight,
            resNode = awaitableResNode,
            threatGatewayPos = threatGatewayPos,
            limit = limit,
            validate = kValidateAwaitEarlyResDrop,
            perform = kExecAwaitEarlyResPlacement
        }
    end,  --AWAIT BUILDING PLACEMENT

    function(bot, brain, marine)

        local name, weight = MarineObjectiveWeights:Get(kMarineBrainObjectiveTypes.PressureEnemyNaturals)

        local sdb = brain:GetSenses()
        local teamBrain = GetTeamBrain(marine:GetTeamNumber())
        local enemyTeam = GetEnemyTeamNumber(marine:GetTeamNumber())
        local enemyTechpoint = GetTeamBrain(enemyTeam).initialTechPointLoc

        local locGraph = GetLocationGraph()

        local ammoFraction = sdb:Get("ammoFraction")
        local healthFraction = marine:GetHealthFraction()

        -- Don't go pressuring naturals if we won't survive
        if ammoFraction < 0.2 or healthFraction < 0.4 then
            return kNilAction
        end

        -- assume any "decent" player will know where the enemy spawned based on map knowledge
        local naturals = locGraph:GetNaturalRtsForTechpoint(enemyTechpoint)

        if not marine:GetLocationName() or marine:GetLocationName() == "" or not naturals or #naturals == 0 then
            return kNilAction
        end

        -- BOT-TODO: enable once tested
         --if bot.aggroAbility < kMarinePressureEnemyThreshold then --orginal deaktiviert
             --return kNilAction
         --end

        local roundTime = GetGameMinutesPassed()
        local maxBots = roundTime <= kMarinePressureEarlyNaturalsLimit and 3 or 1 --orginal and 2 or 1

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

            local gatewayInfo = locGraph:GetGatewayDistance(marine:GetLocationName(), natural)

            if gatewayInfo then

                -- The guts of GetBotWalkDistance, but we already know our source and target locations
                local walkDist = marine:GetOrigin():GetDistance(gatewayInfo.enterGatePos) + gatewayInfo.distance

                -- Don't go for naturals that already have a bot assigned to them or present
                local assigned = teamBrain:GetNumOthersAssignedToEntity(marine, "assault-" .. natural)
                assigned = assigned + teamBrain:GetNumOtherBotsWithGoalDetails(bot, "TakeTerritory", "location", natural)

                local isMarinePresent = GetLocationContention():GetLocationGroup(natural):GetNumMarinePlayers() > 0

                if assigned == 0 and not isMarinePresent and walkDist < bestDist then
                    bestDist = bestDist
                    bestNatural = natural
                    bestPos = gatewayInfo.exitGatePos
                end

            end

        end

        if not bestNatural then
            return kNilAction
        end

        -- Find the first gateway back to the enemy techpoint (to look at)
        local threatGateway = GetThreatGatewayForLocation(bestNatural, enemyTechpoint)

        -- Log("[%s] wants to pressure natural %s of techpoint %s", marine, bestNatural, enemyTechpoint)

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

    CreateExploreAction( 0.5,
        function( pos, targetPos, bot, brain, move )
            if gBotDebug:Get("debugall") or brain.debug then
                DebugLine(brain.player:GetEyePos(), targetPos + Vector(0,1,0), 0.0, 0,0,1,1, true)
            end
            brain.teamBrain:UnassignPlayer(brain.player)
            SwitchToExploreWeapon(brain.player, brain:GetSenses())
            PerformMove(pos, targetPos, bot, brain, move)
            move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
        end     --EXPLORE
    ),
}



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

---@param mem TeamBrain.Memory
local IsLifeformThreat = function(mem)
    local t = mem.btype
    local isThreat = t >= kMinimapBlipType.Skulk and t <= kMinimapBlipType.Gorge
        or t == kMinimapBlipType.Prowler
        or t == kMinimapBlipType.Drifter
        or t == kMinimapBlipType.Whip
        or t == kMinimapBlipType.Hydra

    return isThreat
end

--  Immediate Actions  ----------------------------------------------------------------------------

local kExecAttackLifeforms = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecAttackLifeforms")
    local threat = action.threat
    local sdb = brain:GetSenses()

    if threat then

        brain.teamBrain:UnassignPlayer(marine)

        local target = Shared.GetEntity(threat.memory.entId)
        local dist = GetDistanceToTouch(marine, target)
        local primaryWeapon = marine:GetWeaponInHUDSlot(1)
        local handGrenade = marine:GetWeaponInHUDSlot(5)
        local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( marine, target:GetId() )
        local invWelder = marine:GetWeapon(Welder.kMapName)

        if primaryWeapon and primaryWeapon:GetMapName() == GrenadeLauncher.kMapName and dist < 3.0 or primaryWeapon and primaryWeapon:GetMapName() == Flamethrower.kMapName and dist > 8.0 or primaryWeapon and primaryWeapon:GetMapName() == Shotgun.kMapName and dist > 10 then
            -- Switch to our pistol and fight as a last-ditch effort
            SwitchToPistol(marine)
        elseif sdb:Get("clipFraction") > 0.0 or (target.GetHealthFraction and target:GetHealthFraction() > 0.7 and sdb:Get("ammoFraction") > 0 ) or (numOthers >= 3 and sdb:Get("pistolClipFraction") == 0 ) then
            SwitchToPrimary(marine)
        else   
        if invWelder ~= nil and (dist <= 1.5 and target:GetHealthFraction() <= 0.15 ) or (dist <= 1.5 and sdb:Get("clipFraction") == 0  and numOthers <= 1 and sdb:Get("pistolClipFraction") == 0 ) or (dist <= 1.5 and sdb:Get("ammoFraction") == 0 and sdb:Get("pistolAmmoFraction") == 0 ) then --not marine:isa("JetpackMarine") then -- Vielleicht besser wenn Jetmarines kein Nahkampf verwenden?
            SwitchToWelder(marine)
        else
        if handGrenade ~= nil and dist >= 1.5 and dist < 20 then
            SwitchToHandGrenade(marine)
        else
            SwitchToPistol(marine)
            end
         end
      end  
        brain.teamBrain:AssignPlayerToEntity( marine, threat.memory.entId )
        PerformAttack( marine:GetEyePos(), threat.memory, bot, brain, move )

    end
end

local kExecThrowHandGrenades = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecThrowHandGrenades")
    local threat = action.threat
    local sdb = brain:GetSenses()

    if threat then

        brain.teamBrain:UnassignPlayer(marine)

        local target = Shared.GetEntity(threat.memory.entId)
        local dist = GetDistanceToTouch(marine, target)
        local handGrenade = marine:GetWeaponInHUDSlot(5)
        local hasClearShot = dist < 20 and bot:GetBotCanSeeTarget( target )
                   
        if sdb:Get("clipFraction") > 0.0 and (target.GetHealthFraction and target:GetHealthFraction() > 0.5 and hasClearShot and sdb:Get("ammoFraction") > 0 ) and handGrenade ~= nil and dist < 20 then
        SwitchToHandGrenade(marine)
        else 
        SwitchToHandGrenade(marine)
        end

        brain.teamBrain:AssignPlayerToEntity( marine, threat.memory.entId )
        PerformAttack( marine:GetEyePos(), threat.memory, bot, brain, move )

    end
end

local kExecAttackStructures = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecAttackStructures")

    local sdb = brain:GetSenses()
    local memory = action.threat
    local target = Shared.GetEntity(memory.entId)

    brain.teamBrain:UnassignPlayer(marine)
    brain.teamBrain:AssignPlayerToEntity( marine, memory.entId )

    if sdb:Get("ammoFraction") > 0 then
        SwitchToPrimary(marine)
    else

        if target:GetHealthScalar() <= 0.15 and sdb:Get("ammoFraction") == 0 then
        --just try to kill asap
            SwitchToPistol(marine)
        end
    end

    PerformAttackStructure( marine:GetEyePos(), target, memory.lastSeenPos, bot, brain, move )
      local chatMsg =  bot:SendTeamMessage( "Structural threat! " .. target:GetMapName() .. " in " .. target:GetLocationName() )
            bot:SendTeamMessage(chatMsg, 60)

end

local kExecAttackBabblers = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecAttackBabblers")

    local babblerData = action.babblerData
    if babblerData and babblerData.entity then
        local babbler = babblerData.entity
        SwitchToPrimary(marine)
        PerformAttackEntity(marine:GetEyePos(), babbler, babbler:GetEngagementPoint(), bot, brain, move )
    end
end

local kExecReloadPrimary = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecReloadPrimary")

    if action.threat then
        local target = Shared.GetEntity(action.threat.memory.entId)
        -- move away from biggest threat
        if target and target:isa("Player") then
            --BOT-TODO random strafe? ...or strafe+jump? basically, only time this occurs is IN combat
            bot:GetMotion():SetDesiredMoveDirection(marine:GetOrigin() - target:GetOrigin())
            --bot:GetMotion():SetDesiredViewTarget( target:GetEngagementPoint() ) --orginal
            bot:GetMotion():SetDesiredMoveTarget( nil ) --stay still and dont move when you not in trouble. when bot is reloading a MG or GL for example.
        end
    end

    SwitchToPrimary(marine)
    move.commands = AddMoveCommand(move.commands, Move.Reload)
end

local kExecReloadPistol = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecReloadPistol")
    if action.threat then
        local target = Shared.GetEntity(action.threat.memory.entId)
        
        if target and target:isa("Player") then --babbler? hydra?
            -- move away from biggest threat
            
            --BOT-TODO random strafe? ...or strafe+jump? basically, only time this occurs is IN combat
            
            --TODO Randomize jump if target within X range
            
            bot:GetMotion():SetDesiredMoveDirection(marine:GetOrigin() - target:GetOrigin())
            --bot:GetMotion():SetDesiredViewTarget( target:GetEngagementPoint() ) --orginal
            bot:GetMotion():SetDesiredMoveTarget( nil ) --stay still and dont move when you not in trouble.
            
        end
    end
    
    local pistolWep = action.weapon
    if pistolWep and pistolWep:GetClip() / pistolWep:GetClipSize() < 1 then
        SwitchToPistol(marine)
    else
        SwitchToPrimary(marine)
    end
    
    move.commands = AddMoveCommand(move.commands, Move.Reload)
end

local kExecFindMedpack = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecFindMedpack")
    if action.bestMed then
        PerformMove( marine:GetOrigin(), action.bestMed:GetOrigin(), bot, brain, move )
    end
end

local kExecFindAmmopack = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecFindMedpack")
    if action.bestPack then
        PerformMove( marine:GetOrigin(), action.bestPack:GetOrigin(), bot, brain, move )
    end
end

local kExecPickupDroppedWeapons = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecPickupDroppedWeapons")

    local bestGun = action.bestGun
    --local bestDist = action.bestDist
    local dist = (marine:GetOrigin() - bestGun:GetOrigin()):GetLength()

    if bestGun ~= nil then
        PerformMove( marine:GetOrigin(), bestGun:GetOrigin(), bot, brain, move )
        bot:GetMotion():SetDesiredViewTarget( bestGun:GetOrigin() )
        if dist < 1.0 then
            SwitchToPrimary(marine)
            move.commands = AddMoveCommand( move.commands, Move.Drop )
        end
    end
end

local kExecClearCysts = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecClearCysts")

    local cyst = action.cyst.entity
    assert(cyst ~= nil)

    --[[
    BOT-FIXME Switching to welder results in Marine just micro-circling the cyst origin and never being able to attack, for some reason.

    local invWelder = marine:GetWeapon(Welder.kMapName)
    if invWelder then
        SwitchToWelder(marine)
    else
        SwitchToPrimary(marine)
    end
    --]]

    SwitchToPrimary(marine)

    --Note: Cysts are a special-aim case, so BotAim just points directly at their origin (otherwise, it'll miss them)
    if cyst:GetIsAlive() then
        PerformAttackStructure( marine:GetEyePos(), cyst, cyst:GetOrigin(), bot, brain, move )
    end

end

local kExecBuildNearbyStructure = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecBuildNearbyStructure")

    local target = action.target
    local originalTarget = action.originalTarget
    local targetId = originalTarget and originalTarget:GetId() or target:GetId()

    brain.teamBrain:UnassignPlayer( marine )
    brain.teamBrain:AssignPlayerToEntity( marine, targetId )

    --Switch from PowerNode (local target) to 'actual' build target (local originalTarget)
    --However, in cases where node is already built, confirm there is not 'original'
    if originalTarget and target:GetIsBuilt() and target:GetPowerState() == PowerPoint.kPowerState.socketed and not originalTarget:GetIsBuilt() then
        target = originalTarget
    end

    PerformUse( marine, target, bot, brain , move )

end

local kExecWeldNearest = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecWeldNearest")

    local weldTarget = action.weldTarget

    brain.lastWeldTargetId = weldTarget:GetId()
    brain.teamBrain:UnassignPlayer(marine)
    brain.teamBrain:AssignPlayerToEntity( marine, weldTarget:GetId() )

    SwitchToWelder(marine)
    PerformWeld( marine, weldTarget, bot, brain , move )
end

local kExecMountExosuit = function(move, bot, brain, marine, action)
    PROFILE("MarineBrain - ExecMountExosuit")

    local exo = action.exo

    if exo then
        local touchDist = GetDistanceToTouch( marine:GetEyePos(), exo )
        if touchDist > 1.5 then
            PerformMove( marine:GetOrigin(), exo:GetEngagementPoint(), bot, brain, move )

        else
            brain.buyTargetId = nil
            bot:GetMotion():SetDesiredViewTarget( exo:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveTarget( nil )
            move.commands = AddMoveCommand(move.commands, Move.Use)
        end
    end
end



local kMarineBrainActionTypesOrderScale = 10

--[[
This enum list is the label and priority order of ALL possible MarineBrain actions.
The weight below is highest to lowest. All Marine actions are ordered in scale of 10, highest to lowest.
So, kMarineBrainActionTypes.AttackLifeforms is 21st (highest priority), thus 21 * 10 = 210 weight.
This stepping gives us enough room to tweak/tune within an action (increasing X factor), and provides
consistent behavior/planning/debugging.

Note: All of kMarineBrainActionTypes are considered to be acted upon immediately.
--]]
local kMarineBrainActionTypes = enum({
--Combat Actions--
    "AttackLifeforms",
    "AttackBabblers",
    "AttackStructures",
    "ThrowHandGrenades",
    "ReloadPrimaryWeapon",
    "ReloadPistol",
    "FindMedpack",
    "FindAmmopack",
    "PickupDroppedJetpacks",
    "PickupDroppedWeapons",
    --TODO Add action that just cycles weapon from self-primary (to reset its despawn time)? -- Filter this by Veteran persona?

--Building/Team Actions--
    "FollowOrder",
    "ClearCysts",
    "BuildNearbyStructure",

--Support-Team Actions--
    "WeldNearest",
    "MountExosuit",
})

local function GetMarineActionBaselineWeight( actionId )
    assert(kMarineBrainActionTypes[kMarineBrainActionTypes[actionId]], "Error: Invalid MarineBrain action-id passed")

    local totalActions = #kMarineBrainActionTypes
    local actionOrderId = kMarineBrainActionTypes[kMarineBrainActionTypes[actionId]] --numeric index, not string

    --invert numeric index value and scale, the results in lower value, the higher the index. Which means
    --the Enum of actions is shown and used in a natural order (i.e. order of enum value declaration IS the priority)
    local actionWeightOrder = totalActions - (actionOrderId - 1)
    
    --final action base-line weight value
    return actionWeightOrder * kMarineBrainActionTypesOrderScale
end




local function HasHighPriorityTask(bot, brain)
    return bot:GetPlayerOrder() or
        ( brain.goalAction and brain.goalAction.weight >= MarineObjectiveWeights:GetWeight(kMarineBrainObjectiveTypes.RespondToLowThreat) )
end

------------------------------------------
--  Each want function should return the fuzzy weight or tree along with a closure to perform the action
--  The order they are listed should not really matter, but it is used to break ties (again, ties should be unlikely given we are using fuzzy, interpolated eval)
--  Must NOT be local, since MarineBrain uses it.
------------------------------------------
kMarineBrainActions =
{

    function(bot, brain, marine) 

        PROFILE("MarineBrain - AttackLifeforms")
        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.AttackLifeforms]

        local sdb = brain:GetSenses()
        local threat = sdb:Get("biggestLifeformThreat")
        local responseDist = 35
        local weight = 0

        --BOT-TODO Need to weight target higher if its attacking self(this Bot)
        if threat ~= nil and sdb:Get("weaponOrPistolReady") then
            --BOT-TODO: need a better threshold for responding to high-threat targets that are further away
            -- minimum threat response range of 35 meters, scales up to 105 meters for lifeforms attacking a command structure
            if threat.distance <= responseDist * math.max(1.0, threat.memory.threat) then
                weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.AttackLifeforms )
            end

            -- Don't run off and chase threats while we're guarding something
            local memAge = Shared.GetTime() - threat.memory.lastSeenTime
            if brain.lastGuardEntId and brain.lastGuardEntId ~= Entity.invalidId then
                if memAge > kMarineOnGuardChaseThreatTime then
                    weight = 0.0
                end
            end

        end

        return 
        {
            name = name, 
            weight = weight, 
            fastUpdate = true,
            threat = threat,
            perform = kExecAttackLifeforms
        }
    end, -- ATTACK BIGGEST LIFEFORM THREAT

    function(bot, brain, marine) 
        PROFILE("MarineBrain - AttackStructures")
        -- Log("MarineBrain - AttackStructures")

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.AttackStructures]
        local teamBrain = GetTeamBrain(marine:GetTeamNumber())
        local sdb = brain:GetSenses()
        local weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.AttackStructures )
        local structureThreat = nil

        local mainAmmoFrac = sdb:Get("ammoFraction")

        if mainAmmoFrac <= 0.2 or marine:GetHealthFraction() <= 0.2 then
            return kNilAction
        end

        local order = bot:GetPlayerOrder()

        -- Explicitly attack a structure threat we've been ordered to attack, regardless of the weapon we have
        if order and order:GetType() == kTechId.Attack then

            local mem = teamBrain:GetMemoryOfEntity(order:GetParam())

            if mem and not IsLifeformThreat(mem) and mem.lastSeenLoc == marine:GetLocationName() then

                structureThreat = mem

            end

        elseif not order then
            --We need to check and filter some weapons, as they're drastically less effective against structures
            --HMGs are crap atr structure damage, so don't waste ammo

            local primaryWep = marine:GetWeaponInHUDSlot(1)
            --local handGrenade = marine:GetWeaponInHUDSlot(5)
            local validStructureAttack = primaryWep and primaryWep:GetMapName() ~= HeavyMachineGun.kMapName
            --local validStructureAttack = handGrenade and handGrenade:GetMapName() ~= PulseGrenadeThrower.kMapName


            if validStructureAttack then

                structureThreat = sdb:Get("nearbyStructureThreat")

            end

        end

        if not structureThreat then
            return kNilAction
        end

        return 
        {
            name = name,
            weight = weight,
            fastUpdate = true,
            threat = structureThreat,
            perform = kExecAttackStructures
        }
    end, -- ATTACK BIGGEST STRUCTURE THREAT

    function(bot, brain, marine)

        PROFILE("MarineBrain - AttackBabblers")
        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.AttackBabblers]
        local sdb = brain:GetSenses()
        local weight = 0

        if bot:GetPlayerOrder() then
            return kNilAction
        end

        local babblerData = sdb:Get("nearestBabbler")

        if babblerData and babblerData.entity and sdb:Get("weaponOrPistolReady") then
            local dist = GetBotWalkDistance(babblerData.entity, marine)
            weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.AttackBabblers )
            --TODO Allow for zero'ing this action if we're low on ammo, or have GL, etc, etc.  ...need smarter contextualizing
        end

        return 
        { 
            name = name, 
            weight = weight, 
            fastUpdate = true,
            babblerData = babblerData,
            perform = kExecAttackBabblers
        }

    end, -- ATTACK BABBLERS

    function(bot, brain, marine)
        PROFILE("MarineBrain - ReloadPrimaryWeapon")    --BOT-FIXME Need to ensure Pistol is reloaded too

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.ReloadPrimaryWeapon]
        local weapon = marine:GetWeaponInHUDSlot(1)
        local s = brain:GetSenses()
        local weight = 0
        local threat

        if weapon ~= nil and weapon:isa("ClipWeapon") and s:Get("ammoFraction") > 0 then

            threat = s:Get("biggestLifeformThreat")

            if threat ~= nil and threat.distance < 25 and ( s:Get("clipFraction") > 0.0 or s:Get('pistolClipFraction') > 0 ) then
            -- threat really close, and we have some ammo or a backup weapon
                weight = 0

            elseif weapon:GetClip() == weapon:GetClipSize() then    --full mag
                weight = 0

            elseif weapon:GetClip() == 0 then
                weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.ReloadPrimaryWeapon )

            elseif not marine:GetIsInCombat() and weapon:GetClip() < weapon:GetClipSize() then
            --Force reload now that we're not in combat, but don't have a full mag
                weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.ReloadPrimaryWeapon )
                weight = weight * (kMarineBrainActionTypesOrderScale * 2) --Make sure this runs over just about anything else

            end

        end

        return 
        { 
            name = name, 
            weight = weight,
            threat = threat,
            weapon = weapon,
            perform = kExecReloadPrimary
        }
    end, -- RELOAD PRIMARY WEAPON

    function(bot, brain, marine)
        PROFILE("MarineBrain - ReloadPistol")

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.ReloadPistol]
        local sb = brain:GetSenses()
        local weight = 0
        local threat

        local mainAmmoFrac = sb:Get("ammoFraction")
        local pistolAmmoFrac = sb:Get("pistolAmmoFraction")
        local primaryWep = marine:GetWeaponInHUDSlot(1)
        local pistolWep = marine:GetWeapon(Pistol.kMapName)
        
        if pistolWep then

            local pistolClipSize = pistolWep:GetClipSize()
            local pistolCurClip = pistolWep:GetClip()
            local fullMag = pistolCurClip / pistolClipSize == 1

            if marine:GetIsInCombat() and mainAmmoFrac == 0 and pistolAmmoFrac > 0 and not fullMag then 
            --Bingo on main weapon, keep pistol active
                weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.ReloadPistol )

            elseif not marine:GetIsInCombat() and primaryWep and primaryWep:GetClip() == primaryWep:GetClipSize() and (pistolAmmoFrac > 0 and not fullMag) then     --BOT-FIXME This is dead-locking
            --not in combat, main weapon reloaded and ready, and pistol mag not full
                weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.ReloadPistol )
                weight = weight * (kMarineBrainActionTypesOrderScale * 2) --Make sure this runs over just about anything else

            end
        end

        return 
        { 
            name = name, 
            weight = weight,
            threat = threat,
            weapon = pistolWep,
            perform = kExecReloadPistol
        }
    end, -- RELOAD PISTOL

    function(bot, brain, marine)
        PROFILE("MarineBrain - InterruptObjective")

        -- This thinker returns no valid actions, but will interrupt the bot's current goal
        -- if it is required to react to a high-priority outside action

        local sb = brain:GetSenses()
        local now = Shared.GetTime()
        local lastOrder = bot:GetPlayerOrder()

        local shouldInterrupt = false

        if brain.lastThreatResponseCalcTime + kMarineEvalImmediateThreatTime < now then

            local highThreat = sb:Get("highestThreat")

            if highThreat.memory and highThreat.threat > kMarineImmediateThreatThreshold then
                shouldInterrupt = true
            end

            brain.lastThreatResponseCalcTime = now

        end

        if IsValid(lastOrder) and lastOrder:GetId() ~= brain.lastOrderId then

            shouldInterrupt = true
            brain.lastOrderId = lastOrder:GetId()

        end

        if shouldInterrupt then
            brain:InterruptCurrentGoalAction()
        end

        return kNilAction

    end, -- INTERRUPT OBJECTIVE FOR HIGH-THREAT MEMORY

    function(bot, brain, marine)
        PROFILE("MarineBrain - Find Medpack")

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.FindMedpack]
        local marinePos = marine:GetOrigin()
        local weight = 0
        local health = marine:GetHealthFraction()
        local bestDist
        local bestMed

        if health < 1 then
            local meds = GetEntitiesWithinRangeAreVisible( "MedPack", marinePos, 12, true )     --BOT-FIXME Change to NOT use Vis check, it's expensive
            bestDist, bestMed = GetNearestFiltered( marine, meds )

            if bestMed ~= nil then
                weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.FindMedpack )
            end
        end

        return 
        { 
            name = name, 
            weight = weight,
            bestMed = bestMed,
            perform = kExecFindMedpack
        }
    end, -- FIND MEDPACK

    function(bot, brain, marine)
        PROFILE("MarineBrain - FindAmmopack")

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.FindAmmopack]
        local weight = 0.0
        local pos = marine:GetOrigin()
        local s = brain:GetSenses()
        local weapon = marine:GetActiveWeapon()
        local weaponAmmoFrac = s:Get("ammoFraction")
        local bestPack
        local bestDist
        
        --Only check if we have ammo-based weapon, and we might need it
        if weapon ~= nil and weapon:isa("ClipWeapon") and weaponAmmoFrac < 1 then

            local packs = GetEntitiesWithinRange( "AmmoPack", pos, 10 )

            -- Don't go for dropped weapon mags, causes deadlock issues
            local IsPackForWeapon = Lambda [=[args pack; not pack:isa("WeaponAmmoPack")]=]

            bestDist, bestPack = GetNearestFiltered( marine, packs, IsPackForWeapon )

            if bestPack ~= nil then
                weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.FindAmmopack )
            end
        end

        return 
        { 
            name = name, 
            weight = weight,
            bestPack = bestPack,
            perform = kExecFindAmmopack
        }
    end, -- FIND AMMOPACK (Also specific weapon ones)
    
     function(bot, brain, marine)

        PROFILE("MarineBrain - PickupDroppedJetpacks")
        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.PickupDroppedJetpacks]
        local weight = 0.0

        local weapons = GetEntitiesWithinRange( "Jetpack", marine:GetOrigin(), 20, true )
       
        local jetMarine = marine:isa("JetpackMarine")
        
        if jetMarine then
        weapons = FilterArray( weapons, function(ent) return not ent:isa("Jetpack") end )
        
        end

        local bestDist, bestGun = GetNearestFiltered(marine:GetOrigin(), weapons)
        
                local weight = 0.0
        if not haveGoodWeapon and bestGun ~= nil then
            weight = EvalLPF( bestDist, {
                    {0.0  , 2.0} ,
                    {3.0  , 2.0} ,
                    {5.0  , 1.0}  ,
                    {20.0 , 0.0}
                    })
        end

		
                return { name = name, weight = weight,
                perform = function(move)
                    if bestGun ~= nil then
                        PerformMove( marine:GetOrigin(), bestGun:GetOrigin(), bot, brain, move )
                        bot:GetMotion():SetDesiredViewTarget( bestGun:GetOrigin() )
                        if bestDist < 1.0 then
                            SwitchToPrimary(marine)
                            move.commands = AddMoveCommand( move.commands, Move.Use )
                        end
                    end
                end }
    end, --PICKUP DROPPED JETPACKS
 
    function(bot, brain, marine)

        PROFILE("MarineBrain - PickupDroppedWeapons")
        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.PickupDroppedWeapons]
        local weight = 0.0
        local haveGoodWeapon = HasGoodWeapon(marine)

		-- don't use GetEntitiesWithinRangeAreVisible due to thrashing
        local srcWeapons = GetEntitiesWithinRange( "ClipWeapon", marine:GetOrigin(), 20 )
        local weapons = {}

        for i = 1, #srcWeapons do
            local ent = srcWeapons[i]

            -- ignore weapons owned by someone already
            local className = ent:GetClassName()
            if ent:GetParent() == nil then
                if className == "Shotgun" or
                    className == "GrenadeLauncher" or
                    className == "HeavyMachineGun" or
                    className == "Flamethrower" or
                    className == "Cannon"
                then

                    weapons[#weapons + 1] = ent
                end
            end
        end

        local bestDist, bestGun = GetNearestFiltered(marine, weapons)

        if not haveGoodWeapon and bestGun ~= nil then
            weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.PickupDroppedWeapons )
        end

        return
        {
            name = name, 
            weight = weight,
            bestGun = bestGun,
            bestDist = bestDist,
            perform = kExecPickupDroppedWeapons
        }
    end, --PICKUP DROPPED WEAPONS--]]

    function(bot, brain, marine)
        PROFILE("MarineBrain - ClearCysts")
        -- Log("MarineBrain - ClearCysts")

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.ClearCysts]
        local sdb = brain:GetSenses()
        local weight = 0

        local cyst = sdb:Get("nearestCyst")

        -- Don't build structures if we've been given an order or we're "on a mission"
        if HasHighPriorityTask(bot, brain) then
            return kNilAction
        end

        --FIXME We need a Marine-Global like "fuck this, I need supplies "...otherwise, it'll never be consistent
        --basically ...what commonly consitutes "low ammo" condition? Ideally, refined with whole inventory, etc.
        if cyst.entity and sdb:Get("attackNearbyCyst") and marine:GetHealthScalar() > 0.2 and sdb:Get("ammoFraction") > 0.2 then
            weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.ClearCysts )
        end

        return 
        {
            name = name,
            weight = weight,
            fastUpdate = true,
            cyst = cyst,
            perform = kExecClearCysts
        }

    end, -- CLEAR CYST

    function(bot, brain, marine)
        PROFILE("MarineBrain - BuildNearbyStructure")

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.BuildNearbyStructure]
        local sdb = brain:GetSenses()
        local weight = 0

        local buildTarget = sdb:Get("nearbyBuildable")
        local originalTarget = nil
        local buildLocation = nil

        -- Don't build structures if we've been given an order or we're "on a mission"
        if HasHighPriorityTask(bot, brain) then
            return kNilAction
        end

        --limit to inside relevancy range, becuase we don't want a Marine to go clear across the map to build
        --or we're just exploring anyway but not clear across the map
        if buildTarget then

            local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity( marine, buildTarget:GetId() )

            -- if at least two people are already building this structure, ignore it
            if numOthers >= 2 then
                return kNilAction
            end

            local loc = buildTarget:GetLocationName()

            -- Don't have more than 2 bots total building in main base
            if loc == brain.teamBrain.initialTechPointLoc and brain.teamBrain:GetNumOtherBotsWithActionDetails(bot, name, "buildLocation", loc) >= 2 then
                return kNilAction
            end

            if loc then
            --Note: if this ever fails the condition, we've either got a really screwy bug, or it's a map issue

                local power = GetPowerPointForLocation(loc)

                if power and not power:GetPowerState() ~= PowerPoint.kPowerState.socketed then
                    originalTarget = buildTarget
                    buildTarget = power
                end

            end

            weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.BuildNearbyStructure )
            buildLocation = loc

        end

        return
        {
            name = name,
            weight = weight,
            target = buildTarget,
            originalTarget = originalTarget,
            buildLocation = buildLocation,
            perform = kExecBuildNearbyStructure
        }

    end,

    function(bot, brain, marine)
        PROFILE("MarineBrain - WeldNearest")

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.WeldNearest]
        local sdb = brain:GetSenses()
        local weight = 0
        local weldTarget = nil

        if bot:GetPlayerOrder() then
            return kNilAction
        end

        if sdb:Get("welder") ~= nil then

            weldTarget = sdb:Get("nearbyWeldable")

            -- Continue welding
            if weldTarget ~= nil and weldTarget:GetArmorScalar() < 0.9999 then
                weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.WeldNearest )
            else
            -- clear our "last welded target" once we stop
                brain.lastWeldTargetId = nil
            end

        end

        return
        {
            name = name,
            weight = weight,
            weldTarget = weldTarget,
            perform = kExecWeldNearest
        }
    end, -- WELD NEAREST WELDABLE TARGET

    --BOT-TODO Add Buy HandGrenades and/or Mine(s)
    
    function(bot, brain, marine)
        PROFILE("MarineBrain - MountExosuit")

        local name = kMarineBrainActionTypes[kMarineBrainActionTypes.MountExosuit]
        local sdb = brain:GetSenses()

        local data = sdb:Get("nearestExosuit")
        local exo = data.exo
        local exoDist = data.distance
        local weight = 0
        
        --Only jump in Exosuits that are "Safe" (ownership expired), or we already own
        if exo and not HasGoodWeapon(marine) and (exo:GetOwner() == nil or exo:GetOwner() == marine:GetId() ) and exoDist <= 25 then
            weight = GetMarineActionBaselineWeight( kMarineBrainActionTypes.MountExosuit ) --orginal

            if exoDist <= 8 then
              weight = weight + 222 -- to get the marine in a good order to conquer empty exos on the map... doesnt matter how much enemys in range (only AR-soldier/Advanced give cover)...
        end
     end
        
        return 
        { 
            name = name, 
            weight = weight,
            exo = exo,
            perform = kExecMountExosuit
        }

    end, -- MOUNT EXO

    --[[ 
    function(bot, brain)
        return 
        { 
            name = "debug idle", 
            weight = 0.0,
            perform = 
                function(move)
                -- Do a jump..for fun
                    move.commands = AddMoveCommand(move.commands, Move.Jump)
                    bot:GetMotion():SetDesiredViewTarget(nil)
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                end
        }
    end,
    --]]

}

------------------------------------------
--  Active threats - ie. they can hurt you
--  Only load balance if we cannot see the target
------------------------------------------
local function EvalActiveUrgenciesTable(numOthers)
    local activeUrgencies =
    {
        [kMinimapBlipType.Onos] =       numOthers >= 4 and 0.1 or 7.0,
        [kMinimapBlipType.Fade] =       numOthers >= 3 and 0.1 or 6.0,
        [kMinimapBlipType.Lerk] =       numOthers >= 2 and 0.1 or 5.0,
        [kMinimapBlipType.Skulk] =      numOthers >= 2 and 0.1 or 4.0,
        [kMinimapBlipType.Gorge] =      numOthers >= 2 and 0.1 or 3.0,
        [kMinimapBlipType.Whip] =       numOthers >= 2 and 0.1 or 3.0,
        [kMinimapBlipType.Hydra] =      numOthers >= 2 and 0.1 or 2.0,
        [kMinimapBlipType.Drifter] =    numOthers >= 1 and 0.1 or 1.0,
    }

    return activeUrgencies
end

local activeUrgencies =
    {
        [kMinimapBlipType.Onos] =    7.0,
        [kMinimapBlipType.Fade] =    6.0,
        [kMinimapBlipType.Lerk] =    5.0,
        [kMinimapBlipType.Skulk] =   4.0,
        [kMinimapBlipType.Gorge] =   3.0,
        [kMinimapBlipType.Whip] =    3.0,
        [kMinimapBlipType.Hydra] =   2.0,
        [kMinimapBlipType.Drifter] = 1.0,
    }

local urgentResponders =
{
    [kMinimapBlipType.Onos]  = 4,
    [kMinimapBlipType.Fade]  = 3,
    [kMinimapBlipType.Lerk]  = 2,
    [kMinimapBlipType.Skulk] = 2,
    [kMinimapBlipType.Gorge] = 2,
    [kMinimapBlipType.Whip]  = 2,
}

local function GetStructureAttackUrgency(bot, mem)

    local teamBrain = bot.brain.teamBrain

    -- See if we know whether if it is alive or not
    local target = Shared.GetEntity(mem.entId)
    if not HasMixin(target, "Live") or not target:GetIsAlive() or (HasMixin(target, "Team") and target:GetTeamNumber() == bot:GetTeamNumber()) then
        return nil
    end

    --BOT-TODO Devise formula to denote if Bot can see or not  ...cloak % or similar compared to 0-1 velocity or some such
    -- ...don't forget some Alien structures CAN move
    if HasMixin(target, "Cloakable") and target:GetCloakFraction() >= 1 then -- GetIsCloaked uses a Player-based max of 88%
    --target is completely cloaked and not moving, ignore it
        return nil
    end

    local player = bot:GetPlayer()

    --[[
    --McG: removed this for now, as it just adds fuckery that's just not needed. More robust solution required

    -- for load-balancing
    local numOthers = teamBrain:GetNumAssignedTo( mem,
        function(otherId)
            if otherId ~= player:GetId() and player:GetDistance(mem.lastSeenPos) < 30 then
                return true
            end
            return false
        end
    )
    --]]

    local dist = GetBotWalkDistance(player, target)

    local urgencies = 
    {
        --[[
        --[kMinimapBlipType.Drifter] =            numOthers >= 2 and 0.2 or 0.98,
        [kMinimapBlipType.Crag] =               numOthers >= 2 and 0.2 or 0.95, -- kind of a special case
        [kMinimapBlipType.Hive] =               numOthers >= 6 and 0.8 or 0.93,
        [kMinimapBlipType.Harvester] =          numOthers >= 2 and 0.5 or 0.9,
        [kMinimapBlipType.Egg] =                numOthers >= 1 and 0.2 or 0.5,
        [kMinimapBlipType.Shade] =              numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.Shift] =              numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.Shell] =              numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.Veil] =               numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.Spur] =               numOthers >= 2 and 0.2 or 0.5,
        [kMinimapBlipType.TunnelEntrance] =     numOthers >= 1 and 0.2 or 0.5,
        --]]

    --See....here's the problem...Crag near Hive, yeah, high prio, crag at forward-base...not so much
    --  e.g. Crag at forward-base with Tunnel ...Tunnel must die ...crag by itself...meh, etc, etc
    --XXXX Perhaps find the centroid of all found structures (clustered?), and then derives a weight-bias accordingly to set-combos?
        [kMinimapBlipType.Crag] =               0.95,
        [kMinimapBlipType.Hive] =               0.93,
        [kMinimapBlipType.TunnelEntrance] =     0.9, -- orignal [kMinimapBlipType.Harvester] =          0.9,      
        [kMinimapBlipType.Whip] =               0.89,
        [kMinimapBlipType.Shell] =              0.6,
        [kMinimapBlipType.Veil] =               0.6,
        [kMinimapBlipType.Spur] =               0.6,
        [kMinimapBlipType.Harvester] =          0.5, --orginal [kMinimapBlipType.Tunnel] =              0.5,
        [kMinimapBlipType.Shade] =              0.5,
        [kMinimapBlipType.Shift] =              0.5,
        [kMinimapBlipType.Egg] =                0.4,
        [kMinimapBlipType.Embryo] =             0.385,  --Player-Eggs slightly lower, as we don't want Bots being assholes, now do we?
    }

    local closeBonus = 0

    if target.GetHealthScalar then
        closeBonus = closeBonus + (1 - target:GetHealthScalar()) * 1.5
    end

    if urgencies[ mem.btype ] ~= nil then

        if dist < 20 then
            -- if passive target, then make sure they're all "equal" close bonus so that a marine bot will
            -- much more likely hit a Hive instead of a Harvester, etc. but still prioritize relevanit targets
            -- rather than ones across the map...
            -- Should be under min of active targets (players) so they fight them first.
            if dist < 8 and target:isa("Whip") then
                closeBonus = closeBonus * 2 + 5.0
            else    
                closeBonus = closeBonus + 0.3
            end
        end

        return urgencies[ mem.btype ] + closeBonus

    end

    return 0    --Unknown / Not tracked

end

--[[
McG: We do need _some_ kind of sorting / prioritization for Lifeforms! For example, lifeform attack self SHOULD be higher priority than
one that's retreating, or one that's not attacking us. E.g. Fresh Onos with gorge support vs retreating Lerk. Basically, in an ideal sense
MarineBots need to understand "Something is coming towards me VS Something is running away". So, some linear algerbra and velocity checks, etc.
(with lots of early-out bailing possibilities/constraints).
--]]
local function GetAttackUrgency(bot, player, mem)

    local now = Shared.GetTime()
    local teamBrain = bot.brain.teamBrain

    -- See if we know whether if it is alive or not
    local target = Shared.GetEntity(mem.entId)
    if not HasMixin(target, "Live") or not target:GetIsAlive() or (target.GetTeamNumber and target:GetTeamNumber() == bot:GetTeamNumber()) then
        return nil
    end

    local isPartiallyCloaked =  HasMixin(target, "Cloakable") and target:GetCloakFraction() > 0.5 -- 5.2 is non-celerity sneak speed for skulks
    local isFullyCloaked = HasMixin(target, "Cloakable") and target:GetCloakFraction() > 0.8
    if isFullyCloaked then
        return nil -- Super slow movement
    elseif isPartiallyCloaked then
        local lastTimeCloak = bot.brain.lastTargetCloakTimes[target:GetId()] or 0
        local timeSinceLastCloak = now - lastTimeCloak
        if timeSinceLastCloak < bot.brain.kCloakDelayTime then
            return nil
        end
    else -- Update last time uncloaked
        bot.brain.lastTargetCloakTimes[target:GetId()] = now
    end

    -- for load-balancing
    local numOthers = teamBrain:GetNumAssignedTo( mem,
            function(otherId)
                if otherId ~= player:GetId() and GetBotWalkDistance(player, mem.lastSeenPos, mem.lastSeenLoc) < 30 then
                    return true
                end
                return false
            end)

    -- Closer --> more urgent

    local closeBonus = 0
    local dist = GetBotWalkDistance(player, mem.lastSeenPos, mem.lastSeenLoc)

    ------------------------------------------
    -- Passives - not an immediate threat, but attack them if you got nothing better to do
    ------------------------------------------
    local passiveUrgencies =
    {
        [kMinimapBlipType.Drifter] =            numOthers >= 2 and 0.2 or 0.98,
    }

    if bot.brain.debug then
        if mem.btype == kMinimapBlipType.Hive then
            Print("got Hive, urgency = %f", passiveUrgencies[mem.btype])
        end
    end


    if target.GetHealthScalar and target:GetHealthScalar() < 0.3 then
        closeBonus = closeBonus + (0.3-target:GetHealthScalar()) * 3
    end

    if passiveUrgencies[ mem.btype ] ~= nil then

        if dist < 20 then
            -- if passive target, then make sure they're all "equal" close bonus so that a marine bot will
            -- much more likely hit a Hive instead of a Harvester, etc. but still prioritize relevanit targets
            -- rather than ones across the map...
            -- Should be under min of active targets (players) so they fight them first.
            closeBonus = closeBonus + 0.3
        end


        return passiveUrgencies[ mem.btype ] + closeBonus
    end

    -- Optimization: we only need to do visibilty check if the entity type is active
    -- So get the table first with 0 others
    local urgTable = EvalActiveUrgenciesTable(0)

    if urgTable[ mem.btype ] then
        -- For nearby active threads, respond no matter what - regardless of how many others are around
        if dist < 15 or player:GetIsInCombat() then
            numOthers = 0
        end

        -- local maxResponders = (urgentResponders[ mem.btype ] or 1) + (mem.threat > 1.0 and 1 or 0)
        -- local urgency = numOthers < maxResponders and activeUrgencies[ mem.btype ] or 0.1

        urgTable = EvalActiveUrgenciesTable(numOthers)

        if dist < 20 then
            -- Do not modify numOthers here
        
            if target:isa("Whip") and dist < 8 then
                closeBonus = closeBonus * 2 + 10.0 -- way too close to a whip!
            else    
                closeBonus = closeBonus + 10/math.max(1.0, dist)
            end

        end

        -- return urgency + closeBonus + mem.threat

        return urgTable[ mem.btype ] + closeBonus + mem.threat

    end
    
    return nil

end

------------------------------------------
--  Build the senses database
------------------------------------------

function CreateMarineBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("clipFraction", 
        function(db, marine)
            local weapon = marine:GetWeaponInHUDSlot(1)
            if weapon ~= nil then
                if weapon:isa("ClipWeapon") then
                    return weapon:GetClip() / weapon:GetClipSize()
                else
                    return 1.0
                end
            else
                return 0.0
            end
        end)

    s:Add("exoCounts", function(db, marine)
        local numRailgunExos = 0
        local numMinigunExos = 0

        for _, ent in ipairs(GetEntitiesForTeam("Exo", marine:GetTeamNumber())) do
            if ent:GetHasRailgun() then
                numRailgunExos = numRailgunExos + 1
            elseif ent:GetHasMinigun() then
                numMinigunExos = numMinigunExos + 1
            end
        end

        return { railguns = numRailgunExos, miniguns = numMinigunExos, total = numRailgunExos + numMinigunExos }
    end)
        
    s:Add("pistolClipFraction",
        function(db, marine)
            local weapon = marine:GetWeapon(Pistol.kMapName)
            if weapon ~= nil then
                if weapon:isa("ClipWeapon") then
                    return weapon:GetClip() / weapon:GetClipSize()
                else
                    return 1.0
                end
            else
                return 0.0
            end
        end)

    s:Add("ammoFraction", 
        function(db, marine)
            -- Log("MarinBrain:Senses:ammoFraction")
            local weapon = marine:GetWeaponInHUDSlot(1)
            -- Log("    weapon: %s", weapon)
            local mag = 0
            if weapon ~= nil then
                if weapon:isa("ClipWeapon") then
                    mag = weapon:GetAmmo() / weapon:GetMaxAmmo()
                else
                    mag = 1.0
                end
            else
                mag = 0.0
            end
            -- Log("   mag: %s", mag)
            return mag
        end)

    s:Add("pistolAmmoFraction", 
        function(db, marine)
            local weapon = marine:GetWeapon(Pistol.kMapName)
            if weapon then
                return weapon:GetAmmo() / weapon:GetMaxAmmo()
            end
            return 0
        end)

    s:Add("welder", 
        function(db, marine)
            return marine:GetWeapon( Welder.kMapName )
        end)

    s:Add("welderReady", 
        function(db, marine)
            return marine:GetActiveWeapon():GetMapName() == Welder.kMapName
        end)

    s:Add("weaponReady", 
        function(db, marine)
            return db:Get("ammoFraction") > 0
        end)

    s:Add("weaponOrPistolReady", 
        function(db, marine)
            return db:Get("ammoFraction") > 0 or db:Get("pistolAmmoFraction") > 0
        end)
    
    s:Add("biggestLifeformThreat", 
        function(db, marine)
            PROFILE("MarineBrain - biggestLifeformThreat")

            local teamBrain = GetTeamBrain( marine:GetTeamNumber() )
            local enemyTeam = GetEnemyTeamNumber( marine:GetTeamNumber() )

            local maxUrgency, maxMem = 0.0, nil

            for _, mem in teamBrain:IterMemoriesNearLocation(marine:GetLocationName(), enemyTeam) do

                if IsLifeformThreat(mem) then

                    local urgency = GetAttackUrgency(db.bot, marine, mem)

                    if urgency and urgency > maxUrgency then
                        maxUrgency = urgency
                        maxMem = mem
                    end

                end
            end

            if maxMem ~= nil then
                if db.bot.brain.debug then
                    Print("max mem type = %s", EnumToString(kMinimapBlipType, maxMem.btype))
                end
                --dist = marine:GetEyePos():GetDistance(maxMem.lastSeenPos)

                LogConditional(gBotDebug:Get("target_prio"), "Bot Target: %s", EnumToString(kMinimapBlipType, maxMem.btype))
                
                local dist = GetPhaseDistanceForMarine( marine, maxMem.lastSeenPos, db.bot.brain.lastGateId )
                return 
                {
                    urgency = maxUrgency, 
                    memory = maxMem, 
                    distance = dist
                }
            else
                return nil
            end
        end)

    s:Add("biggestStructureThreat", 
        function(db, marine)
            local memories = GetTeamMemories( marine:GetTeamNumber() )  --Memories? Or IN Range?
            local maxUrgency, maxMem = GetMaxTableEntry( memories,
                function( mem )

                    -- Don't even consider players for structure threat
                    local shouldIgnore = (mem.btype >= kMinimapBlipType.Skulk and mem.btype <= kMinimapBlipType.Gorge)
                        or mem.btype == kMinimapBlipType.Infestation
                        or mem.btype == kMinimapBlipType.InfestationDying
                        or mem.btype == kMinimapBlipType.Prowler

                    if shouldIgnore then
                        return nil
                    end

                    local ent = Shared.GetEntity(mem.entId)
                    if ent then
                        return GetStructureAttackUrgency( db.bot, mem )
                    else
                        return nil
                    end
                end
            )
            
            if maxMem ~= nil then
                if db.bot.brain.debug then
                    Print("max mem type = %s", EnumToString(kMinimapBlipType, maxMem.btype))
                end
                --dist = marine:GetEyePos():GetDistance(maxMem.lastSeenPos)

                LogConditional(gBotDebug:Get("target_prio"), "Bot Target: %s", EnumToString(kMinimapBlipType, maxMem.btype))
                
                local dist = GetPhaseDistanceForMarine( marine, maxMem.lastSeenPos, db.bot.brain.lastGateId )

                return 
                {
                    urgency = maxUrgency, 
                    memory = maxMem, 
                    distance = dist
                }
            end
            
            return nil
        end)
    
    s:Add("nearbyStructureThreat", 
        function(db, marine)

            local teamBrain = GetTeamBrain(marine:GetTeamNumber()) 
            local enemyTeam = GetEnemyTeamNumber(marine:GetTeamNumber())
            local memories = teamBrain:GetMemoriesAtLocation(marine:GetLocationName(), enemyTeam)

            local bestWeight = 0.0
            local bestMem = nil

            for _, mem in ipairs(memories) do
                local urgency = GetStructureAttackUrgency(db.bot, mem)

                if urgency and urgency > bestWeight then
                    bestWeight = urgency
                    bestMem = mem
                end
            end

            return bestMem
        end)


    s:Add("highestThreat",
        function(db, marine)

            local teamBrain = GetTeamBrain(marine:GetTeamNumber())
            local enemyTeam = GetEnemyTeamNumber(marine:GetTeamNumber())

            -- BOT-TODO: sort TeamBrain memories based on team index
            local memories = teamBrain:GetMemories()
            local bestWeight = 0.01
            local bestThreat = 0.0
            local bestMemory = nil

            -- basic filtering for threats this bot can respond to
            for _, mem in ipairs(memories) do
                if mem.team == enemyTeam and mem.threat > 0.0 then

                    local target = Shared.GetEntity(mem.entId)

                    local responseWeight = mem.threat * EstimateBotResponseUtility(marine, target)

                    local attackers = teamBrain:GetNumAssignedToEntity(mem.entId)
                    local responders = teamBrain:GetNumAssignedToEntity("respond-" .. mem.entId)
                    local idealResponders = math.ceil(mem.threat)

                    -- prioritize responding to threats that aren't currently being responded to by a friendly
                    responseWeight = responseWeight * (1.0 - (attackers + responders) / idealResponders)

                    if responseWeight > bestWeight then
                        bestWeight = responseWeight
                        bestThreat = mem.threat
                        bestMemory = mem
                    end

                end
            end

            return { memory = bestMemory, threat = bestThreat }
        end)

    s:Add("nearestArmory", 
        function(db, marine)
            PROFILE("MarineBrain - GetNearestArmory")

            local teamBrain = db.bot.brain.teamBrain

            local dist, armory = FilterNearestMarineEntity(marine, teamBrain.teamArmories, db.lastNearestArmoryId, db.bot.brain.lastGateId)

            if armory ~= nil then
                db.lastNearestArmoryId = armory:GetId()
            end

            return
            {
                armory = armory,
                distance = dist
            }

        end)
    
    s:Add("nearbyArmory", 
        function(db, marine)
            PROFILE("MarineBrain - GetNearbyArmory")

            ---@type MarineTeamBrain
            local teamBrain = db.bot.brain.teamBrain

            local dist, armory = FilterNearbyMarineEntity(marine, teamBrain.teamArmories, db.lastNearbyArmory, db.bot.brain.lastGateId)

            if armory ~= nil then 
                db.lastNearbyArmory = armory:GetId()
            end

            return
            {
                armory = armory,
                distance = dist
            }

        end)

    s:Add("nearbyAdvancedArmory",
        function(db, marine)
            PROFILE("MarineBrain - GetNearbyAdvancedArmory")

            ---@type MarineTeamBrain
            local teamBrain = db.bot.brain.teamBrain

            -- filter only advanced armories
            local armories = {}

            for i = 1, #teamBrain.teamArmories do
                local entId = teamBrain.teamArmories[i]
                local mem = teamBrain:GetMemoryOfEntity(entId)

                if mem and mem.btype == kMinimapBlipType.AdvancedArmory then
                    armories[#armories + 1] = entId
                end
            end

            local dist, armory = FilterNearbyMarineEntity( marine, armories, db.lastNearestAdvArmoryId, db.bot.brain.lastGateId )

            if armory ~= nil then
                db.lastNearestAdvArmoryId = armory:GetId()
            end

            return
            {
                armory = armory,
                distance = dist
            }

        end)
            
    s:Add("nearestHuman", 
        function(db, marine)
            local players = GetEntitiesForTeam( "Player", marine:GetTeamNumber() )
            local botOrg = marine:GetOrigin()

            local dist, targetPlayer = GetMinTableEntry( players,
                function(player)
                    if player then
                        if not player:GetIsVirtual() and player:GetAFKTime() < kBotGuardMaxAFKTime and player:GetIsAlive() and not player:isa("Commander") then
                            --local dist,_ = GetPhaseDistanceForMarine( marine, player, db.bot.brain.lastGateId )
                            local dist = GetBotWalkDistance( marine, player )
                            return dist
                        end
                    end
                end
            )

            return 
            {
                player = targetPlayer, 
                distance = dist
            }
        end)
            
    s:Add("nearestProto", 
        function(db, marine)

            local protos = GetEntitiesForTeam( "PrototypeLab", marine:GetTeamNumber() )

            local dist, proto = GetMinTableEntry( protos,
                function(proto)
                    assert( proto ~= nil )
                    if proto:GetIsBuilt() and proto:GetIsPowered() then
                        local dist,_ = GetPhaseDistanceForMarine( marine, proto, db.bot.brain.lastGateId )

                        -- Weigh our previous nearest a bit better, to prevent thrashing
                        if proto:GetId() == db.lastNearestProtoId then
                            return dist * 0.9
                        else
                            return dist
                        end
                    end
                end)

            if proto ~= nil then 
                db.lastNearestProtoId = proto:GetId() 
            end

            return 
            {
                proto = proto, 
                distance = dist
            }

        end)

    s:Add("nearestExo", 
        function(db, marine)

            local exos = GetEntitiesForTeam( "Exo", marine:GetTeamNumber())

            local dist, exo = GetMinTableEntry( exos,
                function(exo)
                    local dist,_ = GetBotWalkDistance( marine, exo )

                    return dist
                end)

            return
            {
                exo = exo,
                distance = dist
            }

        end)

    s:Add("nearestExosuit", 
        function(db, marine)

            local exos = GetEntitiesForTeam( "Exosuit", marine:GetTeamNumber())

            local dist, exo = GetMinTableEntry( exos,
                function(exo)
                    assert( exo ~= nil )
                    if exo:GetIsValidRecipient(marine) and exo:GetHealthScalar() > 0.8 then
                        local dist,_ = GetPhaseDistanceForMarine( marine, exo, db.bot.brain.lastGateId )

                        -- Weigh our previous nearest a bit better, to prevent thrashing
                        if exo:GetId() == db.lastNearestExoId then
                            return dist * 0.9
                        else
                            return dist
                        end
                    end
                end)

            if exo ~= nil then 
                db.lastNearestExoId = exo:GetId() 
            end
            
            return 
            {
                exo = exo, 
                distance = dist
            }

        end)

    s:Add("nearestPower", function(db, marine)

            local powers = GetEntities( "PowerPoint" )

            local bestDist = 1000
            local bestPower = nil

            local nearby = GetLocationGraph():GetDirectPathsForLocationName( marine:GetLocationName() )

            for i = 1, #powers do
                local power = powers[i]

                if nearby and nearby:Contains(power:GetLocationName()) then
                    local dist = GetBotWalkDistance(marine, power)

                    if dist < bestDist then
                        bestDist = dist
                        bestPower = power
                    end
                end
            end

            return {entity = bestPower, distance = bestDist}
            end)

    s:Add("nearbyWeldable", function(db, marine)

        local teamBrain = GetTeamBrain(marine:GetTeamNumber())

        local memories = teamBrain:GetMemoriesAtLocation(marine:GetLocationName(), marine:GetTeamNumber())

        local bestWeight = 0.0 -- filter out almost-completely finished structures
        local bestWeldable = nil

        for _, mem in ipairs(memories) do
            local ent = Shared.GetEntity(mem.entId)

            if ent and HasMixin(ent, "Weldable") and ent ~= marine then
                --Players can be welded but not built /shrug
                if ent:GetCanBeWelded(marine) and ( not ent.GetIsBuilt or ent:GetIsBuilt() ) then

                    --No point in welding something that's actively infested, skip it. Unless it's health is below X%
                    local healthScalar = (ent.isCorroded and ent:GetHealthFraction()) or (ent:GetArmorScalar())

                    -- prioritize welding the most damaged target that doesn't already have a welder working on it
                    local weight = (1.0 - healthScalar) * math.max(0.0, (1.5 - teamBrain:GetNumOthersAssignedToEntity(marine, mem.entId)))
                    -- weld players before welding structures
                    weight = weight * (ent:isa("Player") and 1.5 or 1.0)
                    weight = weight * (mem.entId == db.bot.brain.lastWeldTargetId and 3.0 or 1.0) -- prioritize finishing the last weldable target

                    if weight > bestWeight then
                        bestWeight = weight
                        bestWeldable = ent
                    end
                end

            end
        end

        return bestWeldable

    end)
            
    s:Add("nearestBuildable",
        function(db, marine)
            PROFILE("MarineBrain - GetNearestBuildable")

            local targets = (GetEntitiesWithMixinForTeam("Construct", marine:GetTeamNumber()))

            local dist, target = GetMinTableEntry( targets,
                function(target)
                    assert( target ~= nil )
                    -- we exclude power points here because they could be unsocketed and therefore unbuildable
                    if not target:GetIsBuilt() and not target:isa("PowerPoint") then
                        local teamBrain = GetTeamBrain(marine:GetTeamNumber())

                        -- Don't go build structures that are already under construction
                        if teamBrain:GetNumAssignedToEntity(target:GetId()) >= 1 then
                            return 9999.0
                        end

                        local dist,_ = GetPhaseDistanceForMarine( marine, target, db.bot.brain.lastGateId )

                        -- Bias against going to build structures that are already reserved
                        if teamBrain:GetNumOthersAssignedToEntity( marine, "reserve-" .. target:GetId() ) > 1 then
                            dist = dist * 2.0
                        end

                        return dist
                    end
                end)

            return {target = target, distance = dist}

        end)

    s:Add("nearbyBuildable",
        function(db, marine)
            PROFILE("MarineBrain - GetNearbyBuildable")

            local teamNumber = marine:GetTeamNumber()
            local teamBrain = GetTeamBrain(teamNumber)

            local memories = teamBrain:GetMemoriesAtLocation(marine:GetLocationName(), teamNumber)
            local bestWeight = 0.0
            local bestEnt = nil

            for _, mem in ipairs(memories) do
                local ent = Shared.GetEntity(mem.entId)

                -- we exclude power points here if there are no structures requiring them to be built
                local buildIfPowerPoint = not ent:isa("PowerPoint") or ent:HasConsumerRequiringPower()

                if HasMixin(ent, "Construct") and not ent:GetIsBuilt() and buildIfPowerPoint then
                    local numOthers = teamBrain:GetNumOthersAssignedToEntity( marine, mem.entId )

                    local dist = GetBotWalkDistance(marine, ent)

                    -- reduce importance of this structure based on how many players are already building it
                    local weight = 1.0 / math.max(1.0, dist * numOthers)

                    if weight > bestWeight then
                        bestWeight = weight
                        bestEnt = ent
                    end
                end
            end

            return bestEnt

        end)

    s:Add("nearestCyst", function(db, marine)

            local marinePos = marine:GetOrigin()
            local cysts = GetEntitiesWithinRange("Cyst", marinePos, 25)

            local dist, cyst = GetMinTableEntry( cysts, function(cyst)
                if cyst:GetIsSighted() then
                    return GetBotWalkDistance(marine, cyst)
                end
                return nil
                end)

            return {entity = cyst, distance = dist}
            end)
            
    s:Add("nearestBabbler", function(db, marine)
            local marinePos = marine:GetOrigin()
            local babblers = GetEntitiesWithinRange("Babbler", marinePos, 10)

        --Make sure we "should" be able to see, and it's not attached to a lifeform
            local dist, babbler = GetMinTableEntry( babblers, 
                function(babbler)
                    local babblerAttached = babbler:GetIsClinged()
                    if not babblerAttached then
                        local dist = marinePos:GetDistance( babbler:GetOrigin() )
                        if IsPointInCone( babbler:GetOrigin(), marine:GetEyePos(), marine:GetViewCoords().zAxis, db.bot.aim.viewAngle ) or dist < 1.5 then
                            return dist
                        else
                            return nil
                        end
                    else
                        return nil
                    end
                end
            )

            return 
            {
                entity = babbler, 
                distance = dist
            }
        end)

    s:Add("attackNearbyCyst",
        function(db, marine)
            local teamBrain = GetTeamBrain(marine:GetTeamNumber())
            
            local memories = teamBrain:GetMemoriesAtLocation(marine:GetLocationName(), marine:GetTeamNumber())

            local shouldAttack = true --muss auf true sein, sonst greifen die bots kaum die cysten an. orginal auf false...

            for _, mem in ipairs(memories) do
                local ent = Shared.GetEntity(mem.entId)

                if HasMixin(ent, "Construct") and (not ent:isa("PowerPoint") or ent:GetIsSocketed() and ent.isCorroded) or ent:isa("ARC") then
                    shouldAttack = true
                    break
                end
            end
    
            return shouldAttack
        end)

    s:Add("attackNearestCyst", function(db, marine) --BOT-FIXME This needs to use whatever the maximum possible infestation range is for Cyst (regardless of maturity, etc.)
    
            local cyst = db:Get("nearestCyst")

            if not cyst.entity then
                return false
            end

            local weldable = db:Get("nearbyWeldable")
            if weldable ~= nil then
                local cystPos = cyst.entity:GetOrigin()
                local powerPos = weldable:GetOrigin()
                --DebugLine( cystPos, powerPos, 0.0, 1,1,0,1,  true )
                return cystPos:GetDistance(powerPos) < 15 or cystPos:GetDistance(marine:GetOrigin()) < 5
            else
                return cyst.entity:GetOrigin():GetDistance(marine:GetOrigin()) < 15
            end

        end)
            
    s:Add("comPingElapsed", function(db, marine)

            local pingTime = GetGamerules():GetTeam(marine:GetTeamNumber()):GetCommanderPingTime()

            if pingTime > 0 and pingTime ~= nil and pingTime < Shared.GetTime() then
                return Shared.GetTime() - pingTime
            else
                return nil
            end

            end)

    s:Add("comPingPosition", function(db, marine)
            
            local rawPos = GetGamerules():GetTeam(marine:GetTeamNumber()):GetCommanderPingPosition()
            -- the position is usually up in the air somewhere, so pretend we did a commander pick to put it somewhere sensible
            local trace = GetCommanderPickTarget(
                marine, -- not right, but whatever
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

    return s

end