-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- Created by Steven An (steve@unknownworlds.com)
--
-- This class takes high-level motion-intents as input (ie. "I want to move here" or "I want to go in this direction")
-- and translates them into controller-inputs, ie. mouse direction and button presses.
--
-- ==============================================================================================

------------------------------------------
--  Provides an interface for higher level logic to specify desired motion.
--  The actual bot classes use this to compute move.move, move.yaw/pitch. Also, jump.
------------------------------------------

class "BotMotion"

function BotMotion:Initialize(player)

    self.currMoveDir = Vector(0,0,0)
    self.currViewDir = Vector(1,0,0)
    self.lastMovedPos = player:GetOrigin()

    self.currPathPoints = nil
    self.currPathPointsIt = 1
    self.unstuckUntil = 0
    self.nextMoveUpdate = 0
end

function BotMotion:ComputeLongTermTarget(player)

    local kTargetOffset = 1

    if self.desiredMoveDirection ~= nil then

        local toPoint = player:GetOrigin() + self.desiredMoveDirection * kTargetOffset
        return toPoint

    elseif self.desiredMoveTarget ~= nil then

        return self.desiredMoveTarget

    else

        return nil

    end
end

------------------------------------------
--  Expensive pathing call
------------------------------------------
function BotMotion:GetOptimalMoveDirection(from, to)
    PROFILE("BotMotion:GetOptimalMoveDirection")

    local minDistOpti = 6 -- Distance below which the next point in the path is removed.
    local newMoveDir, reachable
    local pathPoints = PointArray()

    if self.currPathPoints == nil or self.forcePathRegen or from:GetDistanceTo(to) < minDistOpti then
        -- Generate a full path to follow (expansive)
        self.currPathPoints = PointArray()
        self.currPathPointsIt = 1
        self.forcePathRegen = nil
        reachable = Pathing.GetPathPoints(from, to, self.currPathPoints)
        if reachable and #self.currPathPoints > 0 then
            newMoveDir = (self.currPathPoints[1] - from):GetUnit()
        end
    else

        -- Follow the path we have generated earlier: It is much much faster to compute a
        -- direction using a small portion of the path, and reliable since it gaves us the
        -- real direction to use (regardless of any displacement, pos we could be in)
        if self.currPathPoints and #self.currPathPoints > 0 then
            -- Increase iterator forward for each points of the path below X meters
            while self.currPathPointsIt < #self.currPathPoints
                    and self.currPathPoints[self.currPathPointsIt]:GetDistanceTo(from) < minDistOpti
            do
                self.currPathPointsIt = self.currPathPointsIt + 1
            end

            if self.currPathPointsIt == #self.currPathPoints then
                self.currPathPoints = nil
            else
                -- Compute reliable direction using previously generated path
                reachable = Pathing.GetPathPoints(from, self.currPathPoints[self.currPathPointsIt], pathPoints)
                if reachable and #pathPoints > 0 then
                    newMoveDir = (pathPoints[1] - from):GetUnit()
                end
            end
        end
    end

    if not newMoveDir then -- fallback
        newMoveDir = (to-from):GetUnit()
    end

    self.currMoveDir = newMoveDir
end

------------------------------------------
--
------------------------------------------

function BotMotion:OnGenerateMove(player)
    PROFILE("BotMotion:OnGenerateMove")

    local currentPos = player:GetOrigin()
    local eyePos = player:GetEyePos()
    local doJump = false

    local delta = currentPos - self.lastMovedPos

    ------------------------------------------
    --  Update ground motion
    ------------------------------------------

    local moveTargetPos = self:ComputeLongTermTarget(player)

    if moveTargetPos ~= nil and not player:isa("Embryo") then

        local distToTarget = currentPos:GetDistance(moveTargetPos)

        if distToTarget <= 0.01 then

            -- Basically arrived, stay here
            self.currMoveDir = Vector(0,0,0)

        else

            local now = Shared.GetTime()
            local updateMoveDir = self.nextMoveUpdate < now
            local unstuckDuration = 1.4
            local isStuck = delta:GetLength() < 1e-2 or self.unstuckUntil > now

            if updateMoveDir then

               self.nextMoveUpdate = now + kPlayerBrainTickFrametime
                -- If we have not actually moved much since last frame, then maybe pathing is failing us
                -- So for now, move in a random direction for a bit and jump
               if isStuck
               then

                    if self.unstuckUntil < now then
                         -- Move randomly during Xs
                         self.unstuckUntil = now + unstuckDuration

                         self.currMoveDir = GetRandomDirXZ()
                         if not player:isa("Lerk") then
                             doJump = true
                         else
                             self.currMoveDir.y = -2
                         end
                    end

                elseif distToTarget <= 2.0 then

                    -- Optimization: If we are close enough to target, just shoot straight for it.
                    -- We assume that things like lava pits will be reasonably large so this shortcut will
                    -- not cause bots to fall in
                    -- NOTE NOTE STEVETEMP TODO: We should add a visiblity check here. Otherwise, units will try to go through walls
                    self.currMoveDir = (moveTargetPos - currentPos):GetUnit()

                else

                    -- We are pretty far - do the expensive pathing call
                    self:GetOptimalMoveDirection(currentPos, moveTargetPos)

                end

                self.currMoveTime = Shared.GetTime()

            end

            self.lastMovedPos = currentPos
        end


    else

        -- Did not want to move anywhere - stay still
        self.currMoveDir = Vector(0,0,0)

    end

    ------------------------------------------
    --  View direction
    ------------------------------------------

    if self.desiredViewTarget ~= nil then

        -- Look at target
        self.currViewDir = (self.desiredViewTarget - eyePos):GetUnit()

    elseif self.currMoveDir:GetLength() > 1e-4 then

        -- Look in move dir
        self.currViewDir = self.currMoveDir
        self.currViewDir.y = 0.0  -- pathing points are slightly above ground, which leads to funny looking-up
        self.currViewDir = self.currViewDir:GetUnit()

    else
        -- leave it alone
    end

    return self.currViewDir, self.currMoveDir, doJump

end

------------------------------------------
--  Higher-level logic interface
------------------------------------------
function BotMotion:SetDesiredMoveTarget(toPoint)

    -- Mutually exclusive
    self:SetDesiredMoveDirection(nil)


    if not VectorsApproxEqual( toPoint, self.desiredMoveTarget, 1e-4 ) then
        self.desiredMoveTarget = toPoint
        self.forcePathRegen = true -- TODO: if target is far, we could still reuse the same path and regen later
    end

end

------------------------------------------
--  Higher-level logic interface
------------------------------------------
-- Note: while a move direction is set, it overrides a target set by SetDesiredMoveTarget
function BotMotion:SetDesiredMoveDirection(direction)

    if not VectorsApproxEqual( direction, self.desiredMoveDirection, 1e-4 ) then
        self.desiredMoveDirection = direction
    end

end

------------------------------------------
--  Higher-level logic interface
--  Set to nil to clear view target
------------------------------------------
function BotMotion:SetDesiredViewTarget(target)

    self.desiredViewTarget = target

end

------------------------------------------
--  Utils to handle the path
--  Can be used to make the bot retreat easily or follow a precomputed path
------------------------------------------

function BotMotion:GetPath()

   return self.currPathPoints

end

function BotMotion:GetPathIndex()

   return self.currPathPointsIt

end
