Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'WhipAbility' (AdvancedStructureAbility)

function WhipAbility:GetDropStructureId()
    return kTechId.Whip
end

function WhipAbility:OverrideInfestationCheck(_trace)
    return true
end
function WhipAbility:GetStructurePlaceSide(player)
    return GetHasTech(player,kTechId.OriginForm)
            and AdvancedStructureAbility.kStructurePlaceSide.All
            or AdvancedStructureAbility.kStructurePlaceSide.Upward
end