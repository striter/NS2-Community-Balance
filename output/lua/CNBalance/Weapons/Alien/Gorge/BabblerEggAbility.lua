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
    local rayTracePosition = position + surfaceNormal * 0.05
    local trace = Shared.TraceRay(rayTracePosition, rayTracePosition + kDownCheck, CollisionRep.Move, PhysicsMask.DefaultOnly)
    if trace.fraction ~= 1.0 then
        return IsPathable(trace.endPoint)
    end
    return IsPathable(position)
end 