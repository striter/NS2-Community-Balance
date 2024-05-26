Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")
class 'ProwlerStructureAbility' (DropStructureAbility)
ProwlerStructureAbility.kMapName = "prowler_structure_ability"

local networkVars =
{
}


function ProwlerStructureAbility:OnProcessIntermediate()
    DropStructureAbility.OnProcessIntermediate(self)
    --RappelMixin.ProcessIntermediate(self)
end
function ProwlerStructureAbility:GetHUDSlot()
    return 2
end

if Client then

    function ProwlerStructureAbility:OnDrawClient()

        DropStructureAbility.OnDrawClient(self)
        
        if self.menuActive then
            self:SetActiveStructure(kTechId.Web)
            self.menuActive = false
        end

    end

end
Shared.LinkClassToMap("ProwlerStructureAbility", ProwlerStructureAbility.kMapName, networkVars)