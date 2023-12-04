Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'AdvancedStructureAbility' (StructureAbility)

local kUpVector = Vector(0, 1, 0)
function AdvancedStructureAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, _, entity)

    PROFILE("AdvancedStructureAbility:GetIsPositionValid")

    local valid = true
    if valid then
        local extents = GetExtents(self:GetDropStructureId())
        local traceStart = position + normal * extents.y/2 
        local traceEnd = position + normal * extents.y
        trace = Shared.TraceBox(extents, traceStart, traceEnd, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll)

        --DebugTraceBox(extents, traceStart, traceEnd, 0.1, 45, 45, 45, 1)
        if trace.fraction ~= 1
            or (not self:CouldPlaceNonUpward() and normal:DotProduct(kUpVector) < 0.9)
        then
            valid = false
        end
    end

    return valid

end

function AdvancedStructureAbility:CouldPlaceNonUpward()
    return false
end

function AdvancedStructureAbility:GetGhostModelName(ability)
    return LookupTechData(self:GetDropStructureId(),kTechDataModel)
end

function AdvancedStructureAbility:GetDropMapName()
    return LookupTechData(self:GetDropStructureId(),kTechDataMapName)
end

function AdvancedStructureAbility:RequiresInfestation()
    return 
end

function AdvancedStructureAbility:GetEnergyCost(player)
    return 30
end

function AdvancedStructureAbility:GetDropRange()
    return 6.5
end

function AdvancedStructureAbility:GetDropStructureId()
    assert(false,"Override this please")
end

function AdvancedStructureAbility:GetMaxStructures(biomass)
    return -1
end