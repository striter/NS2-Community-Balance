function GetBotWalkDistance(botPlayerOrPos, targetEntOrPos, targetLocationHint)
    PROFILE("GetBotWalkDistance")

    local botLocationName
    local botPos

    if botPlayerOrPos:isa("Vector") then -- This can fail inside tunnels
        local posLocation = GetLocationForPoint(botPlayerOrPos)
        botLocationName = posLocation and posLocation:GetName() or nil
        botPos = botPlayerOrPos
    elseif botPlayerOrPos:isa("ScriptActor") then
        botLocationName = botPlayerOrPos:GetLocationName()
        botPos = botPlayerOrPos:GetOrigin()
    else
        assert(false, "targetEntOrPos must be a Vector or ScriptActor!")
    end

    local targetPos
    local targetLocationName

    if targetEntOrPos:isa("Vector") then -- This can fail inside tunnels
        targetLocationName = targetLocationHint
        targetPos = targetEntOrPos
    elseif targetEntOrPos:isa("ScriptActor") then
        --McG: Note: if entity (i.e. player) is in _some_ vents, they won't be in a location. depends on the map
        targetLocationName = targetEntOrPos:GetLocationName()
        targetPos = targetEntOrPos:GetOrigin()
    elseif targetEntOrPos:isa("Entity") then
        targetLocationName = targetLocationHint
        targetPos = targetEntOrPos:GetOrigin()
    else
        assert(false, "targetEntOrPos must be a Vector, Entity, or ScriptActor!")
    end

    if not targetLocationName then
        --Determine the target's location if it is not provided by ScriptActor or explicit hint
        local posLocation = GetLocationForPoint(targetPos)
        targetLocationName = posLocation and posLocation:GetName() or nil
    end

    if  not botLocationName or botLocationName == "" or
        not targetLocationName or targetLocationName == "" then
        return botPos:GetDistance(targetPos)
    end

    -- Same location name, so gateway distance shouldn't apply
    if botLocationName == targetLocationName then
        return botPos:GetDistance(targetPos)
    end

    local gatewayDistTable = GetLocationGraph():GetGatewayDistance(botLocationName, targetLocationName)
    if not gatewayDistTable then
        -- Fallback: return straight-line distance if no path is found
        return botPos:GetDistance(targetPos)
    end
    local gatewayDistance = gatewayDistTable.distance
    local enterGatePos = gatewayDistTable.enterGatePos -- the gateway pos on the starting location we used
    local exitGatePos = gatewayDistTable.exitGatePos -- the gateway pos on the end location we used

    -- Calculate distance using gateway distance, and two linear distances for bot->enter gateway, and exit gateway->targetEntPos
    local enterDist = (enterGatePos - botPos):GetLength()
    local exitDist = (targetPos - exitGatePos):GetLength()

    return enterDist + gatewayDistance + exitDist
end

-- Hopefully this fixes the bot problem regarding "attempt to index local 'gatewayDistTable' (a nil value)"