Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/TunnelEntranceAbility.lua")

class 'TunnelExitAbility' (TunnelEntranceAbility)

function TunnelExitAbility:GetDropStructureId()
    return kTechId.TunnelExit
end

function TunnelExitAbility:ModifyCoords(coords, _, normal, player)
    
end

function TunnelExitAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, _, entity)
    PROFILE("TunnelExitAbility:GetIsPositionValid")

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
    local trace = Shared.TraceBox(extents, traceStart, traceEnd, CollisionRep.Damage, PhysicsMask.Movement,EntityFilterOneAndIsa(player, "Player"))
    --DebugTraceBox(extents, traceStart, traceEnd, 0.1, 45, 45, 45, 1)

    if trace.fraction ~= 1 then
        return false
    end

    local rayStart = position + normal * 0.01
    local rayEnd = position + normal * (extents.y * 2 - 0.01)
    trace = Shared.TraceRay(rayStart,rayEnd, CollisionRep.Damage, PhysicsMask.Movement,EntityFilterOneAndIsa(player, "Player"))
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


function TunnelExitAbility:GetDropRange()
    return AdvancedStructureAbility.GetDropRange(self)
end

if Server then

    function TunnelExitAbility:CreateStructure(coords, player, lastClickedPosition)

        local entity =  CreateEntity(self:GetDropMapName(), coords.origin, player:GetTeamNumber())
        entity:UpgradeToTechId(kTechId.TunnelExit)
        return entity
    end
end