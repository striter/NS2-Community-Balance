Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'EggAbility' (AdvancedStructureAbility)

function EggAbility:GetDropStructureId()
    return kTechId.Egg
end

function EggAbility:OverrideInfestationCheck(_trace)
    return true
end
function EggAbility:ModifyCoords(coords)
    coords.origin = coords.origin + coords.yAxis * 0.1
end