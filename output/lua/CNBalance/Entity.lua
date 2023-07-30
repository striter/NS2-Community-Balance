-- Rewrite,some aoe should only be able damage as much as 2x its damage to nearest target,then fades ASAP to prevent unacceptable damage to teaming groups
local kUpEndFallOffDoers = {
    ["Grenade"] = true,
    ["ImpactGrenade"] = true,
    ["Mine"] = true,
    --["ClusterGrenade"] = true,
    --["PulseGrenade"] = true,        --Unable due to some reason
}

function RadiusDamageWithUpEnd(entities, centerOrigin, radius, fullDamage, doer, ignoreLOS, fallOffFunc, useXZDistance)
    local radiusSquared = radius * radius

    local inRangeEntities = {}

    -- Do damage to every target in range
    for _, target in ipairs(entities) do

        -- Find most representative point to hit
        local targetOrigin = GetTargetOrigin(target)
        local distanceVector = targetOrigin - centerOrigin

        -- Trace line to each target to make sure it's not blocked by a wall
        local wallBetween = false
        local distanceFromTarget
        if useXZDistance then
            distanceFromTarget = distanceVector:GetLengthSquaredXZ()
        else
            distanceFromTarget = distanceVector:GetLengthSquared()
        end

        if not ignoreLOS then
            wallBetween = GetWallBetween(centerOrigin, targetOrigin, target)
        end

        if (ignoreLOS or not wallBetween) and (distanceFromTarget <= radiusSquared) then
            local damageDirection = distanceVector
            damageDirection:Normalize()
            table.insert(inRangeEntities,{entity = target,distance = distanceFromTarget,direction = damageDirection})
        end

    end

    local function DistanceCompare(a, b) return a.distance < b.distance end
    table.sort(inRangeEntities,DistanceCompare)

    local index = 0
    for _,targetTable in pairs(inRangeEntities) do
        index = index + 1
        target = targetTable.entity
        -- Damage falloff
        local damage = fullDamage

        if target:isa("Player") then    
            if index <= 1 then
                --damage = fullDamage
            elseif index <= 2 then
                damage = fullDamage * 0.7
            else
                damage = fullDamage * 0.2
            end
        end
        
        local distanceFraction = targetTable.distance / radiusSquared
        if fallOffFunc then
            distanceFraction = fallOffFunc(distanceFraction)
        end
        distanceFraction = Clamp(distanceFraction, 0, 1)
        damage = damage * (1 - distanceFraction)
        
        doer:DoDamage(damage, target, target:GetOrigin(), targetTable.direction, "none")
    end
end

local baseRadiusDamage = RadiusDamage
function RadiusDamage(entities, centerOrigin, radius, fullDamage, doer, ignoreLOS, fallOffFunc, useXZDistance)
    if kUpEndFallOffDoers[doer:GetClassName()] ~= nil then
        RadiusDamageWithUpEnd(entities, centerOrigin, radius, fullDamage, doer, ignoreLOS, fallOffFunc, useXZDistance)
        return
    end
    baseRadiusDamage(entities, centerOrigin, radius, fullDamage, doer, ignoreLOS, fallOffFunc, useXZDistance)
end

