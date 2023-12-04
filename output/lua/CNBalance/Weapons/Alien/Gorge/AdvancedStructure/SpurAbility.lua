Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'SpurAbility' (AdvancedStructureAbility)

function SpurAbility:GetDropStructureId()
    return kTechId.Spur
end
function SpurAbility:CouldPlaceNonUpward()
    return true
end