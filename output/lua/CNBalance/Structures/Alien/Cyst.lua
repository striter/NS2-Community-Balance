local baseOnInitialized = Cyst.OnInitialized
function Cyst:OnInitialized()

    local biomassLevel = 1
    if Server then
        local team = self:GetTeam()
        if team.GetBioMassLevel then
            biomassLevel =  team:GetBioMassLevel()
        end
    else
        local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
        if teamInfo and teamInfo.bioMassLevel then
            biomassLevel = teamInfo.bioMassLevel
        end
    end

    self.cystInfestationRadius = kInfestationRadius
    if not GetHasTech(self,kTechId.OriginForm) then
        self.cystInfestationRadius = kInfestationRadius + math.max(biomassLevel - 1,0) * kInfestationPerBiomass
    end
    baseOnInitialized(self)
end

function Cyst:GetInfestationRadius()
    return self.cystInfestationRadius
end

function Cyst:GetInfestationMaxRadius()
    return self.cystInfestationRadius
end

function Cyst:GetHealSprayBuildAllowed()
    return self:CanBeBuilt() or self:GetIsCatalysted()
end

local kParentSearchRange = 400
local function CreateBetween(trackStart, startNormal, trackEnd, endNormal, startOffset, endOffset)

    trackStart = trackStart + startNormal * 0.01
    trackEnd = trackEnd + endNormal * 0.01
    
    local pathDirection = trackEnd - trackStart
    pathDirection:Normalize()
    
    if startOffset == nil then
        startOffset = 0.1
    end
    
    if endOffset == nil then
        endOffset = 0.1
    end
    
    -- DL: Offset the points a little towards the center point so that we start with a polygon on a nav mesh
    -- that is closest to the start. This is a workaround for edge case where a start polygon is picked on
    -- a tiny island blocked off by an obstacle.
    trackStart = trackStart + pathDirection * startOffset
    trackEnd = trackEnd - pathDirection * endOffset
    
    local points = PointArray()
    local isReachable = Pathing.GetPathPoints(trackStart, trackEnd, points)
    
    if isReachable then
        -- Always include the starting point in this path for convenience
        Pathing.InsertPoint(points, 1, trackStart)
end
    return isReachable, points

end

function GetCystParentFromPoint(origin, normal, connectionMethodName, optionalIgnoreEnt, teamNumber)

    PROFILE("Cyst:GetCystParentFromPoint")
    
    local ents = GetSortedListOfPotentialParents(origin, teamNumber, kCystMaxParentRange, kHiveCystParentRange)
    
    if Client then
        MarkPotentialDeployedCysts(ents, origin)
    end
    
    teamNumber = teamNumber or kAlienTeamType
    for i = 1, #ents do
    
        local ent = ents[i]
        
        -- must be either a built hive or an cyst with a connected infestation
        if optionalIgnoreEnt ~= ent and
           ((ent:isa("Hive") and ent:GetIsBuilt()) 
           or (ent:isa("TunnelEntrance") and ent:GetIsBuilt())
           or (ent:isa("Cyst") and ent[connectionMethodName](ent))
        ) then
            
            local range = (origin - ent:GetOrigin()):GetLength()
            if range <= ent:GetCystParentRange() then
            
                -- check if we have a track from the entity to origin
                local endOffset = 0.1
                if ent:isa("Hive") then
                    endOffset = 3
                end
                
                -- The pathing somehow is able to return two different path ((A -> B) != (B -> A))
                -- Ex: Cysting in derelict between the RT in "Turbines" (a bit above the rt), and "Heat Transfer"
                --     You can check those path with a drifter, it will take two different route.
                local isReachable1, path1 = CreateBetween(origin, normal, ent:GetOrigin(), ent:GetCoords().yAxis, 0.1, endOffset)
                local isReachable2, path2 = CreateBetween(ent:GetOrigin(), ent:GetCoords().yAxis, origin, normal, 0.1, endOffset)
                if isReachable1 and path1 and isReachable2 and path2 then
                
                    -- Check that the total path length is within the range.
                    local pathLength1 = GetPointDistance(path1)
                    local pathLength2 = GetPointDistance(path2)
                    if pathLength1 <= ent:GetCystParentRange() then
                        return ent, path1
                    end
                    if pathLength2 <= ent:GetCystParentRange() then
                        local points = PointArray()
                    
                        if cystChainDebug then
                            Log("GetCystParentFromPoint() Regular path didn't worked, using the reverse")
                end
                
                        -- Reverse the path points so we still get an array of points from A to B
                        for i = 1, #path2 do
                            Pathing.InsertPoint(points, 1, path2[i])
            end
                        return ent, points
                    end
            
        end
        
    end
    
        end
        
    end
    
    return nil, nil
    
end

function GetCystPoints_AddSrcDstCyst(path, splitPoints, normals, existing, teamNumber)
    -- Add first/last point of the chain into @splitPoints
    -- If the last point is too close to a cyst, don't recreate it (mark as existing, don't destroy it)
    PROFILE("Cyst:GetCystPoints_AddSrcDstCyst")

    local distToReuse = 1.50
    local rval, rmsg = true, "No error"
    local srcOrig, dstOrig  = path[1], path[#path]
    local cystAroundSrc     = GetEntitiesForTeamWithinRange("Cyst", teamNumber, srcOrig, distToReuse)
    local cystAroundDst     = GetEntitiesForTeamWithinRange("Cyst", teamNumber, dstOrig, distToReuse)

    if #cystAroundSrc == 0 then
        cystAroundSrc = GetEntitiesForTeamWithinRange("Hive", teamNumber, srcOrig, distToReuse)
    end
    if #cystAroundDst == 0 then
        cystAroundDst = GetEntitiesForTeamWithinRange("Hive", teamNumber, dstOrig, distToReuse)
    end

    if #cystAroundSrc == 0 then
        cystAroundSrc = GetEntitiesForTeamWithinRange("TunnelEntrance", teamNumber, srcOrig, distToReuse)
    end
    if #cystAroundDst == 0 then
        cystAroundDst = GetEntitiesForTeamWithinRange("TunnelEntrance", teamNumber, dstOrig, distToReuse)
    end

    Shared.SortEntitiesByDistance(srcOrig, cystAroundSrc)
    Shared.SortEntitiesByDistance(dstOrig, cystAroundDst)

    local cystAtSrc     = (#cystAroundSrc > 0 and cystAroundSrc[1] or nil)
    local cystAtDst     = (#cystAroundDst > 0 and cystAroundDst[1] or nil)
    local srcPointOrig  = cystAtSrc and cystAtSrc:GetOrigin() or srcOrig
    local dstPointOrig  = cystAtDst and cystAtDst:GetOrigin() or dstOrig

    rval, rmsg = GetCystPoints_AddPointAt(srcPointOrig, splitPoints, normals, existing, cystAtSrc ~= nil)
    if rval then
        rval, rmsg = GetCystPoints_AddPointAt(dstPointOrig, splitPoints, normals, existing, cystAtDst ~= nil)
    end
    return rval, rmsg
end

function GetCystParentAvailable(techId, origin, normal, commander)

    PROFILE("Cyst:GetCystParentAvailable")

    local teamNumber = commander and commander:GetTeamNumber() or kAlienTeamType
    local parents = GetEntitiesForTeamWithinRange("Cyst", teamNumber, origin, kParentSearchRange)
    table.copy(GetEntitiesForTeamWithinRange("Hive", teamNumber, origin, kParentSearchRange), parents, true)
    table.copy(GetEntitiesForTeamWithinRange("TunnelEntrance", teamNumber, origin, kParentSearchRange),parents,true)
    
    return #parents > 0

end

function GetSortedListOfPotentialParents(origin, teamNumber, maxCystParentDistance, maxHiveParentDistance)
    
    teamNumber = teamNumber or kAlienTeamType
    maxCystParentDistance = maxCystParentDistance or kCystMaxParentRange
    maxHiveParentDistance = maxHiveParentDistance or kHiveCystParentRange
    
    local parents = {}
    local hives = GetEntitiesForTeamWithinRange("Hive", teamNumber, origin, maxHiveParentDistance)
    local cysts = GetEntitiesForTeamWithinRange("Cyst", teamNumber, origin, maxCystParentDistance)
    local tunnelEntrances = GetEntitiesForTeamWithinRange("TunnelEntrance", teamNumber, origin, maxCystParentDistance)
    
    table.copy(hives, parents)
    table.copy(cysts, parents, true)
    table.copy(tunnelEntrances, parents, true)
    Shared.SortEntitiesByDistance(origin, parents)
    
    -- Filter out invalid parents
    for i = #parents, 1, -1 do
        local parent = parents[i]
        local removeEntry = false

        if parent:isa("Hive") or parent:isa("TunnelEntrance") then
            removeEntry = not parent:GetIsBuilt()
        elseif parent:isa("Cyst") then
            removeEntry = not parent:GetIsConnected()
        else
            Log("Unknown parent type: " .. EntityToString(parent))
        end

        removeEntry = removeEntry or not parent:GetIsAlive()
        if removeEntry then
            table.remove(parents, i)
        end
    end
    
    return parents
    
end


local baseCanBeBuilt = Cyst.CanBeBuilt
function Cyst:CanBeBuilt()

    local teamInfoEntity = GetTeamInfoEntity(self:GetTeamNumber())
    if teamInfoEntity and teamInfoEntity.isOriginForm then
        return true
    end
    
    return baseCanBeBuilt(self)
end

if Server then
    function Cyst:GetIsActuallyConnected()

        -- Always in dev mode, for making movies and testing
        if Shared.GetDevMode() then
            return true
        end

        local teamInfoEntity = GetTeamInfoEntity(self:GetTeamNumber())
        if teamInfoEntity and teamInfoEntity.isOriginForm then
            return true
        end

        local parent = self:GetCystParent()
        if parent then

            if parent:isa("Hive") then
                return true
            end

            if parent:isa("TunnelEntrance") then
                return true
            end

            return parent:GetIsActuallyConnected()

        end

        return false

    end
end
