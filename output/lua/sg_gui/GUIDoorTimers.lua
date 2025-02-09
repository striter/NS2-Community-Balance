--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

class 'GUIDoorTimers' (GUIScript)

-- half of screen & one row
GUIDoorTimers.kBackgroundScale = Vector(460, 26, 0)
GUIDoorTimers.kDoorTimersFontName = Fonts.kArial_17

function GUIDoorTimers:OnResolutionChanged(oldX, oldY, newX, newY)
    self:Uninitialize()
    self:Initialize()
end

function GUIDoorTimers:Initialize()


    local backgroundSize = GUIScale(GUIDoorTimers.kBackgroundScale)

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(backgroundSize)
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.background:SetPosition( Vector( -backgroundSize.x / 2, GUIScale(3), 0) )
    self.background:SetIsVisible(false)
    self.background:SetColor(Color(0,0,0,0.5))
    self.background:SetLayer(kGUILayerLocationText)

    self.timers = GUIManager:CreateTextItem()
    self.timers:SetFontName(GUIDoorTimers.kDoorTimersFontName)
    self.timers:SetScale(GetScaledVector())
    GUIMakeFontScale(self.timers)
    self.timers:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.timers:SetTextAlignmentX(GUIItem.Align_Center)
    self.timers:SetTextAlignmentY(GUIItem.Align_Center)
    self.timers:SetColor(Color(1, 1, 1, 1))
    self.timers:SetText("TIMERS")
    self.background:AddChild(self.timers)

    self:Update(0)
end

function GUIDoorTimers:Uninitialize()

    if self.timers then
      GUI.DestroyItem(self.timers)
      self.timers = nil
    end

    if self.background then
      GUI.DestroyItem(self.background)
      self.background = nil
    end
end

function GUIDoorTimers:SetIsVisible(visible)
    --Shared.Message(debug.traceback())
end

local function FormatTimer(time, default)
    if time > 0 then
        local minutes = math.floor( time / 60 )
        local seconds = math.floor( time - minutes * 60 )
        return string.format("%d:%02d", minutes, seconds)
    end
    return default
end

function GUIDoorTimers:Update(deltaTime)
    local text = ""
    local visible = false
    local gameTime = PlayerUI_GetGameLengthTime()

    if PlayerUI_GetHasGameStarted() and (gameTime > 0) then
        local front, siege, suddendeath = GetGameInfoEntity():GetSiegeTimes()
        if front > 0 or siege > 0 then
            text = string.format(Locale.ResolveString("SG_DOOR_TIMER"),
                    FormatTimer(front, Locale.ResolveString("SG_DOOR_OPEN")), 
                    FormatTimer(siege, Locale.ResolveString("SG_DOOR_OPEN")))
        else
            text = string.format(Locale.ResolveString("SG_SUDDEN_DEATH"),
                FormatTimer(suddendeath, Locale.ResolveString("SG_SUDDEN_DEATH_ACTIVATED")))
                
            if (suddendeath <= 0) then
                local percentage = math.abs(math.sin(Shared.GetTime() * 3))
                self.timers:SetColor(LerpColor(Color(1, 1, 1, 1), Color(1, 0, 0, 1), percentage))
            end
        end
        self.timers:SetText(text)
        visible = true
    end

    self.background:SetIsVisible(visible)
    self.timers:SetIsVisible(visible)
end
