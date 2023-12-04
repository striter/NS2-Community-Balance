Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/AttachStructureAbility.lua")

class 'ShadeHiveAbility' (AttachStructureAbility)

ShadeHiveAbility.kDropRange = 6.5

function ShadeHiveAbility:GetDropRange()
    return ShadeHiveAbility.kDropRange
end

function ShadeHiveAbility:GetEnergyCost()
    return 80
end

function ShadeHiveAbility:GetDropStructureId()
    return kTechId.ShadeHive
end

function ShadeHiveAbility:PostOnCreate(_ent)
    --_ent.hiveType = 2
    _ent:OnResearchComplete(kTechId.UpgradeToShadeHive)
end