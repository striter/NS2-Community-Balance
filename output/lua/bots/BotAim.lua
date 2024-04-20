-- ======= Copyright (c) 2015, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- Created by Mats olsson (mats.olsson@matsotech.se)
--
-- The aim control builds up a track of the target positions and will try to aim towards
-- the target.
-- It will simulate with a reaction time that uses the history of the target positions to
-- extrapolate to where it will be after the reaction time has passed. This means that the
-- aim is designed to allow the target to dodge bullets by changing direction quickly, ie
-- the aim will be slow to react.
--
-- ==============================================================================================



class "BotAim"

BotAim.viewAngle = math.rad(90)
BotAim.reactionTime = 0.1 --orginal 0.1
BotAim.panicDistSquared = 0.0 * 0.0  --orginal 2.0 * 2.0
BotAim.kTrackingInterval = 0 -- How often to update where we should be aiming. If too high, 1st person spectating will look nauseating.

-- The least amount of accuracy allowed.
BotAim.kMinimumAccuracy = 15 --orginal 12
BotAim.kMaximumAccuracy = 100

BotAim.kAimDebuffAngleDiff = math.rad(120)
BotAim.kAimDebuffSlowHeight = 0.4 -- Further than this much (-1 to 1, 1 is top) makes it slow
BotAim.kTargetDebuffTrackInterval = 0.25 -- Interval to clear target tracking for aim speed penalties
BotAim.kAimDebuffDurationMin = 0.1
BotAim.kAimDebuffDurationMax = 0.4
BotAim.kTargetAcquisitionDelayMin = 0.185
BotAim.kTargetAcquisitionDelayMax = 0.325

-- Lose x percent of accuracy per meter target is from us.
BotAim.kDistanceDebuffPerMeter = 0.25 -- -10% max (40 meters)

-- How long it should wait before staring to hit or miss target.
-- Essentially the update rate for changing between "Missing" and "hitting" a target.
BotAim.kMinAccuracyTime = 0.125

-- Accuracy thresholds by weapon group
-- Each weapon group holds a table of tiered accuracy percents
-- 1 through 7, so "rookie" is never accounted for here.
--
-- Use BotAim:GetAccuracyGoal to get the correct accuracy value
BotAim.kAccuracies =
{   
    [kBotAccWeaponGroup.Bullets] = { 14.5, 16.5, 21, 25, 28.5, 34, 38.5 },

    -- These guys should be stonker
    [kBotAccWeaponGroup.ExoMinigun] = { 23, 25, 28, 30, 35, 39, 43 },
    [kBotAccWeaponGroup.ExoRailgun] = { 25, 28, 30, 32, 35, 39, 43 },

    -- Similar to "bullets", but caps off in higher tiers
    [kBotAccWeaponGroup.LerkSpikes] = { 14.5, 16.5, 21, 25, 28.5, 28.5, 28.5 },

    [kBotAccWeaponGroup.Spit] = { 13.5, 15, 18.5, 21.1, 25.1, 31.1, 41.1 },
    
    --TODO Add Fade and Onos weapons

    [kBotAccWeaponGroup.Melee] = { 25, 28, 32, 38, 42, 48, 55 },

    [kBotAccWeaponGroup.Swipe] = { 28, 32, 38, 42, 48, 55, 62 },

    [kBotAccWeaponGroup.BiteLeap] = { 11, 13, 15, 18.5, 25, 32, 45 },

    [kBotAccWeaponGroup.LerkBite] = { 15, 20, 25, 30, 35, 40, 60 },

    -- [kBotAccWeaponGroup.Parasite]

    --TODO Add Exo weapons?
}

-- Some weapons have a spread or bigger projectiles.
BotAim.kWeaponGroupSpreads =
{
    [kBotAccWeaponGroup.Bullets] = 0.018 + Math.Radians(2.8),
    [kBotAccWeaponGroup.ExoMinigun] = Math.Radians(5),
    [kBotAccWeaponGroup.LerkSpikes] = kSpikeSize + kSpikeSpread,

    --TODO Add Fade and Onos weapons

    [kBotAccWeaponGroup.Melee] = 1.2, -- Actually a volume trace, but most common is 1.2
    [kBotAccWeaponGroup.BiteLeap] = 1.2,
    [kBotAccWeaponGroup.LerkBite] = 1.2,

    -- [kBotAccWeaponGroup.Parasite]

    --TODO Add Exo weapons?
}

BotAim.kDistanceAffectedWeaponGroups = set
{
    kBotAccWeaponGroup.Bullets,
    kBotAccWeaponGroup.ExoMinigun,
    kBotAccWeaponGroup.LerkSpikes,
    kBotAccWeaponGroup.Spit,
    --TODO Add bile?
}

-- Map of classnames -> direction vecs of where to miss on that class
BotAim.kMissDirections =
{
    ["Marine"] = Vector(1, 0, 0),
    ["JetpackMarine"] = Vector(1, 0, 0),
    ["Exo"] = Vector(1, 0, 0),

    ["Skulk"] = Vector(0, 1, 0),
    ["Gorge"] = Vector(0, 1, 0),
    ["Lerk"]  = Vector(0, -1, 0),
    ["Fade"]  = Vector(1, 0, 0),
    ["Onos"]  = Vector(0.5, 0, 0), -- Onos should be 100% accuracy  ....should it?
    ["Embryo"] = Vector(0, 1, 0),
}

-- Map of classnames -> speed modifiers for bot movements
BotAim.kBotTurnSpeeds =
{
    ["Default"] = 1.5,
    ["Marine"] = 1.5,
    ["JetpackMarine"] = 1.7,
    ["Exo"] = 1.5,
    ["Skulk"] = 1.6,
    ["Gorge"] = 1.5,
    ["Lerk"] = 2.0,
    ["Fade"] = 2.3,
    ["Onos"] = 1.5, -- extra hinzugefügt
}
--[[{
    ["Default"] = 1.0,
    ["Marine"] = 1.0,
    ["JetpackMarine"] = 1.2,
    ["Exo"] = 1.0,
    ["Skulk"] = 1.1,
    ["Gorge"] = 1.0,
    ["Lerk"] = 1.5,
    ["Fade"] = 1.8,
}--]] --orginal Werte

function BotAim:Initialize(owner)
    self.owner = owner
    self.target = nil

    self.targetFirstPos = nil
    self.targetFirstPosTime = 0
    self.aimDebuffEndTime = 0
    self.aimDebuffType = kAimDebuffState.None
    self.aimTurnRate = 1.0

    -- Target Acquisition Delay
    self.targetAcqEndTime = 0

    self.lastTrackTime = Shared.GetTime()
    self.targetTrack = {}

    self.timeLastAimState = 0
    self.missing = false -- Should miss target or not
    self.missingOffset = nil

    local player = self.owner:GetPlayer()
    if player then
        self.viewAngle = GetClassDefaultFov(player:GetClassName())
    end
    
end

function BotAim:Clear()
    self.target = nil

    self.targetFirstPos = nil
    self.targetFirstPosTime = 0
    self.aimDebuffEndTime = 0
    self.aimDebuffType = kAimDebuffState.None
    self.aimTurnRate = 1.0

    self.targetAcqEndTime = 0

    self.lastTrackTime = Shared.GetTime()
    self.targetTrack = {}

    self.timeLastAimState = 0
    self.missing = false
    self.missingOffset = nil

end

function BotAim:ApplyAimDebuff(debuffType)
    local serverSkillTier = self:GetServerSkillTier()
    local lerpAmount = 1 - (serverSkillTier / 7)
    local duration = LerpNumber(self.kAimDebuffDurationMin, self.kAimDebuffDurationMax, lerpAmount)
    local now = Shared.GetTime()
    self.aimDebuffEndTime = now + duration
    self.aimDebuffType = debuffType
    self:UpdateAimPenaltyTracking(now)
end

function BotAim:GetTargetAcquisitionDelay()

    local serverSkillTier = self:GetServerSkillTier()
    local lerpAmount = 1 - (serverSkillTier / 7)
    local duration = LerpNumber(self.kTargetAcquisitionDelayMin, self.kTargetAcquisitionDelayMax, lerpAmount)
    return duration

end

function BotAim:GetAimDebuffState()

    if not self:GetIsAimDebuffed() then return
        kAimDebuffState.None
    end

    return self.aimDebuffType
end

function BotAim:GetIsAimDebuffed()
    return (self.aimDebuffEndTime or 0) >= Shared.GetTime()
end

function BotAim:GetAimTurnRateModifier()
    return self.aimTurnRate
end

function BotAim:GetIsWeaponGroupDistanceAffected(weaponGroup)
    return self.kDistanceAffectedWeaponGroups[weaponGroup] == true
end

function BotAim:GetAccuracyGoal(weaponGroup)

    local idealAccuracy = self.kMaximumAccuracy
    if self.kAccuracies[weaponGroup] then
        local serverSkillTier = self:GetServerSkillTier()
        idealAccuracy = self.kAccuracies[weaponGroup][serverSkillTier]
    end

    if not self.target then return idealAccuracy end
    local ownerPlayer = self.owner:GetPlayer()
    if not ownerPlayer then return idealAccuracy end

    local accPenalty = 0
    if self:GetIsWeaponGroupDistanceAffected(weaponGroup) then
        local distance = self.target:GetOrigin():GetDistance(ownerPlayer:GetOrigin())
        accPenalty = distance * self.kDistanceDebuffPerMeter
    end

    return Clamp(idealAccuracy - accPenalty, self.kMinimumAccuracy, self.kMaximumAccuracy)

end

function BotAim:UpdateAim(target, targetAimPoint, weaponGroup)
    PROFILE("BotAim:UpdateAim")

    -- Only update aim when the target is actually in the bot player's pov or really close
    -- So bots don't do 180 degree aim turns and similar unhuman movements
    local player = self.owner:GetPlayer()
    local playerEyePos = player and player:GetEyePos()

    if playerEyePos then

        local isPanicDistance = playerEyePos:GetDistanceSquared(targetAimPoint) <= BotAim.panicDistSquared
        local pointInCone = IsPointInCone(targetAimPoint, playerEyePos, player:GetViewCoords().zAxis, self.viewAngle)

        if isPanicDistance or pointInCone then
            return BotAim_UpdateAim(self, target, targetAimPoint, weaponGroup)
        end

    end

    -- try to view the target anyways, even though we can't directly see it
    self.owner:GetMotion():SetDesiredViewTarget( targetAimPoint )
    return false

end

function BotAim_UpdateAim(self, target, targetAimPoint, weaponGroup)
    local now = Shared.GetTime()
    local isNewTarget = self.target ~= target
    if isNewTarget or now - self.lastTrackTime > 0.5 then
        self.targetTrack = {}
        self.target = target
        -- Log("%s: Reset aim", self.owner)

        if isNewTarget then
            GetBotAccuracyTracker():EndEncounter(self.owner:GetClient())
            self.targetAcqEndTime = now + self:GetTargetAcquisitionDelay()
        end
    end

    self:UpdateAimDebuff(weaponGroup, now, target)

    local player = self.owner:GetPlayer()
    local className = player and player:GetClassName() or "Default"

    if player and player.GetIsInCombat and player:GetIsInCombat() then
        self.aimTurnRate = BotAim.kBotTurnSpeeds[className]
    else
        self.aimTurnRate = 1.0
    end

    self.lastTrackTime = now

    table.insert(self.targetTrack, { targetAimPoint, now, target} )
    local aimPoint = BotAim_GetAimPoint(self, now, targetAimPoint, weaponGroup)

    self.owner:GetMotion():SetDesiredViewTarget( aimPoint )

    -- Try to track target always, but only fire if we "acquire target",
    -- which is just to similuate more human reaction times.
    return (aimPoint ~= nil and not self:GetIsAcquiringTarget())
end

function BotAim:GetIsAcquiringTarget()
    return self.targetAcqEndTime > Shared.GetTime()
end

function BotAim:UpdateAimDebuff(weaponGroup, now, target)

    -- Update aim tracking penalty
    if self.target then

        if now > (self.targetFirstPosTime + self.kTargetDebuffTrackInterval) then
            self:UpdateAimPenaltyTracking(now)
        else
            local player = self.owner:GetPlayer()
            if player then
                local lookDir = player:GetViewCoords().zAxis
                if lookDir.y > self.kAimDebuffSlowHeight then
                    self:ApplyAimDebuff(kAimDebuffState.UpHigh)
                elseif self.targetFirstPos then
                    local startVec = self.targetFirstPos - player:GetEyePos()
                    local curVec = self.target:GetOrigin() - player:GetEyePos()
                    local angle = GetAngleBetweenVectors(startVec, curVec)
                    if angle > self.kAimDebuffAngleDiff then
                        self:ApplyAimDebuff(kAimDebuffState.TooFast)
                    end
                end
            end
        end
        
    end

end

function BotAim:UpdateAimPenaltyTracking(now)
    self.targetFirstPos = self.target:GetOrigin()
    self.targetFirstPosTime = now
end

function BotAim:GetServerSkillTier()

    if gSkillTierOverride then
        return gSkillTierOverride
    end

    local gameInfoEnt = GetGameInfoEntity()
    local serverSkill = gameInfoEnt and gameInfoEnt:GetAveragePlayerSkill()
    local serverSkillTier = GetPlayerSkillTier(serverSkill, false, nil, false)
    serverSkillTier = Clamp(serverSkillTier, 1, 7)
    return serverSkillTier

end

-- Adjust aim reaction times based the server's avg player skill
function BotAim:GetReactionTime()
    local player = self.owner:GetPlayer()
    if not player then return end

    local reducedReaction = self.owner.aimAbility * 0.1
    local gameInfoEnt = GetGameInfoEntity()
    local serverSkill = gameInfoEnt and gameInfoEnt:GetAveragePlayerSkill() -- Todo: Use enemy's team skill instead
    if serverSkill then
        reducedReaction = reducedReaction * Clamp((serverSkill - 500) / 4000, -1, 1)
    end

    local reactionTime = BotAim.reactionTime - reducedReaction
    if player:isa("Alien") then
        reactionTime = reactionTime / 2
    end

    return reactionTime
end

gBotDebug:AddBoolean("aim", false)
function BotAim_GetAimPoint(self, now, aimPoint, weaponGroup)

    -- if gBotDebug:Get("aim") and gBotDebug:Get("spam") then
    --     Log("%s: getting aim point", self.owner)
    -- end

    local aimTrackInterval = BotAim.kTrackingInterval
    while #self.targetTrack > 1 do
        -- search for a pair of tracks where the oldest is old enough for us to shoot from
        local targetData1 = self.targetTrack[1]
        local targetData2 = self.targetTrack[2]
        local p1, t1, target1 = targetData1[1], targetData1[2], targetData1[3]
        local p2, t2, target2 = targetData2[1], targetData2[2], targetData2[3]
        local timeSinceFirstTrack = now - t1

        if target1 ~= target2 or now - t1 > aimTrackInterval + 0.5 or now - t2 > aimTrackInterval then
            -- t1 can't be used to shot on t2 due to different target
            -- OR t1 is uselessly old
            -- OR we can use 2 because t2 is > reaction time
            table.remove(self.targetTrack, 1)
        elseif timeSinceFirstTrack > aimTrackInterval then
            -- .. ending up here with [ (reactionTime + 0.1) > t1 > reactionTime > t2 ]
            local mt = t2 - t1
            if mt > 0 then
                local movementVector = (p2 - p1) / mt
                local speed = movementVector:GetLength()
                local result = p1 + movementVector * (timeSinceFirstTrack)

                local targetDistanceSq = self.owner:GetPlayer():GetOrigin():GetDistanceSquared(target2:GetOrigin())
                local isPanicDistance = targetDistanceSq < self.panicDistSquared

                local isTargetPlayer = target2:isa("Player")
                if isTargetPlayer and now - self.timeLastAimState > self.kMinAccuracyTime then

                    local needsAccuracyChange = false
                    local currentAccuracy = GetBotAccuracyTracker():GetBotAccuracy(self.owner:GetClient(), weaponGroup, false)
                    local goalAccuracy = self:GetAccuracyGoal(weaponGroup)

                    needsAccuracyChange =
                        (self.missing and currentAccuracy < goalAccuracy) or
                        (not self.missing and currentAccuracy >= goalAccuracy)

                    GetBotDebuggingManager():UpdateBotDebugSectionField(self.owner:GetId(), kBotDebugSection.BotAim, "Target Class", target2:GetClassName())
                    GetBotDebuggingManager():UpdateBotDebugSectionField(self.owner:GetId(), kBotDebugSection.BotAim, "Needs Accuracy Change", needsAccuracyChange)
                    GetBotDebuggingManager():UpdateBotDebugSectionField(self.owner:GetId(), kBotDebugSection.BotAim, "Miss Direction", self.kMissDirections[target2:GetClassName()])
                    GetBotDebuggingManager():UpdateBotDebugSectionField(self.owner:GetId(), kBotDebugSection.BotAim, "Accuracy Goal", goalAccuracy)
                    GetBotDebuggingManager():UpdateBotDebugSectionField(self.owner:GetId(), kBotDebugSection.BotAim, "Skill Tier", self:GetServerSkillTier())

                    if needsAccuracyChange and self.kMissDirections[target2:GetClassName()] then
                        self.timeLastAimState = now
                        self.missing = not self.missing

                        GetBotDebuggingManager():UpdateBotDebugSectionField(self.owner:GetId(), kBotDebugSection.BotAim, "Missing", self.missing)

                        if self.missing then

                            local min, max = target2:GetModelExtents()
                            local targetSize = (max - min)
                            local extraOffset = 0
                            local spread = self.kWeaponGroupSpreads[weaponGroup] or 0 + extraOffset

                            GetBotDebuggingManager():UpdateBotDebugSectionField(self.owner:GetId(), kBotDebugSection.BotAim, "Spread", spread)

                            local missDirection = self.kMissDirections[target2:GetClassName()] or Vector(0,1,0)
                            local offsetVec = (targetSize * missDirection) + (spread * missDirection)
                            self.missingOffset = offsetVec
                        end

                    end

                end

                if isTargetPlayer and self.missing then
                    result = result + (self.missingOffset or 0)
                end

                -- if gBotDebug:Get("aim") then
                --     local delta = result - aimPoint
                --     Log("%s: Aiming at %s, off by %s, speed %s (%s tracks)", self.owner, target1, delta:GetLength(), speed, #self.targetTrack)
                -- end

                return result
            end

        else
            return nil
        end
    end

    -- if gBotDebug:Get("aim") and gBotDebug:Get("spam") then
    --     Log("%s: no target", self.owner)
    -- end

    return nil
end

if Server then
Event.Hook("Console_bot_reactiontime", function(_, arg)
        if arg then
            BotAim.reactionTime = tonumber(arg)
        end
        Print("bot aim reaction time = %f", BotAim.reactionTime )
    end)
end
