
if Server then

    function Tunnel:GetOwnerClientId()
        return self.ownerClientId
    end

    function Tunnel:SetOwnerClientId(clientId)
        self.ownerClientId = clientId
    end

    local function remap(x,t1,t2,s1,s2)
        local invLerp= ((x - t1) / (t2 - t1))
        return  invLerp * (s2 - s1) + s1
    end
    
    function Tunnel:UseExit(entity, exit, exitSide)
        
        
        local destinationOrigin = exit:GetOrigin() 

        local normal =exit:GetCoords().yAxis

        local extents = GetExtents(entity:GetTechId())
        local maxExtent = math.max(extents.x,extents.y,extents.z)
        local upValue = Math.DotProduct(normal,Vector(0,1,0))  -- -1 down 1 up
        local downParam = remap(upValue,1,-1,0,1)
        local sideParam = remap(math.abs(upValue),0,1,1,0)
        
        destinationOrigin =  destinationOrigin + normal * (0.3 + downParam * maxExtent * 2)
        destinationOrigin = destinationOrigin - Vector(0,sideParam * maxExtent ,0)
        
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
