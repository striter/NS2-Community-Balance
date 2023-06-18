-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Mine.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/StunMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/MarineOutlineMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/Ragdoll.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")

class 'Mine' (ScriptActor)

Mine.kMapName = "active_mine"

Mine.kModelName = PrecacheAsset("models/marine/mine/mine.model")
-- The amount of time until the mine is detonated once armed.
local kTimeArmed = 0.1
-- The amount of time it takes other mines to trigger their detonate sequence when nearby mines explode.
local kTimedDestruction = 0.5

local kWarmupSound = PrecacheAsset("sound/NS2.fev/marine/common/mine_warmup")
local kKillNoBoomBoomSound = PrecacheAsset("sound/NS2.fev/marine/structures/recycle")

-- range in which other mines are trigger when detonating
local kMineChainDetonateRange = 3

local kMineCameraShakeDistance = 15
local kMineMinShakeIntensity = 0.01
local kMineMaxShakeIntensity = 0.13

local networkVars = {
    camouflaged = "boolean",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(StunMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)

function Mine:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, StunMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, ParasiteMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, CombatMixin)

    if Client then
        InitMixin(self, MarineOutlineMixin)
    end

    if Server then

        -- init after OwnerMixin since 'OnEntityChange' is expected callback
        InitMixin(self, SleeperMixin)

        self:SetUpdates(true, kDefaultUpdateRate)

    end

end

function Mine:OverrideCheckVisibilty()

    local isParasited = HasMixin(self, "ParasiteAble") and self:GetIsParasited()
    local isInCombat = HasMixin(self, "Combat") and self:GetIsInCombat()

    return isParasited or isInCombat
end

function Mine:GetReceivesStructuralDamage()
    return true
end

local function SineFalloff(distanceFraction)
    local piFraction = Clamp(distanceFraction, 0, 1) * math.pi / 2
    return math.cos(piFraction + math.pi) + 1
end

function Mine:Detonate()
    if not self.active then return end

    local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kMineDetonateRange)
    RadiusDamage(hitEntities, self:GetOrigin(), kMineDetonateRange, kMineDamage, self, false, SineFalloff)

    -- Start the timed destruction sequence for any mine within range of this exploded mine.
    local nearbyMines = GetEntitiesWithinRange("Mine", self:GetOrigin(), kMineChainDetonateRange)
    for _, mine in ipairs(nearbyMines) do

        if mine ~= self and not mine.armed then
            mine:AddTimedCallback(mine.Arm, (math.random() + math.random()) * kTimedDestruction)
        end

    end

    local params = {}
    params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis )

    params[kEffectSurface] = "metal"

    self:TriggerEffects("mine_explode", params)

    DestroyEntity(self)

    CreateExplosionDecals(self)
    TriggerCameraShake(self, kMineMinShakeIntensity, kMineMaxShakeIntensity, kMineCameraShakeDistance)

end

-- Returns true if the mine was armed, or was already armed.  False if the mine was not armed.
function Mine:Arm()

    if not self.active then return false end

    if not self.armed then

        self:AddTimedCallback(self.Detonate, kTimeArmed)

        self:TriggerEffects("mine_arm")

        self.armed = true

    end

    return true -- self.armed is always true at this point.

end

function Mine:CheckEntityExplodesMine(entity)

    if not self.active then
        return false
    end

    if entity:isa("Hallucination") or entity.isHallucination then
        return false
    end

    if not HasMixin(entity, "Team") or GetEnemyTeamNumber(self:GetTeamNumber()) ~= entity:GetTeamNumber() then
        return false
    end

    if not HasMixin(entity, "Live") or not entity:GetIsAlive() or not entity:GetCanTakeDamage() then
        return false
    end

    if not (entity:isa("Player") or entity:isa("Whip") or entity:isa("Babbler")) then
        return false
    end

    if entity:isa("Commander") then
        return false
    end

    if entity:isa("Fade") and entity:GetIsBlinking() then

        return false

    end

    local minePos = self:GetEngagementPoint()
    local targetPos = entity:GetEngagementPoint()
    -- Do not trigger through walls. But do trigger through other entities.
    if not GetWallBetween(minePos, targetPos, entity) then

        -- If this fails, targets can sit in trigger, no "polling" update performed.
        self:Arm()
        return true

    end

    return false

end

function Mine:CheckAllEntsInTriggerExplodeMine()

    local ents = self:GetEntitiesInTrigger()
    for e = 1, #ents do
        self:CheckEntityExplodesMine(ents[e])
    end

end

function Mine:OnInitialized()

    ScriptActor.OnInitialized(self)

    if Server then

        InitMixin(self, MapBlipMixin)
        InitMixin(self, InfestationTrackerMixin)

        self.active = false
        self:AddTimedCallback(self.Activate, kMineActiveTime)

        self.armed = false
        self.harmless = false
        self:SetHealth(self:GetMaxHealth())
        self:SetArmor(self:GetMaxArmor())
        self:TriggerEffects("mine_spawn")
        self:PlaySound(kWarmupSound)

        InitMixin(self, TriggerMixin)
        self:SetSphere(kMineTriggerRange)

        self.camouflaged = GetHasTech(self,kTechId.ArmorStation)
    end

    self:SetModel(Mine.kModelName)
end

if Server then

    function Mine:OnDestroy()

        self:StopSound(kWarmupSound)

        ScriptActor.OnDestroy(self)

    end

end

if Server then
    function Mine:Activate()
        self.active = true
        self:CheckAllEntsInTriggerExplodeMine()
    end

    function Mine:OnTouchInfestation()
        self:Arm()
    end

    function Mine:OnStun()
        self:Arm()
    end

    function Mine:OnKill(attacker, doer, point, direction)

        local isArmed = self:Arm()
        self.harmless = not isArmed

        -- Spawn a mine ragdoll if the mine was destroyed without exploding.
        if self.harmless then
            CreateMineRagdoll(self)
            Shared.PlayWorldSound(nil, kKillNoBoomBoomSound, nil, self:GetOrigin(), 1)
        end

        ScriptActor.OnKill(self, attacker, doer, point, direction)

    end

    function Mine:GetPlayInstantRagdoll()
        return true
    end

    function Mine:GetDestroyOnKill()
        return self.harmless
    end

    function Mine:OnTriggerEntered(entity)
        self:CheckEntityExplodesMine(entity)
    end

    --
    -- Go to sleep my sweet little mine if there are no entities nearby.
    --
    function Mine:GetCanSleep()
        return self:GetNumberOfEntitiesInTrigger() == 0
    end

    --
    -- We need to check when there are entities within the trigger area often.
    --
    function Mine:OnUpdate()

        local now = Shared.GetTime()
        self.lastMineUpdateTime = self.lastMineUpdateTime or now
        if now - self.lastMineUpdateTime >= 0.5 then

            self:CheckAllEntsInTriggerExplodeMine()
            self.lastMineUpdateTime = now

        end

    end

end

function Mine:GetRequiresPower()
    return false
end

function Mine:GetCanBeUsed(_, useSuccessTable)
    useSuccessTable.useSuccess = false
end

function Mine:GetTechButtons(techId)

    local techButtons

    if techId == kTechId.RootMenu then

        techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                        kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    end

    return techButtons

end

function Mine:GetAttachPointOriginHardcoded()
    return self:GetOrigin() + self:GetCoords().yAxis * 0.01
end

function Mine:GetDeathIconIndex()
    return kDeathMessageIcon.Mine
end

if Client then

    function Mine:OnInitialized()

        InitMixin(self, HiveVisionMixin)
        ScriptActor.OnInitialized(self)

    end

    function Mine:OnGetIsVisible(visibleTable, viewerTeamNumber)

        local player = Client.GetLocalPlayer()

        if player and player:isa("Commander") and viewerTeamNumber == GetEnemyTeamNumber(self:GetTeamNumber()) then

            visibleTable.Visible = false

        end

    end

end

function Mine:ComputeDamageOverride(attacker, damage, damageType, hitPoint, overshieldDamage)

    -- Lerk spikes do double damage to mines.
    if damageType == kDamageType.Puncture and attacker:isa("Lerk") then
        damage = damage * 2
    end

    return damage, overshieldDamage

end

function Mine:GetShowSensorBlip()
    return false
end

function Mine:GetMapBlipType()
    return kMinimapBlipType.SensorBlip -- Todo: Add mine blip type
end

Shared.LinkClassToMap("Mine", Mine.kMapName, networkVars)

class "MineRagdoll" (Ragdoll)

MineRagdoll.kMapName = "mine_ragdoll"

function CreateMineRagdoll(fromMine)

    local ragdoll = CreateEntity(MineRagdoll.kMapName, fromMine:GetOrigin())
    ragdoll:SetCoords(fromMine:GetCoords())
    ragdoll:SetModel(fromMine:GetModelName())
    ragdoll:SetPhysicsType(PhysicsType.Dynamic)
    ragdoll:SetPhysicsGroup(PhysicsGroup.RagdollGroup)

end

-- constants for the mine flipping.
MineRagdoll.kOffsetXZScale = 0.1
MineRagdoll.kOffsetYScale = 0.1
MineRagdoll.kImpulseMagnitude = 0.25

if Client then

    function MineRagdoll:DoFlip()

        local physicsModel = self:GetPhysicsModel()
        if physicsModel then
            local offset = Vector((math.random() * 2 - 1) * self.kOffsetXZScale, math.random() * self.kOffsetYScale, (math.random() * 2 - 1) * self.kOffsetXZScale)
            physicsModel:AddImpulse(offset, self:GetCoords().yAxis * MineRagdoll.kImpulseMagnitude)
            return false -- don't fire again
        end

        return true -- not available, try again next update.
    end

    function MineRagdoll:OnInitialized()

        Ragdoll.OnInitialized(self)

        -- Add random impulse to make the mine flip around.
        -- Gotta do it once the physics model is available though, so keep trying until we can.
        self:AddTimedCallback(self.DoFlip, 0)

    end

    function Mine:GetIsHighlightEnabled()
        return self.camouflaged and 0.94 or 1
    end

end

Shared.LinkClassToMap("MineRagdoll", MineRagdoll.kMapName, {})