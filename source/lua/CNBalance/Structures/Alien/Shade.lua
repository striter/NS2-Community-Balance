Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Shade.OnCreate
function Shade:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Shade:GetHealthPerBioMass()
    return kCragHealthPerBioMass
end