Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'VeilAbility' (AdvancedStructureAbility)

function VeilAbility:GetDropStructureId()
    return kTechId.Veil
end
function VeilAbility:GetStructurePlaceSide()
    return AdvancedStructureAbility.kStructurePlaceSide.All
end

if Client then

    function VeilAbility:GetGUITechAndDescription()
        if self:GetHasTech(kTechId.ThreeVeils) then
            return kTechId.ThreeVeils , "x3"
        elseif self:GetHasTech(kTechId.TwoVeils) then
            return kTechId.TwoVeils , "x2"
        elseif self:GetHasTech(kTechId.Veil) then
            return kTechId.Veil , "x1"
        end

        return kTechId.Veil , "x0"
    end

end 