local kDownCheck =  Vector(0, -50, 0)       --Shouldnt place that high as heel? 

function BabblerEggAbility:GetMaxStructures(biomass)
    return 1 + math.floor(biomass / 5)
end

local kExtents = Vector(0.3, 0.3, 0.3)
local function IsPathable(position)
    local noBuild = Pathing.GetIsFlagSet(position, kExtents, Pathing.PolyFlag_NoBuild)
    local walk = Pathing.GetIsFlagSet(position, kExtents, Pathing.PolyFlag_Walk)
    return not noBuild and walk
end

function BabblerEggAbility:GetIsPositionValid(position, player, surfaceNormal)
    local startPosition = position + surfaceNormal * 0.3
    local endPosition = startPosition + kDownCheck
    local trace = Shared.TraceRay(startPosition,endPosition , CollisionRep.Default, PhysicsMask.Movement)
    if trace.fraction ~= 1.0 then
        --DebugLine(startPosition, trace.endPoint, .2, 1,0,0,1)
        return IsPathable(trace.endPoint)
    end
    --DebugLine(startPosition, endPosition, .2, 0,0,1, 1)
    return IsPathable(position)
end 