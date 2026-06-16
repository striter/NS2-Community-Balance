if Server then

    function MinimapConnectionMixin:OnUpdate(deltaTime)

        local endPoint = self:GetConnectionEndPoint()
        local startPoint = self:GetConnectionStartPoint()

        if (not endPoint or not startPoint) and self.connectorId then

            local connector = Shared.GetEntity(self.connectorId)
            if connector then
                DestroyEntity(connector)
            end

            self.connectorId = nil

        elseif endPoint and startPoint and not self.connectorId then
            self.connectorId = CreateEntity(MapConnector.kMapName, startPoint, self:GetTeamNumber()):GetId()

            if self.GetIsConnectionOneSided and self:GetIsConnectionOneSided() then
                local connector = Shared.GetEntity(self.connectorId)
                if connector then
                    connector.isOneSided = true
                end
            end
        end

        if endPoint and startPoint and self.connectorId then

            local connector = Shared.GetEntity(self.connectorId)
            assert(connector)
            connector:SetOrigin(startPoint)
            connector:SetEndPoint(endPoint)

        end

    end
    
end
