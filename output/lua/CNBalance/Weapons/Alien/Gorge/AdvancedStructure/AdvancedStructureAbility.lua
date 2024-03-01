Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'AdvancedStructureAbility' (StructureAbility)

AdvancedStructureAbility.kStructurePlaceSide = enum( {'All','Upward','UpwardAndDownward'} )
local kUpVector = Vector(0, 1, 0)
function AdvancedStructureAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, _, entity)

    PROFILE("AdvancedStructureAbility:GetIsPositionValid")

    if entity then
        return false
    end
    
    local extents = GetExtents(self:GetDropStructureId())
    if math.abs(normal.y) < 0.95 then
        local maxExtent = math.max(extents.x,extents.y,extents.z)
        extents = Vector(maxExtent, maxExtent, maxExtent)
    end
        
    local traceStart = position + normal * (extents.y - 0.01)
    local traceEnd = position + normal * (extents.y + 0.01)
    local trace = Shared.TraceBox(extents, traceStart, traceEnd, CollisionRep.Damage, PhysicsMask.Bullets,EntityFilterOneAndIsa(player, "Player"))
    --DebugTraceBox(extents, traceStart, traceEnd, 0.1, 45, 45, 45, 1)
    
    if trace.fraction ~= 1 then
        return false
    end
    
    local rayStart = position + normal * 0.01
    local rayEnd = position + normal * (extents.y * 2 - 0.01)
    trace = Shared.TraceRay(rayStart,rayEnd, CollisionRep.Damage, PhysicsMask.Bullets,EntityFilterOneAndIsa(player, "Player"))
    --DebugTraceRay(rayStart,rayEnd,PhysicsMask.Bullets)
    if trace.fraction ~= 1 then
        return false
    end
    
    
    local upwardFraction = normal:DotProduct(kUpVector)
    local side = self:GetStructurePlaceSide()
    if side == AdvancedStructureAbility.kStructurePlaceSide.All then
        return true
    elseif side == AdvancedStructureAbility.kStructurePlaceSide.Upward then
        return upwardFraction > 0.9
    elseif side == AdvancedStructureAbility.kStructurePlaceSide.UpwardAndDownward then
        return math.abs(upwardFraction) > .9
    end
    assert(false)
    return true

end

function AdvancedStructureAbility:GetStructurePlaceSide()
    return AdvancedStructureAbility.kStructurePlaceSide.All
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

if Client then
    
    function AdvancedStructureAbility:GetHasTech(techId)

        local techTree = GetTechTree()
        return techTree ~= nil and techTree:GetHasTech(techId)

    end
    
end 