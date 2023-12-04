Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'AttachStructureAbility' (StructureAbility)

AttachStructureAbility.kDropRange = 6.5
AttachStructureAbility.kAttachToPoints = true

function AttachStructureAbility:GetDropRange()
    return AttachStructureAbility.kDropRange
end

function AttachStructureAbility:GetGhostModelName(ability)       --TD-FIXME Needs means to swap mat

    --local player = ability:GetParent()
    --if player and player:isa("Gorge") then
    --
    --    local clientVariants = GetAndSetVariantOptions()
    --    local variant = clientVariants.alienStructuresVariant
    --
    --    if variant == kAlienStructureVariants.Shadow or variant == kHydraVariants.Auric then
    --        return Hydra.kModelNameShadow
    --    elseif variant == kHydraVariants.Abyss then
    --        return Hydra.kModelNameAbyss
    --    end
    --
    --end

    return LookupTechData(self:GetDropStructureId(),kTechDataModel)

end

function AttachStructureAbility:GetIsPositionValid(position, player, surfaceNormal)
    local techId = self:GetDropStructureId()
    return GetAttachEntity(techId,position,kStructureSnapRadius) ~= nil
end

function AttachStructureAbility:ModifyCoords(coords)
    local techId = self:GetDropStructureId()
    
    local entity = GetAttachEntity(techId,coords.origin,kStructureSnapRadius)
    if entity then
            
        local dstCoords = entity:GetCoords()
        coords.origin = dstCoords.origin
        coords.zAxis = dstCoords.zAxis
        coords.yAxis = dstCoords.yAxis
        coords.xAxis = dstCoords.xAxis
    end
    
    local spawnHeight = LookupTechData(techId, kTechDataSpawnHeightOffset, 0)
    if spawnHeight then
        coords.origin = coords.origin + Vector(0,spawnHeight,0)
    end
end


function AttachStructureAbility:GetDropStructureId()
    assert(false,"Override this please")
    --return kTechId.BuildMenu
end

function AttachStructureAbility:CreateStructure(coords, player, structureAbility)

    local techId = self:GetDropStructureId()
    local mapName = LookupTechData(techId, kTechDataMapName)
    local newEnt = nil
    if mapName then
        local origin = coords.origin
        newEnt = CreateEntity( mapName, origin, player:GetTeamNumber() )

        -- Hook it up to attach entity
        local attachEntity = GetAttachEntity(techId, origin,kStructureSnapRadius)
        if attachEntity then
            newEnt:SetAttached(attachEntity)
        end
        self:PostOnCreate(newEnt)
    end
    return newEnt
end

function AttachStructureAbility:PostOnCreate(_ent)
    
end

function AttachStructureAbility:GetEnergyCost()
    return 40 -- Todo: Make a balance var
end

function AttachStructureAbility:IsAllowed(player)
    return true
end

function AttachStructureAbility:GetMaxStructures(biomass)
    return -1
end