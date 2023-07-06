Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = ArmsLab.OnCreate
function ArmsLab:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function ArmsLab:GetHealthPerTeamExceed()
    return kArmsLabHealthPerPlayerAdd
end