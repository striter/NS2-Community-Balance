
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local kFadeBrainActionTypesOrderScale = 10
local kFadeBrainObjectiveTypesOrderScale = 100

-- Combat conditions under which we should retreat from the engagement and regain health/energy
local kFadeBrainHealthRetreatStart = 0.55
local kFadeBrainHealthRetreatStop = 0.95

local kFadeBrainEnergyRetreatStart = 0.3
local kFadeBrainEnergyRetreatStop = 0.9

-- If retreating from danger, try to go back to the hive for at least this much time
local kFadeRetreatMinTime = 10.0

local kFadeRequiredEnergyBlinkCombat = kStartBlinkEnergyCost * 6
local kFadeBlinkSequenceJumps = 2

local kFadeAttackRange = 2.4

local kFadeBrainPheromoneWeights = 
{
    [kTechId.ThreatMarker] = 3.0,
    [kTechId.ExpandingMarker] = 1.0,
}

local kFadeRetreatType = enum({
    "Health",
    "Energy",
    "Danger"
})

local kFadeBrainActionTypes = enum({
    "Retreat",
    "Attack",
    "DefendHive", -- Want to retreat, but should defend hive instead.
    "Order",
    "Evolve",
    "Pheromone",
    "Explore"
})

local function GetFadeActionBaselineWeight( actionId )
    assert(kFadeBrainActionTypes[kFadeBrainActionTypes[actionId]], "Error: Invalid OnosBrain action-id passed")

    local totalActions = #kFadeBrainActionTypes
    local actionOrderId = kFadeBrainActionTypes[kFadeBrainActionTypes[actionId]] --numeric index, not string

    --invert numeric index value and scale, the results in lower value, the higher the index. Which means
    --the Enum of actions is shown and used in a natural order (i.e. order of enum value declaration IS the priority)
    local actionWeightOrder = totalActions - (actionOrderId - 1)

    --final action base-line weight value
    return actionWeightOrder * kFadeBrainActionTypesOrderScale
end

-- Return an estimate of how well this bot is able to respond to a target based on its distance
-- from the target. Linearly decreates from 1.0 at 30 distance to 0.0 at 150 distance
local function EstimateFadeResponseUtility(fade, target)
    PROFILE("FadeBrain - EstimateFadeResponseUtility")

    local mloc = fade:GetLocationName()
    local tloc = target:GetLocationName()

    if mloc == tloc then
        return 1.0
    end

    local dist = GetTunnelDistanceForAlien(fade, target)
    return Clamp(1.0 - ( ( dist - 30.0 ) / 60.0 ), 0.0, 1.0)
end

local function PerformMove( alienPos, targetPos, bot, brain, move )

    local postIgnore, targetDist, targetMove, entranceTunel = HandleAlienTunnelMove( alienPos, targetPos, bot, brain, move )
    if postIgnore then 
    -- We are waiting for a tunnel pass-through, which requires staying still
        return 
    end

    GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "BlinkSeq", ToString(brain.blinkSequenceActive))
    GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "BlinkJumpTk", ToString(brain.blinkJumpTick))

    local fade = bot:GetPlayer()

    if fade and not fade:GetIsAlive() then
        return
    end

    local desiredDiff = (targetPos - alienPos)
    local time = Shared.GetTime()
    local curEng = fade:GetEnergy()
    local minBlinkEng = kStartBlinkEnergyCost * 3 --increase so we don't over-consume energy
    local fadeUnitVel = fade:GetVelocity():GetUnit()
    local fadePerctMaxSpeed = fade:GetVelocity():GetLength() / fade:GetMaxSpeed()
    local desiredDot = Math.DotProduct(fadeUnitVel, desiredDiff:GetUnit())


    --Handle movement sequence Blink -> Jump -> Jump -> Blink
    if brain.blinkSequenceActive and brain.blinkJumpTick >= kFadeBlinkSequenceJumps then
        brain:ResetBlinkSequence()
    end

    local canBlink = brain.blinkJumpTick == 0 and brain.blinkSequenceActive == false and not fade:GetIsBlinking()

    if canBlink then

        brain.blinkSequenceActive = true
        brain.timeOfBlink = time
        move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )

    elseif brain.onLandedTrigger and brain.blinkSequenceActive then --FIXME This might not be triggering consistently...

        move.commands = AddMoveCommand( move.commands, Move.Jump )
        brain.timeOfJump = time

        brain.blinkJumpTick = brain.blinkJumpTick + 1
        brain.onLandedTrigger = false

    else
    --fail-over state in case onLandedTrigger gets out of sync while blinkSequenceActive
        move.commands = AddMoveCommand( move.commands, Move.Jump )
        brain.timeOfJump = time

        if fade:GetIsOnGround() then -- assume we're in some jump-locked state
            brain:ResetBlinkSequence()
        end

    end

    local canMetab =
        not fade:GetIsBlinking() and brain.timeOfMetab < time and
        (
            curEng / fade:GetMaxEnergy() <= 0.85 or fade:GetHealthScalar() < 1
        )

    --Trigger Metab is available and we need it
    if canMetab then
        move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
        brain.timeOfMetab = time + kMetabolizeDelay * 2
    end

end

local function GetAttackUrgency( bot, mem )

    -- See if we know whether if it is alive or not
    local ent = Shared.GetEntity(mem.entId)
    if (not HasMixin(ent, "Live") or not ent:GetIsAlive()) or (ent.GetTeamNumber and ent:GetTeamNumber() == bot:GetTeamNumber()) then
        return nil
    end

    local botPos = bot:GetPlayer():GetOrigin()
    local targetPos = ent:GetOrigin()

    -- Don't calculate tunnel distance for every single target memory, gets very expensive very quickly
    -- local distance = select(2, GetTunnelDistanceForAlien(bot:GetPlayer(), ent))
    local distance = botPos:GetDistance(targetPos)

    local immediateThreats = 
    {
        [kMinimapBlipType.Marine] = true,
        [kMinimapBlipType.JetpackMarine] = true,
        [kMinimapBlipType.Exo] = true,
    }

    if distance < 15 and immediateThreats[mem.btype] then
        -- Attack the nearest immediate threat (urgency will be 1.1 - 2)
        return 1 + 1 / math.max(distance, 1)
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
    local urgencies = 
    {
        [kMinimapBlipType.Marine] =             numOthers >= 2 and 0.6 or 1,
        [kMinimapBlipType.JetpackMarine] =      numOthers >= 2 and 0.7 or 1.1,
        [kMinimapBlipType.Exo] =                numOthers >= 2 and 0.8 or 1.2,

        [kMinimapBlipType.Sentry] =             numOthers >= 2 and 0.5 or 0.95,
        [kMinimapBlipType.ARC] =                numOthers >= 1 and 0.4 or 0.9,
        [kMinimapBlipType.CommandStation] =     numOthers >= 2 and 0.3 or 0.75,
        [kMinimapBlipType.PhaseGate] =          numOthers >= 1 and 0.2 or 0.9,
        [kMinimapBlipType.Observatory] =        numOthers >= 1 and 0.2 or 0.8,
        [kMinimapBlipType.Extractor] =          numOthers >= 1 and 0.2 or 0.7,
        [kMinimapBlipType.InfantryPortal] =     numOthers >= 1 and 0.2 or 0.6,
    }

    if urgencies[ mem.btype ] ~= nil then
        return urgencies[ mem.btype ]
    end

    return nil

end

local function PerformAttackEntity( eyePos, bestTarget, bot, brain, move )

    assert( bestTarget )

    GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Target", ToString(bestTarget))

    local aimPos = GetBestAimPoint( bestTarget )
    local fade = bot:GetPlayer()
    local curEng = fade:GetEnergy() / fade:GetMaxEnergy()
    local doFire = false
    local time = Shared.GetTime()
    local isDodgeable = bestTarget:isa("Player")
    local dist = select(2, GetTunnelDistanceForAlien(fade, bestTarget))
    local hasClearShot = dist < 15.0 and bot:GetBotCanSeeTarget( bestTarget )

    --fuzzy range, to allow self+targ move to potentially get hit in range (plus latency, etc.)
    if dist <= kFadeAttackRange + math.random(0.05, 0.125) then
        doFire = true
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack ) -- hinzugef�gt f�r mehr Trefferchancen....
    end

    local idealMoveTo = GetPositionBehindTarget( fade, bestTarget, kFadeAttackRange )

    if bot.aim then
        doFire = doFire and bot.aim:UpdateAim(bestTarget, aimPos, kBotAccWeaponGroup.Swipe)
    end

    --TODO Rand "blink-behind" chance? Above? Just bail? ...hmm, options

    if doFire then

        if isDodgeable then

            --adjust starfe target to ensure it's always in direction of behind our target
            local strafeTarg = 
                IsPointInCone( aimPos, eyePos, fade:GetViewAngles():GetCoords().zAxis, math.rad(55) ) and
                idealMoveTo or aimPos

            local strafeTarget = (eyePos - aimPos):CrossProduct(Vector(0,1,0))      --clamp to X interval (e.g. strage left at least Y time?)
            strafeTarget:Normalize()
        
            -- numbers chosen arbitrarily to give some appearance of random juking
            strafeTarget = strafeTarget * ConditionalValue( math.sin(time * 3.5 ) + math.sin(time * 4.5 ) > 0 , -1, 1)

            if strafeTarget:GetLengthSquared() > 0 then
                bot:GetMotion():SetDesiredMoveDirection(strafeTarget)
            end

        else

            if dist < kFadeAttackRange * 0.915 then
            -- Stop running at the structure when close enough
                bot:GetMotion():SetDesiredMoveTarget(nil)
                move.commands = RemoveMoveCommand( move.commands, Move.Jump )
                move.commands = RemoveMoveCommand( move.commands, Move.SecondaryAttack )
            end

        end

        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )

    else
    --FIXME This won't do any dodge of any sort, need another layer (is in sight / not seen, etc.)
        
        if idealMoveTo then
            PerformMove(eyePos, idealMoveTo, bot, brain, move)
        else
            PerformMove(eyePos, bestTarget:GetOrigin(), bot, brain, move)
        end

    end
    
end

local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        PerformAttackEntity( eyePos, target, bot, brain, move )
         --local chatMsg =  bot:SendTeamMessage( "Blink and slash marines! " .. target:GetMapName() .. " in " .. target:GetLocationName() )
         --   bot:SendTeamMessage(chatMsg, 60)

    else
    
        -- mem is too far to be relevant, so move towards it
        PerformMove(eyePos, mem.lastSeenPos, bot, brain, move)

    end
    
    brain.teamBrain:AssignBotToMemory(bot, mem)

end

------------------------------------------
-- Fade Brain Objective Validators
------------------------------------------

local kValidateFadeRetreat = function(bot, brain, fade, action)
    if not IsValid(action.hive) or not action.hive:GetIsAlive() then
        return false
    end

    if fade:GetHealthScalar() >= kFadeBrainHealthRetreatStop and ( fade:GetEnergy() / fade:GetMaxEnergy() >= kFadeBrainEnergyRetreatStop ) then
        return false
    end

    return true
end

------------------------------------------
-- Fade Brain Objective Executors
------------------------------------------

local kExecFadeRetreat = function(move, bot, brain, fade, action)

    local hive = action.hive

    local inCombat = fade:GetIsInCombat()
    local eHP = fade:GetHealthScalar()
    local energy = fade:GetEnergy() / fade:GetMaxEnergy()

    -- we are retreating, unassign ourselves from anything else, e.g. attack targets
    brain.teamBrain:UnassignBot(bot)

    local touchDist = GetDistanceToTouch( fade:GetEyePos(), hive )

    if touchDist > 3.25 or inCombat then
    
        local jitter = Vector(math.random()-0.5, math.random()-0.5, math.random()-0.5) * 3
        PerformMove(fade:GetEyePos(), hive:GetEngagementPoint() + jitter, bot, brain, move)
        
    else
        if fade:GetIsUnderFire() then
            -- If under attack, we want to move away to other side of Hive
            local damageOrigin = fade:GetLastTakenDamageOrigin()
            local hiveOrigin = hive:GetEngagementPoint()
            local retreatDir = (hiveOrigin - damageOrigin):GetUnit()
            local _, max = hive:GetModelExtents()
            local retreatPos = hiveOrigin + (retreatDir * max.x)
            bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveTarget( retreatPos )

        else
            -- We're safe, just sit still
            bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveTarget( nil )
        end
    end

    local hasEnergy = energy > kFadeBrainEnergyRetreatStop
    local hasHealth = eHP > kFadeBrainHealthRetreatStop
    local timeSinceRetreat = (Shared.GetTime() - action.retreatStart)

    -- Finish retreating once we're fully healed and have energy again
    if action.retreatType == kFadeRetreatType.Health and hasHealth and hasEnergy then
        return kPlayerObjectiveComplete

    elseif action.retreatType == kFadeRetreatType.Energy and hasEnergy then
        return kPlayerObjectiveComplete

    elseif action.retreatType == kFadeRetreatType.Danger and not fade:GetIsInCombat() and timeSinceRetreat > kFadeRetreatMinTime then
        return kPlayerObjectiveComplete

    end

end

------------------------------------------
-- Fade Brain Objectives
------------------------------------------

local kFadeBrainObjectiveTypes = enum({
    "Retreat",
    "RespondToThreat",
    "Evolve",
    "GoToCommPing",
    "Pheromone",
    "Explore"
})

local FadeObjectiveWeights = MakeBotActionWeights(kFadeBrainObjectiveTypes, kFadeBrainObjectiveTypesOrderScale)

kFadeBrainObjectives =
{

    ------------------------------------------
    -- RespondToThreat
    ------------------------------------------
    CreateAlienRespondToThreatAction(FadeObjectiveWeights, kFadeBrainObjectiveTypes.RespondToThreat, PerformMove),

    ------------------------------------------
    -- Retreat
    ------------------------------------------
    function(bot, brain, fade)
        PROFILE("FadeBrain_Data:retreat")

        local name, weight = FadeObjectiveWeights:Get(kFadeBrainObjectiveTypes.Retreat)
        local sdb = brain:GetSenses()

        -- hallucinations don't retreat
        if fade.isHallucination then
            return kNilAction
        end

        local hiveData = sdb:Get("nearestHive")
        local hive = hiveData.hive
        local hiveDist = hiveData.distance or 0

        if not hive then
            return kNilAction
        end

        local retreatInfo = sdb:Get("retreatThreshold")

        -- Don't retreat if we have enough stores of HP and energy to continue fighting
        if not retreatInfo.retreat then
            return kNilAction
        end

        if brain.blinkSequenceActive then
        --ensure we can trigger blink immediately
            brain:ResetBlinkSequence()
        end

        return
        {
            name = name,
            weight = weight,
            hive = hive,
            retreatType = retreatInfo.type,
            retreatStart = Shared.GetTime(),
            validate = kValidateFadeRetreat,
            perform = kExecFadeRetreat
        }

    end,

    ------------------------------------------
    -- Evolve
    ------------------------------------------
    CreateAlienEvolveAction(FadeObjectiveWeights, kFadeBrainObjectiveTypes.Evolve, kTechId.Fade),

    ------------------------------------------
    -- Pheromone
    ------------------------------------------
    CreateAlienPheromoneAction(FadeObjectiveWeights, kFadeBrainObjectiveTypes.Pheromone, kFadeBrainPheromoneWeights, PerformMove),

    ------------------------------------------
    -- Comm Ping
    ------------------------------------------
    CreateAlienGoToCommPingAction(FadeObjectiveWeights, kFadeBrainObjectiveTypes.GoToCommPing, PerformMove),

    ------------------------------------------
    -- Explore
    ------------------------------------------
    CreateExploreAction( FadeObjectiveWeights:GetWeight(kFadeBrainObjectiveTypes.Explore),
        function(pos, targetPos, bot, brain, move)
            PerformMove(bot:GetPlayer():GetEyePos(),targetPos, bot, brain, move)
        end),

    
}

local kExecAttackAction = function(move, bot, brain, fade, action)
    brain.teamBrain:UnassignBot(bot)
    PerformAttack( fade:GetEyePos(), action.bestMem, bot, brain, move )
end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------
kFadeBrainActions =
{

    ------------------------------------------
    -- Debug Idle
    ------------------------------------------
    --[[
    function(bot, brain)
        return { name = "debug idle", weight = 0.001,
                perform = function(move)
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                    -- there is nothing obvious to do.. figure something out
                    -- like go to the marines, or defend
                end }
    end,
    --]]


    ------------------------------------------
    -- Attack
    ------------------------------------------
    function(bot, brain, fade)
        PROFILE("FadeBrain_Data:attack")
        local name = "attack"

        local memories = GetTeamMemories(bot:GetTeamNumber())
        local bestUrgency, bestMem = 
            GetMaxTableEntry( memories, 
                function( mem )
                    return GetAttackUrgency( bot, mem )
                end
            )

        local weapon = fade:GetActiveWeapon()
        local canAttack = weapon ~= nil and weapon:isa("SwipeBlink")

        local eHP = fade:GetHealthScalar()
        local energy = fade:GetEnergy() / fade:GetMaxEnergy()

        canAttack = canAttack and (not brain:GetSenses():Get("retreatThreshold").retreat)
            -- and not fade:GetIsUnderFire() -- BOT-TODO: do we need to wait to retreat until we're no longer under fire?

        local weight = 0.0

        if canAttack and bestMem ~= nil then

            local dist = select(2, GetTunnelDistanceForAlien(fade, bestMem.lastSeenPos))

            if dist <= 50 and eHP > kFadeBrainHealthRetreatStop then
                weight = GetFadeActionBaselineWeight(kFadeBrainActionTypes.Attack)
            elseif dist <= 15 then
                weight = GetFadeActionBaselineWeight(kFadeBrainActionTypes.Attack)
            end
        end

        return 
        {
            name = name,
            weight = weight,
            bestMem = bestMem,
            fastUpdate = true,
            perform = kExecAttackAction
        }
    end,

    CreateAlienInterruptAction(),

}


function CreateFadeBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("allThreats",
        function(db, player)
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

    s:Add("nearestThreat",
        function(db, player)
            local allThreats = db:Get("allThreats")

            local distance, nearestThreat = GetMinTableEntry( allThreats,
                function( mem )
                    local origin = mem.origin
                    local targetEnt = Shared.GetEntity(mem.entId)
                    if targetEnt == nil then
                        origin = targetEnt:GetOrigin()
                    end
                    return select(2, GetTunnelDistanceForAlien(player, targetEnt or origin))
                end)

            return {distance = distance, memory = nearestThreat}
        end)

    s:Add("nearestHive",
    function(db, player)
        local hives = GetEntitiesForTeam("Hive", player:GetTeamNumber())

        local nearestDistance, nearestHive = GetMinTableEntry( hives,
            function( hive )
                if not hive:GetIsBuilt() or not hive:GetIsAlive() then return end
                return select(2, GetTunnelDistanceForAlien(player, hive))
            end)

        return { distance = nearestDistance, hive = nearestHive }
    end)

    s:Add("retreatThreshold",
        function(db, fade)

            local eHP = fade:GetHealthScalar()
            local energy = fade:GetEnergy() / fade:GetMaxEnergy()
            local friendlyBalance = 0
            local inCombat = fade.GetIsInCombat and fade:GetIsInCombat()

            local locGroup = GetLocationContention():GetLocationGroup(fade:GetLocationName())
            if locGroup then
                friendlyBalance = locGroup:GetNumAlienPlayers() - locGroup:GetNumMarinePlayers()
            end

            if eHP < kFadeBrainHealthRetreatStart then
                return { retreat = true, type = kFadeRetreatType.Health }
            elseif friendlyBalance <= -2 then
                return { retreat = true, type = kFadeRetreatType.Danger }
            elseif inCombat and energy < kFadeBrainEnergyRetreatStart then
                return { retreat = true, type = kFadeRetreatType.Energy }
            end

            return { retreat = false, type = nil }

        end)

    CreateAlienThreatSense(s, EstimateFadeResponseUtility)

    CreateAlienCommPingSense(s)

    return s
end
