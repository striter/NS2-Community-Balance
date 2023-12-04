Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/AttachStructureAbility.lua")

class 'ShiftHiveAbility' (AttachStructureAbility)

ShiftHiveAbility.kDropRange = 6.5

function ShiftHiveAbility:GetDropRange()
    return ShiftHiveAbility.kDropRange
end

function ShiftHiveAbility:GetEnergyCost()
    return 80
end

function ShiftHiveAbility:GetDropStructureId()
    return kTechId.ShiftHive
end

function ShiftHiveAbility:PostOnCreate(_ent)
    --_ent.hiveType = 3
    _ent:OnResearchComplete(kTechId.UpgradeToShiftHive)
end