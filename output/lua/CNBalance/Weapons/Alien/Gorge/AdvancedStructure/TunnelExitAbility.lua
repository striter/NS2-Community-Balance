Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/TunnelEntranceAbility.lua")

class 'TunnelExitAbility' (TunnelEntranceAbility)

function TunnelExitAbility:GetDropStructureId()
    return kTechId.TunnelExit
end

function TunnelExitAbility:ModifyCoords(coords, _, normal, player)
    
end

function TunnelExitAbility:GetIsPositionValid(position, player, surfaceNormal)
    return AdvancedStructureAbility.GetIsPositionValid(self,position, player, surfaceNormal)
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