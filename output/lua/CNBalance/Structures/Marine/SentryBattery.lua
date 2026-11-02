SentryBattery.kRange = 5

function GetSentryBatteryCoveringPoint(point, teamNumber)
    if not point or not teamNumber then
        return nil
    end
    for _, battery in ipairs(GetEntitiesForTeam("SentryBattery", teamNumber)) do
        if GetIsUnitActive(battery) and battery:GetOrigin():GetDistanceTo(point) <= SentryBattery.kRange then
            return battery
        end
    end
    return nil
end

function GetSentryBatterySlotCap(entity)
    if GetHasTech and entity and GetHasTech(entity, kTechId.ElectronicStation) then
        return kMaxLocalPoweredElectronic or 2
    end
    return kMaxLocalPowered or 1
end

function IsSentryBatteryPowerTarget(battery, consumer)
    if consumer == battery or consumer:isa("SentryBattery") then
        return false
    end
    if HasMixin(consumer, "Live") and consumer.GetIsAlive and not consumer:GetIsAlive() then
        return false
    end
    if HasMixin(consumer, "Recycle") and consumer.GetIsRecycled and (consumer:GetIsRecycled() or consumer:GetIsRecycling()) then
        return false
    end
    return true
end

function GetSentryBatteryCandidates(battery)
    local origin = battery:GetOrigin()
    local result = { }
    for _, consumer in ipairs(GetEntitiesWithMixinForTeamWithinRange("PowerConsumer", battery:GetTeamNumber(), origin, SentryBattery.kRange)) do
        if IsSentryBatteryPowerTarget(battery, consumer) and (not consumer.GetIsBuilt or consumer:GetIsBuilt()) then
            table.insert(result, { id = consumer:GetId(), dist = origin:GetDistanceTo(consumer:GetOrigin()), powered = consumer.localPower or false })
        end
    end
    return result
end

if Server then

    local function GetPoweredList(battery)
        if not battery.localPoweredIds then
            battery.localPoweredIds = { }
            battery.localPoweredSet = { }
        end
        return battery.localPoweredIds, battery.localPoweredSet
    end

    local function RemoveAllLocalPower(battery)
        if battery.localPoweredIds then
            for index = #battery.localPoweredIds, 1, -1 do
                local consumer = Shared.GetEntity(battery.localPoweredIds[index])
                if consumer and consumer.SetLocalPower then
                    consumer:SetLocalPower(false)
                end
            end
            battery.localPoweredIds = nil
            battery.localPoweredSet = nil
        end
    end

    local function IsPoweredByOtherBattery(battery, consumerId)
        for _, other in ipairs(GetEntitiesForTeam("SentryBattery", battery:GetTeamNumber())) do
            if other ~= battery and other.localPoweredSet and other.localPoweredSet[consumerId] then
                return true
            end
        end
        return false
    end

    local function SelectPoweredConsumers(battery)
        local candidates = GetSentryBatteryCandidates(battery)
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
        local selected = { }
        for index = 1, math.min(GetSentryBatterySlotCap(battery), #candidates) do
            selected[candidates[index].id] = true
        end
        return selected
    end

    local function UpdateLocalPowerRange(battery)
        local time = Shared.GetTime()
        if battery.lastLocalPowerCheckTime == nil or time > battery.lastLocalPowerCheckTime + 0.5 then
            battery.lastLocalPowerCheckTime = time
            local poweredList, poweredSet = GetPoweredList(battery)
            local selectedSet = { }
            if GetIsUnitActive(battery) then
                selectedSet = SelectPoweredConsumers(battery)
            end
            for consumerId in pairs(selectedSet) do
                if not poweredSet[consumerId] then
                    local consumer = Shared.GetEntity(consumerId)
                    if consumer and consumer.SetLocalPower then
                        consumer:SetLocalPower(true)
                    end
                    poweredSet[consumerId] = true
                    table.insert(poweredList, consumerId)
                end
            end
            for index = #poweredList, 1, -1 do
                local consumerId = poweredList[index]
                if not selectedSet[consumerId] then
                    local consumer = Shared.GetEntity(consumerId)
                    if consumer and consumer.SetLocalPower and not IsPoweredByOtherBattery(battery, consumerId) then
                        consumer:SetLocalPower(false)
                    end
                    poweredSet[consumerId] = nil
                    table.remove(poweredList, index)
                end
            end
        end
    end

    function SentryBattery:OnUpdate(deltaTime)
        UpdateLocalPowerRange(self)
    end

    local baseOnDestroy = SentryBattery.OnDestroy
    function SentryBattery:OnDestroy()
        if baseOnDestroy then
            baseOnDestroy(self)
        end
        RemoveAllLocalPower(self)
    end

end
