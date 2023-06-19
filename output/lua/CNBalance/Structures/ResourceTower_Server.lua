
function ResourceTower:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    
    -- Its handled by playingteam,so we don't concern about it anymore
    --if self:GetIsCollecting() then
    --
    --    if not self.timeLastCollected then
    --        self.timeLastCollected = Shared.GetTime()
    --    end
    --
    --    if self.timeLastCollected + kResourceTowerResourceInterval < Shared.GetTime() then
    --    
    --        self:CollectResources()
    --        self.timeLastCollected = Shared.GetTime()
    --        
    --    end
    --    
    --else
    --    self.timeLastCollected = nil
    --end

end
