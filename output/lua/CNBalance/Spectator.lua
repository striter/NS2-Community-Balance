-- Spectator dark vision override


if Client then
    local baseOnCreate = Spectator.OnCreate
    function Spectator:OnCreate()
        baseOnCreate(self)

        self.darkVisionOn = false
        self.darkVisionLastFrame = false
        self.lastDarkVisionState = false
        self.darkVisionTime = 0
        self.darkVisionEndTime = 0
    end
    
    local baseUpdateClientEffects = Spectator.UpdateClientEffects
    function Spectator:UpdateClientEffects(deltaTime, isLocal)
        baseUpdateClientEffects(self, deltaTime, isLocal)
        
        local darkVisionFadeAmount = 1
        local darkVisionFadeTime = 0.2
        local darkVisionState = self.darkVisionOn
        
        if self.lastDarkVisionState ~= darkVisionState then
            if darkVisionState then
                self.darkVisionTime = Shared.GetTime()
            else
                self.darkVisionEndTime = Shared.GetTime()
            end
            self.lastDarkVisionState = darkVisionState
        end
        
        if not darkVisionState then
            darkVisionFadeAmount = Clamp(1 - (Shared.GetTime() - self.darkVisionEndTime) / darkVisionFadeTime, 0, 1)
        end

        local useShader = Player.screenEffects.darkVision
        if useShader then
            useShader:SetActive(true)
            useShader:SetParameter("startTime", self.darkVisionTime)
            useShader:SetParameter("time", Shared.GetTime())
            useShader:SetParameter("amount", darkVisionFadeAmount)
        end
    end
    
    local baseOnProcessMove = Spectator.OnProcessMove
    function Spectator:OnProcessMove(input)
        baseOnProcessMove(self, input)

        local darkVisionPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
        if not self.darkVisionLastFrame and darkVisionPressed then
            self.darkVisionOn = not self.darkVisionOn
        end
        self.darkVisionLastFrame = darkVisionPressed
    end
end
