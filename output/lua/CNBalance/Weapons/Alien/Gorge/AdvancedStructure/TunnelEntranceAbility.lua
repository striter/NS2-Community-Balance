Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

local debugPlacement = false

class 'TunnelEntranceAbility' (AdvancedStructureAbility)

function TunnelEntranceAbility:GetDropStructureId()
    return kTechId.Tunnel
end

function TunnelEntranceAbility:OverrideInfestationCheck(_trace)
    return true
end

function TunnelEntranceAbility:GetMaxStructures()
    return 1
end

function TunnelEntranceAbility:GetEnergyCost()
    return kDropStructureEnergyCost
end

function TunnelEntranceAbility:GetGhostModelName(ability)

    local player = ability:GetParent()
    if player and player:isa("Gorge") then

        local variant = player:GetVariant()
        if variant == kGorgeVariants.shadow then
            return TunnelEntrance.kModelNameShadow
        end

    end

    return TunnelEntrance.kModelName

end

function TunnelEntranceAbility:GetSuffixName()
    return "gorgetunnel"
end

function TunnelEntranceAbility:GetDropClassName()
    return "GorgeTunnel" --"TunnelEntrance"
end

function TunnelEntranceAbility:GetDropMapName()
    return GorgeTunnel.kMapName
end

function TunnelEntranceAbility:GetDropRange()
    return 5
end

function TunnelEntranceAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, _, entity)
    PROFILE("TunnelEntranceAbility:GetIsPositionValid")

    if entity then
        return false
    end

    local extents = GetExtents(self:GetDropStructureId())
    local maxExtent = math.max(extents.x,extents.y,extents.z)
    if math.abs(normal.y) < 0.95 then
        extents = Vector(maxExtent, maxExtent, maxExtent)
    end

    local traceStart = position + normal * (extents.y - 0.02)
    local traceEnd = position + normal * (extents.y + 0.02)
    local trace = Shared.TraceBox(extents, traceStart, traceEnd, CollisionRep.Move, PhysicsMask.Movement,EntityFilterOneAndIsa(player, "Player"))
    --DebugTraceBox(extents, traceEnd, traceStart, 0.1, 45, 45, 45, 1)
    
    if trace.fraction ~= 1 then
        return false
    end

    local sphereRadius =  maxExtent 
    local sphereCenter = position + normal * (sphereRadius + 0.1)
    local bias = 0.05       --That guy Biase was smurfing around 2024.05 - 2024.06
    sphereRadius = sphereRadius - bias
    local height = bias * 2
    local capsuleStart =  sphereCenter + normal * -bias
    local capsuleEnd =  sphereCenter + normal * bias
    trace = Shared.TraceCapsule(capsuleStart, capsuleEnd, sphereRadius,height,
            CollisionRep.Move, PhysicsMask.Movement, EntityFilterOneAndIsa(self, "Player"))
    --DebugCapsule(capsuleStart, capsuleEnd, sphereRadius,height, 0.1,true)
    if trace.fraction ~= 1 then
        return false
    end

    --normal = Vector(0,1,0)
    --capsuleStart =  sphereCenter + normal * -bias * 2
    --capsuleEnd =  sphereCenter + normal * bias * 2
    --trace = Shared.TraceCapsule(capsuleStart, capsuleEnd, sphereRadius,height,
    --        CollisionRep.Move, PhysicsMask.Movement, EntityFilterOneAndIsa(self, "Player"))
    --DebugCapsule(capsuleStart, capsuleEnd, sphereRadius,height, 0.1,true)
    --if trace.fraction ~= 1 then
    --    return false
    --end
    
    --local rayStart = position + normal * 0.01
    --local rayEnd = position + normal * (extents.y * 2 - 0.01)
    --trace = Shared.TraceRay(rayStart,rayEnd, CollisionRep.Damage, PhysicsMask.Movement,EntityFilterOneAndIsa(player, "Player"))
    --DebugTraceRay(rayStart,rayEnd,PhysicsMask.Bullets)
    --if trace.fraction ~= 1 then
    --    return false
    --end

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


if Client then

    local function OnDebugTunnelAbility()
        debugPlacement = not debugPlacement
        if debugPlacement then
            Log("Tunnel placement debug info enabled.")
        else
            debugPlacement = true
            Debug_ClearTraceVis()
            debugPlacement = false
            Log("Tunnel placement debug info disabled.")
        end
    end
    Event.Hook("Console_debug_tunnel_ability", OnDebugTunnelAbility)

end