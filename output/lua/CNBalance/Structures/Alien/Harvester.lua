Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Harvester.OnCreate
function Harvester:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Harvester:GetHealthPerTeamExceed()
    return kHarvesterHealthPerPlayerAdd
end
