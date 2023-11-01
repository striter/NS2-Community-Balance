Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'HiveStructureAbility' (StructureAbility)

HiveStructureAbility.kDropRange = 6.5

function HiveStructureAbility:GetDropRange()
    return HiveStructureAbility.kDropRange
end

function HiveStructureAbility:GetEnergyCost()
    return 40 -- Todo: Make a balance var
end

function HiveStructureAbility:GetGhostModelName(ability)       --TD-FIXME Needs means to swap mat

    local player = ability:GetParent()
    if player and player:isa("Gorge") then

        local clientVariants = GetAndSetVariantOptions()
        local variant = clientVariants.hydraVariant

        if variant == kHydraVariants.Shadow or variant == kHydraVariants.Auric then
            return Hydra.kModelNameShadow
        elseif variant == kHydraVariants.Abyss then
            return Hydra.kModelNameAbyss
        end

    end

    return Hydra.kModelName

end

function HiveStructureAbility:GetDropStructureId()
    return kTechId.Hive
end

function HiveStructureAbility:GetIsPositionValid(position, player, surfaceNormal)
    return GetAttachEntity(kTechId.Hive,position,kStructureSnapRadius) ~= nil
end

function HiveStructureAbility:ModifyCoords(coords)
    local entity = GetAttachEntity(kTechId.Hive,coords.origin,kStructureSnapRadius)
    if entity then
        coords.origin =  entity:GetOrigin()
    end
end

function HiveStructureAbility:GetSuffixName()
    return "Hive"
end

function HiveStructureAbility:GetDropClassName()
    return "Hive"
end

function HiveStructureAbility:GetDropMapName()
    return Hive.kMapName
end
