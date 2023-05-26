Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Shift.OnCreate
function Shift:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Shift:GetHealthPerBioMass()
    return kCragHealthPerBioMass
end