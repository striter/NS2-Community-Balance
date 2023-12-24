Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'CystAbility' (AdvancedStructureAbility)

function CystAbility:GetDropStructureId()
    return kTechId.Cyst
end

function CystAbility:GetStructurePlaceSide()
    return AdvancedStructureAbility.kStructurePlaceSide.UpwardAndDownward
end

function CystAbility:GetGhostModelTechId()
    return kTechId.GorgeCystGhostModelOverride
end
