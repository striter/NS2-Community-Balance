
if Server then

    local baseUseExit =Tunnel.UseExit
    function Tunnel:UseExit(entity, exit, exitSide)
        baseUseExit(self,entity,exit,exitSide)
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
