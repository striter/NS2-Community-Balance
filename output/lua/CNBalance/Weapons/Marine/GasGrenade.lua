

local kCloudUpdateRate = 0.3
local kSpreadDelay = 0.6
local kNerveGasCloudRadius = kNerveGasCloudRadius
local kNerveGasCloudLifetime = 8

local function TimeUp(self)
    DestroyEntity(self)
end

function NerveGasCloud:OnCreate()

    Entity.OnCreate(self)

    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)

    if Server then

        self.creationTime = Shared.GetTime()

        self:AddTimedCallback(TimeUp, kNerveGasCloudLifetime)
        self:AddTimedCallback(NerveGasCloud.DoNerveGasDamage, kCloudUpdateRate)

        InitMixin(self, OwnerMixin)

    end

    --Realtime required for position updates to be smooth
    --Otherwise gas cloud will "hop" due to shit update rate.
    self:SetUpdates(true, kRealTimeUpdateRate)

    self:SetRelevancyDistance(kMaxRelevancyDistance)

end

local gNerveGasDamageTakers = {}

local function GetIsInCloud(self, entity, radius)

    local targetPos = entity.GetEyePos and entity:GetEyePos() or entity:GetOrigin()
    return (self:GetOrigin() - targetPos):GetLength() <= radius

end

local function GetRecentlyDamaged(entityId, time)

    for index, pair in ipairs(gNerveGasDamageTakers) do
        if pair[1] == entityId and pair[2] > time then
            return true
        end
    end

    return false

end

local function SetRecentlyDamaged(entityId)

    for index, pair in ipairs(gNerveGasDamageTakers) do
        if pair[1] == entityId then
            table.remove(gNerveGasDamageTakers, index)
        end
    end

    table.insert(gNerveGasDamageTakers, {entityId, Shared.GetTime()})

end

-- Use CombatMixin.GetIsUnderFire to check if entity is recently damaged
local function GetIsUnderFire(entity)
    if entity.GetIsUnderFire then
        return entity:GetIsUnderFire()
    end
    return false
end

local debugVisUpdateRate = 0.1
local lastVisUpdate = 0
function NerveGasCloud:DoNerveGasDamage()

    local radius = math.min(1, (Shared.GetTime() - self.creationTime) / kSpreadDelay) * kNerveGasCloudRadius

    local time = Shared.GetTime()
    for _, entity in ipairs(GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), 2*kNerveGasCloudRadius)) do
        if not GetRecentlyDamaged(entity:GetId(), (Shared.GetTime() - kCloudUpdateRate)) and GetIsInCloud(self, entity, radius) and GetIsUnderFire(entity) then
            self:DoDamage(kNerveGasDamagePerSecond * kCloudUpdateRate, entity, entity:GetOrigin(), GetNormalizedVector(self:GetOrigin() - entity:GetOrigin()), "none")
            SetRecentlyDamaged(entity:GetId())
        end
    end
    
    for _, entity in ipairs(GetEntitiesWithMixinForTeamWithinRange("Regeneration", self:GetTeamNumber(), self:GetOrigin(), 2*kNerveGasCloudRadius)) do
        if not GetRecentlyDamaged(entity:GetId(), (Shared.GetTime() - kCloudUpdateRate)) and GetIsInCloud(self, entity, radius) and GetIsUnderFire(entity) then
            SetRecentlyDamaged(entity:GetId())
            entity:AddRegeneration(kNerveGasRegenPerSecond * kCloudUpdateRate)
        end
    end

    if GetDebugGrenadeDamage() then
        if lastVisUpdate + debugVisUpdateRate < time then
        --throttled to prevent net-msg spam
            lastVisUpdate = time
            DebugWireSphere( self:GetOrigin(), radius, 0.45, 1, 1, 0, 1 )
        end
    end

    return true

end
