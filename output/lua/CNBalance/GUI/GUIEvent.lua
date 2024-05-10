
local kDebugNotifications = false
local function GetResearchTime(techNode)
    local researchTime = techNode.time
    if GetHasTech(Client.GetLocalPlayer(),kTechId.MilitaryProtocol) then
        researchTime = researchTime * kMilitaryProtocolResearchDurationMultiply
    end
    return researchTime
end


function GUIEvent:GetTimeLeftForResearch(techId, entityId)

    local techNode = GetTechNode(techId)
    local researchTime = GetResearchTime(techNode)
    local researchProgress = techNode:GetResearchProgress(entityId) or 1
    local timePassed = researchProgress * researchTime
    local timeLeftSeconds = researchTime - timePassed

    return timeLeftSeconds
end

GUIEvent.kBroadCastVO = {
    kTechId.MilitaryProtocol,
    kTechId.StandardSupply,
    kTechId.ArmorSupply,
    kTechId.ExplosiveSupply,
    kTechId.ElectronicSupply,
    kTechId.OriginForm,
}

function GUIEvent:Update(_, newNotification)

    local remainingNotifications = {}
    local remainingNotificationData = {}
    local newTechIdInsertIndex = 0

    if newNotification ~= nil then
        newTechIdInsertIndex = self:InsertNotification(newNotification)
    end

    -- A new research that has a time-to-complete that places it in our displayed notification items list.
    if newNotification ~= nil and newTechIdInsertIndex <= #self.displayedNotifications then

        local insertedNotificationItem = CreateNotificationItem(self.script, newNotification.techId, self.scale, self.notificationFrame, self.useMarineStyle, newNotification.entityId)
        insertedNotificationItem.lastSecondsLeft = self:GetTimeLeftForResearch(insertedNotificationItem.techId, insertedNotificationItem.entityId)

        table.insert(self.displayedNotifications, newTechIdInsertIndex, insertedNotificationItem)
        insertedNotificationItem:SetPositionInstant(newTechIdInsertIndex - 1)
        insertedNotificationItem:FadeIn(0.5)

        -- Shift down all the following displayed notifications.
        for i = newTechIdInsertIndex + 1, #self.displayedNotifications do
            self.displayedNotifications[i]:ShiftDown()
        end

    else

        -- Add more notifications if we haven't reached our max and have more research waiting. Since data is already sorted, we can simply add to the end.
        local numDisplayedNotifications = #self.displayedNotifications
        if numDisplayedNotifications < self.maxNotifications and #self.notificationsData > numDisplayedNotifications then

            local newNotificationPosition = numDisplayedNotifications + 1
            local data = self.notificationsData[newNotificationPosition]
            local newNotification = CreateNotificationItem(self.script, data.techId, self.scale, self.notificationFrame, self.useMarineStyle, data.entityId)

            newNotification:SetPositionInstant(newNotificationPosition - 1)
            newNotification:FadeIn(0.5)
            table.insert(self.displayedNotifications, newNotification)

        end
    end

    local techTree = GetTechTree()
    -- Move canceled research to the top if it's out of view so players know about it.
    if techTree:GetAndClearTechTreeResearchCancelled() then

        for i = 1, #self.notificationsData do

            local data = self.notificationsData[i]
            local inProgress = techTree:GetResearchInProgress(data.techId, data.entityId)

            -- Only need to pop it in if its not already on the top.
            if not inProgress and i > 1 then

                local insertedNotificationItem
                local cancelledOutOfView = false
                if i > #self.displayedNotifications then

                    cancelledOutOfView = true
                    insertedNotificationItem = CreateNotificationItem(self.script, data.techId, self.scale, self.notificationFrame, self.useMarineStyle, data.entityId)
                    table.insert(self.displayedNotifications, 1, insertedNotificationItem)

                else

                    insertedNotificationItem = self.displayedNotifications[i]
                    table.remove(self.displayedNotifications, i)
                    table.insert(self.displayedNotifications, 1, insertedNotificationItem)

                end

                table.remove(self.notificationsData, i)
                table.insert(self.notificationsData, 1, data)

                insertedNotificationItem:SetPositionInstant(0)
                insertedNotificationItem:FadeIn(0.5)

                -- Shift down all the following displayed notifications, up to wherever the notification was.
                local stopIndexInclusive = ConditionalValue(cancelledOutOfView, #self.displayedNotifications, i)
                for j = 2, stopIndexInclusive do

                    self.displayedNotifications[j]:ShiftDown()

                end

            end

        end
    end

    -- Update displayed notifications
    local shiftUpTimes = 0
    for index, displayedNotification in ipairs(self.displayedNotifications) do

        displayedNotification:UpdateItem()

        if kDebugNotifications then
            displayedNotification.techTitle:SetText(tostring(displayedNotification.position))
        end

        local completedThisUpdate = false
        local cancelledThisUpdate = false
        local techNode = techTree:GetTechNode(displayedNotification.techId)

        local researchProgress = techNode:GetResearchProgress(displayedNotification.entityId) or displayedNotification.lastProgress
        local researched = researchProgress == 1
        local researching = techTree:GetResearchInProgress(displayedNotification.techId, displayedNotification.entityId)

        -- First time we're processing a complete state.
        if researched and not displayedNotification:GetCompleted() then

            completedThisUpdate = true

            -- Fade out the item if the "stay time" has passed.
        elseif displayedNotification:GetShouldStartFading() then

            displayedNotification:FadeOut(1)

        elseif not displayedNotification:GetCancelled() and not displayedNotification:GetCompleted()
                and not researched and not researching then

            cancelledThisUpdate = true
        end

        if displayedNotification:GetIsReadyToBeDestroyed() then

            displayedNotification:Destroy()
            shiftUpTimes = shiftUpTimes + 1

        elseif index > self.maxNotifications then

            displayedNotification:FadeOut(0.5)
            table.insert(remainingNotifications, displayedNotification)
            table.insert(remainingNotificationData, self.notificationsData[index])

        else

            table.insert(remainingNotifications, displayedNotification)
            table.insert(remainingNotificationData, self.notificationsData[index])

            -- Update research status of the notification
            if not displayedNotification:GetCompleted() and not displayedNotification:GetCancelled() then

                -- Update the timer.
                local researchTime = GetResearchTime(techNode)
                local timePassed = researchProgress * researchTime
                local timeLeftSeconds = researchTime - timePassed
                displayedNotification.lastSecondsLeft = timeLeftSeconds

                local minutes = math.floor( timeLeftSeconds / 60 )
                local seconds = math.floor( timeLeftSeconds - minutes * 60 )

                local timeText = string.format( "%02d:%02d", minutes, seconds)
                displayedNotification.bottomText:SetText(timeText)

                -- Update the bar.
                local progressBarWidth = displayedNotification.progressBarSize.x
                local fullProgressBarHeight = displayedNotification.progressBarSize.y

                local fullNoGlowHeight = fullProgressBarHeight - (displayedNotification.guiOffsets.ProgressBarGlowRadius * 2)
                local noGlowHeight = Clamp(math.floor((fullNoGlowHeight * researchProgress)), 0, fullNoGlowHeight)

                -- Glow is part of the asset, so only add the glow part of the texture when we reach enough progress.
                local progressBarHeight = noGlowHeight

                if progressBarHeight > 0 then

                    progressBarHeight = progressBarHeight + displayedNotification.guiOffsets.ProgressBarGlowRadius

                    if progressBarHeight >= (fullProgressBarHeight - displayedNotification.guiOffsets.ProgressBarGlowRadius) then
                        progressBarHeight = fullProgressBarHeight
                    end
                end

                local barTexCoords = displayedNotification.progressBarTextureCoords
                barTexCoords[2] = barTexCoords[4] - progressBarHeight
                displayedNotification.progressBar:SetSize(Vector(progressBarWidth, progressBarHeight, 0))
                displayedNotification.progressBar:SetTexturePixelCoordinates(GUIUnpackCoords(barTexCoords))

                local newYPos = fullProgressBarHeight - progressBarHeight
                displayedNotification.progressBar:SetPosition( displayedNotification.guiOffsets.ProgressBarPos + Vector(0, newYPos, 0))

                if completedThisUpdate then

                    displayedNotification:SetCompleted()
                    if not table.contains(GUIEvent.kBroadCastVO,displayedNotification.techId) then
                        Client.GetLocalPlayer():TriggerEffects("upgrade_complete")
                    end

                elseif cancelledThisUpdate then

                    displayedNotification:SetCancelled()

                end
            end

            -- Shift up lower notifications if one has been destroyed.
            if shiftUpTimes > 0 then
                displayedNotification:ShiftUp(shiftUpTimes)
            end

        end

        -- Clean up the tech node's instance since we don't need it anymore.
        -- TODO(Salads): I don't want this here it smells
        if techNode.instances and (cancelledThisUpdate or completedThisUpdate) then

            techNode.instances[displayedNotification.entityId] = nil

        end

    end

    local lastDisplayIndex = #self.displayedNotifications
    self.displayedNotifications = remainingNotifications

    -- Add the leftover data after the last displayed notification index.
    for i = lastDisplayIndex + 1, #self.notificationsData do

        table.insert(remainingNotificationData, self.notificationsData[i])
    end

    self.notificationsData = remainingNotificationData
end