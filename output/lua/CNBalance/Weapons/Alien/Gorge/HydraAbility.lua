
function HydraStructureAbility:GetEnergyCost()
    return 27
end

function HydraStructureAbility:GetMaxStructures(biomass)
    return 2 + math.floor((biomass + 1 ) / 3)
end