--________________________________
--
--  NS2: Combat
--    Copyright 2014 Faultline Games Ltd.
--  and Unknown Worlds Entertainment Inc.
--
--_______________________________

class 'GUIDevour' (GUIAnimatedScript)

GUIDevour.kDevourTexture = "ui/devour/fetal_skeleton.dds"
GUIDevour.kFont = Fonts.kAgencyFB_Small

GUIDevour.kBackgroundWidth = GUIScale(50)
GUIDevour.kBackgroundHeight = GUIScale(89)
GUIDevour.kBackgroundOffsetX = GUIScale(40)
GUIDevour.kBackgroundOffsetY =  GUIScale(-325)

GUIDevour.kSkeletonTexCoords = {0, 0, 71, 127}
GUIDevour.kBodyTexCoordsX = 71
GUIDevour.kBodyTexCoordsY = 127
GUIDevour.kBodyTextureBuckets = 9


GUIDevour.kBackgroundColor = Color(0, 0, 0, 0.5)

function GUIDevour:Initialize()    
    
	GUIAnimatedScript.Initialize(self)
	
	-- background
	self.devourBackground = self:CreateAnimatedGraphicItem()
	self.devourBackground:SetIsScaling(false)
    self.devourBackground:SetSize( Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0) )
    self.devourBackground:SetPosition( Vector(0, 0, 0) ) 
    self.devourBackground:SetIsVisible(false)
    self.devourBackground:SetLayer(kGUILayerPlayerHUDBackground)
    self.devourBackground:SetColor( Color(1, 1, 1, 0) )
	
    -- devour skeleton 
    self.devourSkeleton = self:CreateAnimatedGraphicItem()
    self.devourSkeleton:SetSize( Vector(GUIDevour.kBackgroundWidth, GUIDevour.kBackgroundHeight, 0) )
    self.devourSkeleton:SetPosition(Vector(GUIDevour.kBackgroundOffsetX, GUIDevour.kBackgroundOffsetY, 0))
    self.devourSkeleton:SetAnchor(GUIItem.Left, GUIItem.Bottom) 
    self.devourSkeleton:SetLayer(kGUILayerPlayerHUD)
    self.devourSkeleton:SetTexture(GUIDevour.kDevourTexture)
    self.devourSkeleton:SetTexturePixelCoordinates(unpack(GUIDevour.kSkeletonTexCoords))
    self.devourSkeleton:SetIsVisible(true)
	self.devourBackground:AddChild(self.devourSkeleton)
	
	-- devour full - this slowly dissolves to reveal the skeleton
	self.devourBody = self:CreateAnimatedGraphicItem()
    self.devourBody:SetSize( Vector(GUIDevour.kBackgroundWidth, GUIDevour.kBackgroundHeight, 0) )
    self.devourBody:SetPosition(Vector(GUIDevour.kBackgroundOffsetX, GUIDevour.kBackgroundOffsetY, 0))
    self.devourBody:SetAnchor(GUIItem.Left, GUIItem.Bottom) 
    self.devourBody:SetLayer(kGUILayerPlayerHUDForeground1)
    self.devourBody:SetTexture(GUIDevour.kDevourTexture)
    self.devourBody:SetTexturePixelCoordinates(unpack(GUIDevour.kSkeletonTexCoords))
    self.devourBody:SetIsVisible(true)
	self.devourBackground:AddChild(self.devourBody)
    
    self:Update(0)

end

function GUIDevour:UpdateDevourIcon(devourFraction)

	-- The skeleton is the first one, so start at the next one along.
	local x1Coord = GUIDevour.kBodyTexCoordsX + GUIDevour.kBodyTexCoordsX * math.floor(devourFraction * GUIDevour.kBodyTextureBuckets)
	local x2Coord = x1Coord + GUIDevour.kBodyTexCoordsX
	local texCoords = { x1Coord, 0, x2Coord, GUIDevour.kBodyTexCoordsY }
	self.devourBody:SetTexturePixelCoordinates(unpack(texCoords))
    
end


function GUIDevour:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    local devour = nil
	local devourScalar = 0

    if player and player:GetIsAlive() then 
		if player:isa("Onos") then
			local abilities = GetChildEntities(player, "Devour")
			if #abilities > 0 then
				devour = abilities[1]
			end
			if devour then
				devourScalar = devour:GetDevourScalar()
			end
			
			if devourScalar ~= 0 then
				self.devourBackground:SetIsVisible(true)
				self:UpdateDevourIcon(devourScalar)
			else
				self.devourBackground:SetIsVisible(false)
			end
		elseif player:isa("DevouredPlayer") then
			self.devourBackground:SetIsVisible(true)
			self:UpdateDevourIcon(player:GetDevourScalar())	
		else
			self.devourBackground:SetIsVisible(false)
		end
    else
        self.devourBackground:SetIsVisible(false)
    end

end