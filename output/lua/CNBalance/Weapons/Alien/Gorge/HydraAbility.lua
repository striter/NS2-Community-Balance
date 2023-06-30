
function HydraStructureAbility:GetEnergyCost()
    return 40
end

function HydraStructureAbility:GetMaxStructures(biomass)
    return 3 + math.floor(biomass / 4)
end