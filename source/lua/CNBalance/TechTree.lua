if Client then
    function TechTree:UpdateTechNodeFromNetwork(techNodeUpdateTable)

        local techNode = self:GetTechNode(techNodeUpdateTable.techId)
    
        if techNode ~= nil then
    

            local lastResearching = techNode:GetResearching() and not techNode:GetResearched()
            ParseTechNodeUpdateMessage(techNode, techNodeUpdateTable)
    
            if techNode:GetTechId() == kTechId.Revolver then
                Shared.Message(tostring(techNode.GetAvailable()))
            end
            
            if techNode:GetIsResearch() then
    
                local techId = techNode:GetTechId()
                local inProgress = ConditionalValue(techNode:GetResearching() and not techNode:GetResearched(), true, nil)
                self.inProgressResearch[techId] = ConditionalValue(inProgress, {techId = techId, entityId = nil}, nil)
    
                if not self.inProgressCancelled then
                    self.inProgressCancelled = (lastResearching == true and inProgress == nil)
                end
    
                -- Make sure Client knows about researching changes.
                if Client and lastResearching ~= inProgress then
    
                    local player = Client.GetLocalPlayer()
                    if player and inProgress and HasMixin(player, "GUINotification") and not GetTechIdIsInstanced(techId) then
                        player:AddNotification({techId = techId, entityId = nil, source = kResearchNotificationSource.UpdateNode})
                    end
    
                end
            end
        end
    end
end

if Server then

    function TechTree:SendTechTreeUpdates(playerList)

        for _, techNode in ipairs(self.techNodesChanged:GetList()) do
            
            Shared.Message(EnumToString(kTechId,techNode:GetTechId()))
            local techNodeUpdateTable = BuildTechNodeUpdateMessage(techNode)
            local removedInstances = {}
            
            for _, player in ipairs(playerList) do
            
                Server.SendNetworkMessage(player, "TechNodeUpdate", techNodeUpdateTable, true)
                removedInstances = self:SendTechNodeInstances(player, techNode)
                
            end
    
            -- Remove any done-for research instances after we are done sending them to players.
            if techNode.instances then
                for i = 1, #removedInstances do
                    techNode.instances[removedInstances[i]] = nil
                end
            end
            
        end
        
        self.techNodesChanged:Clear()
        
    end
end