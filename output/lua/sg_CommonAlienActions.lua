function HandleAlienTunnelMove( alienPos, targetPos, bot, brain, move )
    -- PROFILE("HandleAlienTunnelMove")

    -- -- Should caller avoid setting move target/dir
    -- -- For example, Skulk likes to jump which can cause it to overshoot tunnel entrances
    -- local shouldIgnorePostMove = false

    -- --bot:GetMotion():SetIgnoreStuck(false)

    -- local alien = bot:GetPlayer()
    -- local eResult, targetDistance, goalPos, entranceTunnel = GetTunnelDistanceForAlien(alien, targetPos)
    -- GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Tunnel eResult", EnumToString(kTunnelDistanceResult, eResult))
    -- GetBotDebuggingManager():UpdateBotDebugSectionField(bot:GetId(), kBotDebugSection.ActionWeight, "Tunnel Target Distance", targetDistance)
    -- local goalDistance = alienPos:GetDistance(goalPos)

    -- if eResult == kTunnelDistanceResult.NoTunnel then -- No good tunnel available, just move normally
    --     brain.teamBrain:DequeueBotForTunnel(alien:GetId())
    --     bot:GetMotion():SetDesiredMoveTarget( goalPos )
    -- elseif eResult == kTunnelDistanceResult.SameTunnel then -- We are in the same tunnel as the target!

    --     brain.teamBrain:DequeueBotForTunnel(alien:GetId())
    --     local moveDirection = (goalPos - alienPos):GetUnit()
    --     bot:GetMotion():SetDesiredMoveDirection(moveDirection)
    --     bot:GetMotion():SetDesiredViewTarget(goalPos)

    -- elseif eResult == kTunnelDistanceResult.WrongTunnel then -- In a tunnel, but the wrong one (or one on the way to target)

    --     brain.teamBrain:DequeueBotForTunnel(alien:GetId())
    --     local moveDirection = (goalPos - alienPos):GetUnit()
    --     bot:GetMotion():SetDesiredMoveDirection(moveDirection)
    --     bot:GetMotion():SetDesiredViewTarget(goalPos)

    -- elseif eResult == kTunnelDistanceResult.TunnelCollapse then -- No exits to use! we should be dead already but just in case we'll just stay still here

    --     brain.teamBrain:DequeueBotForTunnel(alien:GetId())
    --     shouldIgnorePostMove = true

    -- elseif eResult == kTunnelDistanceResult.EnterTunnel then -- We want to enter a tunnel.

    --     brain.teamBrain:EnqueueBotForTunnel(alien:GetId(), entranceTunnel:GetId())

    --     local tunnelOrigin = entranceTunnel:GetOrigin()
    --     local isThisBotsTurn, nextPlayerId = brain.teamBrain:GetCanBotUseTunnel(alien:GetId(), entranceTunnel:GetId())

    --     bot:GetMotion():SetDesiredMoveTarget( goalPos )

    --     local xzAlienPos = Vector(alienPos.x, 0, alienPos.z)
    --     local xzGoalPos = Vector(goalPos.x, 0, goalPos.z)
    --     local xzGoalDistance = xzAlienPos:GetDistance(xzGoalPos)

    --     if isThisBotsTurn then

    --         if xzGoalDistance < 3 then

    --             local moveDir = (goalPos - alien:GetOrigin()):GetUnit()
    --             bot:GetMotion():SetDesiredMoveDirection(moveDir)

    --             -- Go slow here, so we don't constantly overshoot and get stuck
    --             local slowMoveCommand = kAlienClassSlowMoveMap[alien:GetClassName()] or 0
    --             move.commands = AddMoveCommand( move.commands, slowMoveCommand )

    --             if xzGoalDistance < 0.8 then -- STOP! Any movement will cancel entering the tunnel!
    --                 bot:GetMotion():SetDesiredMoveTarget( nil )
    --             end

    --             shouldIgnorePostMove = true
    --             if alien:isa("Lerk") then
    --                 goalPos.y = goalPos.y + 0.3 -- Just so that lerk can more easily step over the tunnel
    --                 bot:GetMotion():SetIgnoreStuck(true)
    --                 bot:GetMotion():SetDesiredViewTarget( goalPos )
    --             else
    --                 bot:GetMotion():SetDesiredViewTarget( goalPos )
    --             end

    --         end
    --     elseif xzGoalDistance < 4 then
    --         local nextPlayer = Shared.GetEntity(nextPlayerId)
    --         bot:GetMotion():SetDesiredMoveTarget( nil )
    --         bot:GetMotion():SetDesiredViewTarget( nextPlayer and nextPlayer:GetOrigin() or nil )
    --         if brain.lastTunnelEntranceId ~= entranceTunnel:GetId() then
    --             -- When we just enter the "stop and wait" phase, re-sort so we make sure that the closest
    --             -- bot is the first one.
    --             GetTeamBrain(alien:GetTeamNumber()):SortTunnelQueue(entranceTunnel:GetId())
    --             brain.lastTunnelEntranceId = entranceTunnel:GetId()
    --         end

    --         bot:GetMotion():SetIgnoreStuck(true)
    --         shouldIgnorePostMove = true -- Stop and wait for the next bot in queue
    --     end
    -- end

    -- return shouldIgnorePostMove, targetDistance, goalPos, entranceTunnel
    return 0
end