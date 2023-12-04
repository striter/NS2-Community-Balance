Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'ShellAbility' (AdvancedStructureAbility)

function ShellAbility:GetDropStructureId()
    return kTechId.Shell
end
function ShellAbility:CouldPlaceNonUpward()
    return true
end