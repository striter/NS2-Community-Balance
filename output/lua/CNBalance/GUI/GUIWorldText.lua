
local function CreateMessageItem(self)

    local messageItem = GetGUIManager():CreateTextItem()
    messageItem:SetFontName(GUIWorldText.kFont)
    messageItem:SetScale(GetScaledVector())
    GUIMakeFontScale(messageItem)
    messageItem:SetTextAlignmentX(GUIItem.Align_Center)
    messageItem:SetTextAlignmentY(GUIItem.Align_Center)
    messageItem:SetDropShadowEnabled(true)

    table.insert(self.messages, messageItem)

end

local function RemoveMessageItem(self, messageItem)

    table.removevalue(self.messages, messageItem)
    GUI.DestroyItem(messageItem)

end

local kDeathColor = Color(1,0,0,1)
function GUIWorldText:Update(deltaTime)

    PROFILE("GUIWorldText:Update")

    if not self.messages then
        Print("Warning: GUIWorldText script has not been cleaned up properly")
        return
    end

    local messages = PlayerUI_GetWorldMessages()
    local messageDiff = #messages - #self.messages

    if messageDiff > 0 then

        -- add new messages
        for i = 1, math.abs(messageDiff) do
            CreateMessageItem(self)
        end

    elseif messageDiff < 0 then

        -- remove unused messages
        for i = 1, math.abs(messageDiff) do
            RemoveMessageItem(self, self.messages[1])
        end

    end

    if #self.messages > 0 then
        self.updateInterval = kUpdateIntervalFull
    else
        self.updateInterval = kUpdateIntervalLow
    end

    for index, message in ipairs(messages) do

        -- Fetch UI element to update from our current message
        local messageItem = self.messages[index]

        if message.messageType == kWorldTextMessageType.Damage then

            local useColor = ConditionalValue(PlayerUI_IsOnMarineTeam(), GUIWorldText.kMarineDamageColor, GUIWorldText.kAlienDamageColor)
            local entity = Shared.GetEntity(message.entityId)
            if entity and entity.GetHealthScalar then
                useColor = LerpColor(kDeathColor,useColor,entity:GetHealthScalar())
            end
            
            self:UpdateDamageMessage(message, messageItem, useColor, deltaTime)

        elseif message.messageType == kWorldTextMessageType.DamageBoneshield then
            self:UpdateDamageMessage(message, messageItem, GUIWorldText.kBoneshieldDamageColor, deltaTime)
        else
            local useColor = ConditionalValue(PlayerUI_IsOnMarineTeam(), Color(kMarineTeamColorFloat), Color(kAlienTeamColorFloat))
            self:UpdateRegularMessage(message, messageItem, useColor)
        end

        if self.visible == false then
            messageItem:SetIsVisible(false)
        end

    end

end
