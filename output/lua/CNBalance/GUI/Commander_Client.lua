if Client then

    local function ShouldDrawBatteryGuides(commander)
        return commander.GetShowPowerIndicator
            and commander:GetShowPowerIndicator()
            and commander.currentTechId ~= kTechId.Sentry
    end

    local baseUpdateGhostGuides = Commander.UpdateGhostGuides
    function Commander:UpdateGhostGuides()
        baseUpdateGhostGuides(self)
        if ShouldDrawBatteryGuides(self) and GetBatteryInRange then
            local entities, ranges = GetBatteryInRange(self)
            for _, battery in ipairs(entities) do
                local radius = ranges[battery]
                if radius and GetIsUnitActive(battery) then
                    self:AddGhostGuide(Vector(battery:GetOrigin()), radius)
                end
            end
        end
    end

end
