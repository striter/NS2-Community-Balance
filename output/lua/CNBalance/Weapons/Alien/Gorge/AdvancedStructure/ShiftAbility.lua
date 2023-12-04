Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'ShiftAbility' (AdvancedStructureAbility)

function ShiftAbility:GetDropStructureId()
    return kTechId.Shift
end

function ShiftAbility:GetGhostModelTechId()
    return kTechId.GorgeShiftGhostModelOverride
end

function ShiftAbility:OverrideInfestationCheck(_trace)
    return true
end
function ShiftAbility:CouldPlaceNonUpward()
    return true
end