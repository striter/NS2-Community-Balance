Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'VeilAbility' (AdvancedStructureAbility)

function VeilAbility:GetDropStructureId()
    return kTechId.Veil
end
function VeilAbility:CouldPlaceNonUpward()
    return true
end