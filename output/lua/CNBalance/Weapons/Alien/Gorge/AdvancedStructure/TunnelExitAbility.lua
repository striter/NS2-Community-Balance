Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/TunnelEntranceAbility.lua")

class 'TunnelExitAbility' (TunnelEntranceAbility)

function TunnelExitAbility:GetDropStructureId()
    return kTechId.TunnelExit
end
if Server then

    function TunnelExitAbility:CreateStructure(coords, player, lastClickedPosition)

        local entity =  CreateEntity(self:GetDropMapName(), coords.origin, player:GetTeamNumber())
        entity:UpgradeToTechId(kTechId.TunnelExit)
        return entity
    end
end