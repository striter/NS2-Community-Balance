-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\GUIMinimapFrame.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages displaying the minimap and the minimap background.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIMinimap.lua")

class 'GUIMinimapFrame' (GUIMinimap)

local desiredSpawnPosition
local isAlienRespawning = false
local isRespawning = false
local function OnSetIsRespawning(message)
    isRespawning = message.isRespawning
    isAlienRespawning = isRespawning and PlayerUI_GetTeamType() == kTeam2Index
end
Client.HookNetworkMessage("SetIsRespawning", OnSetIsRespawning)

function GetPlayerIsSpawning()
    return isRespawning
end

function GetDesiredSpawnPosition()
    return desiredSpawnPosition
end

GUIMinimapFrame.kModeMini = 0
GUIMinimapFrame.kModeBig = 1
GUIMinimapFrame.kModeZoom = 2

local kMapBackgroundXOffset
local kMapBackgroundYOffset

local kBigSizeScale = 3
local kZoomedBlipSizeScale = 1 -- 0.8
local kMiniBlipSizeScale = 0.5

local kMarineZoomedIconColor = Color(191 / 255, 226 / 255, 1, 1)

local kFrameTextureSize
local kMarineFrameTexture = PrecacheAsset("ui/marine_commander_textures.dds")
local kFramePixelCoords = { 466, 250 , 466 + 473, 250 + 354 }

local kBackgroundNoiseTexture = PrecacheAsset("ui/alien_commander_bg_smoke.dds")
local kSmokeyBackgroundSize

local kMarineIconsFileName = PrecacheAsset("ui/marine_minimap_blip.dds")

local function UpdateItemsGUIScale(self)
    self.chooseSpawnText:SetFontName(Fonts.kAgencyFB_Large)
    self.chooseSpawnText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.chooseSpawnText)
    self.chooseSpawnText:SetPosition(Vector(0, GUIScale(-128), 0))
    
    --self.spawnQueueText:SetFontName(Fonts.kAgencyFB_Small)
    --self.spawnQueueText:SetScale(GetScaledVector())
    --GUIMakeFontScale(self.spawnQueueText)
    --self.spawnQueueText:SetPosition(GUIScale(Vector(15, -4, 0)))
    
    kFrameTextureSize = GUIScale(Vector(473, 354, 0))
    kMapBackgroundXOffset = GUIScale(28)
    kMapBackgroundYOffset = GUIScale(28)
    
    self.minimapFrame:SetSize(kFrameTextureSize)
    self.minimapFrame:SetPosition(Vector(-kMapBackgroundXOffset, -kFrameTextureSize.y + kMapBackgroundYOffset, 0))
    
    kSmokeyBackgroundSize = GUIScale(Vector(480, 640, 0))
    self.smokeyBackground:SetSize(kSmokeyBackgroundSize)
    self.smokeyBackground:SetPosition(-kSmokeyBackgroundSize * .5)
    
    -- Cycling through modes resizes and respotions everything
    -- Not really elegant, but gets the job done
    local comMode = self.comMode or 0
    self:SetBackgroundMode(0, true)
    self:SetBackgroundMode(1, true)
    self:SetBackgroundMode(comMode, true)
end

function GUIMinimapFrame:Initialize()

    self.cachedHudDetail = Client.GetHudDetail()

    GUIMinimap.Initialize(self)
    
    self.updateInterval = kUpdateIntervalFull
    
    self.zoom = 1
    self.desiredZoom = 1
    
    self:InitSmokeyBackground()
    self:InitFrame()
    
    self.visible = true -- is it allowed to be visible?
    
    self.chooseSpawnText = GetGUIManager():CreateTextItem()
    self.chooseSpawnText:SetText(SubstituteBindStrings(Locale.ResolveString("CHOOSE_SPAWN")))
    self.chooseSpawnText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.chooseSpawnText:SetTextAlignmentX(GUIItem.Align_Center)
    self.chooseSpawnText:SetTextAlignmentY(GUIItem.Align_Max)
    self.chooseSpawnText:SetIsVisible(false)
    
    --self.spawnQueueText = GUIManager:CreateTextItem()
    --self.spawnQueueText:SetFontIsBold(true)
    --self.spawnQueueText:SetAnchor(GUIItem.Left, GUIItem.Top)
    --self.spawnQueueText:SetTextAlignmentX(GUIItem.Align_Min)
    --self.spawnQueueText:SetTextAlignmentY(GUIItem.Align_Center)
    --self.spawnQueueText:SetColor( Color(1,1,1,1) )
    --self.spawnQueueText:SetIsVisible(self.visible)
    --self.minimapFrame:AddChild( self.spawnQueueText )
    
    self.showingMouse = false
    self:UpdatePlayerMinimapVisible()

    UpdateItemsGUIScale(self)
end

function GUIMinimapFrame:Uninitialize()

    GUIMinimap.Uninitialize(self)
    
    if self.chooseSpawnText then
        GUI.DestroyItem(self.chooseSpawnText)
        self.chooseSpawnText = nil
    end
    
    --if self.spawnQueueText then
        --GUI.DestroyItem(self.spawnQueueText)
        --self.spawnQueueText = nil
    --end
    
    if self.showingMouse then
    
        MouseTracker_SetIsVisible(false)
        self.showingMouse = false
        
    end

end

function GUIMinimapFrame:InitFrame()

    self.minimapFrame = GUIManager:CreateGraphicItem()
    self.minimapFrame:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.minimapFrame:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", kMarineFrameTexture))
    self.minimapFrame:SetTexturePixelCoordinates(GUIUnpackCoords(kFramePixelCoords))
    self.minimapFrame:SetIsVisible(false)
    self.minimapFrame:SetLayer(-1)
    self.background:AddChild(self.minimapFrame)

end

function GUIMinimapFrame:InitSmokeyBackground()

    self.smokeyBackground = GUIManager:CreateGraphicItem()
    self.smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.smokeyBackground:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", "ui/alien_minimap_smkmask.dds"))
    self.smokeyBackground:SetShader("shaders/GUISmoke.surface_shader")
    self.smokeyBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.smokeyBackground:SetFloatParameter("correctionX", 1)
    self.smokeyBackground:SetFloatParameter("correctionY", 1.2)
    self.smokeyBackground:SetIsVisible(false)
    self.smokeyBackground:SetLayer(-1)
    
    self.background:AddChild(self.smokeyBackground)

end

function GUIMinimapFrame:SendKeyEvent(key, down)

    local handledInput = false
    local choosingSpawn = isAlienRespawning and self.background:GetIsVisible()

    -- TODO(Salads): "SetIsRespawning" network message only is sent on AlienSpectator, and there is duplicate input handling on Player_Client for Marines... (Infantry Portal for netmessage)
    if isAlienRespawning and GetIsBinding(key, "ShowMap") and not ChatUI_EnteringChatMessage() then
    
        if not down then
    
            local showMap = self.visible and not self.background:GetIsVisible()
            self:ShowMap(showMap)
            self:SetBackgroundMode(GUIMinimapFrame.kModeBig)
        
        end
        
        handledInput = true
    
    elseif choosingSpawn and key == InputKey.MouseButton0 then

        local mouseX, mouseY = Client.GetCursorPosScreen()
        local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
        if containsPoint then
        
            -- perform action only on key up, but also consume key down even, otherwise mouse0 is not being processed correctly
            if not down then
            
                local newDesiredPosition = MinimapToWorld(nil, withinX / self:GetMinimapSize().x, withinY / self:GetMinimapSize().y)
                
                if newDesiredPosition ~= desiredSpawnPosition then
                
                    desiredSpawnPosition = newDesiredPosition
                    Client.SendNetworkMessage("SetDesiredSpawnPoint", { desiredSpawnPoint = desiredSpawnPosition }, true)
                    
                end

            end
            
            handledInput = true
        
        end
    
    else

        local player = Client.GetLocalPlayer()
        local mapBindName = ConditionalValue(player and player:isa("Commander"), "ShowMapCom", "ShowMap")

        if GetIsBinding(key, mapBindName) and not ChatUI_EnteringChatMessage() and GUIMinimap.kToggleMap then

            local isOverheadView = player and (player:isa("Commander") or player:isa("Spectator"))
            local largeMapVisible = self:LargeMapIsVisible()

            if not down then

                self:ShowMap(not largeMapVisible or isOverheadView)

                -- Overhead view simply switches between "mini" and "big" modes.
                -- For marines, the GUIMarineHUD has an extra instance of the minimap that stays in "zoom" mode".
                if not isOverheadView then
                    self:SetBackgroundMode(GUIMinimapFrame.kModeBig)
                else
                    self:SetBackgroundMode(ConditionalValue(largeMapVisible, GUIMinimapFrame.kModeMini, GUIMinimapFrame.kModeBig))
                end

            end

            handledInput =  true

        elseif PlayerUI_IsOverhead() then

            local mouseX, mouseY = Client.GetCursorPosScreen()
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)

            if key == InputKey.MouseButton0 then
                self.mouseButton0Down = down
            elseif PlayerUI_IsACommander() and key == InputKey.MouseButton1 then

                if down and containsPoint then

                    if self.buttonsScript then

                        -- Cancel just in case the user had a targeted action selected before this press.
                        CommanderUI_ActionCancelled()
                        self.buttonsScript:SetTargetedButton(nil)

                    end

                    OverheadUI_MapClicked(withinX / self:GetMinimapSize().x, withinY / self:GetMinimapSize().y, 1, nil)
                    handledInput = true

                end

            end

        end

    end

    self:UpdatePlayerMinimapVisible()
    return handledInput

end

function GUIMinimapFrame:Update(deltaTime)

    PROFILE("GUIMinimapFrame:Update")
    
    local showMouse = self.visible and self.background:GetIsVisible() and isAlienRespawning
    if showMouse ~= self.showingMouse then
    
        MouseTracker_SetIsVisible(showMouse, "ui/Cursor_MenuDefault.dds", true)
        self.showingMouse = showMouse
        
    end

    self.chooseSpawnText:SetIsVisible(self.visible and (not self.background:GetIsVisible() and isAlienRespawning))
    
    self.minimapFrame:SetIsVisible(self.visible and (PlayerUI_GetTeamType() == kMarineTeamType and self.comMode == GUIMinimapFrame.kModeMini))
    self.smokeyBackground:SetIsVisible(self.visible and (PlayerUI_GetTeamType() == kAlienTeamType and self.comMode == GUIMinimapFrame.kModeMini))
    
    if PlayerUI_IsOverhead() and self.comMode ~= GUIMinimapFrame.kModeBig then
        
        if PlayerUI_IsACommander() then
            
            local teamInfo = GetTeamInfoEntity( PlayerUI_GetTeamNumber() )
            if teamInfo and PlayerUI_GetTeamNumber() == kTeam1Index then
                --self.spawnQueueText:SetColor( kMarineFontColor )
                --TODO Check number respawning and adjust color if above X threshold
                --self.spawnQueueText:SetText( string.format( Locale.ResolveString("MARINES_RESPAWNING"), teamInfo:GetSpawnQueueTotal() ) )
            end
            
            -- Commander always sees the minimap.
            if not PlayerUI_IsCameraAnimated() then
                self.background:SetIsVisible(self.visible)
            else
                self.background:SetIsVisible(false)
            end

        else
            self.background:SetIsVisible(self.visible)
        end

        self:UpdatePlayerMinimapVisible()

    end
    
    if self.comMode == GUIMinimapFrame.kModeZoom then
    
        if self.desiredZoom ~= self.zoom then
        
            local currSqrt = math.sqrt(self.zoom)
            local zoomSpeed = 0.8
            if self.zoom < self.desiredZoom then
            
                currSqrt = currSqrt + deltaTime*zoomSpeed
                self:SetZoom(Clamp(currSqrt*currSqrt, 0, self.desiredZoom))
                
            else
                currSqrt = currSqrt - deltaTime*zoomSpeed
                self:SetZoom(Clamp(currSqrt*currSqrt, self.desiredZoom, 1))
            end
            
        end
        
    end
    
    GUIMinimap.Update(self, deltaTime)

    local newHudDetail = Client.GetHudDetail()
    if self.cachedHudDetail ~= newHudDetail then

        self.cachedHudDetail = newHudDetail
        self.smokeyBackground:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", "ui/alien_minimap_smkmask.dds"))
        self.minimapFrame:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", kMarineFrameTexture))
    end

end

function GUIMinimapFrame:SetZoom(zoom)

    self.zoom = zoom
    self:SetScale(kBigSizeScale * zoom)
    self:SetBlipScale(zoom)
    
end

function GUIMinimapFrame:SetDesiredZoom(desiredZoom)
    self.desiredZoom = Clamp(desiredZoom, 0, 1)
end

function GUIMinimapFrame:GetDesiredZoom()
    return self.desiredZoom
end

function GUIMinimapFrame:SetBackgroundMode(setMode, forceReset)

    if self.comMode ~= setMode or forceReset then
        
        self.comMode = setMode
        local modeIsMini = self.comMode == GUIMinimapFrame.kModeMini
        local modeIsZoom = self.comMode == GUIMinimapFrame.kModeZoom

        if self.comMode == GUIMinimapFrame.kModeBig then
            self.background:SetLayer(kGUILayerBigMap)
        else
            self.background:SetLayer(kGUILayerMinimap)
        end

        -- Special settings for zoom mode
        self:SetMoveBackgroundEnabled(modeIsZoom)
        local playerArrowColor = GetAdvancedOption("minimaparrowcolor")

        if modeIsZoom then
            
            self:SetStencilFunc(GUIItem.NotEqual)
            self:SetPlayerIconColor(Color(playerArrowColor))
            self:SetIconFileName(kMarineIconsFileName)
        else
            self:SetStencilFunc(GUIItem.Always)
            self:SetPlayerIconColor(Color(playerArrowColor))
            self:SetIconFileName(nil)
        end
        
        --
        self:SetLocationNamesEnabled(not modeIsMini and not modeIsZoom)

        -- We want the background to sit "inside" the border so move it up and to the right a bit.
        --local borderExtraWidth = ConditionalValue(self.background, GUIMinimapFrame.kBackgroundWidth - self:GetMinimapSize().x, 0)
        --local borderExtraHeight = ConditionalValue(self.background, GUIMinimapFrame.kBackgroundHeight - self:GetMinimapSize().y, 0)
        --local defaultPosition = Vector(borderExtraWidth / 2, borderExtraHeight / 2, 0)
        --local modePosition = ConditionalValue(modeIsMini, defaultPosition, Vector(0, 0, 0))
        --self.minimap:SetPosition(modePosition * self.zoom)
        
        if modeIsMini then
            self:SetScale(1)
            self:SetBlipScale(kMiniBlipSizeScale)
            self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
            self.background:SetPosition(Vector(kMapBackgroundXOffset, -GUIMinimap.kBackgroundHeight - kMapBackgroundYOffset, 0))
            self.background:SetSize(Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0))
            self.minimap:SetAnchor(GUIItem.Left, GUIItem.Top)
            self.minimap:SetPosition(Vector(0, 0, 0))
        elseif modeIsZoom then
            self:SetScale(kBigSizeScale * self.zoom)
            self:SetBlipScale(kZoomedBlipSizeScale)
            self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
            local scale = Client.GetScreenHeight() / kBaseScreenHeight
            self.background:SetSize(Vector(190 * (scale * 2), 180 * (scale * 2), 0)) -- don't ask.. the minimap placement in GUIMarineHud.lua needs some clean up
            self.minimap:SetAnchor(GUIItem.Middle, GUIItem.Center)
            self.minimap:SetPosition(Vector(0, 0, 0))
            
        else
            self:InitializeLocationNames()
            self:SetScale(kBigSizeScale)
            -- Very low resolutions sometimes can't fit the big map, reduce scale a bit
            if self:GetMinimapSize().y > Client.GetScreenHeight() then
                self:SetScale(kBigSizeScale * 0.75)
            end
            self:SetBlipScale(1)
            
            self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
            self.background:SetSize( Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0) )
            self.background:SetPosition(Vector(0, 0, 0))
            
            self.minimap:SetAnchor(GUIItem.Middle, GUIItem.Center)
            local modeSize = self:GetMinimapSize()
            self.minimap:SetPosition(modeSize * -0.5)

        end
        
        -- Make sure everything is in sync in case this function is called after GUIMinimapFrame:Update() is called.
        self:Update(0)

        self:UpdatePlayerMinimapVisible()
    
    end
    
end

function GUIMinimapFrame:OnResolutionChanged(oldX, oldY, newX, newY)

    GUIMinimap.OnResolutionChanged(self, oldX, oldY, newX, newY)

    if self.comMode == GUIMinimapFrame.kModeZoom then
        local scale = newY / kBaseScreenHeight
        self.background:SetSize(Vector(190 * (scale * 2), 180 * (scale * 2), 0)) -- don't ask.. the minimap placement in GUIMarineHud.lua needs some clean up
    elseif self.comMode == GUIMinimapFrame.kModeBig then
        self.background:SetSize(Vector(newX, newY, 0) )
    end
    
    UpdateItemsGUIScale(self)
end
