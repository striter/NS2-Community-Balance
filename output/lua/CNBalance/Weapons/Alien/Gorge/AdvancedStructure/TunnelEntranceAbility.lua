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
    return 1.5
end

local kExtents = Vector(0.4, 0.5, 0.4) -- 0.5 to account for pathing being too high/too low making it hard to palce tunnels
local function IsPathable(position)

    local noBuild = Pathing.GetIsFlagSet(position, kExtents, Pathing.PolyFlag_NoBuild)
    local walk = Pathing.GetIsFlagSet(position, kExtents, Pathing.PolyFlag_Walk)
    return not noBuild and walk

end

local function Debug_DisplayBentness(pos, value, color)

    if not Client then
        return
    end

    if not debugPlacement then
        return
    end

    if not gDebugBentRenderLayer then
        gDebugBentRenderLayer = GUI.CreateItem()
        gDebugBentRenderLayer:SetLayer(20)
        gDebugBentRenderLayer:SetOptionFlag(GUIItem.ManageRender)
        gDebugBentRenderLayer:SetIsVisible(true)
        gDebugBentRenderLayer:SetTextAlignmentX(GUIItem.Align_Min)
        gDebugBentRenderLayer:SetTextAlignmentY(GUIItem.Align_Center)
        gDebugBentRenderLayer:SetFontName(Fonts.kArial_17)
        gDebugBentRenderLayer:SetColor(Color(1,1,1,1))
    end

    gDebugBentRenderLayer:SetText(value)
    gDebugBentRenderLayer:SetPosition(Client.WorldToScreen(pos))

    if color then
        gDebugBentRenderLayer:SetColor(color)
    end

end

local function Debug_ClearTraceVis()

    if not Client then
        return
    end

    if not debugPlacement then
        return
    end

    if gDebugTraceRenderLayer then
        gDebugTraceRenderLayer:ClearLines()
    end

    if gDebugBentRenderLayer then
        gDebugBentRenderLayer:SetText("")
    end

end

local function Debug_VisualizeBoxTrace(startPoint, endPoint, extents, fraction)

    if not Client then
        return
    end

    if not debugPlacement then
        return
    end

    if not gDebugTraceRenderLayer then
        gDebugTraceRenderLayer = GUI.CreateItem()
        gDebugTraceRenderLayer:SetOptionFlag(GUIItem.ManageRender)
        gDebugTraceRenderLayer:SetLayer(20)
        gDebugTraceRenderLayer:SetIsVisible(true)
    end

    local pt0_0 = startPoint + Vector(-extents.x, -extents.y, -extents.z)
    local pt0_1 = startPoint + Vector( extents.x, -extents.y, -extents.z)
    local pt0_2 = startPoint + Vector(-extents.x,  extents.y, -extents.z)
    local pt0_3 = startPoint + Vector( extents.x,  extents.y, -extents.z)
    local pt0_4 = startPoint + Vector(-extents.x, -extents.y,  extents.z)
    local pt0_5 = startPoint + Vector( extents.x, -extents.y,  extents.z)
    local pt0_6 = startPoint + Vector(-extents.x,  extents.y,  extents.z)
    local pt0_7 = startPoint + Vector( extents.x,  extents.y,  extents.z)

    local pt1_0 = endPoint + Vector(-extents.x, -extents.y, -extents.z)
    local pt1_1 = endPoint + Vector( extents.x, -extents.y, -extents.z)
    local pt1_2 = endPoint + Vector(-extents.x,  extents.y, -extents.z)
    local pt1_3 = endPoint + Vector( extents.x,  extents.y, -extents.z)
    local pt1_4 = endPoint + Vector(-extents.x, -extents.y,  extents.z)
    local pt1_5 = endPoint + Vector( extents.x, -extents.y,  extents.z)
    local pt1_6 = endPoint + Vector(-extents.x,  extents.y,  extents.z)
    local pt1_7 = endPoint + Vector( extents.x,  extents.y,  extents.z)

    local numSteps = 5
    local stepInterp = 1.0 / (numSteps - 1)
    for i=1, numSteps do
        local index = i-1
        local interp = stepInterp * index

        -- green = clear, red = obstructed, color intensity fades along trace vector.
        local color = (fraction >= interp) and Color(0,1,0,1) or Color(1,0,0,1)
        color = color * (interp * 0.5 + 0.5)
        color.a = 1.0

        local p0 = Client.WorldToScreen(pt0_0 * (1.0 - interp) + pt1_0 * interp)
        local p1 = Client.WorldToScreen(pt0_1 * (1.0 - interp) + pt1_1 * interp)
        local p2 = Client.WorldToScreen(pt0_2 * (1.0 - interp) + pt1_2 * interp)
        local p3 = Client.WorldToScreen(pt0_3 * (1.0 - interp) + pt1_3 * interp)
        local p4 = Client.WorldToScreen(pt0_4 * (1.0 - interp) + pt1_4 * interp)
        local p5 = Client.WorldToScreen(pt0_5 * (1.0 - interp) + pt1_5 * interp)
        local p6 = Client.WorldToScreen(pt0_6 * (1.0 - interp) + pt1_6 * interp)
        local p7 = Client.WorldToScreen(pt0_7 * (1.0 - interp) + pt1_7 * interp)

        gDebugTraceRenderLayer:AddLine(p0, p1, color)
        gDebugTraceRenderLayer:AddLine(p1, p3, color)
        gDebugTraceRenderLayer:AddLine(p3, p2, color)
        gDebugTraceRenderLayer:AddLine(p2, p0, color)
        gDebugTraceRenderLayer:AddLine(p4, p5, color)
        gDebugTraceRenderLayer:AddLine(p5, p7, color)
        gDebugTraceRenderLayer:AddLine(p7, p6, color)
        gDebugTraceRenderLayer:AddLine(p6, p4, color)
        gDebugTraceRenderLayer:AddLine(p0, p4, color)
        gDebugTraceRenderLayer:AddLine(p1, p5, color)
        gDebugTraceRenderLayer:AddLine(p2, p6, color)
        gDebugTraceRenderLayer:AddLine(p3, p7, color)
    end

end

local function Debug_VisualizeTrace(startPoint, endPoint, color, fraction)

    if not Client then
        return
    end

    if not debugPlacement then
        return
    end

    if not gDebugTraceRenderLayer then
        gDebugTraceRenderLayer = GUI.CreateItem()
        gDebugTraceRenderLayer:SetOptionFlag(GUIItem.ManageRender)
        gDebugTraceRenderLayer:SetLayer(20)
        gDebugTraceRenderLayer:SetIsVisible(true)
    end

    fraction = fraction or 1

    local pt0 = Client.WorldToScreen(startPoint)
    local pt1 = Client.WorldToScreen(startPoint * (1.0 - fraction) + endPoint * fraction)
    local pt2 = Client.WorldToScreen(endPoint)

    color = color or Color(1,1,1,1)
    color2 = color * 0.333
    color2.a = 1.0

    gDebugTraceRenderLayer:AddLine(pt0, pt1, color)
    gDebugTraceRenderLayer:AddLine(pt1, pt2, color2)

    -- small x at start
    gDebugTraceRenderLayer:AddLine(pt0 - Vector(3,3,0), pt0 + Vector(3,3,0), color)
    gDebugTraceRenderLayer:AddLine(pt0 - Vector(-3,3,0), pt0 + Vector(-3,3,0), color)

    -- small x at fractionPoint
    gDebugTraceRenderLayer:AddLine(pt1 - Vector(2,2,0), pt1 + Vector(2,2,0), color2)
    gDebugTraceRenderLayer:AddLine(pt1 - Vector(-2,2,0), pt1 + Vector(-2,2,0), color2)

end

local function Debug_VisualizePoint(pt, color)

    if not Client then
        return
    end

    if not debugPlacement then
        return
    end

    pt0_0 = Client.WorldToScreen(pt) - Vector(4,4,0)
    pt0_1 = Client.WorldToScreen(pt) + Vector(4,4,0)

    pt1_0 = Client.WorldToScreen(pt) - Vector(-4,4,0)
    pt1_1 = Client.WorldToScreen(pt) + Vector(-4,4,0)

    gDebugTraceRenderLayer:AddLine(pt0_0, pt0_1, color)
    gDebugTraceRenderLayer:AddLine(pt1_0, pt1_1, color)

end

local kUpVector = Vector(0, 1, 0)
local kCheckDistance = 0.8 -- bigger than onos
local kVerticalOffset = 0.3
local kVerticalSpace = 1.75
local kBoxSweepOutset = 0.2
local kBoxSweepHeight = 0.5
local kGroundCheckDistance = 2.0

-- maximum distance the centroid of the trace end points can be from original position before being
-- considered too bent.
local kBentThreshold = 0.235
local kBentThresholdSq = kBentThreshold * kBentThreshold

local function CalculateTunnelPosition(position, player, surfaceNormal)

    PROFILE("CalculateTunnelPosition")

    local xAxis
    local zAxis
    local dot

    local valid = true

    Debug_ClearTraceVis()

    -- if the gorge isn't facing a point on the ground, and we are too far off the ground for the
    -- downward trace to find a surface, we're given a 0 vector and a garbage position for this
    -- function call... just fail.
    if surfaceNormal.x == 0.0 and surfaceNormal.y == 0.0 and surfaceNormal.z == 0.0 then
        return false, nil
    end

    if not surfaceNormal then
        return false, nil
    end

    dot = surfaceNormal:DotProduct(kUpVector)
    if dot < 0.86603 then -- 30 degrees off vertical
        valid = false -- keep processing so we get a better visualization.
    end

    if math.abs(kUpVector:DotProduct(surfaceNormal)) >= 0.9999 then
        xAxis = Vector(1,0,0)
    else
        xAxis = kUpVector:CrossProduct(surfaceNormal):GetUnit()
    end

    zAxis = xAxis:CrossProduct(surfaceNormal)

    local pts =
    {
        xAxis * -kCheckDistance + surfaceNormal * kGroundCheckDistance,
        xAxis * -kCheckDistance * 0.707 + zAxis * -kCheckDistance * 0.707 + surfaceNormal * kGroundCheckDistance,
        zAxis * -kCheckDistance + surfaceNormal * kGroundCheckDistance,
        xAxis *  kCheckDistance * 0.707 + zAxis * -kCheckDistance * 0.707 + surfaceNormal * kGroundCheckDistance,
        xAxis *  kCheckDistance + surfaceNormal * kGroundCheckDistance,
        xAxis *  kCheckDistance * 0.707 + zAxis *  kCheckDistance * 0.707 + surfaceNormal * kGroundCheckDistance,
        zAxis *  kCheckDistance + surfaceNormal * kGroundCheckDistance,
        xAxis * -kCheckDistance * 0.707 + zAxis *  kCheckDistance * 0.707 + surfaceNormal * kGroundCheckDistance,
    }

    local groundHits = {}
    for i = 1, #pts do
        local traceStart = pts[i] + position
        local traceEnd = pts[i] + position - (surfaceNormal * kGroundCheckDistance * 1.5)
        local trace = Shared.TraceRay(traceStart, traceEnd, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterOneAndIsa(player, "Babbler"))

        Debug_VisualizeTrace(traceStart, traceEnd, nil, trace.fraction)

        -- can never place on top of entities.
        if trace.entity ~= nil then
            Debug_VisualizeTrace(traceStart, traceEnd, Color(1,0,0.5,1))
            valid = false
        end

        -- all points of the gorge tunnel must either be on pathable ground, or on "tunnel_allowed" ground.
        if not IsPathable(trace.endPoint) and trace.surface ~= "tunnel_allowed" then
            Debug_VisualizeTrace(traceStart, traceEnd, Color(1,0,0,1))
            valid = false
        end

        -- trace never touches anything... don't want gorge tunnels hanging off cliffs!
        if trace.fraction == 1 then
            Debug_VisualizeTrace(traceStart, traceEnd, Color(1,0,0,1))
            valid = false
        else
            groundHits[#groundHits+1] = trace.endPoint
        end

    end

    -- smooth out the tunnel's orientation based on the 8 ground surface points we found.
    local centroid = Vector(0,0,0)
    for i=1, #groundHits do
        centroid = centroid + groundHits[i]
    end
    centroid = centroid / #groundHits

    -- ensure the "disc" of trace points isn't too bent.  Slopes are fine, but we don't want
    -- tunnels being placed on too uneven ground.  Measure how bent it is by how far the
    -- centroid is from the initial trace point.
    if (centroid - position):GetLengthSquared() > kBentThresholdSq then
        Debug_VisualizePoint(position, Color(1.0, 0.0, 0.0, 1))
        Debug_VisualizePoint(centroid, Color(0.5, 0.0, 0, 1))
        Debug_DisplayBentness((position + centroid) * 0.5, string.format("%.4f", (centroid - position):GetLength()), Color(0.75, 0.0, 0.0, 1.0))
        -- too bent!  Not a good tunnel placement.
        valid = false
    else
        Debug_DisplayBentness((position + centroid) * 0.5, string.format("%.4f", (centroid - position):GetLength()), Color(0.0, 0.75, 0.0, 1.0))
        Debug_VisualizePoint(position, Color(0, 0.5, 1.0, 1))
        Debug_VisualizePoint(centroid, Color(1.0, 0.5, 0, 1))
    end

    for i=1, #groundHits do
        groundHits[i] = groundHits[i] - centroid
    end

    local avgNorm = Vector(0,0,0)
    for i=1, #groundHits do
        local p0 = groundHits[i]
        local p1 = groundHits[(i % #groundHits) + 1]
        avgNorm = avgNorm + p1:CrossProduct(p0):GetUnit()
    end
    avgNorm = avgNorm:GetUnit()

    local traceStart
    local traceEnd
    local extents
    if valid then

        -- check also if there is enough space above
        local xDot = math.abs(xAxis:DotProduct(kUpVector))
        local zDot = math.abs(zAxis:DotProduct(kUpVector))

        -- so the corners of the box don't dig into the ground at more extreme angles.
        local yOffset = dot * kVerticalOffset + xDot * kCheckDistance + zDot * kCheckDistance

        extents = Vector(kCheckDistance, kBoxSweepHeight, kCheckDistance)
        traceStart = position + Vector(0, yOffset, 0) + avgNorm * kBoxSweepOutset
        traceEnd = traceStart + avgNorm * (kVerticalSpace / dot)

        local trace = Shared.TraceBox(extents, traceStart, traceEnd, CollisionRep.Move, PhysicsMask.Movement, EntityFilterAll())

        Debug_VisualizeBoxTrace(traceStart, traceEnd, extents, trace.fraction)

        if trace.fraction ~= 1 then
            -- ceiling clearance is too low!
            valid = false
        end

    end

    if valid then

        -- trace backwards, to check for obstacles inside the gorge tunnel.  Don't go as close to the ground though, otherwise
        -- we always intersect the terrain, and use half extents, otherwise it's a bit too wide.
        local startPoint2 = traceEnd
        local endPoint2 = traceStart
        endPoint2 = (endPoint2 - startPoint2) * 0.667 + startPoint2
        local trace2 = Shared.TraceBox(extents * 0.5, startPoint2, endPoint2, CollisionRep.Move, PhysicsMask.Movement, EntityFilterAll())

        Debug_VisualizeBoxTrace(startPoint2, endPoint2, extents * 0.5, trace2.fraction)

        if trace2.fraction ~= 1 then
            -- something is protruding out of the middle of the tunnel!
            valid = false
        end

    end

    local newCoords = Coords()
    newCoords.origin = centroid
    newCoords.yAxis = avgNorm
    newCoords.zAxis = Vector(1,0,0):CrossProduct(avgNorm):GetUnit()
    newCoords.xAxis = newCoords.yAxis:CrossProduct(newCoords.zAxis)

    return valid, newCoords

end

function TunnelEntranceAbility:ModifyCoords(coords, _, normal, player)

    PROFILE("TunnelEntranceAbility:ModifyCoords")

    local _, newCoords = CalculateTunnelPosition(coords.origin, player, normal)

    if newCoords then
        coords.origin = newCoords.origin
        coords.xAxis = newCoords.xAxis
        coords.yAxis = newCoords.yAxis
        coords.zAxis = newCoords.zAxis
    end

end

function TunnelEntranceAbility:GetIsPositionValid(position, player, surfaceNormal)

    PROFILE("TunnelEntranceAbility:GetIsPositionValid")

    local valid, _ = CalculateTunnelPosition(position, player, surfaceNormal)

    return valid

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