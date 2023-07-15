
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
    local nutrientMist = player.canNutrientMist~=nil and player.canNutrientMist or false
    self.nutrientMist:SetIsVisible(nutrientMist)
end 
