Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'ShellAbility' (AdvancedStructureAbility)

function ShellAbility:GetDropStructureId()
    return kTechId.Shell
end
function ShellAbility:CouldPlaceNonUpward()
    return true
end

if Client then

    function ShellAbility:GetGUITechAndDescription()
        if self:GetHasTech(kTechId.ThreeShells) then
            return kTechId.ThreeVeils , "x3"
        elseif self:GetHasTech(kTechId.TwoShells) then
            return kTechId.TwoVeils , "x2"
        elseif self:GetHasTech(kTechId.Shell) then
            return kTechId.Veil , "x1"
        end

        return kTechId.Shell , "x0"
    end

end 