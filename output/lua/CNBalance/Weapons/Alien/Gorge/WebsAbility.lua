
function WebsAbility:GetMaxStructures(biomass)
    return 2 + math.floor((biomass + 1 ) / 3)
end