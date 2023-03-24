if Client then

    local baseOnInitialized = AlienCommander.OnInitialized
    function AlienCommander:OnInitialized()
        baseOnInitialized(self)
        self.darkVisionTime = Shared.GetTime()
    end
    
    function AlienCommander:UpdateClientEffects(deltaTime, isLocal)

        Commander.UpdateClientEffects(self,deltaTime, isLocal)
        
        if isLocal then

            local useShader = Player.screenEffects.darkVision

            if useShader then

                useShader:SetActive(true)
                useShader:SetParameter("startTime", self.darkVisionTime)
                useShader:SetParameter("time", Shared.GetTime())
                useShader:SetParameter("amount", 1)

            end

        end

    end
    
end 