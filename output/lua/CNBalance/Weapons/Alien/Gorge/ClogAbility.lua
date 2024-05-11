
function ClogAbility:GetMaxStructures(biomass)
    return 10 + math.floor(biomass/2) * 2
end

local kGreaterDistance = 1.5
local kMinDistance = 0.5
function ClogAbility:GetIsPositionValid(position, player, normal)

    local entities = GetEntitiesWithinRange("ScriptActor", position, 7)
    for _, entity in ipairs(entities) do

        if not entity:isa("Infestation") and not entity:isa("Babbler") and entity ~= player and (not entity.GetIsAlive or entity:GetIsAlive()) then

            local checkDistance = ConditionalValue(entity:isa("PhaseGate") or entity:isa("TunnelEntrance") or entity:isa("InfantryPortal"), kGreaterDistance, kMinDistance)
            local valid = ((entity:GetCoords().yAxis * checkDistance * 0.75 + entity:GetOrigin()) - position):GetLength() > checkDistance

            if not valid then
                return false
            end

        end

    end

    -- ensure we're not creating clogs inside of other clogs.
    local radius = Clog.kRadius - 0.001
    local entities = GetEntitiesWithinRange("Clog", position, radius)
    for i=1, #entities do
        if entities[i] then
            return false
        end
    end

    return true


end