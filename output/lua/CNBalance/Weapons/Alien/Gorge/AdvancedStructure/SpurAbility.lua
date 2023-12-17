Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'SpurAbility' (AdvancedStructureAbility)

function SpurAbility:GetDropStructureId()
    return kTechId.Spur
end
function SpurAbility:CouldPlaceNonUpward()
    return true
end

if Client then

    function SpurAbility:GetGUITechAndDescription()
        if self:GetHasTech(kTechId.ThreeSpurs) then
            return kTechId.ThreeVeils , "x3"
        elseif self:GetHasTech(kTechId.TwoSpurs) then
            return kTechId.TwoVeils , "x2"
        elseif self:GetHasTech(kTechId.Spur) then
            return kTechId.Veil , "x1"
        end

        return kTechId.Spur , "x0"
    end

end 