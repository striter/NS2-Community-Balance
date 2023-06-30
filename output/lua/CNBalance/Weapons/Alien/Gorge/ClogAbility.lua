
function ClogAbility:GetMaxStructures(biomass)
    return 10 + math.floor(biomass/2) * 2
end