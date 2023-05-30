-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Prowler_Client.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Prowler.kCameraRollSpeedModifier = 0.5
Prowler.kCameraRollTiltModifier = 0.05

Prowler.kViewModelRollSpeedModifier = 7
Prowler.kViewModelRollTiltModifier = 0.15

function Prowler:GetHealthbarOffset()
    return 0.7
end

function Prowler:GetHeadAttachpointName()
    return ""
end

function Prowler:GetSpeedDebugSpecial()
    return 0
end

--[[function Prowler:ModifyViewModelCoords(viewModelCoords)

    if self.currentViewModelRoll ~= 0 then

        local roll = self.currentViewModelRoll and self.currentViewModelRoll * Prowler.kViewModelRollTiltModifier or 0
        local rotationCoords = Angles(0, 0, roll):GetCoords()
        
        return viewModelCoords * rotationCoords
    
    end
    
    return viewModelCoords

end--]]