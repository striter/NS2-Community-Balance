Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Observatory.OnCreate
function Observatory:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Observatory:GetHealthPerTeamExceed()
    return kObservatoryHealthPerPlayerAdd
end


function Observatory:GetTechButtons(techId)

    if techId == kTechId.RootMenu then
        return  { kTechId.Scan, kTechId.DistressBeacon, kTechId.None, kTechId.Detector,
        kTechId.PhaseTech, kTechId.None, kTechId.None, kTechId.None }
    end

    return nil

end