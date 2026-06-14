
if Client then

    local kHiveReturnHoldTime = 0.6
    local kHiveReturnProximitySq = 6.25

    local baseOnProcessMove = AlienActionFinderMixin.OnProcessMove

    function AlienActionFinderMixin:OnProcessMove(input)
        baseOnProcessMove(self, input)

        -- Check for Shift return-to-hive interaction
        local player = Client.GetLocalPlayer()
        if player == self and self.actionIconGUI and self:GetIsAlive() and not self:GetIsDestroyed() and GetHasTech(self, kTechId.ShiftHive) then

            local shifts = GetEntitiesForTeam("Shift", self:GetTeamNumber())
            local shiftWithEcho = nil
            if shifts then
                for _, shift in ipairs(shifts) do
                    if GetIsUnitActive(shift) and shift.echoLocationId and shift.echoLocationId > 0 then
                        if (self:GetOrigin() - shift:GetOrigin()):GetLengthSquared() <= kHiveReturnProximitySq then
                            shiftWithEcho = shift
                            break
                        end
                    end
                end
            end

            if shiftWithEcho then
                -- Get location name from locationId (works even if far hive is not in client's entity list)
                local hintText = "ECHO_RETURN"
                if shiftWithEcho.echoLocationId and shiftWithEcho.echoLocationId > 0 then
                    local rawName = Shared.GetString(shiftWithEcho.echoLocationId)
                    local locationName = Locale.ResolveLocation and Locale.ResolveLocation(rawName) or rawName
                    if locationName and locationName ~= "" then
                        hintText = Locale.ResolveString("ECHO_RETURN") .. " → " .. locationName
                    end
                end
                
                local holdStart = self._clientEHoldStart
                if holdStart then
                    local elapsed = Shared.GetTime() - holdStart
                    if elapsed < kHiveReturnHoldTime then
                        self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, hintText, elapsed / kHiveReturnHoldTime)
                        if self.actionIconGUI.holdText then
                            self.actionIconGUI.holdText:SetText(string.format("%d%%", math.floor(elapsed / kHiveReturnHoldTime * 100)))
                        end
                    else
                        self._clientEHoldStart = nil
                        self.actionIconGUI:Hide()
                    end
                else
                    self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, hintText, nil)
                end
            end
        end
    end

end
