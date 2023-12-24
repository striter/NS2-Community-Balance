Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'CragAbility' (AdvancedStructureAbility)

function CragAbility:GetDropStructureId()
    return kTechId.Crag
end

function CragAbility:GetStructurePlaceSide()
    return AdvancedStructureAbility.kStructurePlaceSide.All
end

if Client then
    function CragAbility:GetGUITechAndDescription()
        if not self:GetHasTech(kTechId.CragHive) then
            return kTechId.None, nil
        end

        local count = GetTeamInfoEntity(kAlienTeamType).cragCount
        if count then
            local nextBiomassLevel = GetOriginFormBiomassLevel(count) + 1
            local nextBiomass = kTechId.RecoverBiomassThree
            if nextBiomassLevel == 2 then
                nextBiomass = kTechId.RecoverBiomassOne
            elseif nextBiomassLevel == 3 then
                nextBiomass = kTechId.RecoverBiomassTwo
            end

            return nextBiomass , string.format("%d/%d",count,kBiomassPerTower[math.min(#kBiomassPerTower, nextBiomassLevel)])
        end
        return kTechId.None, nil
    end
end 