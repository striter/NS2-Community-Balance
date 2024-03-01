
if Server then

    function Tunnel:GetOwnerClientId()
        return self.ownerClientId
    end

    function Tunnel:SetOwnerClientId(clientId)
        self.ownerClientId = clientId
    end

    function Tunnel:UseExit(entity, exit, exitSide)
        
        local extent = GetExtents(entity:GetTechId())
        
        local destinationOrigin = exit:GetOrigin() 

        local normal =exit:GetCoords().yAxis
        if normal.y == 1 then
            destinationOrigin = destinationOrigin + normal*0.3
        else
            destinationOrigin = destinationOrigin + normal * (0.5 +extent.y * 2)
        end
        
        if entity.OnUseGorgeTunnel then
            entity:OnUseGorgeTunnel(destinationOrigin)
        end

        self:TriggerEffects("tunnel_exit_3D", { effecthostcoords = entity:GetCoords() })

        --Required to call effects manager due to sound-parenting behaviors, otherwise sound doesn't play INSIDE tunnels
        self:TriggerEffects("tunnel_exit_3D", { effecthostcoords = entity:GetCoords() })

        entity:SetOrigin(destinationOrigin)

        if entity:isa("Player") then

            local newAngles = entity:GetViewAngles()
            newAngles.pitch = 0
            newAngles.roll = 0
            newAngles.yaw = newAngles.yaw + self:GetMinimapYawOffset()
            entity:SetOffsetAngles(newAngles)

            if HasMixin(entity, "TunnelUser") then
                entity.currentTunnelId = Entity.invalidId
            end

        end

        exit:OnEntityExited(entity)

        if exitSide == kTunnelExitSide.A then
            self.timeExitAUsed = Shared.GetTime()
        elseif exitSide == kTunnelExitSide.B then
            self.timeExitBUsed = Shared.GetTime()
        end
        
        if exit.hasCragUpgrade then
            if entity and HasMixin(entity, "Mucousable") then
                entity:SetMucousShield()
            end
        end
    end
    
    local baseMovePlayerToTunnel = Tunnel.MovePlayerToTunnel
    function Tunnel:MovePlayerToTunnel(player, entrance)
    
        assert(player)
        assert(entrance)
        
        local entranceId = entrance:GetId()
        if entrance.hasShiftUpgrade then
            if entranceId == self.exitAId then
                local exitB = self:GetExitB()
                if exitB then
                    self.timeExitAUsed = Shared.GetTime()
                    self:UseExit(player, exitB, kTunnelExitSide.B)
                    return
                end
            elseif entranceId == self.exitBId then
                local exitA = self:GetExitA()
                if exitA then
                    self.timeExitBUsed = Shared.GetTime()
                    self:UseExit(player, exitA, kTunnelExitSide.A)
                    return
                end 
            end
        end
        baseMovePlayerToTunnel(self,player,entrance)
    end
end
