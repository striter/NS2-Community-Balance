
function ParseMarineBuildMessage(t)
    return t.origin, t.direction, t.structureIndex, t.lastClickedPosition
end

function OnCommandMarineBuildStructure(client, message)

    local player = client:GetControllingPlayer()
    local origin, direction, structureIndex, lastClickedPosition = ParseMarineBuildMessage(message)
    
    local dropStructureAbility = player:GetActiveWeapon()
    -- The player may not have an active weapon if the message is sent
    -- after the player has gone back to the ready room for example.
    if dropStructureAbility and dropStructureAbility.OnDropStructure then
        dropStructureAbility:OnDropStructure(origin, direction, structureIndex, lastClickedPosition)
    end
    
end
Server.HookNetworkMessage("MarineBuildStructure", OnCommandMarineBuildStructure)


function OnCommandGorgeBuildStructure(client, message)

    local player = client:GetControllingPlayer()
    local origin, direction, structureTechId, lastClickedPosition, lastClickedPositionNormal = ParseGorgeBuildMessage(message)

    local activeAbility = player:GetActiveWeapon()
    if not activeAbility then
        return 
    end
    
    if activeAbility.OnDropStructure then
        activeAbility:OnDropStructure(origin, direction, structureTechId, lastClickedPosition, lastClickedPositionNormal)
    end
end
Server.HookNetworkMessage("GorgeBuildStructure", OnCommandGorgeBuildStructure)