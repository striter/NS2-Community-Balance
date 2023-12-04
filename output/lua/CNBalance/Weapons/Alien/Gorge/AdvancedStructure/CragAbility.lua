Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'CragAbility' (AdvancedStructureAbility)

function CragAbility:GetDropStructureId()
    return kTechId.Crag
end

function CragAbility:OverrideInfestationCheck(_trace)
    return true
end
function CragAbility:CouldPlaceNonUpward()
    return true
end