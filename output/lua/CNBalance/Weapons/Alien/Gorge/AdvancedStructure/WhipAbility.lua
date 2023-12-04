Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'WhipAbility' (AdvancedStructureAbility)

function WhipAbility:GetDropStructureId()
    return kTechId.Whip
end

function WhipAbility:OverrideInfestationCheck(_trace)
    return true
end
function WhipAbility:CouldPlaceNonUpward()
    return true
end