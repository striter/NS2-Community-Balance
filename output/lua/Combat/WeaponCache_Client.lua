local kHealthIndicatorModelName = PrecacheAsset("models/marine/armory/health_indicator.model")

function WeaponCache:OnInitClient()
    if not self.clientConstructionComplete then
        self.clientConstructionComplete = self.constructionComplete
    end    
    
    -- Initialize health indicator
    self.healthIndicator = nil
end

function WeaponCache:GetWarmupCompleted()
    return not self.timeConstructionCompleted or (self.timeConstructionCompleted + 0.7 < Shared.GetTime())
end

-- Handle use key press to open buy menu
function WeaponCache:OnUse(player, elapsedTime, useSuccessTable)
    self:UpdateArmoryWarmUp()
    
    if GetIsUnitActive(self) and not Shared.GetIsRunningPrediction() and not player.buyMenu and self:GetWarmupCompleted() then
        if Client.GetLocalPlayer() == player then
            Client.SetCursor("ui/Cursor_MarineCommanderDefault.dds", 0, 0)
            player:BuyMenu(self)
        end
    end
end

function WeaponCache:SetOpacity(amount, identifier)
    for i = 0, self:GetNumChildren() - 1 do
        local child = self:GetChildAtIndex(i)
        if HasMixin(child, "Model") then
            child:SetOpacity(amount, identifier)
        end
    end
end

function WeaponCache:UpdateArmoryWarmUp()
    if self.clientConstructionComplete ~= self.constructionComplete and self.constructionComplete then
        self.clientConstructionComplete = self.constructionComplete
        self.timeConstructionCompleted = Shared.GetTime()
    end
end

local kUpVector = Vector(0, 1, 0)

function WeaponCache:OnUpdateRender()
    PROFILE("WeaponCache:OnUpdateRender")

    -- Constant health indicator when built - always show above cache
    local showHealthIndicator = self:GetIsBuilt()
    
    -- Create health indicator model if not exists
    if not self.healthIndicator then
        self.healthIndicator = Client.CreateRenderModel(RenderScene.Zone_Default)  
        self.healthIndicator:SetModel(kHealthIndicatorModelName)
    end
    
    -- Always update visibility
    self.healthIndicator:SetIsVisible(showHealthIndicator)
    
    -- Rotate health indicator when visible
    if showHealthIndicator then
        local time = Shared.GetTime()
        local zAxis = Vector(math.cos(time * 1.5), 0, math.sin(time * 1.5))
        -- Position above the cache
        local coords = Coords.GetLookIn(self:GetOrigin() + 2 * kUpVector, zAxis)
        self.healthIndicator:SetCoords(coords)
    end
end

function WeaponCache:OnDestroy()
    if self.healthIndicator then
        Client.DestroyRenderModel(self.healthIndicator)
        self.healthIndicator = nil
    end
    
    ScriptActor.OnDestroy(self)
end
