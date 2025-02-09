
function CreateBuildStructureActionForEach( techId, className, numExistingToWeightLPF, buildNearClass, maxDist)

    return function(bot, brain)

        local name = "build"..EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local coms = doables[techId]

        -- find structures we can build near
        local hosts = GetEntitiesForTeam( buildNearClass, com:GetTeamNumber() )
        local mainHost
        if coms ~= nil and #coms > 0
        and hosts ~= nil and #hosts > 0 then
            assert( coms[1] == com )
            
            local team = com:GetTeam()
            if (sdb:Get("gameMinutes") > 5 or team:GetTeamResources() > 100) then

                --local existingEnts = GetEntitiesForTeam( className, com:GetTeamNumber() )
                --weight = EvalLPF( #existingEnts, numExistingToWeightLPF )
                
                for _,host in ipairs(hosts) do
                    
                    if host:GetIsBuilt() and host:GetIsAlive() then
                        local existingEnts = GetEntitiesForTeamWithinRange( className, com:GetTeamNumber(), host:GetOrigin(), maxDist + 1)
                        local newWeight = EvalLPF( #existingEnts, numExistingToWeightLPF )
                        if newWeight > weight then
                            weight = newWeight
                            mainHost = host
                        end
                    end
                end
            end
        end

        return { name = name, weight = weight,
            perform = function(move)

                if mainHost then
                    if mainHost:GetIsBuilt() and mainHost:GetIsAlive() then
                    
                        local pos = GetRandomBuildPosition( techId, mainHost:GetOrigin() + Vector(math.random() * 10 - 5, math.random() * 10 - 5, math.random() * 10 - 5), maxDist )
                        if pos ~= nil then
                            brain:ExecuteTechId( com, techId, pos, com )
                        end
                            
                    end
                end

            end }
    end

end


function CreateBuildStructureActionLate( techId, className, numExistingToWeightLPF, buildNearClass, maxDist , lateTime)

    return function(bot, brain)

        local name = "build"..EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local coms = doables[techId]
        local mainHost

        -- find structures we can build near
        local hosts = GetEntitiesForTeam( buildNearClass, com:GetTeamNumber() )

        if coms ~= nil and #coms > 0
        and hosts ~= nil and #hosts > 0 then
            assert( coms[1] == com )

            for _,host in ipairs(hosts) do
                
                if host:GetIsBuilt() and host:GetIsAlive() then
                    -- figure out how many exist already
                    local existingEnts = GetEntitiesForTeam( className, com:GetTeamNumber() )
                    weight = EvalLPF( #existingEnts, numExistingToWeightLPF )
                    
                    -- Pick the first host for now
                    mainHost = host
                end
            end
        end
        -- ultra hack!
        local team = com:GetTeam()
        if (sdb:Get("gameMinutes") < lateTime and team:GetTeamResources() < 150) then 
            weight = 0
        end
        

        return { name = name, weight = weight,
            perform = function(move)
                if mainHost then 
                    local pos = GetRandomBuildPosition( techId, mainHost:GetOrigin(), maxDist )
                    if pos ~= nil then
                        brain:ExecuteTechId( com, techId, pos, com )
                    end
                end
            end }
    end

end

function CreateUpgradeStructureActionLate( techId, weightIfCanDo, existingTechId, lateTime)

    return function(bot, brain)

        local name = EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local structures = doables[techId]
        local host

        if structures ~= nil then

            weight = weightIfCanDo
            
            host = structures[ math.random(#structures) ]

            -- but if we have the upgrade already, halve the weight
            -- TODO THIS DOES NOT WORK WTFFF
            if existingTechId ~= nil then
--                DebugPrint("Checking if %s exists..", EnumToString(kTechId, existingTechId))
                if GetTechTree(com:GetTeamNumber()):GetHasTech(existingTechId) then
                    DebugPrint("halving weight for already having %s", name)
                    weight = weight * 0.5
                end
            end

        end
        
        
        -- ultra hack!
        local team = com:GetTeam()
        if (sdb:Get("gameMinutes") < lateTime and team:GetTeamResources() < 150) then 
            weight = 0.0
        end
        

        return {
            name = name, weight = weight,
            perform = function(move)

                -- chooses from a random host
                brain:ExecuteTechId( com, techId, Vector(0,0,0), host )
                
            end }
    end

end


function CreateUpgradeStructureAction( techId, weightIfCanDo, existingTechId )

    return function(bot, brain)

        local name = EnumToString( kTechId, techId )
        local com = bot:GetPlayer()
        local sdb = brain:GetSenses()
        local doables = sdb:Get("doableTechIds")
        local weight = 0.0
        local structures = doables[techId]

        if structures ~= nil then

            weight = weightIfCanDo

            -- but if we have the upgrade already, set the weight to 0
            if existingTechId ~= nil then
                if GetTechTree(com:GetTeamNumber()):GetHasTech(existingTechId) then
                    DebugPrint("setting weight to 0 for already having %s", name)
                    weight = 0
                end
            end

        end

        return {
            name = name, weight = weight,
            perform = function(move)

                if structures == nil then return end
                -- choose a random host
                local host = structures[ math.random(#structures) ]
                if host then
                    brain:ExecuteTechId( com, techId, Vector(0,0,0), host )
                end
            end }
    end

end


function CreateDefendAction( weightIfTargetAcquired, moveToFunction )

    return function(bot, brain)

        local name = "explore"
        local player = bot:GetPlayer()
        local origin = player:GetOrigin()

        local findNew = true
        if brain.defendTargetId ~= nil then
            local target = Shared.GetEntity(brain.defendTargetId)
            if target ~= nil then
                local dist = target:GetOrigin():GetDistance(origin)
                if dist > 5.0 then
                    findNew = false
                end
            end
        end

        if findNew then
            
            -- TODO: Get furthest one
            local memories = GetTeamMemories( player:GetTeamNumber() )
            local exploreMems = FilterTable( memories,
                    function(mem)
                        return mem.entId ~= brain.defendTargetId
                            and ( mem.btype == kMinimapBlipType.Extractor
                                or mem.btype == kMinimapBlipType.PhaseGate
                                or mem.btype == kMinimapBlipType.PhaseGate )
                    end )

            -- TODO pick the furthest one
            if #exploreMems > 0 then
                local targetMem = exploreMems[ math.random(#exploreMems) ]
                brain.defendTargetId = targetMem.entId
            else
                brain.defendTargetId = nil
            end
        end

        local weight = 0.0
        if brain.defendTargetId ~= nil then
            weight = weightIfTargetAcquired
        end

        return { name = name, weight = weight,
            perform = function(move)
                local target = Shared.GetEntity( brain.defendTargetId )
                if brain.debug then
                    DebugPrint("exploring to move target %s", ToString(target:GetOrigin()))
                end

                moveToFunction( origin, target:GetOrigin(), bot, brain, move )
            end }
    end

end


