
function WebsAbility:GetMaxStructures(biomass)
    return 3 + math.floor((biomass + 1 ) / 3)
end