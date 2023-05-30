local kHealthIndicatorModelName = PrecacheAsset("models/marine/armory/health_indicator.model")

function GetResearchPercentage(techId)

    local techNode = GetTechTree():GetTechNode(techId)
    
    if(techNode ~= nil) then
    
        if(techNode:GetAvailable()) then
            return 1
        elseif(techNode:GetResearching()) then
            return techNode:GetResearchProgress()
        end    
        
    end
    
    return 0
    
end

function Armory_Debug()

    -- Draw armory points
    
    local indexToUseOrigin = {
        Vector(Armory.kResupplyUseRange, 0, 0), 
        Vector(0, 0, Armory.kResupplyUseRange),
        Vector(-Armory.kResupplyUseRange, 0, 0),
        Vector(0, 0, -Armory.kResupplyUseRange)
    }
    
    local indexToColor = {
        Vector(1, 0, 0),
        Vector(0, 1, 0),
        Vector(0, 0, 1),
        Vector(1, 1, 1)
    }
    
    function isaWeaponCache(entity) return entity:isa("WeaponCache") end
    
    for index, armory in ientitylist(Shared.GetEntitiesWithClassname("WeaponCache")) do
    
        local startPoint = armory:GetOrigin()
        
        for loop = 1, 4 do
            
            local endPoint = startPoint + indexToUseOrigin[loop]
            local color = indexToColor[loop]
            DebugLine(startPoint, endPoint, .2, color.x, color.y, color.z, 1)
            
        end
        
    end
    
end

function WeaponCache:OnInitClient()

    if not self.clientConstructionComplete then
        self.clientConstructionComplete = self.constructionComplete
    end    


end

function WeaponCache:GetWarmupCompleted()
    return not self.timeConstructionCompleted or (self.timeConstructionCompleted + 0.7 < Shared.GetTime())
end


--deprecated funtion from old armory code. you can no long use weapon cache or armory 
--[[
function WeaponCache:OnUse(player, elapsedTime, useSuccessTable)
    if Client.GetIsControllingPlayer() and self:GetIsBuilt() then
        player:Buy(self)
    end
end
]]--

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

    local player = Client.GetLocalPlayer()
    local showHealthIndicator = false
    
    if player then    
        --showHealthIndicator = GetIsUnitActive(self) and GetAreFriends(self, player) and (player:GetHealth()/player:GetMaxHealth()) ~= 1 and player:GetIsAlive() and not player:isa("Commander")
        showHealthIndicator = self:GetIsBuilt() and GetAreFriends(self, player) and (player:GetHealth()/player:GetMaxHealth()) ~= 1 and player:GetIsAlive() and not player:isa("Commander")  
    end

    if not self.healthIndicator then
    
        self.healthIndicator = Client.CreateRenderModel(RenderScene.Zone_Default)  
        self.healthIndicator:SetModel(kHealthIndicatorModelName)
        
    end
    
    self.healthIndicator:SetIsVisible(showHealthIndicator)
    
    -- rotate model if visible
    if showHealthIndicator then
    
        local time = Shared.GetTime()
        local zAxis = Vector(math.cos(time), 0, math.sin(time))

        local coords = Coords.GetLookIn(self:GetOrigin() + 2.9 * kUpVector, zAxis)
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