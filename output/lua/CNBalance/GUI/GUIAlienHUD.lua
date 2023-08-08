
local baseInitialize = GUIAlienHUD.Initialize
function GUIAlienHUD:Initialize()
    baseInitialize(self)
    self.nutrientMist = GUIUtility_CreateRequestIcon(kTechId.NutrientMist,Vector(- 62, -36, 0),kAlienTeamType)
    self.resourceDisplay.background:AddChild(self.nutrientMist)
end

local baseUpdate = GUIAlienHUD.Update
function GUIAlienHUD:Update(deltaTime)
    baseUpdate(self,deltaTime)

    local player = Client.GetLocalPlayer()
    local nutrientMist = player.timeLastPrimaryRequestHandle ~= nil
    if nutrientMist then
        local color = kIconColors[kAlienTeamType]
        percentage = math.Clamp(1 - (player.timeLastPrimaryRequestHandle - Shared.GetTime())/kAutoMistCooldown,0,1)
        local mist = color * (percentage * percentage)
        mist.a = percentage >= 1 and 1 or 0.5
        percentage = percentage * percentage
        self.nutrientMist:SetColor(mist)
    end
    
    self.nutrientMist:SetIsVisible(nutrientMist)
end 
