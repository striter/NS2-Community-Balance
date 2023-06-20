
function BabblerEggAbility:GetMaxStructures(biomass)
    return 1 + math.floor(biomass / 5)
end