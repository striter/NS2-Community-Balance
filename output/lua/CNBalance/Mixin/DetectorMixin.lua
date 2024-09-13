-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\DetectorMixin.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

DetectorMixin = CreateMixin(DetectorMixin)
DetectorMixin.type = "Detector"

-- Should be smaller than DetectableMixin:kResetDetectionInterval
local kUpdateDetectionInterval = 0.5

DetectorMixin.expectedCallbacks =
{
    -- Returns integer for team number
    GetTeamNumber = "",
    
    -- Returns 0 if not active currently
    GetDetectionRange = "Return range of the detector.",
    
    GetOrigin = "Detection origin",
}

local function PerformDetection(self)

    -- Get list of Detectables in range.
    local range = self:GetDetectionRange()
    
    if range > 0 then
    
        local teamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
        local origin = self:GetOrigin()
        local detectables = GetEntitiesWithMixinForTeamWithinXZRange("Detectable", teamNumber, origin, range)
        
        -- Mark them as detected.
        for index, detectable in ipairs(detectables) do
            if not detectable:isa("Alien")
                    or not GetHasCamouflageUpgrade(detectable) then
                detectable:SetDetected(true)
                if detectable:isa("Skulk") and self.SetParasited then
                    self:SetParasited(detectable)
                end
            end

            if detectable.OnScan then
                detectable:OnScan()
            end
        end
        
    end
    
    return true
    
end

function DetectorMixin:__initmixin()
    
    PROFILE("DetectorMixin:__initmixin")
    
    self.timeSinceLastDetected = 0
    
    self:AddTimedCallback(PerformDetection, kUpdateDetectionInterval)
    
end