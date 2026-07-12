function BabblerEggAbility:GetMaxStructures(biomass)
    return 1 + math.floor(biomass / 5)
end

local kDropExtents = Vector(0.6, 16, 0.6)
local function IsPathableInDropRange(position)
    local checkPos = position + Vector(0, -15, 0)
    local noBuild = Pathing.GetIsFlagSet(checkPos, kDropExtents, Pathing.PolyFlag_NoBuild)
    local walk = Pathing.GetIsFlagSet(checkPos, kDropExtents, Pathing.PolyFlag_Walk)
    return not noBuild and walk
end

function BabblerEggAbility:GetIsPositionValid(position, player, surfaceNormal)
    return IsPathableInDropRange(position)
end
