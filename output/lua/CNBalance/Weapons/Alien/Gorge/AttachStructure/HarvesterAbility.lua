Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AttachStructure/AttachStructureAbility.lua")

class 'HarvesterAbility' (AttachStructureAbility)

HarvesterAbility.kDropRange = 6.5

function HarvesterAbility:GetDropRange()
    return HarvesterAbility.kDropRange
end

function HarvesterAbility:GetEnergyCost()
    return 40
end

function HarvesterAbility:GetDropStructureId()
    return kTechId.Harvester
end