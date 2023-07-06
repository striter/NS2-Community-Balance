
Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = PowerPoint.OnCreate
function PowerPoint:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function PowerPoint:GetHealthPerTeamExceed()
    return kPowerPointHealthPerPlayerAdd
end
