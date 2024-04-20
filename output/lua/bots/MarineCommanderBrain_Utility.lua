-- ======= Copyright (c) 2003-2022, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/bots/MarineCommanderBrain_Utility.lua
--
--    Created by: Darrell Gentry (darrell@unknownworlds.com)
--
-- Utility functions for marine commander brain
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarinesNearbyRange = 200 --orginal 12

function GetBaseUnitFromDoables(senses, brain, doableList)
    PROFILE("GetBaseUnitFromDoables")

    if not doableList then return end

    local firstBaseDoable
    local tpLocations = GetLocationGraph():GetTechpointLocations()
    local homeBaseLocation = brain:GetStartingTechPoint()

    if homeBaseLocation and homeBaseLocation ~= "" then

        local homeBaseLocationId = Shared.GetStringIndex(homeBaseLocation)
        for _, unit in ipairs(doableList) do
            if unit:GetLocationId() == homeBaseLocationId then
                return unit
            end
        end

    end


end

function GetEntityCanUseMedpack(ent)

    local canUse = HasMixin(ent, "Live") and ent:GetHealthFraction() < 1
    local isOnCooldown = ent.timeLastMedpack and Shared.GetTime() < ent.timeLastMedpack + kMedpackPickupDelay

    return canUse and not isOnCooldown, isOnCooldown

end
