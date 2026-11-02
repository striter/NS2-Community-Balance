if Client then

    local function ResolveAreaName(location)
        local raw = location and location:GetName() or ""
        if Locale.ResolveLocation then
            raw = Locale.ResolveLocation(raw)
        end
        return raw
    end

    local function EvaluateBatterySlots(battery, position)
        if not battery or not GetSentryBatteryCandidates then
            return true, 0, 1
        end
        local cap = GetSentryBatterySlotCap(battery)
        local distSelf = battery:GetOrigin():GetDistanceTo(position)
        local closer = 0
        local powered = 0
        for _, candidate in ipairs(GetSentryBatteryCandidates(battery)) do
            if candidate.dist < distSelf then
                closer = closer + 1
            end
            if candidate.powered then
                powered = powered + 1
            end
        end
        return closer < cap, math.min(powered, cap), cap
    end

    local baseUpdate = MarineGhostModel.Update
    function MarineGhostModel:Update()
        baseUpdate(self)
        if not GetSentryBatteryCoveringPoint or not self.powerIcon then
            return
        end
        local player = Client.GetLocalPlayer()
        if not player or not player.GetGhostModelCoords then
            return
        end
        local techId = player.currentTechId
        if not (techId and techId ~= kTechId.None and LookupTechData(techId, kTechDataRequiresPower, false)) then
            return
        end
        local coords = player:GetGhostModelCoords()
        if not coords then
            return
        end
        local coveringBat = GetSentryBatteryCoveringPoint(coords.origin, player:GetTeamNumber())
        if not coveringBat then
            return
        end
        local wins, used, cap = EvaluateBatterySlots(coveringBat, coords.origin)
        if techId ~= kTechId.Sentry and not wins then
            return
        end
        local location = GetLocationForPoint(coords.origin)
        local powerNode = location and GetPowerPointForLocation(location:GetName())
        if powerNode and powerNode:GetIsPowering() then
            return
        end
        local areaName = ResolveAreaName(location)
        local poweredText
        if techId == kTechId.Sentry then
            poweredText = string.format(Locale.ResolveString("CNBATTERY_POWERED"), areaName)
        else
            poweredText = string.format(Locale.ResolveString("CNBATTERY_POWERED_SLOTS"), areaName, used, cap)
        end
        local animation = (1 + math.sin(Shared.GetTime() * 8)) * 0.5
        local poweredColor = Color(
            (1 - kMarineTeamColorFloat.r) * animation + kMarineTeamColorFloat.r,
            (1 - kMarineTeamColorFloat.g) * animation + kMarineTeamColorFloat.g,
            (1 - kMarineTeamColorFloat.b) * animation + kMarineTeamColorFloat.b,
            1
        )
        if powerNode then
            self.powerIcon:SetColor(poweredColor)
            if self.powerLocationText then
                self.powerLocationText:SetText(poweredText)
                self.powerLocationText:SetColor(poweredColor)
            end
        else
            self.powerIcon:SetIsVisible(true)
            self.powerIcon:SetColor(poweredColor)
            local screenPos = Client.WorldToScreen(coords.origin)
            self.powerIcon:SetPosition(screenPos + GUIScale(Vector(36, -36, 0)))
            if self.powerLocationText then
                self.powerLocationText:SetIsVisible(true)
                self.powerLocationText:SetText(poweredText)
                self.powerLocationText:SetColor(poweredColor)
                self.powerLocationText:SetAnchor(GUIItem.Left, GUIItem.Center)
                self.powerLocationText:SetTextAlignmentX(GUIItem.Align_Min)
                self.powerLocationText:SetPosition(GUIScale(Vector(38, 0, 0)))
            end
        end
    end

end
