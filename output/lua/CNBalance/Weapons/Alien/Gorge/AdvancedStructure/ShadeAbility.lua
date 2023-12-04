Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'ShadeAbility' (AdvancedStructureAbility)

function ShadeAbility:GetDropStructureId()
    return kTechId.Shade
end

function ShadeAbility:OverrideInfestationCheck(_trace)
    return true
end
function ShadeAbility:CouldPlaceNonUpward()
    return true
end