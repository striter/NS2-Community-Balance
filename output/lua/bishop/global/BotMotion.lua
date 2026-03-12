-- NOTE: This is 99% a mirror of the original file and was necessary because the
-- functions are so huge. It will slowly morph into something new over time.

-- TODO: A lot of the code in OnGenerateMove is class specific. For the sake of
-- readability and maintainability perhaps these segments should be separated
-- into their own function calls.

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

local GetGroundTrace = Bishop.utility.GetGroundTrace
local GetTargetTrace = Bishop.utility.GetTargetTrace

---@class BotMotion
BotMotion = nil
class "BotMotion"

--------------------------------------------------------------------------------
-- Technical values.
--------------------------------------------------------------------------------

local kGenerateLenSq = 100         -- Skip fallback cases if the path is short.
local kPathSegmentLength = 4       -- Trim path points within this length.

local kMaxNavMeshDistance = 0.65   -- Furthest XZ distance allowed from navmesh.

local kMinUnstuckDistance = 3.0    -- Delta distance to reset stuck status.
local kMaxStuckTime = 60           -- Time spent stuck before respawning.

local kMaxRotateSpeed = 1.0        -- Maximum bot (and hallucination) aim speed.
local kAimStateToRotateSpeeds = {
  [kAimDebuffState.None]    = kMaxRotateSpeed,
  [kAimDebuffState.TooFast] = 0.7, -- Target went past quickly.
  [kAimDebuffState.UpHigh]  = 0.5  -- Target is in the air.
}

local kLookDistance = 4            -- Path distance ahead for look direction.

local kUnstuckDuration = 1.2       -- Maximum time to remain in unstuck mode.

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

-- Attempts to compute a movement direction using a temporarily generated path.
-- Returns direction if successful or nil if unsuccessful.
local function GetPathDirection(from, to)
  local reachable
  local pathPoints = PointArray()

  reachable = Pathing.GetPathPoints(from, to, pathPoints)
  if not reachable or #pathPoints == 0 then
    return nil
  end

  return (pathPoints[1] - from):GetUnit()
end

--------------------------------------------------------------------------------
-- Bot movement for all bots.
--------------------------------------------------------------------------------

function BotMotion:Initialize(player, bot)
  self.bot = bot
  self.currMoveDir = Vector(0,0,0)
  self.currViewDir = Vector(1,0,0)

  self.lastMovedPos = player:GetOrigin()
  self.lastGroundHeight = nil
  self.nextMoveUpdate = 0

  self.currPathPoints = nil
  self.currPathPointsIt = 1

  self.ignoreStuck = false
  self.unstuckUntil = 0
end

-- Set whether stuck conditions should be ignored. The stuck state is reset when
-- this is changed.
function BotMotion:SetIgnoreStuck(ignore)
  self.ignoreStuck = ignore

  self.unstuckUntil = 0
  self.lastStuckPos = nil
  self.lastStuckTime = nil
end

-- If the bot has a move target, return that. Otherwise, return 1m in the
-- desired move direction. If there is no desired motion, this returns nil.
function BotMotion:ComputeLongTermTarget(player)
  if self.desiredMoveDirection then
    return player:GetOrigin() + self.desiredMoveDirection
  elseif self.desiredMoveTarget then
    return self.desiredMoveTarget
  end
  return nil
end

-- TODO: There is already a perfectly valid GetNearest function in NS2Utility.
-- Isn't this just a line-for-line duplication? There's also a function lying
-- around somewhere that caches its results.
local function GetNearestPowerPoint(origin)
  local nearest
  local nearestDistance = 0

  for _, ent in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do
    local distance = (ent:GetOrigin() - origin):GetLengthSquared()
    if not nearest or distance < nearestDistance then
      nearest = ent
      nearestDistance = distance
    end
  end

  return nearest
end

-- Used to determine lookahead and querying small sub-sections of the pathing
-- for move directions. Retrieve the furthest path point index < collapseDist
-- away.
function BotMotion:ComputeNextPathPointIndex(from, index, collapseDist)
  if self.currPathPoints == nil or #self.currPathPoints == 0 then
    return index
  end

  local total = 0
  local len = #self.currPathPoints
  while index < len do
    local step = from:GetDistanceTo(self.currPathPoints[index])
    if step + total >= collapseDist then
      break
    end
    total = total + step
    from = self.currPathPoints[index]
    index = index + 1
  end

  return index
end

-- Returns the mean height of the groundPoint and all path points up to dist.
function BotMotion:ComputePathHeightMean(groundPoint, index, dist)
  if self.currPathPoints == nil or #self.currPathPoints == 0 then
    return groundPoint.y
  end

  local heights = {groundPoint.y}
  local nextIndex = self:ComputeNextPathPointIndex(groundPoint, index, dist)
  for i = index, nextIndex do
    table.insert(heights, self.currPathPoints[i].y)
  end

  return table.mean(heights)
end

-- Sets currMoveDir to a move direction following the desired path.
-- TODO: Perhaps should return the direction rather than set it directly?
function BotMotion:GetOptimalMoveDirection(from, to)
  PROFILE("BotMotion:GetOptimalMoveDirection")

  local newMoveDir, reachable

  if not self.currPathPoints or self.forcePathRegen or from:GetDistanceTo(to)
      < kPathSegmentLength then
    -- There is no path, regeneration is being forced, or the path is short.
    self.currPathPoints = PointArray()
    self.currPathPointsIt = 1
    self.forcePathRegen = nil
    reachable = Pathing.GetPathPoints(from, to, self.currPathPoints)
    if reachable and #self.currPathPoints > 0 then
      newMoveDir = (self.currPathPoints[1] - from):GetUnit()
    end
  else
    -- Use the existing path to get a direction.
    if self.currPathPoints and #self.currPathPoints > 0 then
      self.currPathPointsIt = self:ComputeNextPathPointIndex(from,
        self.currPathPointsIt, kPathSegmentLength)

      if self.currPathPointsIt == #self.currPathPoints then
        self.currPathPoints = nil
      else
        -- Compute a temporary miniature path along the segment and get a
        -- direction from that. (The longer, older path may have new obstacles.)
        newMoveDir = GetPathDirection(from,
          self.currPathPoints[self.currPathPointsIt])
      end
    end
  end

  if not newMoveDir and (to - from):GetLengthSquared() > kGenerateLenSq then
    -- Fallback 1) A path couldn't be generated, so try the nearest node.
    local node = GetNearest(to, "ResourcePoint")
    if node then
      newMoveDir = GetPathDirection(from, node:GetOrigin())
    end
    if not newMoveDir then
      -- Fallback 2) Resource node path failed, try a power node instead.
      node = GetNearestPowerPoint(to)
      if node then
        newMoveDir = GetPathDirection(from, node:GetOrigin())
      end
    end
  end

  self.currMoveDir = newMoveDir or (to - from):GetUnit()
end

function BotMotion:GetRotateSpeed()
  -- Use the maximum rotation speed for hallucinations or missing aim profiles.
  if not self.bot or not self.bot.aim then
    return kMaxRotateSpeed
  end

  local aim = self.bot.aim
  return aim:GetAimTurnRateModifier()
    * kAimStateToRotateSpeeds[aim:GetAimDebuffState()]
end

-- Returns a look direction towards the desired target if within range, or along
-- the current path if out of range.
function BotMotion:GetCurPathLook(eyePos)
  local lookVec, lookDir
  if self.desiredViewTarget then
    lookVec = self.desiredViewTarget - eyePos
    lookDir = lookVec:GetUnit()
  end

  if self.currPathPoints
      and (not lookVec or lookVec:GetLength() > kLookDistance) then
    local iter = self.currPathPointsIt + 1
    local iterMax = #self.currPathPoints
    while iter < iterMax and self.currPathPoints[iter]:GetDistanceTo(eyePos)
        < kLookDistance do
      iter = iter + 1
    end
    if iter < iterMax then
      lookDir = (self.currPathPoints[iter] - eyePos):GetUnit()
    end
  end

  return lookDir or self.currMoveDir
end

function BotMotion:OnGenerateMove(player)
  PROFILE("BotMotion:OnGenerateMove")
  
  if not player:GetIsAlive() then
    Log("WARNING: Bot GenerateMove called while player[%s] is dead!",
      player:GetId())
  end

  local origin = player:GetOrigin()
  -- TODO: Only used once:
  local onGround = player.GetIsOnGround and player:GetIsOnGround()
  local eyePos = player:GetEyePos()
  local isSneaking = (player.GetCrouching and player:GetCrouching()
      and player:isa("Marine"))
    or (player:isa("Skulk") and player.movementModiferState)
  local isGroundMover = player:isa("Marine") or player:isa("Exo")
    or player:isa("Onos") or player:isa("Gorge")
  local isInCombat = (player.GetIsInCombat and player:GetIsInCombat())
  local doJump = false
  local groundPoint = Pathing.GetClosestPoint(origin)
  local isStuck = false

  local delta = origin - self.lastMovedPos
  local distToTarget = 100
  local now = Shared.GetTime()

  -- Pathing.GetClosestPoint can return the incorrect point for flying units
  -- when the map contains vertical geometry. (The Neck in ns2_veil, the stairs
  -- leading up to Launch Control in ns2_descent, etc.) For flying units, trace
  -- down to the ground and get the nearest pathing point from there in attempt
  -- to reduce this phenomenon.
  if not isGroundMover then
    local trace = GetGroundTrace(player, origin)
    if trace and trace.fraction < 1 then
      groundPoint = Pathing.GetClosestPoint(trace.endPoint)
    end
  end

  -- Reference:
  -- 1) Update ground motion.
  -- 1a) Check if flying units are making forward progress.
  -- 1b) Check if ground units need to traverse a vertical obstacle.
  -- 1c) Perform a movement update.
  -- 1c1) If the bot was flagged as stuck, move randomly and jump.
  -- 1c2) If the movement target is <1m away, go straight to it.
  -- 1c3) Determine a new movement direction.
  -- 1c3a) Adjust the desired height based on position and class. -- DISABLED --
  -- 1c3b) Add random strafing if sneaking.                       -- DISABLED --

  -- 2) Apply pathing tweak to marines if using a Phase Gate.

  -- 3) Prevent bots from leaving the navmesh.

  -- 4) Calculate view direction for a desired view target.
  -- 4a) If there is a desired view target, look directly at it.
  -- 4b) If not, look in the movement direction along the current path.
  -- 4c) Adjust marine, Exosuits and Fades to look higher when off ground.
  -- 4d) Adjust Lerk view direction when in combat.
  -- 4e) Height adjustment for all other bots.
  -- 4e1) Calculate a distance up to 4m based on obstacles.
  -- 4e2) Calculate Skulk view height.
  -- 4e3) Calculate Fade view height.
  -- 4e4) Calculate Lerk view height.
  -- 4e5) Adjust Lerk, Skulk, Fade yaw and pitch based on the result of 4e1.

  -- 5) If there was a desired view target, compute a new view direction.

  -- 6) Make sure Exosuits hold jump for at least 2 seconds.

  -- 7) Console kill the bot if stuck for over a minute.
  
  -- 1) Update ground motion.
  local moveTargetPos = self:ComputeLongTermTarget(player)
  if moveTargetPos ~= nil and not player:isa("Embryo") then
    distToTarget = origin:GetDistance(moveTargetPos)
    
    -- If within tolerance of the desired position, stay still.
    if distToTarget <= 0.01 then
      self.currMoveDir = Vector(0,0,0)
    else
      isStuck = not self.ignoreStuck
        and (delta:GetLength() < 1e-2 or self.unstuckUntil > now)

      -- 1a) Check if flying units are making forward progress.
      -- This update is currently hardcoded to happen every 3 seconds.
      -- If the unit hasn't moved 2.5m in 3s, isStuck mode is enabled.
      if not isGroundMover and not isStuck and not isSneaking then
        if not self.lastFlyingPos then
          self.lastFlyingPos = origin
          self.lastFlyingTime = now
        else
          if self.lastFlyingTime + 3 < now then
            local flyingDelta = origin - self.lastFlyingPos
            if not self.ignoreStuck and flyingDelta:GetLength() < 2.5 then
              isStuck = true
              self.unstuckUntil = now + kUnstuckDuration * math.random()
            else
              self.lastFlyingPos = origin
              self.lastFlyingTime = now
            end
          end
        end
      end

      local forwardProgress = self.desiredMoveTarget
        and delta:GetUnit():DotProduct(self.currMoveDir:GetUnit())

      -- 1b) Check if ground units need to traverse a vertical obstacle.
      -- The check looks for progress less than 1cm (1e-2) or forward movement
      -- at a different angle to the desired move direction.
      -- If found, it then checks for a height difference with its target and
      -- enables isStuck to jump.
      if self.desiredMoveTarget and isGroundMover
          and (not isStuck and (forwardProgress < 0.9
            or delta:GetLength() < 1e-2)) then
        local moveTargetDelta = self.desiredMoveTarget - origin
        local vertDist = math.abs(moveTargetDelta.y)

        if not self.ignoreStuck and vertDist > 0.5
            and vertDist > moveTargetDelta:GetLengthXZ() then
          isStuck = true
          self.lastStuckPos = nil
          self.lastStuckTime = nil
          self.unstuckUntil = now + kUnstuckDuration * math.random()
        end
      end

      -- 1c) Perform a movement update.
      if self.nextMoveUpdate <= now then
        self.nextMoveUpdate = now + kPlayerBrainTickFrametime

        -- 1c1) If the bot was flagged as stuck, move randomly and jump.
        -- Ground units will jump, and flying units add a sine wave to their
        -- vertical movement.
        if isStuck and not isSneaking then
          -- DebugLine(origin, origin + Vector(0,3,0), 0.2, 1, 1, 0, 1)
          if not self.lastStuckPos
              or (origin - self.lastStuckPos):GetLength()
                > kMinUnstuckDistance then
            self.lastStuckPos = origin
            self.lastStuckTime = now
          end

          if self.unstuckUntil < now then
            self.unstuckUntil = now + kUnstuckDuration * math.random()
            self.currMoveDir = GetRandomDirXZ()
              - GetNormalizedVectorXZ(player:GetViewCoords().zAxis)
              * GetSign((forwardProgress or 0) + 0.0001)

            if isGroundMover then
              doJump = true
              self.lastJumpTime = now
              self:SetDesiredMoveDirection(self.currMoveDir)
            else
              self.currMoveDir.y = math.sin(now * 0.3) * 4 - 2
              self.desiredViewTarget = nil
              groundPoint = nil
            end

            self.currMoveDir:Normalize()
          end

        -- 1c2) If the movement target is <1m away, go straight to it.
        -- UWE notes that this doesn't take into account the possiblity of the
        -- movement target being on the opposite side of a thin wall, and
        -- suggests adding a visibility check.
        -- Bhaz: Set slightly higher to account for floating point errors.
        elseif distToTarget <= 1.01 then
          self.currMoveDir = (moveTargetPos - origin):GetUnit()

          if self.lastStuckPos then
            self.lastStuckPos = nil
            self.lastStuckTime = nil
          end

        -- 1c3) Determine a new movement direction.
        -- This call will generate a new "major" path if there isn't one, or if
        -- the destination has changed. It also generates a "minor" (~4m) path
        -- used to determine the movement direction.
        else
          self:GetOptimalMoveDirection(origin, moveTargetPos)

          if self.lastStuckPos and
              (origin - self.lastStuckPos):GetLength()
                > kMinUnstuckDistance then
            self.lastStuckPos = nil
            self.lastStuckTime = nil
          end

          -- 1c3a) Adjust the desired height based on position and class.
          -- TODO: This was diabled by UWE. Can it be fixed?
          --[[
          if groundPoint then
            local wantedHeight = self:ComputePathHeightMean(groundPoint,
              self.currPathPointsIt, 4.0)

            if player:isa("Fade") then
              -- wantedHeight = wantedHeight + 1.3
              wantedHeight = currentPos.y
            elseif player:isa("Lerk") then
              wantedHeight = wantedHeight + 1.1
            elseif player:isa("Skulk") then
              wantedHeight = wantedHeight + 0.4
            end

            -- Adjust move direction to ensure bots stay off the ground as
            -- needed.
            local heightDiff = wantedHeight - currentPos.y

            if math.abs(heightDiff) > 0.4 then
              self.currMoveDir.y = heightDiff
            else
              self.currMoveDir.y = 0.0
            end
          end
          --]]

          -- 1c3b) Add random strafing if sneaking.
          -- TODO: Also disabled by UWE. Apparently gets bots stuck easily.
          --[[
          if isSneaking then
            local time = Shared.GetTime()
            local strafeTarget = self.currMoveDir:CrossProduct(Vector(0,1,0))
            strafeTarget:Normalize()

            -- Numbers chosen arbitrarily to give some appearance of sneaking.
            strafeTarget = strafeTarget * ConditionalValue(math.sin(time * 1.5)
              + math.sin(time * 0.2 ) > 0 , -1, 1)
            strafeTarget = (strafeTarget + self.currMoveDir):GetUnit()

            if strafeTarget:GetLengthSquared() > 0 then
              self.currMoveDir = strafeTarget
            end
          end
          --]]
        end

        self.currMoveTime = now
      end

      self.lastMovedPos = origin
    end
  else
    self.currMoveDir = Vector(0,0,0)
  end

  -- 2) Apply pathing tweak to marines if using a Phase Gate.
  -- This allows marines about to move through a Phase Gate to leave the
  -- navmesh.
  -- TODO: Another variable that's only used outside once.
  local skipOnNavMeshTweak = false
  local forceOffNavMesh = false
  if player:isa("Marine") then
    if self.bot and self.bot.brain and self.bot.brain.lastGateId ~= nil then
      skipOnNavMeshTweak = true
    end
  end
  if self.bot and self.bot.offNavMesh then
    forceOffNavMesh = true
  end

  -- 3) Prevent bots from leaving the navmesh.
  -- This forces the move direction to a point at the edge of the navmesh if a
  -- bot has exceeded the allowed tolerance.
  if (self.desiredMoveDirection and distToTarget <= 2.0
      and not skipOnNavMeshTweak) and not forceOffNavMesh then 
    local roughNextPoint = origin + self.currMoveDir * delta:GetLength()
    local closestPoint = Pathing.GetClosestPoint(roughNextPoint)
    if closestPoint and groundPoint
        and ((closestPoint - roughNextPoint):GetLengthXZ()
          > kMaxNavMeshDistance)
        and ((groundPoint - origin):GetLengthXZ() > 0.1) then
      self.currMoveDir = (closestPoint - origin):GetUnit()
    end
  end

  -- 4) Calculate view direction for a desired view target.
  local desiredDir
  if self.desiredViewTarget ~= nil then
    -- 4a) If there is a desired view target, look directly at it.
    desiredDir = (self.desiredViewTarget - eyePos):GetUnit()
  elseif self.currMoveDir:GetLength() > 1e-4 and not isStuck then
    -- 4b) If not, look in the movement direction along the current path.
    -- Marines and Exosuits always look along their current path. Aliens have
    -- their look vector adjusted for height.
    if self:isa("Marine") or self:isa("Exo") then
      desiredDir = self:GetCurPathLook(eyePos)
    else
      desiredDir = self.currMoveDir
      if isGroundMover or player:isa("Skulk") then
        -- Pathing points are off ground, which can make the bots look up.
        desiredDir.y = 0.0
      end
      desiredDir = desiredDir:GetUnit()
    end

    -- 4c) Adjust marine, Exosuits and Fades to look higher when off ground.
    if player:isa("Exo") or player:isa("Marine") or player:isa("Fade") then
      if doJump or not onGround then
        desiredDir.y = 0.2
      else
        desiredDir.y = 0.0
      end
    end

    -- 4d) Adjust Lerk view direction when in combat.
    -- Uses a sine wave to (allegedly) simulate a good player's movements.
    -- TODO: Bring this back out and test, and maybe tone it down.
    if player:isa("Lerk") and isInCombat and distToTarget > 8.5
        and (not HasMixin(player, "Live")
          or player:GetHealthScalar() < 0.75) then
      -- TODO: Tune based on "allowable" space for X Location(segment)
      -- TODO: Could be useful for jetpack marines.

      desiredDir.y = (math.sin(now * 2.48) + math.cos(now * 0.9)) * 0.4

      -- If too low, prevent the desired y from being negative. This should
      -- prevent the sine wave from making the Lerk faceplant.
      if groundPoint and origin.y < groundPoint.y then
        desiredDir.y = 0.2
      end

      -- When a Lerk is headbutting a wall, their eyePos actually clips through
      -- the wall. The engagement point is used instead. (Rough centre.)
      local engagement = player:GetEngagementPoint()
      local trace = GetTargetTrace(player, engagement,
        engagement + desiredDir * 3)

      -- Emergency dive/climb back to "normal" levels if the Lerk is going to
      -- fly into something while attempting to juke.
      if trace and trace.fraction < 1
          or (groundPoint and (origin.y - groundPoint.y) > 2.0) then
        -- If the Lerk is about to impact a doorway, give it a quick tap of the
        -- crouch key to duck under.
        if groundPoint and origin.y - groundPoint.y > 2.75 then
          self.shouldCrouch = true
        end

        desiredDir = self:GetCurPathLook(eyePos)
        desiredDir.y = desiredDir.y - 0.3 -- Fallback approximation.

        if trace and groundPoint then
          -- Better approximation using angle to the ground to pick a vertical
          -- look component. Still not perfect but would need round-trip through
          -- a Coords for actual mathematically-correct rotation
          local heightDiff = 0.8 - (origin.y - groundPoint.y)
          -- Increase the vertical dive factor here with tuned constants.
          local desiredAng = math.atan2(heightDiff,
            (trace.endPoint - origin):GetLengthXZ() * 0.8)
          desiredDir.y = math.sin(desiredAng)

          -- If the Lerk is too low, this should have the opposite effect.
          if origin.y < groundPoint.y then
            desiredDir.y = -desiredDir.y
          end
        end
      end
      --[[ DebugLine(origin, origin + GetNormalizedVector(desiredDir) * 3,
        1/3, 1, 0, 0, 1) ]]
    
    -- 4e) Height adjustment for all other bots.
    else
      local desiredHeight = groundPoint and groundPoint.y + 1.1 or 0
      local desiredDist = 4.0

      -- 4e1) Calculate a distance up to 4m based on obstacles.
      -- Determine if we're going to run into anything and adjust our
      -- "achievable distance".
      if player:isa("Lerk") or player:isa("Skulk") or player:isa("Fade") then
        local traceDir = self.currMoveDir
        if player:isa("Lerk") or player:isa("Fade") then
          traceDir = player:GetVelocity():GetUnit()
        end

        local engagement = player:GetEngagementPoint()
        local trace = GetTargetTrace(player, engagement,
          engagement + traceDir * desiredDist)

        if trace and trace.fraction < 1 then
          desiredDist = (trace.endPoint - origin):GetLengthXZ()
        end
      end

      -- 4e2) Calculate Skulk view height.
      -- Skulk vertical view is 3m path height mean + 0.2.
      if player:isa("Skulk") then
        local heightAvg = groundPoint and self:ComputePathHeightMean(
          groundPoint, self.currPathPointsIt, 3.0) + 0.2
        desiredHeight = heightAvg or origin.y

      -- 4e3) Calculate Fade view height.
      -- Fade vertical view is 4m path height mean + 0.5 out of combat, and
      -- target height in combat when the target is <8.5m away.
      -- Original value was + 1.3, which basically made Fades look at the roof.
      elseif player:isa("Fade") then
        local heightAvg = groundPoint and self:ComputePathHeightMean(
          groundPoint, self.currPathPointsIt, 4.0) + 0.5
        -- TODO: This wipes out ALL prior y calculations. So why bother?
        desiredDir.y = 0

        if isInCombat and distToTarget < 8.5 then
          desiredHeight = moveTargetPos.y
        else
          desiredHeight = heightAvg or origin.y
        end

      -- 4e4) Calculate Lerk view height.
      -- Lerks out of combat follow 4m height path average, with smoothing
      -- applied so turns are made less violently.
      elseif player:isa("Lerk") and not isInCombat then
        desiredDir.y = 0

        local fromPoint = groundPoint or Vector(origin.x, self.lastGroundHeight
          or origin.y, origin.z)
        local heightMean = self:ComputePathHeightMean(fromPoint,
          self.currPathPointsIt, 4.0)

        if not self.lastGroundHeight then
          self.lastGroundHeight = heightMean
        end

        -- TODO: Experiment with values other than 0.8, how low can it go to
        -- create a much smoother flight path before it becomes a detriment?
        heightMean = Lerp(self.lastGroundHeight, heightMean, 0.8)

        if self.currPathPoints and #self.currPathPoints > 0 then
          -- Find the next point we'll be attempting to move to
          local nextPointIdx = self:ComputeNextPathPointIndex(eyePos,
            self.currPathPointsIt, 6)
          local nextPoint = self.currPathPoints[nextPointIdx]

          local currentPoint = self.currPathPoints[self.currPathPointsIt]
          local steerDist = (currentPoint - origin):GetLengthXZ()

          local nextDir = GetNormalizedVectorXZ(nextPoint - currentPoint)
          local progress = Clamp(steerDist / 4.0, 0.0, 1.0)

          -- Progressively steer towards the next path point.
          desiredDir = Lerp(desiredDir, nextDir, 1.0 - progress)
        end

        -- Apply a sine wave to the flight height.
        -- Default was 1.3, trying 1.5 to see if they touch the ground less.
        local height = 1.5 + (math.sin(now * 1.45) + math.cos(now * 2.15))
          * 0.45
        desiredHeight = heightMean + height
      end

      -- 4e5) Adjust Lerk, Skulk, Fade yaw and pitch based on the result of 4e1.
      -- Shifts view pitch up to a maximum of 4m based on immediate obstacles.
      if player:isa("Lerk") or player:isa("Skulk") or player:isa("Fade") then
        local yaw = GetYawFromVector(desiredDir)
        local pitch = math.atan2(desiredHeight - origin.y, desiredDist)

        local currentPitch = player:GetViewAngles().pitch
        local newPitch = SlerpRadians(currentPitch, pitch, 0.8)

        desiredDir = Vector(math.sin(yaw), math.sin(newPitch), math.cos(yaw))

        -- For a Lerk, an obstacle may not necessarily be a box on the floor,
        -- but a rafter on the ceiling.
        if player:isa("Lerk") and desiredDist < 0.5 and desiredDir.y > 0
            and origin.y > groundPoint.y then
          desiredDir.y = -desiredDir.y
          --[[ DebugLine(origin, origin + GetNormalizedVector(desiredDir) * 4,
            1/3, 1, 1, 0, 1) ]]
        end
      end
    end

    desiredDir:Normalize()
  end

  -- 5) If there was a desired view target, compute a new view direction.
  if desiredDir then
    -- TODO: Change the frametime to the actual time spent, since it could be in
    -- combat doing 26fps or out of combat and doing 8fps.
    local slerpSpeed = kPlayerBrainTickFrametime * self:GetRotateSpeed()

    local currentYaw = player:GetViewAngles().yaw
    local targetYaw = GetYawFromVector(desiredDir)

    local xzLen = desiredDir:GetLengthXZ()

    local newYaw = SlerpRadians(currentYaw, targetYaw, slerpSpeed)

    local currentPitch = player:GetViewAngles().pitch
    local targetPitch = GetPitchFromVector(desiredDir)
    local newPitch = SlerpRadians(currentPitch, targetPitch, slerpSpeed)

    --local inBetween = Vector(math.sin(newYaw) * xzLen, -math.sin(targetPitch),
    --  math.cos(newYaw) * xzLen)
    local cosPitch = math.cos(newPitch)
    local inBetween = Vector(
      cosPitch * math.sin(newYaw),
      -math.sin(newPitch),
      cosPitch * math.cos(newYaw))
    self.currViewDir = inBetween:GetUnit()
  end
  --[[ if forceOffNavMesh and self.desiredViewTarget then
    self.currViewDir = (self.desiredViewTarget - eyePos):GetUnit()
  end ]]

  -- 6) Make sure Exosuits hold jump for at least 2 seconds.
  if player:isa("Exo") and (self.lastJumpTime and self.lastJumpTime
      > now - 2) then
    doJump = true
  end

  -- 7) Console kill the bot if stuck for over a minute.
  if self.lastStuckPos and self.lastStuckTime
      and (origin - self.lastStuckPos):GetLength() < kMinUnstuckDistance
      and self.lastStuckTime + kMaxStuckTime < now then
    player:Kill(nil, nil, origin)
    self.lastStuckPos = nil
    self.lastStuckTime = nil
  end

  return self.currViewDir, self.currMoveDir, doJump
end

--------------------------------------------------------------------------------
-- Interface for move and view direction.
--------------------------------------------------------------------------------

-- Set a desired move location. Also clears the desired move direction if one
-- exists.
---@diagnostic disable-next-line: duplicate-set-field
function BotMotion:SetDesiredMoveTarget(toPoint)
  if self.bot and self.bot.overridePathing then
    return
  end
  self:SetDesiredMoveDirection(nil)
  if not VectorsApproxEqual(toPoint, self.desiredMoveTarget, 1e-4) then
    -- TODO: If the target is far, reuse the same path and regen later.
    self.desiredMoveTarget = toPoint
    self.desiredMoveDirection = nil
    self.forcePathRegen = true
  end
end

-- While a move direction is set, it overrides SetDesiredMoveTarget.
function BotMotion:SetDesiredMoveDirection(direction)
  if self.bot and self.bot.overridePathing then
    return
  end
  if not VectorsApproxEqual(direction, self.desiredMoveDirection, 1e-4) then
    self.desiredMoveDirection = direction
    self.desiredMoveTarget = nil
  end
end

-- Set or clear a view target.
function BotMotion:SetDesiredViewTarget(target)
  if self.bot and self.bot.overridePathing then
    return
  end
  self.desiredViewTarget = target
end

-- Get the current path, returns nil if not currently on one.
function BotMotion:GetPath()
  return self.currPathPoints
end

-- Get the current path index. Check if the path is nil first.
function BotMotion:GetPathIndex()
  return self.currPathPointsIt
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
