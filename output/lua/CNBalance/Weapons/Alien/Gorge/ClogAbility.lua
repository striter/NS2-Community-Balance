
function ClogAbility:GetMaxStructures(biomass)
    return 8 + math.floor(biomass/2) * 2
end