-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\PowerPointLightHandler.lua
--
--    Created by:   Mats Olsson (mats.olsson@matsotech.se)
--
-- Responsible for working the lights on a map. This is a performance critical area, as there are
-- lots of lights and they may need to be updated each client frame. Also, ALL lights over the whole
-- map is updated at all times, as the player can see light coming from powerpoints located very far
-- from his actual position.
--
-- Care must be taken to ensure that updating does not take too much time.
--
-- Design
--
-- For each PowerPoint, a PowerPointLightHandler class is created.
--
-- The PowerPointLightHandler contains a LightWorker for each kLightMode that the powerpoint can be in.
-- Each frame, the PowerPointLightHandler for each powerpoint is called. It checks what worker should be
-- run this frame and makes sure that if the mode has changed, the new worker is initialized.
-- Then, the selected worker is Run().
--
-- Normally, a worker has a table of activeLights, and as time passes, the activeLights table
-- empties and you end up with no lights in the activeTable, and thus basically no CPU spent.
--
-- If you end up in a non-static state, try skipping some updates (keeping changes in ligth to 20 updates per sec)
-- or optimize it similar to the NoPowerLightWorkers use of LightGroups.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kMinCommanderLightIntensityScalar = 0.3

local kOffTime = 2
local kLowPowerCycleTime = 1
local kLowPowerMinIntensity = 0.4
local kDamagedCycleTime = 0.8
local kDamagedMinIntensity = 0.4
local kAuxPowerMinIntensity = 0
local kAuxPowerMinCommanderIntensity = 0.5

-- set the intensity and color for a light. If the renderlight is ambient, we set the color
-- the same in all directions
local function SetLight(renderLight, intensity, color)

    PROFILE("PowerPointLightHandler:SetLight")

    if intensity then
        renderLight:SetIntensity(intensity)
    end

    if color then

        renderLight:SetColor(color)

        if renderLight:GetType() == RenderLight.Type_AmbientVolume then

            renderLight:SetDirectionalColor(RenderLight.Direction_Right,    color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Left,     color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Up,       color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Down,     color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  color)
            renderLight:SetDirectionalColor(RenderLight.Direction_Backward, color)

        end

    end

end

class 'PowerPointLightHandler'

function PowerPointLightHandler:Init(powerPoint)

    PROFILE("PowerPointLightHandler:Init")

    self.powerPoint = powerPoint
    self.lightTable = { }
    self.glowTable = { }
    self.probeTable = { }

    -- all lights for this powerPoint, and filter away those that
    -- shouldn't be affected by the power changes
    for _, light in ipairs(GetLightsForLocation(powerPoint:GetLocationName())) do

        if not light.ignorePowergrid then
            table.insert(self.lightTable, light)
        end

    end

    for _, prop in ipairs(GetGlowingPropsForLocation(self.powerPoint:GetLocationName())) do

        table.insert(self.glowTable, prop)

    end

    for _, probe in ipairs(GetReflectionProbesForLocation(self.powerPoint:GetLocationName())) do
        if not probe.values.ignorePowergrid then
            table.insert(self.probeTable, probe)
        end
    end

    self.lastWorker = nil
    self.lastTimeOfChange = nil

    self.workerTable = {
        [kLightMode.Normal] = NormalLightWorker():Init(self, "normal"),
        [kLightMode.NoPower] = NoPowerLightWorker():Init(self, "nopower"),
        [kLightMode.LowPower] = LowPowerLightWorker():Init(self, "lowpower"),
        [kLightMode.Damaged] = DamagedLightWorker():Init(self, "damaged"),
    }

    return self

end

function PowerPointLightHandler:Reset()

    self.lightTable = { }
    self.glowTable = { }
    self.probeTable = { }

    -- all lights for this powerPoint, and filter away those that
    -- shouldn't be affected by the power changes
    for _, light in ipairs(GetLightsForLocation(self.powerPoint:GetLocationName())) do

        if not light.ignorePowergrid then
            table.insert(self.lightTable, light)
        end

    end

    for _, prop in ipairs(GetGlowingPropsForLocation(self.powerPoint:GetLocationName())) do

        table.insert(self.glowTable, prop)

    end

    for _, probe in ipairs(GetReflectionProbesForLocation(self.powerPoint:GetLocationName())) do
        if not probe.values.ignorePowergrid then
            table.insert(self.probeTable, probe)
        end
    end

    self.workerTable = {
        [kLightMode.Normal] = NormalLightWorker():Init(self, "normal"),
        [kLightMode.NoPower] = NoPowerLightWorker():Init(self, "nopower"),
        [kLightMode.LowPower] = LowPowerLightWorker():Init(self, "lowpower"),
        [kLightMode.Damaged] = DamagedLightWorker():Init(self, "damaged"),
    }

    self:Run(self.lastMode)

end

function PowerPointLightHandler:Run(mode)

    self.lastMode = mode

    local worker = self.workerTable[mode]
    local timeOfChange = self.powerPoint:GetTimeOfLightModeChange()

    if self.lastWorker ~= worker or self.lastTimeOfChange ~= timeOfChange then

        worker:Activate()
        self.lastWorker = worker
        self.lastTimeOfChange = timeOfChange

    end
    worker:Run()

end

function PowerPointLightHandler:SetEmissiveModValue(value)

    if value == self.emissiveModValue then
        return
    end
    self.emissiveModValue = value

    for i=1, #self.glowTable do
        self.glowTable[i]:SetMaterialParameter("emissiveMod", value)
    end
end

--
-- Base class for all LightWorkers, ie per-mode workers.
--
class 'BaseLightWorker'

function BaseLightWorker:Init(handler, name)

    self.handler = handler
    self.name = name
    self.activeLights = unique_set()
    self.activeProbes = false

    return self

end

-- called whenever the mode changes so this Worker is activated
function BaseLightWorker:Activate()

    self.activeLights:Clear()

    for _, light in ipairs(self.handler.lightTable) do

        self.activeLights:Insert(light)
        light.randomValue = Shared.GetRandomFloat()
        light.flickering = nil

    end

    self.activeProbes = true

end

-- if a light should try to flicker, call with the light and the chance to flicker
function BaseLightWorker:CheckFlicker(renderLight, chance, scalar)

    PROFILE("BaseLightWorker:CheckFlicker")

    if renderLight.flickering == nil then
        renderLight.flickering = math.random() < chance
    end

    if renderLight.flickering then
        return self:FlickerLight(scalar)
    end

    return 1

end

function BaseLightWorker:FlickerLight(scalar)

    PROFILE("BaseLightWorker:FlickerLight")

    if scalar < 0.5 then

        local flicker_intensity = Clamp(math.sin(math.pow((1 - scalar) * 6, 8)) + 1, .8, 2) / 2.0
        return flicker_intensity * flicker_intensity

    end
    return 1

end


function BaseLightWorker:RestoreColor(renderLight)

    PROFILE("BaseLightWorker:RestoreColor")

    renderLight:SetColor(renderLight.originalColor)

    if renderLight:GetType() == RenderLight.Type_AmbientVolume then

        renderLight:SetDirectionalColor(RenderLight.Direction_Right,    renderLight.originalRight)
        renderLight:SetDirectionalColor(RenderLight.Direction_Left,     renderLight.originalLeft)
        renderLight:SetDirectionalColor(RenderLight.Direction_Up,       renderLight.originalUp)
        renderLight:SetDirectionalColor(RenderLight.Direction_Down,     renderLight.originalDown)
        renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  renderLight.originalForward)
        renderLight:SetDirectionalColor(RenderLight.Direction_Backward, renderLight.originalBackward)

    end

end

function BaseLightWorker:LerpColor(renderLight,color,t)

    renderLight:SetColor(LerpColor(renderLight.originalColor,color,t))

    if renderLight:GetType() == RenderLight.Type_AmbientVolume then

        renderLight:SetDirectionalColor(RenderLight.Direction_Right,    LerpColor(renderLight.originalRight,color,t))
        renderLight:SetDirectionalColor(RenderLight.Direction_Left,     LerpColor(renderLight.originalLeft,color,t))
        renderLight:SetDirectionalColor(RenderLight.Direction_Up,       LerpColor(renderLight.originalUp,color,t))
        renderLight:SetDirectionalColor(RenderLight.Direction_Down,     LerpColor(renderLight.originalDown,color,t))
        renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  LerpColor(renderLight.originalForward,color,t))
        renderLight:SetDirectionalColor(RenderLight.Direction_Backward, LerpColor(renderLight.originalBackward,color,t))

    end

end

--
-- handles kLightMode.Normal
--
class 'NormalLightWorker' (BaseLightWorker)

function NormalLightWorker:Activate()

    BaseLightWorker.Activate(self)

    self.lastUpdateTimePassed = -1

end

-- Turning on full power.
-- When turn on full power, the lights are never decreased in intensity.
--
function NormalLightWorker:Run()

    PROFILE("NormalLightWorker:Run")

    local timeOfChange = self.handler.powerPoint:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange

    local deadlockScalar = self.deadlockScalar or 0
    local gameInfo = GetGameInfoEntity(kTeam1Index)
    if gameInfo then
        local deadLockTime = gameInfo and gameInfo:GetMarineDeadlockTime() or 99999
        deadlockScalar =  deadLockTime > 0 and Lerp(deadlockScalar, Shared.GetTime() > deadLockTime and 1 or 0,0.05) or 0
    else
        deadlockScalar = 0
    end
    self.deadlockScalar = deadlockScalar

    if self.activeProbes then

        local startFullLightTime = PowerPoint.kMinFullLightDelay

        local probeTint

        if timePassed < startFullLightTime then
            -- we don't change lights or color during this period
        else
            probeTint = lightColor
            self.activeProbes = false
        end

        if probeTint then
            for _, probe in ipairs(self.handler.probeTable) do
                probe:SetTint(lightColor)
            end
        end

    end

    local startFullTime = PowerPoint.kMinFullLightDelay
    if timePassed > startFullTime then

        local timeRatio = Clamp((timePassed - startFullTime) / PowerPoint.kFullPowerOnTime, 0, 1)
        self.handler:SetEmissiveModValue(timeRatio)

    end

    for renderLight in self.activeLights:IterateBackwards() do
        local intensity
        local randomValue = renderLight.randomValue

        local startFullLightTime = PowerPoint.kMinFullLightDelay + PowerPoint.kMaxFullLightDelay * randomValue
        -- time when full lightning is achieved
        local fullFullLightTime = startFullLightTime + PowerPoint.kFullPowerOnTime
        local t = timePassed - startFullLightTime
        local scalar = math.sin(( t / PowerPoint.kFullPowerOnTime  ) * math.pi / 2)

        if timePassed < startFullLightTime then
            -- we don't change lights or color during this period

        elseif timePassed < fullFullLightTime then

            -- the period when lights start to come on, possibly with a little flickering
            intensity = renderLight.originalIntensity * scalar

            if renderLight.flickering == nil and intensity < renderLight:GetIntensity() then
                -- don't change anything until we exceed the origin light intensity.
            else

                if renderLight.flickering == nil then
                    self:RestoreColor(renderLight)
                end
                intensity = intensity * self:CheckFlicker(renderLight,PowerPoint.kFullFlickerChance, scalar)

            end

        else

            intensity = renderLight.originalIntensity

            self:RestoreColor(renderLight)
        end

        if(deadlockScalar > 0.01) then
            self:LerpColor(renderLight,PowerPoint.kDisabledColor,deadlockScalar)
            intensity = intensity * self:CheckFlicker(renderLight,PowerPoint.kFullFlickerChance,scalar)
        end
        -- color are only changed once during the full-power-on
        SetLight(renderLight, intensity, lightColor)
    end
end

--
-- Handles Damaged. In damaged state, all lights cycle once whenever they are damaged
-- then and the go back to steady state. Whenever we are damaged anew, we are reset and
-- start over
--
class 'DamagedLightWorker' (BaseLightWorker)

function DamagedLightWorker:Run()

    PROFILE("DamagedLightWorker:Run")

    local timeOfChange = self.handler.powerPoint:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange

    local scalar = math.sin(Clamp(timePassed / kDamagedCycleTime, 0, 1) * math.pi)

    for renderLight in self.activeLights:Iterate() do

        local intensity = renderLight.originalIntensity * (1 - scalar * (1 - kDamagedMinIntensity))
        SetLight(renderLight, intensity, nil)

    end

    if timePassed > kDamagedCycleTime then
        self.activeLights:Clear()
        self.activeProbes = false
    end

end

-- Handles LowPower warning.
-- This cycles the light constantly
class 'LowPowerLightWorker' (BaseLightWorker)

function LowPowerLightWorker:Run()

    PROFILE("LowPowerLightWorker:Run")

    local timeOfChange = self.handler.powerPoint:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange

    local scalar = math.cos((timePassed / (kLowPowerCycleTime / 2)) * math.pi / 2)
    local minIntensity = kLowPowerMinIntensity
    local halfIntensity = (1 - minIntensity) / 2

    for renderLight in self.activeLights:Iterate() do

        -- Cycle lights up and down telling everyone that there's an imminent threat
        local intensity = renderLight.originalIntensity * minIntensity + halfIntensity + scalar * halfIntensity
        SetLight(renderLight, intensity, nil)

    end

end


-- Handles NoPower. This is a bit complex, as we end up in a continouosly varying light
-- state, where the auxilary light cycles now and then. To
class 'NoPowerLightWorker' (BaseLightWorker)

NoPowerLightWorker.kNumGroups = 10

function NoPowerLightWorker:Init(handler, name)

    BaseLightWorker.Init(self, handler, name)

    self.lightGroups = {}

    for i = 1, NoPowerLightWorker.kNumGroups, 1 do
        self.lightGroups[i] = LightGroup():Init()
    end

    return self

end

function NoPowerLightWorker:Activate()

    BaseLightWorker.Activate(self)
    for i = 1, NoPowerLightWorker.kNumGroups, 1 do
        self.lightGroups[i].lights = {}
    end

end

--
-- handles lights when the powerpoint has no power. This involves a time with no lights,
-- and then a period when lights are coming on line into aux power setting. Once the aux light
-- has stabilized, the lights will stay mostly steady, but will sometimes cycle a bit.
--
-- Performance wise, we shift lights from the activeLights table over to lightgroups. Each group
-- of lights stay fixed for a while, then starts to cycle as one for another span of time. Done
-- this way so that we can avoid running the lights most of the time.
--
function NoPowerLightWorker:Run()

    PROFILE("NoPowerLightWorker:Run")

    local timeOfChange = self.handler.powerPoint:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange

    local scalar = math.Clamp((kOffTime - timePassed ) / kOffTime,0,1)
    local probeTint = Color(
            scalar,scalar,scalar,
            1)

    if probeTint then
        for _, probe in ipairs(self.handler.probeTable) do
            probe:SetTint( probeTint )
        end
    end

    self.handler:SetEmissiveModValue(0)

    for renderLight in self.activeLights:Iterate() do


        local showCommanderLight = false

        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
            showCommanderLight = true
        end

        local intensity
        if showCommanderLight then
            intensity = renderLight.originalIntensity * Lerp(1,kMinCommanderLightIntensityScalar,scalar)
        else
            intensity = scalar
        end
        
        if timePassed >= kOffTime then

            -- Deactivate from initial state
            self.activeLights:Remove(renderLight)

            -- in steady state, we shift lights between a constant state and a varying state.
            -- We assign each light to one of several groups, and then randomly start/stop cycling for each group.
            local lightGroupIndex = math.random(1, NoPowerLightWorker.kNumGroups)
            table.insert(self.lightGroups[lightGroupIndex].lights, renderLight)

        end

        SetLight(renderLight, intensity, nil)

    end

    -- handle the light-cycling groups.
    for _, lightGroup in ipairs(self.lightGroups) do
        lightGroup:Run(timePassed)
    end

end

-- used to cycle lights periodically in groups
class 'LightGroup'

function LightGroup:Init()

    self.lights = {}
    self.cycleUsedTime = 0
    self.cycleEndTime = 0
    self.cycleStartTime = 0
    self.nextThinkTime = 0
    self.stateFunction = LightGroup.RunFixed

    return self

end

function LightGroup:Run(time)

    if time >= self.nextThinkTime then
        self:stateFunction(time)
    end

end

function LightGroup:RunFixed(time)

    -- shift this group from fixed to cycling
    self.stateFunction = LightGroup.RunCycle
    self.cycleBaseTime = time
    self.cycleStartTime = time
    self.cycleEndTime = time + math.random(10)
    self.nextThinkTime = time

end

function LightGroup:RunCycle(time)

    if time > self.cycleEndTime then

        -- end varying cycle and fix things for a while. Note that the intensity will
        -- stay a bit random, which is all to the good.
        self.stateFunction = LightGroup.RunFixed
        self.nextThinkTime = time + math.random(10)
        self.cycleUsedTime = self.cycleUsedTime + (time - self.cycleStartTime)

    else

        -- this is the time used to calc intensity. This is calculated so that when
        -- we restart after a pause, we continue where we left off.
        local t = time - self.cycleStartTime + self.cycleUsedTime

        local showCommanderLight = false
        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
            showCommanderLight = true
        end

        for _, renderLight in ipairs(self.lights) do

            -- Fade disabled color in and out to make it very clear that the power is out
            --local scalar = math.cos((t / (PowerPoint.kAuxPowerCycleTime / 2)) * math.pi / 2)
            --local halfAmplitude = (1 - kAuxPowerMinIntensity) / 2

            local intensity 
            --local color = PowerPoint.kDisabledColor

            if showCommanderLight then
                intensity = renderLight.originalIntensity * kMinCommanderLightIntensityScalar
            else
                intensity = 0
            end


            --local disabledIntensity = (kAuxPowerMinIntensity + halfAmplitude + scalar * halfAmplitude)
            --local intensity = renderLight.originalIntensity * disabledIntensity

            SetLight(renderLight, intensity, nil)

        end

    end

end


