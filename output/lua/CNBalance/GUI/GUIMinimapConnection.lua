-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIMinimapConnection.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Used for rendering connections on the minimap.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIMinimapConnection'

GUIMinimapConnection.kLineMode = GetAdvancedOption("pglines")

local kLineTexture = PrecacheAsset("ui/mapconnector_line.dds")
local kDashedLineTexture = PrecacheAsset("ui/mapconnector_dashed.dds")
local kLineTextureCoord = {0, 0, 64, 16}

function GUIMinimapConnection:CheckLineTexture()

    self.lineTexture = ConditionalValue(GUIMinimapConnection.kLineMode == 2, kDashedLineTexture, kLineTexture)

    if self.line then
        self.line:SetTexture(self.lineTexture)
    end

end

function GUIMinimapConnection:UpdateAnimation(teamNumber, modeIsMini)
    if not self.isVisible then return end

    local animatedArrows = not modeIsMini and teamNumber == kTeam1Index and #GetEntitiesForTeam("MapConnector", kTeam1Index) > 2
    local animation = ConditionalValue(animatedArrows and GUIMinimapConnection.kLineMode > 1, (Shared.GetTime() % 1) / 1, 0)
                
    local x1Coord = kLineTextureCoord[1] - animation * (kLineTextureCoord[3] - kLineTextureCoord[1])
    local x2Coord = x1Coord + (self.length or 0)

    -- Don't draw arrows for just 2 PGs, the direction is clear here
    -- Gorge tunnels also don't need this since it is limited to entrance/exit
    local textureIndex = ConditionalValue(animatedArrows and GUIMinimapConnection.kLineMode > 0, 16, 0)
    
    self.line:SetTexturePixelCoordinates(x1Coord, textureIndex, x2Coord, textureIndex + 16)
    self.line:SetColor(ConditionalValue(teamNumber == kTeam1Index, kMarineFontColor, kAlienFontColor))
    self.line:SetSize(Vector(self.length, GUIScale(ConditionalValue(modeIsMini, 6, 10)), 0))

end

local kTunnelColor1=Color(123)
local kTunnelColor2=Color(123)
local kTunnelColor3=Color(123)
local kTunnelColor4=Color(123)
local kTunnelColor5=Color(123)
local kTunnelColor6=Color(123)
local kTunnelColor7=Color(123)
local kTunnelColor8=Color(123)
local tunnelColorTable = {kTunnelColor1, kTunnelColor2, kTunnelColor3, kTunnelColor4, kTunnelColor5, kTunnelColor6, kTunnelColor7, kTunnelColor8}

local function getLineColor(tunnelIndex)
    return tunnelColorTable[tunnelIndex]
end

function GUIMinimapConnection:UpdateAnimation_Alien(modeIsMini, tunnelIndex)
    if not self.isVisible then return end
                
    local x1Coord = kLineTextureCoord[1] - 0
    local x2Coord = x1Coord + (self.length or 0)

    -- Don't draw arrows for just 2 PGs, the direction is clear here
    -- Gorge tunnels also don't need this since it is limited to entrance/exit
    local textureIndex = 0
    
    self.line:SetTexturePixelCoordinates(x1Coord, textureIndex, x2Coord, textureIndex + 16)
    local calcedTunnelIndex = tunnelIndex % 8
    self.line:SetColor(getLineColor(calcedTunnelIndex))
    self.line:SetSize(Vector(self.length, GUIScale(ConditionalValue(modeIsMini, 6, 10)), 0))
end



function GUIMinimapConnection:Setup(startPoint, endPoint, parent)

    assert(startPoint:isa("Vector"))
    assert(endPoint:isa("Vector"))
    assert(parent)

    self.lineTexture = ConditionalValue(GUIMinimapConnection.kLineMode == 2, kDashedLineTexture, kLineTexture)
    
    if startPoint ~= self.startPoint or endPoint ~= self.endPoint or self.parent ~= parent then
    
        -- Since we're using a texture we need to move the points up a bit so it gets aligned properly
        startPoint = startPoint - (Vector(0,4,0))
        endPoint = endPoint - (Vector(0,4,0))

        local direction = GetNormalizedVector(startPoint - endPoint)
        local rotation = math.atan2(direction.x, direction.y)
        if rotation < 0 then
            rotation = rotation + math.pi * 2
        end

        rotation = rotation + math.pi * 0.5

        self.startPoint = Vector(startPoint)
        self.endPoint = Vector(endPoint)
        self.parent = parent
        self.rotationVec = Vector(0, 0, rotation)
        
        local delta = self.endPoint - self.startPoint
        self.length = math.sqrt(delta.x ^ 2 + delta.y ^ 2)

        self:SetIsVisible(true)
        
        self:Render()
    
    end

end

function GUIMinimapConnection:SetStencilFunc(func)

    if self.line then
        self.line:SetStencilFunc(func)
    end
    
    self.stencilFunc = func
    
end

function GUIMinimapConnection:Uninitialize()

    if self.line then
        GUI.DestroyItem(self.line)
        self.line = nil
    end

end

function GUIMinimapConnection:Render()

    if not self.line then

        self.lineTexture = ConditionalValue(GUIMinimapConnection.kLineMode == 2, kDashedLineTexture, kLineTexture)

        self.line = GUI.CreateItem()
        self.line:SetTexture(self.lineTexture)
        self.line:SetAnchor(GUIItem.Middle, GUIItem.Center)
        self.line:SetStencilFunc(self.stencilFunc)
        
        if self.parent then
            self.parent:AddChild(self.line)
        end
        
    end
    
    self.line:SetSize(Vector(self.length, GUIScale(10), 0))
    self.line:SetPosition(self.startPoint)
    self.line:SetRotationOffset(Vector(-self.length, 0, 0))
    self.line:SetRotation(self.rotationVec)
    
    -- update line parent
    local currentParent = self.line:GetParent()
    if currentParent and currentParent ~= self.parent then
    
        currentParent:RemoveChild(self.line)
        
        if self.parent then
            self.parent:AddChild(self.line)
        end
        
    end

end

function GUIMinimapConnection:SetIsVisible(isVisible)
    if self.line then
        self.line:SetIsVisible(isVisible)
    end

    self.isVisible = isVisible
end
