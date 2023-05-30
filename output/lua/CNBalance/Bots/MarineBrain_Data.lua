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
        [kMinimapBlipType.Harvester] =          0.9,
        [kMinimapBlipType.Whip] =               0.89,
        [kMinimapBlipType.Shell] =              0.6,
        [kMinimapBlipType.Veil] =               0.6,
        [kMinimapBlipType.Spur] =               0.6,
        [kMinimapBlipType.Shade] =              0.5,
        [kMinimapBlipType.Shift] =              0.5,
        [kMinimapBlipType.TunnelEntrance] =     0.5,
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


local function EvalActiveUrgenciesTable(numOthers)
    local activeUrgencies =
    {
        [kMinimapBlipType.Onos] =       numOthers >= 4 and 0.1 or 7.0,
        [kMinimapBlipType.Fade] =       numOthers >= 3 and 0.1 or 6.0,
        [kMinimapBlipType.Lerk] =       numOthers >= 2 and 0.1 or 5.0,
        [kMinimapBlipType.Prowler] =    numOthers >= 2 and 0.1 or 4.0,
        [kMinimapBlipType.Skulk] =      numOthers >= 2 and 0.1 or 4.0,
        [kMinimapBlipType.Gorge] =      numOthers >= 2 and 0.1 or 3.0,
        [kMinimapBlipType.Whip] =       numOthers >= 2 and 0.1 or 3.0,
        [kMinimapBlipType.Hydra] =      numOthers >= 2 and 0.1 or 2.0,
        [kMinimapBlipType.Drifter] =    numOthers >= 1 and 0.1 or 1.0,
    }

    return activeUrgencies
end

local IsLifeformThreat = function(mem)
    local t = mem.btype
    local isThreat = t >= kMinimapBlipType.Skulk and t <= kMinimapBlipType.Gorge
            or t == kMinimapBlipType.Prowler
            or t == kMinimapBlipType.Drifter
            or t == kMinimapBlipType.Whip
            or t == kMinimapBlipType.Hydra

    return isThreat
end

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

            local shouldAttack = false

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