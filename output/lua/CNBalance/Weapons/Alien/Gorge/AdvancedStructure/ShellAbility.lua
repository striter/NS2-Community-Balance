Script.Load("lua/CNBalance/Weapons/Alien/Gorge/AdvancedStructure/AdvancedStructureAbility.lua")

class 'ShellAbility' (AdvancedStructureAbility)

function ShellAbility:GetDropStructureId()
    return kTechId.Shell
end
function ShellAbility:GetStructurePlaceSide()
    return AdvancedStructureAbility.kStructurePlaceSide.All
end

if Client then

    function ShellAbility:GetGUITechAndDescription()
        if self:GetHasTech(kTechId.ThreeShells) then
            return kTechId.ThreeShells , "x3"
        elseif self:GetHasTech(kTechId.TwoShells) then
            return kTechId.TwoShells , "x2"
        elseif self:GetHasTech(kTechId.Shell) then
            return kTechId.Shell , "x1"
        end

        return kTechId.Shell , "x0"
    end

end 