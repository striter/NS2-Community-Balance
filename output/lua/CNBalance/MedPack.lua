

MedPack.kRegen = kMedpackRegen
MedPack.kMedpackRegenWhenHealing = kMedpackRegenWhenHealing

function MedPack:OnTouch(recipient)

    if not recipient.timeLastMedpack or recipient.timeLastMedpack + self.kPickupDelay <= Shared.GetTime() then

        local oldHealth = recipient:GetHealth()
        if recipient:GetRegeneratingHealth() <= 0 then
            recipient:AddHealth(MedPack.kHealth, false, true)
            recipient:AddRegeneration(MedPack.kRegen)
        else
            recipient:AddHealth(kMedpackHealWhenRegening, false, true)
            recipient:AddRegeneration(kMedpackRegenWhenRegening)
        end

        recipient.timeLastMedpack = Shared.GetTime()

        self:TriggerEffects("medpack_pickup", { effecthostcoords = self:GetCoords() })

        -- Handle Stats
        if Server then

            local commanderStats = StatsUI_GetStatForCommander(StatsUI_GetMarineCommmaderSteamID())

            -- If the medpack hits immediatly expireTime is 0
            if ConditionalValue(self.expireTime == 0, Shared.GetTime(), self.expireTime - kItemStayTime) + 0.025 > Shared.GetTime() then
                commanderStats["medpack"].hitsAcc = commanderStats["medpack"].hitsAcc + 1
            end

            commanderStats["medpack"].misses = commanderStats["medpack"].misses - 1
            commanderStats["medpack"].picks = commanderStats["medpack"].picks + 1
            commanderStats["medpack"].refilled = commanderStats["medpack"].refilled + recipient:GetHealth() - oldHealth

        end

    end
    
end