
function HydraStructureAbility:GetEnergyCost()
    return 25
end

function HydraStructureAbility:GetMaxStructures(biomass)
    return 3 + math.floor(biomass / 4)
end