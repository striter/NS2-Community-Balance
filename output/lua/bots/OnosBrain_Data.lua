
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local kOnosBrainPheromoneWeights = {
    [kTechId.ThreatMarker] = 5.0,
    [kTechId.ExpandingMarker] = 2.0
}

local kOnosBrainRetreatHealthStart = 0.65
local kOnosBrainRetreatHealthStop = 0.90

local kOnosBrainChargeStart = 0.85
local kOnosBrainChargeStop = 0.55

local kOnosBrainActionTypesOrderScale = 10
local kOnosBrainActionTypes = enum({
    "Retreat",
    "Attack",
    "Order",
    "Evolve",
    "Pheromone",
    "Explore"
})

local function GetOnosActionBaselineWeight( actionId )
    assert(kOnosBrainActionTypes[kOnosBrainActionTypes[actionId]], "Error: Invalid OnosBrain action-id passed")

    local totalActions = #kOnosBrainActionTypes
    local actionOrderId = kOnosBrainActionTypes[kOnosBrainActionTypes[actionId]] --numeric index, not string

    --invert numeric index value and scale, the results in lower value, the higher the index. Which means
    --the Enum of actions is shown and used in a natural order (i.e. order of enum value declaration IS the priority)
    local actionWeightOrder = totalActions - (actionOrderId - 1)

    --final action base-line weight value
    return actionWeightOrder * kOnosBrainActionTypesOrderScale
end

local kBotStompRange = 12 -- Its really more like 16-17 but this is for feel\

-- Return an estimate of how well this bot is able to respond to a target based on its distance
-- from the target. Linearly decreates from 1.0 at 30 distance
local function EstimateOnosResponseUtility(onos, target)
    PROFILE("OnosBrain - EstimateOnosResponseUtility")

    local mloc = onos:GetLocationName()
    local tloc = target:GetLocationName()

    if mloc == tloc then
        return 1.0
    end

    local dist = GetTunnelDistanceForAlien(onos, target)
    return Clamp(1.0 - ( ( dist - 30.0 ) / 40.0 ), 0.0, 1.0)
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
    local isInCombat = (player.GetIsInCombat and player:GetIsInCombat())

    -- Don't calculate tunnel distance for every single target memory, gets very expensive very quickly
    --local dist = select(2, GetTunnelDistanceForAlien(player, target))
    local dist = player:GetOrigin():GetDistance(target:GetOrigin())

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
            [kMinimapBlipType.Marine]        = numOthers >= 2 and 0.1 or 6.0,
            [kMinimapBlipType.Exo]           = numOthers >= 4 and 0.1 or 5.0,
            [kMinimapBlipType.JetpackMarine] = numOthers >= 1 and 0.1 or 4.0,
            [kMinimapBlipType.Sentry]        = numOthers >= 3 and 0.1 or 3.0
        }
        
        return activeUrgencies
    end

    -- Optimization: we only need to do visibilty check if the entity type is active
    -- So get the table first with 0 others
    local urgTable = EvalActiveUrgenciesTable(0)

    if urgTable[ mem.btype ] then

        -- For nearby active threads, respond no matter what - regardless of how many others are around
        if dist < 15 then
            numOthers = 0
        end

        if isInCombat then
            closeBonus = closeBonus * 3
        end
        
        urgTable = EvalActiveUrgenciesTable(numOthers)
        return urgTable[ mem.btype ] + closeBonus

    end
    
    return nil

end

local function SwitchToGore(onos)
    if not onos then return end

    if onos:GetWeapon(Gore.kMapName) then
        return onos:SetActiveWeapon(Gore.kMapName, true)
    end

    return false
end

local function SwitchToBoneShield(onos)
    if not onos then return end

    if onos:GetWeapon(BoneShield.kMapName) then
        return onos:SetActiveWeapon(BoneShield.kMapName, true)
    end

    return false
end

local function PerformMove( alienPos, targetPos, bot, brain, move, inRetreat )

    local postIgnore, targetDist, targetMove, entranceTunel = HandleAlienTunnelMove( alienPos, targetPos, bot, brain, move )
    if postIgnore then return end -- We are waiting for a tunnel pass-through, which requires staying still

    local onos = brain.player
    local energy = onos:GetEnergy() / onos:GetMaxEnergy()

    -- Put extra stuff like crouch-move etc here

    -- Charge forwards if we have the energy

    ---@type BotMotion
    local motion = bot:GetMotion()
    local viewDir = GetNormalizedVectorXZ(onos:GetViewCoords().zAxis)
    local similarity = GetNormalizedVectorXZ(motion.currMoveDir):DotProduct(viewDir)

    -- Evaluate the current path and only charge forwards if we're moving in mostly a straight line
    -- (The bot motion will "cheat" otherwise and allow itself to turn while charging)
    if motion.currPathPoints and #motion.currPathPoints > 0 then

        local nextPathIndex = motion:ComputeNextPathPointIndex(onos:GetOrigin(), motion.currPathPointsIt, 4)
        local lastPoint = onos:GetOrigin()

        for i = motion.currPathPointsIt, nextPathIndex do
            similarity = similarity * GetNormalizedVectorXZ(motion.currPathPoints[i] - lastPoint):DotProduct(viewDir)
        end

    end

    local shouldCharge = (energy > kOnosBrainChargeStart or brain.lastIsCharging and energy > kOnosBrainChargeStop)

    if inRetreat then
    -- hammer the sprint key while retreating (ignore energy limits)
        shouldCharge = (energy > 0.2 or brain.lastIsCharging and energy > 0.05)
    end

    if not brain.lastIsStomping and shouldCharge and similarity > 0.9 then
        brain.lastIsCharging = true
        move.commands = AddMoveCommand(move.commands, Move.MovementModifier)
    else
        brain.lastIsCharging = false
    end

end

local function PerformAttackEntity( eyePos, bestTarget, bot, brain, move )

    assert( bestTarget )

    local marinePos = bestTarget:GetOrigin()

    local doFire = false

    local sdb = brain:GetSenses()
    local onosPlayer = bot:GetPlayer()
    local hiveData = sdb:Get("nearestHive")

    PerformMove(eyePos, marinePos, bot, brain, move)

    local goreWeapon = onosPlayer:GetWeapon(Gore.kMapName)
    local hasStomp =
            goreWeapon ~= nil and
            goreWeapon:GetSecondaryTechId() == kTechId.Stomp and
            goreWeapon:GetHasSecondary(onosPlayer)

    local distance = GetDistanceToTouch(eyePos, bestTarget)
    if distance < 4 then

        SwitchToGore(onosPlayer, brain) 
        -- jitter view target a little bit
        -- local jitter = Vector( math.random(), math.random(), math.random() ) * 0.1
        bot:GetMotion():SetDesiredViewTarget( bestTarget:GetEngagementPoint() )
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )

        if distance < 1 then
            -- Stop running at the structure when close enough
            bot:GetMotion():SetDesiredMoveTarget(nil)
        end
        
    else
    
        bot:GetMotion():SetDesiredViewTarget( nil )

        local tNow = Shared.GetTime()
        local isStomping = hasStomp and goreWeapon:GetIsStomping()
        if brain.lastIsStomping and brain.lastIsStomping ~= isStomping then
            --brain.wantsToStomp = false --Orginal = false (fehler der mit der zeit bewirkt das der onos nicht mehr kämpfen kann und in seiner stomp animation festhängt, wenn auf false) bot kann sich selbst debuggen wenn der fehler autritt (SwitchToBoneShield) /false bezieht sich nur auf den code if not brain.wantsToStomp wenn er aktiv ist.  
        end

        brain.lastIsStomping = isStomping

        local targetIsStompable = onosPlayer:GetEnergy() > kStompEnergyCost and
            HasMixin(bestTarget, "Stun") and not bestTarget:GetIsStunned() and
            distance <= kBotStompRange and
            (not bestTarget:isa("JetpackMarine") or bestTarget:GetIsOnGround())

        if tNow - onosPlayer:GetTimeLastDamageTaken() < 1 and SwitchToBoneShield(onosPlayer, brain) then
            move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )--]]
        elseif hasStomp and
                ( ( tNow - brain.timeLastStomp > 6 ) or (brain.wantsToStomp) ) and
                targetIsStompable then

            local isStompEquipped = hasStomp and goreWeapon:GetIsActive()
            local viewDirection = GetNormalizedVectorXZ( onosPlayer:GetViewCoords().zAxis )
            local targetDirection = GetNormalizedVector( bestTarget:GetOrigin() - onosPlayer:GetOrigin() )

            -- a dot product with normalized vectors just turns into a cos of the angle between them
            -- using form |A||B|cos(t)
            local xzCos = viewDirection:DotProduct( targetDirection)
            if xzCos >= 0.9 and isStompEquipped then
                move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
                brain.timeLastStomp = tNow
                --brain.wantsToStomp = true
            else
                SwitchToGore(onosPlayer, brain)
            end

        -- elseif distance < 15 and distance > 5 then
        --     move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
        end
   
    end

end

local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        PerformAttackEntity( eyePos, target, bot, brain, move )
         local chatMsg =  bot:SendTeamMessage( "Stomp and crush TSF! " .. target:GetMapName() .. " in " .. target:GetLocationName() )
            bot:SendTeamMessage(chatMsg, 60)

    else
    
        -- mem is too far to be relevant, so move towards it
        bot:GetMotion():SetDesiredViewTarget(nil)
        PerformMove(eyePos, mem.lastSeenPos, bot, brain, move)

    end
    
    brain.teamBrain:AssignBotToMemory(bot, mem)

end

local kValidateOnosRetreat = function(bot, brain, onos, action)
    if not IsValid(action.hive) or not action.hive:GetIsAlive() then
        return false
    end

    return true
end

local kExecOnosRetreat = function(move, bot, brain, onos, action)

    local hive = action.hive

    -- we are retreating, unassign ourselves from anything else, e.g. attack targets
    brain.teamBrain:UnassignBot(bot)

    local touchDist = GetDistanceToTouch( onos:GetEyePos(), hive )
    if touchDist > Hive.kHealRadius * 0.5 then
        bot:GetMotion():SetDesiredViewTarget( nil )
        PerformMove(onos:GetEyePos(), hive:GetEngagementPoint(), bot, brain, move, true)
    else
        if onos:GetIsUnderFire() and hive:GetIsAlive() then
            -- If under attack, we want to move away to other side of Hive
            local damageOrigin = onos:GetLastTakenDamageOrigin()
            local hiveOrigin = hive:GetEngagementPoint()
            local retreatDir = (hiveOrigin - damageOrigin):GetUnit()
            local _, max = hive:GetModelExtents()
            local retreatPos = hiveOrigin + (retreatDir * max.x)

            bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
            PerformMove(onos:GetEyePos(), retreatPos, bot, brain, move)

        else
            -- We're safe, just sit still
            bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveTarget( nil )
        end
    end

    if onos:GetHealthScalar() > kOnosBrainRetreatHealthStop then
        return kPlayerObjectiveComplete
    end

end

local kOnosBrainObjectiveTypes = enum({
    "Retreat",
    "RespondToThreat",
    "Evolve",
    "Pheromone",
    "GoToCommPing",
    "Explore"
})

local OnosObjectiveWeights = MakeBotActionWeights(kOnosBrainObjectiveTypes, 100)

kOnosBrainObjectives =
{

    ------------------------------------------
    -- Retreat
    ------------------------------------------
    function(bot, brain)
        PROFILE("OnosBrain_Data:retreat")
        local name, weight = OnosObjectiveWeights:Get(kOnosBrainObjectiveTypes.Retreat)
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

        if not hive or healthFraction > kOnosBrainRetreatHealthStart then
            return kNilAction
        end

        return {
            name = name,
            weight = weight,
            hive = hive,
            validate = kValidateOnosRetreat,
            perform = kExecOnosRetreat
        }

    end,

    CreateAlienRespondToThreatAction(OnosObjectiveWeights, kOnosBrainObjectiveTypes.RespondToThreat, PerformMove),

    ------------------------------------------
    -- Evolve
    ------------------------------------------
    CreateAlienEvolveAction(OnosObjectiveWeights, kOnosBrainObjectiveTypes.Evolve, kTechId.Onos),

    ------------------------------------------
    -- Pheromone (Alien waypoints)
    ------------------------------------------
    CreateAlienPheromoneAction(OnosObjectiveWeights, kOnosBrainObjectiveTypes.Pheromone, kOnosBrainPheromoneWeights, PerformMove),

    ------------------------------------------
    -- Explore
    ------------------------------------------
    CreateExploreAction( OnosObjectiveWeights:GetWeight(kOnosBrainObjectiveTypes.Explore),
        function(pos, targetPos, bot, brain, move)
            bot:GetMotion():SetDesiredViewTarget(nil)
            PerformMove(pos, targetPos, bot, brain, move)
        end ),
}

local kExecAttackAction = function(move, bot, brain, onos, action)
    brain.teamBrain:UnassignBot(bot)
    PerformAttack( onos:GetEyePos(), action.bestMem, bot, brain, move )
end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------
kOnosBrainActions =
{
    
    ------------------------------------------
    -- Debug Idle
    ------------------------------------------
    -- function(bot, brain)
    --     return { name = "debug idle", weight = 0.001,
    --             perform = function(move)
    --                 bot:GetMotion():SetDesiredMoveTarget(nil)
    --                 -- there is nothing obvious to do.. figure something out
    --                 -- like go to the marines, or defend
    --             end }
    -- end,

    ------------------------------------------
    -- Attack
    ------------------------------------------
    function(bot, brain)
        PROFILE("OnosBrain_Data:attack")
        local name = "attack"
        local onos = bot:GetPlayer()
        
        local memories = GetTeamMemories(onos:GetTeamNumber())
        local bestUrgency, bestMem = GetMaxTableEntry( memories, 
                function( mem )
                    return GetAttackUrgency( bot, mem )
                end)

        local weapon = onos:GetActiveWeapon()
        local eHP = onos:GetHealthScalar()
        local weight = 0.0

        if bestMem ~= nil then

            local target = Shared.GetEntity(bestMem.entId)
            local dist = select(2, GetTunnelDistanceForAlien(onos, target or bestMem.lastSeenPos))
            
            if dist <= 50 and eHP > kOnosBrainRetreatHealthStop then
            -- don't attack if we're at low health
                weight = GetOnosActionBaselineWeight(kOnosBrainActionTypes.Attack)
            elseif (dist <= 6 or dist <= 20 and bestMem.threat >= 1.9) and eHP > kOnosBrainRetreatHealthStart then
                -- deal with the immediate threat and get out
                weight = GetOnosActionBaselineWeight(kOnosBrainActionTypes.Attack)
            elseif dist <= 2 and eHP > 0.45 then
                -- finish killing the marine we're right next to and then run
                -- (e.g. marine between us and the hive / body blocking)
                weight = GetOnosActionBaselineWeight(kOnosBrainActionTypes.Attack)
            end

        end

        return {
            name = name,
            weight = weight,
            fastUpdate = true,
            bestMem = bestMem,
            perform = kExecAttackAction
        }
    end,

}

------------------------------------------
--
------------------------------------------
function CreateOnosBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("allThreats", function(db, onos)
            local team = onos:GetTeamNumber()
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

    s:Add("nearestThreat", function(db, onos)
            local allThreats = db:Get("allThreats")
            
            local distance, nearestThreat = GetMinTableEntry( allThreats,
                function( mem )
                    local origin = mem.origin
                    local target = Shared.GetEntity(mem.entId)
                    if origin == nil then
                        origin = target:GetOrigin()
                    end
                    return select(2, GetTunnelDistanceForAlien(onos, target or origin))
                end)

            return {distance = distance, memory = nearestThreat}
        end)

    s:Add("nearestHive", function(db, onos)

            local hives = GetEntitiesForTeam( "Hive", onos:GetTeamNumber() )

            local dist, hive = GetMinTableEntry( hives,
                function(hive)
                    if hive:GetIsBuilt() then
                        return select(2, GetTunnelDistanceForAlien(onos, hive))
                    end
                end)

            return {entity = hive, distance = dist}
        end)

    CreateAlienThreatSense(s, EstimateOnosResponseUtility)

    CreateAlienCommPingSense(s)

    return s
end
