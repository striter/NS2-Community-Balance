-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\BabblerEggAbility.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'SporeMineAbility' (StructureAbility)

function SporeMineAbility:GetEnergyCost(player)
    return kDropStructureEnergyCost
end

function SporeMineAbility:GetGhostModelName(ability)       --TD-FIXME Needs means to swap mat
    return SporeMine.kModelName
    
end

function SporeMineAbility:GetDropStructureId()
    return kTechId.SporeMine
end

local function SporeMineEntityFilter(entity)
    return function (test) return EntityFilterOneAndIsa(entity, "Clog") or test:isa("Hydra") end
end

function SporeMineAbility:GetIsPositionValid(position, player, normal, lastClickedPosition, _, entity)

    PROFILE("SporeMineAbility:GetIsPositionValid")

    local valid = true
    if valid then
        local extents = GetExtents(kTechId.SporeMine) / 2.25
        local traceStart = position + normal * 0.15 -- A bit above to allow hydras to be placed on uneven ground easily
        local traceEnd = position + normal * extents.y
        trace = Shared.TraceBox(extents, traceStart, traceEnd, CollisionRep.Damage, PhysicsMask.Bullets, SporeMineEntityFilter(player))

        if trace.fraction ~= 1 then
            -- DebugTraceBox(extents, traceStart, traceEnd, 0.1, 45, 45, 45, 1)
            valid = false
        end
    end

    return valid

end

function SporeMineAbility:GetSuffixName()
    return "sporemine"
end

function SporeMineAbility:GetDropClassName()
    return "SporeMine"
end

function SporeMineAbility:GetDropRange()
    return SporeMine.kDropRange
end

function SporeMineAbility:GetDropMapName()
    return SporeMine.kMapName
end

function SporeMineAbility:GetMaxStructures(biomass)
    return 1 + math.floor(biomass  / 4)
end