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
                    kTechId.PhaseTech, kTechId.MotionTrack, kTechId.None, kTechId.None }
    end

    return nil

end

Observatory.kBeaconVO = PrecacheAsset("sound/ns2plus.fev/comm/beacon")
local baseTriggerDistressBeacon = Observatory.TriggerDistressBeacon
function Observatory:TriggerDistressBeacon()

    local success = baseTriggerDistressBeacon(self)
    if success then
        self:GetTeam():PlayPrivateTeamSound(Observatory.kBeaconVO)
    end
    return success, not success

end