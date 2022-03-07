
if Server then

    
    function Tunnel:MovePlayerToTunnel(player, entrance)
    
        assert(player)
        assert(entrance)
        
        local entranceId = entrance:GetId()

        if GetHasTech(self,kTechId.FastTunnel) then
            if entranceId == self.exitAId then
                self.timeExitAUsed = Shared.GetTime()   
                self:UseExit(player, self:GetExitB(), kTunnelExitSide.B)
            elseif entranceId == self.exitBId then
                self.timeExitBUsed = Shared.GetTime()
                self:UseExit(player, self:GetExitA(), kTunnelExitSide.A)
            end

            return
        end
        
        local newAngles = player:GetViewAngles()
        newAngles.pitch = 0
        newAngles.roll = 0

        --Two sound effects required here for inside and outside a tunnel
        --Required to call effects manager due to sound-parenting behaviors
        if entranceId == self.exitAId then
        
            player:SetOrigin(self:GetEntranceAPosition())
            newAngles.yaw = GetYawFromVector(self:GetCoords().zAxis)
            player:SetOffsetAngles(newAngles)
            self:TriggerEffects("tunnel_enter_3D", { effecthostcoords = player:GetCoords() })
            self:TriggerEffects("tunnel_enter_3D", { effecthostcoords = entrance:GetCoords() })
            self.timeExitAUsed = Shared.GetTime()   
            
        elseif entranceId == self.exitBId then
        
            player:SetOrigin(self:GetEntranceBPosition())
            newAngles.yaw = GetYawFromVector(-self:GetCoords().zAxis)
            player:SetOffsetAngles(newAngles)
            self:TriggerEffects("tunnel_enter_3D", { effecthostcoords = player:GetCoords() })
            self:TriggerEffects("tunnel_enter_3D", { effecthostcoords = entrance:GetCoords() })
            self.timeExitBUsed = Shared.GetTime()
            
        end

        
    end
end
