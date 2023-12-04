Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/AttachStructureAbility.lua")

class 'CragHiveAbility' (AttachStructureAbility)

CragHiveAbility.kDropRange = 6.5

function CragHiveAbility:GetDropRange()
    return CragHiveAbility.kDropRange
end

function CragHiveAbility:GetEnergyCost()
    return 80
end

function CragHiveAbility:GetDropStructureId()
    return kTechId.CragHive
end

function CragHiveAbility:PostOnCreate(_ent)
    --_ent.hiveType = 1
    _ent:OnResearchComplete(kTechId.UpgradeToCragHive)
end