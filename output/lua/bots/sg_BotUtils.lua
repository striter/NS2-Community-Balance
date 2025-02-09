
function ResourcePointsWithPathToCC(list, ccs)

    local rps = {}
    if #ccs <= 0 then 
        return rps 
    end
    for _,rp in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do
        if not rp:GetAttached() then
            
            local dist = GetMinPathDistToEntities(rp, ccs)
            local hasPathToPoint = (dist ~= nil and dist > 0)
            local hasNearbyPlayer = false
            for _, friend in ipairs( GetEntitiesForTeamWithinRange("Player", ccs[1]:GetTeamNumber(), rp:GetOrigin(), 5) ) do
                if friend:GetIsAlive() then
                    hasNearbyPlayer = true
                end
            end
            
            if hasPathToPoint or hasNearbyPlayer then
                if not rp:GetAttached() then
                    table.insert( rps, rp )
                end
            end
        end
    end

    return rps

end

-- from ONE entity to MANY entities
function GetMinPathDistToEntities( fromEnt, toEnts )

    local minDist
    local fromPos = fromEnt:GetOrigin()

    for _,toEnt in ipairs(toEnts) do

        local path = PointArray()
        local validPath = Pathing.GetPathPoints(fromPos, toEnt:GetOrigin(), path)
        local dist = GetPointDistance(path)

        if validPath and (not minDist or dist < minDist) then
            minDist = dist
        end

    end

    return minDist

end


-- from ONE entity to MANY entities
function GetMaxPathDistToEntities( fromEnt, toEnts )

    local maxDist = 0
    local fromPos = fromEnt:GetOrigin()

    for _,toEnt in ipairs(toEnts) do
        
        local path = PointArray()
        local validPath = Pathing.GetPathPoints(fromPos, toEnt:GetOrigin(), path)
        local dist = GetPointDistance(path)

        if validPath and (not maxDist or dist > maxDist) then
            
            maxDist = dist
        end
    end

    return maxDist

end