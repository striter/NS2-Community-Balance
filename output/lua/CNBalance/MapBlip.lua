if Client then

    local kExoMapBlipTypes = {
        [kMinimapBlipType.ClawMinigunExo] = true,
        [kMinimapBlipType.ClawRailgunExo] = true,
        [kMinimapBlipType.DualRailgunExo] = true,
    }

    local baseGetMapBlipColor = MapBlip.GetMapBlipColor
    function MapBlip:GetMapBlipColor(minimap, item)
        local color = baseGetMapBlipColor(self, minimap, item)
        if kExoMapBlipTypes[self.mapBlipType] then
            color = MapBlip.kCustomMarineColor or color
        end
        return color
    end

end
