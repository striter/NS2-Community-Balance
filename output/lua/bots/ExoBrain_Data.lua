Script.Load("lua/bots/BotDebug.lua")
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")
Script.Load("lua/bots/BotAim.lua")

local gMarineAimJitterAmount = 0.8

local kExoBrainRetreatHealth = 0.6
local kMarineBrainNearbyEnemyThreshold = 25

------------------------------------------
--  Handles things like using phase gates
------------------------------------------
local function PerformMove( marinePos, targetPos, bot, brain, move )

    bot:GetMotion():SetDesiredMoveTarget( targetPos )
    bot:GetMotion():SetDesiredViewTarget( nil )
    
end

------------------------------------------
--
------------------------------------------

-- BOT-FIXME: unused? Do we need to track weapon heat at this level?
--[[
local function GetCanAttack(marine)
    local weaponHolder = marine:GetActiveWeapon()
    if weaponHolder ~= nil then
      
        local leftWeapon = weaponHolder:GetLeftSlotWeapon()
        local rightWeapon = weaponHolder:GetRightSlotWeapon()
        
        if leftWeapon:isa("Minigun") and not leftWeapon.overheated and rightWeapon:isa("Minigun") and not rightWeapon.overheated then
            return true
		elseif leftWeapon:isa("Railgun") and rightWeapon:isa("Railgun") then
			return true
        else
            return false
        end
        
    else
        return false
    end
end
--]]

local function ArcHasActiveOrder(arc)
    if not arc or not arc.GetHasOrder then
        return false
    end

    if not arc:GetHasOrder() then
        return false
    end

    if arc.GetOrders then
        local orders = arc:GetOrders()
        if orders and #orders > 0 then
            local order = orders[1]
            if order.move_target then
                return true
            end
        end
    end

    return true
end

local function ArcIsDefended(arc)
    if not IsValid(arc) then return false end

    local team = arc:GetTeamNumber()
    local players = GetEntitiesForTeam("Player", team)

    for _, p in ipairs(players) do
        
        -- Commander hat keine normalen Orders ? ignorieren
        if p:isa("MarineCommander") then
            goto continue_player
        end

        -- Manche Entities haben keine GetCurrentOrder Methode
        if not p.GetCurrentOrder then
            goto continue_player
        end

        local order = p:GetCurrentOrder()
        if order and order:GetType() == kTechId.Defend then

            -- Manche Orders nutzen GetParam(), andere GetTargetId()
            local targetId = order.GetParam and order:GetParam() or order:GetTargetId()

            if targetId == arc:GetId() then
                return true
            end
        end

        ::continue_player::
    end

    return false
end

------------------------------------------
--  Utility perform function used by multiple wants
------------------------------------------
local function PerformAttackEntity( eyePos, target, lastSeenPos, bot, brain, move )

    assert(target ~= nil)

    -- Retreat-Flag MUSS GANZ OBEN DEFINIERT WERDEN
    local retreating = false

    ----------------------------------------------------------------------
    -- Eier niemals beschießen – Exo soll sie nur zertreten
    ----------------------------------------------------------------------
    if target:isa("Egg") or target:isa("Embryo") then

        local eggPos = target:GetOrigin()
        bot:GetMotion():SetDesiredMoveTarget(eggPos)
        bot:GetMotion():SetDesiredViewTarget(nil)
        return
    end

    ----------------------------------------------------------------------
    -- Sicherheitscheck: Ziel muss Sichtbarkeitsfunktion besitzen
    ----------------------------------------------------------------------
    if not target.GetIsSighted then
        Print("attack target has no GetIsSighted: %s", target:GetClassName())
        return
    end

    ----------------------------------------------------------------------
    -- Senses laden (Freunde, Feinde, Health, Armory)
    ----------------------------------------------------------------------
    local sdb = brain:GetSenses()

    local numFriendlies = sdb:Get("nearbyFriendlies") or 0
    local numEnemies = sdb:Get("nearbyEnemies") or 0
    local healthFraction = sdb:Get("healthFraction") or 1

    local nearestArmoryData = sdb:Get("nearestArmory")
    local armory = nearestArmoryData and nearestArmoryData.armory or nil

    ----------------------------------------------------------------------
    -- Dynamische Distanz: Wenn Eier in der Nähe sind ? mehr Bewegungsfreiheit
    ----------------------------------------------------------------------
    local stompEggs = GetEntitiesWithinRange("Egg", eyePos, 25)
    local stompEmbryos = GetEntitiesWithinRange("Embryo", eyePos, 25)

    local stompTargets = {}

    for _, e in ipairs(stompEggs) do table.insert(stompTargets, e) end
    for _, e in ipairs(stompEmbryos) do table.insert(stompTargets, e) end

    local eggsNearby = #stompTargets > 0

    local dynamicCloseDist = eggsNearby and 30 or 10

    ----------------------------------------------------------------------
    -- Egg-Commitment System (NEU)
    ----------------------------------------------------------------------
    bot.stompEggUntil = bot.stompEggUntil or 0

    -- Eier nur stampfen wenn genug Freunde da sind ODER keine Feinde
    local canStompEggs = (numFriendlies > 4 or numEnemies == 0)

    if eggsNearby and canStompEggs then
        bot.stompEggUntil = Shared.GetTime() + 1.0   -- 1 Sekunde Commitment
    end

    local committedToEgg = Shared.GetTime() < bot.stompEggUntil

    ----------------------------------------------------------------------
    -- Zielposition bestimmen
    ----------------------------------------------------------------------
    local sighted = target:GetIsSighted()
    local aimPos = sighted and GetBestAimPoint(target) or lastSeenPos
    local dist = GetDistanceToTouch(eyePos, target)
    local doFire = false

    local hasClearShot = dist < 45.0 and bot:GetBotCanSeeTarget(target)

    ----------------------------------------------------------------------
    -- TAKTISCHES RETREAT
    ----------------------------------------------------------------------
    local tacticalRetreat = false

    if brain.isMinigun then
        tacticalRetreat = (numEnemies > 1 and numFriendlies < 2)
    else
        tacticalRetreat = (numEnemies > 1 and numFriendlies < 3)
    end

    ----------------------------------------------------------------------
    -- Wenn kein klarer Schuss möglich ? weiterlaufen (aber NICHT wenn Ei-Commitment)
    ----------------------------------------------------------------------
    if not hasClearShot and not committedToEgg then
        PerformMove(eyePos, aimPos, bot, brain, move)
        doFire = false

    else
        ------------------------------------------------------------------
        -- Hostile Callout (nur alle 45 Sekunden)
        ------------------------------------------------------------------
        if (not bot.lastHostilesTime or bot.lastHostilesTime < Shared.GetTime() - 45)
        and target:isa("Player") then
            CreateVoiceMessage(bot:GetPlayer(), kVoiceId.MarineHostiles)
            bot.lastHostilesTime = Shared.GetTime()
        end

        ------------------------------------------------------------------
        -- Distanzbasierte Kampfentscheidungen
        ------------------------------------------------------------------
        if dist > 45.0 then
            bot:GetMotion():SetDesiredMoveTarget(aimPos)
            doFire = false

        elseif dist > dynamicCloseDist then
            bot:GetMotion():SetDesiredMoveTarget(aimPos)
            doFire = true

        else
            ------------------------------------------------------------------
            -- Nahkampfbereich: Strafen + Eier zertreten
            ------------------------------------------------------------------
            local myOrigin = eyePos
            local strafeTarget = (myOrigin - aimPos):CrossProduct(Vector(0,1,0))
            strafeTarget:Normalize()

            strafeTarget = strafeTarget * ConditionalValue(
                math.sin(Shared.GetTime() * 3.5) + math.sin(Shared.GetTime() * 2.2) > 0,
                -0.5, 0.5
            )

            local strafePos = strafeTarget + myOrigin
            local pathingPos = Pathing.GetClosestPoint(strafePos)

            -- NEU: Egg-Commitment überschreibt Strafen
           if committedToEgg then
           
           local stompTarget = stompTargets[1]
           
           if stompTarget then
           
           bot:GetMotion():SetDesiredMoveTarget(stompTarget:GetOrigin())
           end


            else
                if strafeTarget:GetLengthSquared() > 0
                and target:isa("Player")
                and (pathingPos - strafePos):GetLength() < 0.2 then
                    bot:GetMotion():SetDesiredMoveTarget(strafeTarget + myOrigin)
                else
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                end
            end

            doFire = true
        end

        ------------------------------------------------------------------
        -- Aiming abhängig von Railgun/Minigun
        ------------------------------------------------------------------
        local aimGroup = brain.isMinigun and kBotAccWeaponGroup.ExoMinigun
                                         or kBotAccWeaponGroup.ExoRailgun

        doFire = doFire and hasClearShot and bot.aim:UpdateAim(target, aimPos, aimGroup)
    end

    ----------------------------------------------------------------------
    -- HEALTH-RETREAT / EXO DROP (inkl. taktisches Retreat)
    ----------------------------------------------------------------------
    dist = GetDistanceToTouch(eyePos, target)

    if armory and (
        healthFraction < kExoBrainRetreatHealth
        or numFriendlies == 0
        or tacticalRetreat
    ) and target:isa("Player") then

        local threatDist = (lastSeenPos - eyePos):GetLengthXZ()
        local touchDist = GetDistanceToTouch(eyePos, armory)

        if touchDist > 2.0 then
            bot:GetMotion():SetDesiredMoveTarget(armory:GetEngagementPoint())

            if threatDist < 15.0 and not doFire then
                bot:GetMotion():SetDesiredViewTarget(lastSeenPos)
            end
        else
            brain.retreatTargetId = nil
            bot:GetMotion():SetDesiredViewTarget(armory:GetEngagementPoint())
            bot:GetMotion():SetDesiredMoveTarget(nil)
            doFire = false

            if healthFraction <= 1.0 and dist <= 20 then
                move.commands = AddMoveCommand(move.commands, Move.Drop)
            end
        end

        retreating = true
    end

    if healthFraction <= 0.05 then
        move.commands = AddMoveCommand(move.commands, Move.Drop)
    end

    ----------------------------------------------------------------------
    -- Feuerlogik
    ----------------------------------------------------------------------
    if doFire or (brain.lastShootingTime and brain.lastShootingTime > Shared.GetTime() - 0.5) then

        local player = bot:GetPlayer()
        local weaponHolder = player:GetActiveWeapon()
        local leftWeapon = weaponHolder:GetLeftSlotWeapon()
        local rightWeapon = weaponHolder:GetRightSlotWeapon()

        if brain.isMinigun then
            if not leftWeapon or not leftWeapon.heatAmount or leftWeapon.heatAmount < 0.95 then
                move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)
            end
            if not rightWeapon or not rightWeapon.heatAmount or rightWeapon.heatAmount < 0.95 then
                move.commands = AddMoveCommand(move.commands, Move.SecondaryAttack)
            end

        else
            local railgunFireCharge = 0.98
            if dist < dynamicCloseDist and target:isa("Player") then
                railgunFireCharge = 0.4
            end

            if leftWeapon and leftWeapon:GetChargeAmount() < railgunFireCharge then
                move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)
            end
            if rightWeapon and rightWeapon:GetChargeAmount() < railgunFireCharge then
                move.commands = AddMoveCommand(move.commands, Move.SecondaryAttack)
            end
        end

    else
        if brain.lastShootingTime and brain.lastShootingTime > Shared.GetTime() - 0.5 then
            bot:GetMotion():SetDesiredViewTarget(bot:GetMotion().desiredViewTarget)
            move.commands = AddMoveCommand(move.commands, Move.PrimaryAttack)

        elseif not retreating and dist < dynamicCloseDist + 5 then
            bot:GetMotion():SetDesiredViewTarget(aimPos)

        elseif retreating then
            move.commands = AddMoveCommand(move.commands, Move.MovementModifier)
        end
    end

    if doFire then
        brain.lastShootingTime = Shared.GetTime()
    end

    ----------------------------------------------------------------------
    -- Debug-Linien
    ----------------------------------------------------------------------
    if gBotDebug:Get("debugall") or brain.debug then
        if doFire then
            DebugLine(eyePos, aimPos, 0.0, 1,0,0,1, true)
        else
            DebugLine(eyePos, aimPos, 0.0, 1,0.5,0,1, true)
        end
    end

end

------------------------------------------
--
------------------------------------------
local function PerformAttack(eyePos, mem, bot, brain, move)

    assert(mem)

    local target = Shared.GetEntity(mem.entId)
    local player = bot:GetPlayer()
    local client = player.GetClient and player:GetClient()
    local isSelfBot = client and client:GetIsVirtual()

    if target ~= nil then

        --------------------------------------------------------------------
        -- Angriff ausführen
        --------------------------------------------------------------------
        PerformAttackEntity(eyePos, target, mem.lastSeenPos, bot, brain, move)

        --------------------------------------------------------------------
        -- Gemeinsames Marine/Exo-Memo (kein Spam)
        --------------------------------------------------------------------
        if isSelfBot and target:GetTeamNumber() ~= bot:GetTeamNumber() then

            local location = target:GetLocationName()
            local now = Shared.GetTime()

            -- Letzte Meldung für diese Location (geteilt von ALLEN Marines/Exos)
            local lastReport = gLastMarineReports[location] or 0

            -- Nur melden, wenn seit 60 Sekunden nichts kam
            if now - lastReport > 60 then

                local chatMsg = bot:SendTeamMessage(
                    "Cooonnntaaaact! " .. target:GetMapName() .. " in " .. location
                )

                bot:SendTeamMessage(chatMsg, 60)

                -- Zeitstempel aktualisieren
                gLastMarineReports[location] = now
            end
        end
        --------------------------------------------------------------------

    end

    brain.teamBrain:AssignPlayerToEntity(brain.player, mem.entId)
end

local function GetIsUseOrder(order)
    return order:GetType() == kTechId.Construct 
            or order:GetType() == kTechId.AutoConstruct
            or order:GetType() == kTechId.Build
end

------------------------------------------
-- Exo Objective Validator Functions
------------------------------------------

local kValidateFollowOrder = function(bot, brain, exo, action)
    if not IsValid(action.order) then
        return false
    end

    return true
end

local kValidateRetreat = function(bot, brain, exo, action)
    -- retreat-to structure has been destroyed, not safe!
    if not IsValid(action.structure) then
        return false
    end

    return true
end

local kValidateProtectARC_Exo = function(bot, brain, exo, action)

    local arc = action.arc
    if not IsValid(arc) then
        return false
    end

    if not arc:GetIsAlive() then
        return false
    end

    if arc:GetTeamNumber() ~= exo:GetTeamNumber() then
        return false
    end

    -- ARC wird bereits verteidigt ? Exo soll nicht begleiten
    if ArcIsDefended(arc) then
        return false
    end

    -- ARC muss aktiv sein
    if not ArcHasActiveOrder(arc) then
        return false
    end

    -- Distanzlimit
    local dist = GetPhaseDistanceForMarine(exo, arc, brain.lastGateId)
    if dist > 40 then
        return false
    end

    -- Nur ein Exo pro ARC
    local numOthers = brain.teamBrain:GetNumOthersAssignedToEntity(exo, arc:GetId())
    if numOthers and numOthers >= 1 then
        return false
    end

    return true
end

local kValidateGoToCommPing = function(bot, brain, exo, action)
    local db = brain:GetSenses()

    local kPingLifeTime = 30.0
    local pingTime = db:Get("comPingElapsed")

    if not pingTime or pingTime > kPingLifeTime then
        return false
        
    end

    if db:Get("healthFraction") < kExoBrainRetreatHealth then
        return false
    end

    return true
end

------------------------------------------
-- Exo Objective Executor Functions
------------------------------------------

local kExecFollowOrder = function(move, bot, brain, exo, action)
    local order = action.order

    brain.teamBrain:UnassignPlayer(exo)

    local target = Shared.GetEntity(order:GetParam())

    if target ~= nil and order:GetType() == kTechId.Attack then

        brain.teamBrain:AssignPlayerToEntity(exo, target:GetId())
        PerformAttackEntity( exo:GetEyePos(), target, order:GetLocation(), bot, brain, move )

    elseif order:GetType() == kTechId.Move then

        PerformMove( exo:GetOrigin(), order:GetLocation(), bot, brain, move )

    else

        DebugPrint("unknown order type: %d", order:GetType())
        PerformMove( exo:GetOrigin(), order:GetLocation(), bot, brain, move )

    end
end

local kExecRetreat = function(move, bot, brain, exo, action)
    local structure = action.structure

    -- we are retreating, unassign ourselves from anything else, e.g. attack targets
    brain.teamBrain:UnassignPlayer(exo)

    local dist = GetBotWalkDistance(exo, structure)
    local minFraction = brain:GetSenses():Get("healthFraction")

    -- If we are pretty close to the armory, stay with it a bit longer to encourage full-healing, etc.
    -- so pretend our situation is more dire than it is
    if dist > 6.0 and minFraction > 0.9 then
        -- auto-weld has fixed the exo most of the way up
        return kPlayerObjectiveComplete
    end

    if dist > 6.0 then

        PerformMove( exo:GetOrigin(), structure:GetOrigin(), bot, brain, move )
        move.commands = AddMoveCommand( move.commands, Move.MovementModifier )

        if dist > 15.0 then
            bot:SendTeamMessage("I could really use some welds!")
        end

    else

        -- try to find a place to get out
        -- local armoryPoint = armory:GetEngagementPoint() + Vector(math.random() * 6 - 3, 0, math.random() * 6 - 3 )
        -- PerformMove( marine:GetOrigin(), armoryPoint, bot, brain, move )

        -- BOT-TODO: review whether bots should leave Exos or not
        move.commands = AddMoveCommand(move.commands, Move.Drop)
        return kPlayerObjectiveComplete

    end
end

local kExecProtectARC_Exo = function(move, bot, brain, exo, action)

    PROFILE("ExoBrain - ExecProtectARC")

    local arc = action.arc
    if not IsValid(arc) then
        return kPlayerObjectiveComplete
    end

    if ArcIsDefended(arc) then
        return kPlayerObjectiveComplete
    end

    if not ArcHasActiveOrder(arc) then
        return kPlayerObjectiveComplete
    end

    if not action.assigned then
        brain.teamBrain:AssignPlayerToEntity(exo, arc:GetId())
        action.assigned = true
    end

    local exoPos = exo:GetOrigin()
    local arcPos = arc:GetOrigin()
    local targDist = GetBotWalkDistance(exoPos, arc)

    -- GuardNearestHuman-Style Distanz
    local desiredDist = 6.5
    local desiredDistMin = 3.0

    local inDesiredRange = targDist < desiredDist and targDist > desiredDistMin

    -- Pathing-Fix
    local engagementPoint = (arc.GetEngagementPoint and arc:GetEngagementPoint()) or arcPos

    if not inDesiredRange then
        PerformMove(exoPos, engagementPoint, bot, brain, move, false, false)
        bot:GetMotion():SetDesiredViewTarget(nil)
    else
        -- Kein LookAround mehr, einfach stehen bleiben
        bot:GetMotion():SetDesiredMoveTarget(nil)
        bot:GetMotion():SetDesiredViewTarget(nil)
    end

    return nil
end

local kExecGoToCommPing = function(move, bot, brain, exo, action)
    local pingPos = action.pingPos

    local origin = exo:GetOrigin()

    if (pingPos - origin):GetLengthXZ() < 5 then
        -- we got close enough, remember to ignore this ping
        brain.lastReachedPingPos = pingPos
        return kPlayerObjectiveComplete
    end

    PerformMove( exo:GetOrigin(), pingPos, bot, brain, move )
end

------------------------------------------
-- Exo Objective Goals
------------------------------------------

local kExoBrainObjectiveTypes = enum({
    'FollowOrder',
    'Retreat',
    'ProtectARC',
    'GoToCommPing',
})

local ExoBrainObjectiveWeights = MakeBotActionWeights(kExoBrainObjectiveTypes, 100)

kExoBrainObjectives =
{
    function(bot, brain, exo)

        local name, weight = ExoBrainObjectiveWeights:Get(kExoBrainObjectiveTypes.FollowOrder)

        local order = bot:GetPlayerOrder()

        if not order or GetIsUseOrder(order) then
            return kNilAction
        end

        return {
            name = name,
            weight = weight,
            fastUpdate = order:GetType() == kTechId.Attack,
            order = order,
            validate = kValidateFollowOrder,
            perform = kExecFollowOrder
        }
    end,

    function(bot, brain, exo)        --FIXME ...retreat to an Armory? eh...this needs a refactor

        local name, weight = ExoBrainObjectiveWeights:Get(kExoBrainObjectiveTypes.Retreat)
        local sdb = brain:GetSenses()

        local retreatTo = sdb:Get("nearestArmory")
        local structure = retreatTo.armory

        local minFraction = sdb:Get("healthFraction")

        -- Don't start retreating if we're above 60% health or can't find a place to retreat to
        if structure == nil or minFraction > kExoBrainRetreatHealth then
            return kNilAction
        end

        return {
            name = name,
            weight = weight,
            structure = structure,
            validate = kValidateRetreat,
            perform = kExecRetreat
        }

    end,
    
function(bot, brain, exo)

    PROFILE("ExoBrain - ProtectARC")

    local name = kExoBrainObjectiveTypes[kExoBrainObjectiveTypes.ProtectARC]
    local sdb = brain:GetSenses()
    local teamBrain = GetTeamBrain(exo:GetTeamNumber())

    local arcs = sdb:Get("teamARCs")
    if not arcs or #arcs == 0 then
        return { name = name, weight = 0 }
    end

    local bestArc = nil
    local bestDist = math.huge
    local exoPos = exo:GetOrigin()

    for _, arc in ipairs(arcs) do
        if IsValid(arc) and arc:GetIsAlive() then

            -- ? ARC wird verteidigt ? überspringen
            if ArcIsDefended(arc) then
                goto continue_arc
            end

            if not ArcHasActiveOrder(arc) then
                goto continue_arc
            end

            local dist = (arc:GetOrigin() - exoPos):GetLength()
            if dist < bestDist then
                bestArc = arc
                bestDist = dist
            end
        end
        ::continue_arc::
    end

    if not bestArc or bestDist > 40 then
        return { name = name, weight = 0 }
    end

    local arcId = bestArc:GetId()
    local assigned = teamBrain:GetNumOthersAssignedToEntity(exo, arcId)
    if assigned > 0 then
        return { name = name, weight = 0 }
    end

    return {
        name       = name,
        weight     = 1.0,
        fastUpdate = true,
        arc        = bestArc,
        validate   = kValidateProtectARC_Exo,
        perform    = kExecProtectARC_Exo
    }
end, -- Protect ARCs

    function( bot, brain, exo )

        local name, weight = ExoBrainObjectiveWeights:Get(kExoBrainObjectiveTypes.GoToCommPing)
        local db = brain:GetSenses()

        local kPingLifeTime = 30.0
        local pingTime = db:Get("comPingElapsed")
        local pingPos

        if pingTime ~= nil and pingTime < kPingLifeTime then

            pingPos = db:Get("comPingPosition")

            if brain.lastReachedPingPos ~= nil and pingPos:GetDistance(brain.lastReachedPingPos) < 5 then
                -- we already reached this ping - ignore it
                pingPos = nil
            end

        end

        if not pingPos then
            return kNilAction
        end

        return {
            name = name,
            weight = weight,
            pingPos = pingPos,
            validate = kValidateGoToCommPing,
            perform = kExecGoToCommPing
        }

    end,

    -- Explore only as a last resort if there is no other place to go to
    CreateExploreAction( 0.5,
        function( pos, targetPos, bot, brain, move )
            if gBotDebug:Get("debugall") or brain.debug then
                DebugLine(brain.player:GetEyePos(), targetPos+Vector(0,1,0), 0.0,     0,0,1,1, true)
            end
            brain.teamBrain:UnassignPlayer(brain.player)
            PerformMove(pos, targetPos, bot, brain, move)
        end),
}

------------------------------------------
-- Exo Immediate Actions
------------------------------------------

local kExoBrainActionTypes = enum({
    'Attack',
    'ClearCysts'
})

local ExoBrainActionWeights = MakeBotActionWeights(kExoBrainActionTypes, 1)

local kExecAttack = function(move, bot, brain, exo, action)
	PerformAttack( exo:GetEyePos(), action.threat, bot, brain, move)
end

local kExecClearCysts = function(move, bot, brain, exo, action)
    local cyst = action.cyst

    PerformAttackEntity( exo:GetEyePos(), cyst, cyst:GetOrigin(), bot, brain, move )
end

------------------------------------------
--  Each want function should return the fuzzy weight or tree along with a closure to perform the action
--  The order they are listed should not really matter, but it is used to break ties (again, ties should be unlikely given we are using fuzzy, interpolated eval)
--  Must NOT be local, since MarineBrain uses it.
------------------------------------------
kExoBrainActions =
{
    function(bot, brain, exo)

        local name, weight = ExoBrainActionWeights:Get(kExoBrainActionTypes.Attack)

        local sdb = brain:GetSenses()
        local threat = sdb:Get("biggestThreat")

        if not threat then
            return kNilAction
        end

        return {
			name = name,
			weight = weight,
			fastUpdate = true,
			threat = threat.memory,
            perform = kExecAttack
        }
    end,

    function(bot, brain, exo)

        local name, weight = ExoBrainActionWeights:Get(kExoBrainActionTypes.ClearCysts)
        local sdb = brain:GetSenses()

        local cyst = sdb:Get("nearbyCyst")
        local shouldAttack = cyst and sdb:Get("attackNearestCyst")

        -- Don't attack cysts if we're a railgun exo
        if not cyst or brain.isRailgun or not shouldAttack then
            return kNilAction
        end

        return {
            name = name,
            weight = weight,
            fastUpdate = true,
            cyst = cyst,
            perform = kExecClearCysts
        }

    end,

    function(bot, brain, exo)

        -- This thinker returns no valid actions, but will interrupt the bot's current goal
        -- if it is required to react to a high-priority outside action

        local sb = brain:GetSenses()
        local lastOrder = bot:GetPlayerOrder()

        local shouldInterrupt = false

        if IsValid(lastOrder) and lastOrder:GetId() ~= brain.lastOrderId then

            shouldInterrupt = true
            brain.lastOrderId = lastOrder:GetId()

        end

        if shouldInterrupt then
            brain:InterruptCurrentGoalAction()
        end

        return kNilAction

    end, -- INTERRUPT OBJECTIVE FOR HIGH-THREAT MEMORY
}

------------------------------------------
--  More urgent == should really attack it ASAP
------------------------------------------
local function GetAttackUrgency(bot, exo, mem)

    local teamBrain = bot.brain.teamBrain

    -- See if we know whether if it is alive or not
    local target = Shared.GetEntity(mem.entId)
    if not HasMixin(target, "Live") or not target:GetIsAlive() or (target.GetTeamNumber and target:GetTeamNumber() == bot:GetTeamNumber()) then
        return nil
    end

    -- for load-balancing
    local numOthers = teamBrain:GetNumOthersAssignedToEntity( exo, mem.entId )

    -- Closer --> more urgent

    local closeBonus = 0
    local dist = exo:GetOrigin():GetDistance( mem.lastSeenPos )

    if dist < 15 then
        -- Do not modify numOthers here
        closeBonus = 10/math.max(1.0, dist)
    end

    ------------------------------------------
    -- Passives - not an immediate threat, but attack them if you got nothing better to do
    ------------------------------------------
    local passiveUrgencies =
    {
        [kMinimapBlipType.Crag] = numOthers >= 2           and 0.2 or 0.95, -- kind of a special case
        [kMinimapBlipType.Hive] = numOthers >= 6           and 0.5 or 0.9,
        [kMinimapBlipType.TunnelEntrance] = numOthers >= 1 and 0.45 or 0.85,
        [kMinimapBlipType.Harvester] = numOthers >= 2      and 0.4 or 0.8,
        [kMinimapBlipType.Egg] = numOthers >= 1            and 0.2 or 0.5,
        [kMinimapBlipType.Shade] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Shift] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Shell] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Veil] = numOthers >= 2           and 0.2 or 0.5,
        [kMinimapBlipType.Spur] = numOthers >= 2           and 0.2 or 0.5,
    }

    if bot.brain.debug then
        if mem.btype == kMinimapBlipType.Hive then
            Print("got Hive, urgency = %f", passiveUrgencies[mem.btype])
        end
    end

    if passiveUrgencies[ mem.btype ] ~= nil then
        if target.GetIsGhostStructure and target:GetIsGhostStructure() and 
            mem.btype ~= kMinimapBlipType.Extractor then
            return nil
        end
        return passiveUrgencies[ mem.btype ] + closeBonus * 0.3
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
            [kMinimapBlipType.Lerk] = numOthers >= 2   and 0.1 or 5.0,
            [kMinimapBlipType.Fade] = numOthers >= 3   and 0.1 or 6.0,
            [kMinimapBlipType.Onos] =  numOthers >= 4  and 0.1 or 7.0,
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
        if dist < 15 then
            numOthers = 0
        end

        urgTable = EvalActiveUrgenciesTable(numOthers)
        return urgTable[ mem.btype ] + closeBonus

    end

    return nil

end

------------------------------------------
--  Build the senses database
------------------------------------------

function CreateExoBrainsSenses()

    local s = BrainSenses()
    s:Initialize()

    -- Exos don't use ammo and always have their weapons 'ready' to fire,
    -- so we don't need any senses to track that

    s:Add("healthFraction", function(db, exo)
            local marine = db.bot:GetPlayer()
            return marine:GetHealthScalar()
		end)

--[[
    s:Add("biggestThreat", function(db, exo)
            local marine = db.bot:GetPlayer()
            local memories = GetTeamMemories( marine:GetTeamNumber() )
            local maxUrgency, maxMem = GetMaxTableEntry( memories,
                function( mem )
                    return GetAttackUrgency( db.bot, mem )
                end)
            local dist = nil
            if maxMem ~= nil then
                if db.bot.brain.debug then
                    Print("max mem type = %s", EnumToString(kMinimapBlipType, maxMem.btype))
                end
                dist = marine:GetEyePos():GetDistance(maxMem.lastSeenPos)
                return {urgency = maxUrgency, memory = maxMem, distance = dist}
            else
                return nil
            end
		end)
--]]

	s:Add("biggestThreat", 
		function(db, exo)
			PROFILE("ExoBrain - biggestLifeformThreat")

			local teamBrain = GetTeamBrain( exo:GetTeamNumber() )
			local enemyTeam = GetEnemyTeamNumber( exo:GetTeamNumber() )

			local maxUrgency, maxMem = 0.0, nil

			for _, mem in teamBrain:IterMemoriesNearLocation(exo:GetLocationName(), enemyTeam) do

				local urgency = GetAttackUrgency(db.bot, exo, mem)

				if urgency and urgency > maxUrgency then
					maxUrgency = urgency
					maxMem = mem
				end

			end

			if maxMem ~= nil then
				local dist = GetBotWalkDistance( exo, maxMem.lastSeenPos, maxMem.lastSeenLoc )

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
		
		s:Add("teamARCs", function(db)
    local team = db.bot:GetTeamNumber()
    return GetEntitiesAliveForTeam("ARC", team)
end)

    s:Add("nearestArmory", function(db, exo)

            local armories = GetEntitiesForTeam( "Armory", exo:GetTeamNumber() )

            local dist, armory = GetMinTableEntry( armories,
                function(arm)
                    assert( arm ~= nil )
                    if arm:GetIsBuilt() and arm:GetIsPowered() then
                        local dist = GetBotWalkDistance(exo, arm)
                        -- Weigh our previous nearest a bit better, to prevent thrashing
                        if arm:GetId() == db.lastNearestArmoryId then
                            return dist * 0.9
                        else
                            return dist
                        end
                    end
                end)

            if armory ~= nil then
                db.lastNearestArmoryId = armory:GetId()
            end

            return {
                armory = armory,
                distance = dist
            }

        end)

--[[
    s:Add("nearestPower", function(db, exo)

            local exoPos = exo:GetOrigin()
            local powers = GetEntities( "PowerPoint" )

            local dist, power = GetMinTableEntry( powers,
                function(power)
                    if power:GetIsBuilt() then
                        return exoPos:GetDistance( power:GetOrigin() )
                    end
                end)

            return {entity = power, distance = dist}
		end)
--]]

    s:Add("nearbyCyst", function(db, exo)

            local exoPos = exo:GetOrigin()
            local cysts = GetEntitiesWithinRange("Cyst", exoPos, 20)

            local dist, cyst = GetMinTableEntry( cysts, function(cyst)
                if cyst:GetIsSighted() then
                    return GetBotWalkDistance( exo, cyst )
                end
                return nil
            end)

            return cyst
		end)

    s:Add("attackNearestCyst", function(db, exo)

            local cyst = db:Get("nearbyCyst")

            if not cyst then
                return false
            end

            local loc = cyst:GetLocationName()
            local memories = GetTeamBrain(exo:GetTeamNumber()):GetMemoriesAtLocation(loc, exo:GetTeamNumber())

            local shouldAttack = true

            -- if we have anything in the room other than a player, mine, or MAC (e.g. ARC, structure, etc)
            -- clear cysts from this room
            for _, mem in ipairs(memories) do
                local isTransient = mem.btype == kMinimapBlipType.Marine
                    or mem.btype == kMinimapBlipType.JetpackMarine
                    or mem.btype == kMinimapBlipType.Exo
                    or mem.btype == kMinimapBlipType.MAC
                    or mem.btype == kMinimapBlipType.SensorBlip

                if not isTransient then
                    shouldAttack = true
                end
            end

            return shouldAttack
		end)


    s:Add("nearbyFriendlies",
        function(db, exo)
            local teamBrain = GetTeamBrain(exo:GetTeamNumber())
            local roomMemories = teamBrain:GetMemoriesAtLocation(exo:GetLocationName(), exo:GetTeamNumber())

            local numFriendlies = 0
            local numEnemies = 0

            for _, mem in ipairs(roomMemories) do
                if mem.btype == kMinimapBlipType.Marine
                    or mem.btype == kMinimapBlipType.JetpackMarine
                    or mem.btype == kMinimapBlipType.ARC -- protect the ARCs!
                    or mem.btype == kMinimapBlipType.Exo
                then
                    numFriendlies = numFriendlies + 1
                end
            end

            return numFriendlies
        end)
                    
        s:Add("nearbyEnemies",
    function(db, marine)
        local teamBrain = GetTeamBrain(marine:GetTeamNumber())
        local enemyTeam = GetEnemyTeamNumber(marine:GetTeamNumber())
        local marinePos = marine:GetOrigin()
        local numEnemies = 0
        local bestMem = nil

        for _, mem in teamBrain:IterMemoriesNearLocation(marine:GetLocationName(), enemyTeam) do
            local isActiveThreat = mem.btype == kMinimapBlipType.Skulk
                or mem.btype == kMinimapBlipType.Lerk
                or mem.btype == kMinimapBlipType.Fade
                or mem.btype == kMinimapBlipType.Onos
                or mem.btype == kMinimapBlipType.Whip

                if isActiveThreat then
                local dist = marinePos:GetDistance(mem.lastSeenPos)

                if dist <= kMarineBrainNearbyEnemyThreshold then
                    numEnemies = numEnemies + 1
                end
            end
        end

        return numEnemies
    end)

    s:Add("comPingElapsed", function(db, exo)

            local pingTime = GetGamerules():GetTeam(exo:GetTeamNumber()):GetCommanderPingTime()

            if pingTime > 0 and pingTime ~= nil and pingTime < Shared.GetTime() then
                return Shared.GetTime() - pingTime
            else
                return nil
            end

		end)

    s:Add("comPingPosition", function(db, exo)
            
            local rawPos = GetGamerules():GetTeam(exo:GetTeamNumber()):GetCommanderPingPosition()
            -- the position is usually up in the air somewhere, so pretend we did a commander pick to put it somewhere sensible
            local trace = GetCommanderPickTarget(
                exo, -- not right, but whatever
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

--[[
if Server then
Event.Hook("Console_marinejitter", function(client, arg)
        gMarineAimJitterAmount = tonumber(arg)
        Print("gMarineAimJitterAmount = %f", gMarineAimJitterAmount)
        end
        )
end
--]]
