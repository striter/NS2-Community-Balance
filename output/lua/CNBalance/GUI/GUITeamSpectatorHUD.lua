local timeWaveSpawnEnds = 0
local function OnSetTimeWaveSpawnEnds(message)
    timeWaveSpawnEnds = message.time
end
Client.HookNetworkMessage("SetTimeWaveSpawnEnds", OnSetTimeWaveSpawnEnds)

local function TeamUI_GetWaveSpawnTime()

    if timeWaveSpawnEnds > 0 then
        return timeWaveSpawnEnds - Shared.GetTime()
    end
    
    return 0
    
end

class 'GUITeamSpectatorHUD' (GUIScript)

local kFontScale
local kTextFontName = Fonts.kAgencyFB_Large
local kFontColor = Color(1, 1, 1, 1)

local kRespawnIconSize

local kPadding
local kRespawnIconTopOffset

local kNoEggsColor = Color(1, 0, 0, 1)
local kWhite = Color(1, 1, 1, 1)

local kRespawnIconTexture = "ui/respawnIcon.dds"

local kSpawnInOffset

local function UpdateItemsGUIScale(self)
    kFontScale = GetScaledVector()
    kRespawnIconSize = GUIScale(Vector(192, 96, 0) * 0.5)
    kPadding = GUIScale(32)
    kRespawnIconTopOffset = GUIScale(128)
    kSpawnInOffset = GUIScale(Vector(0, -125, 0))

    self.spawnText:SetPosition(kSpawnInOffset)
    self.spawnText:SetFontName(kTextFontName)
    self.spawnText:SetScale(kFontScale)
    GUIMakeFontScale(self.spawnText)
    
    self.respawnIcon:SetPosition(Vector(-kRespawnIconSize.x * 0.75 - kPadding * 0.5, kRespawnIconTopOffset, 0))
    self.respawnIcon:SetSize(kRespawnIconSize)
    
    self.respawnCount:SetScale(kFontScale)
    self.respawnCount:SetFontName(kTextFontName)
    GUIMakeFontScale(self.respawnCount)
    self.respawnCount:SetPosition(Vector(kPadding * 0.5, 0, 0))
end

function GUITeamSpectatorHUD:OnResolutionChanged(oldX, oldY, newX, newY)
    UpdateItemsGUIScale(self)
end

function GUITeamSpectatorHUD:Initialize()

    self.spawnText = GUIManager:CreateTextItem()
    self.spawnText:SetFontName(kTextFontName)
    self.spawnText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.spawnText:SetTextAlignmentX(GUIItem.Align_Center)
    self.spawnText:SetTextAlignmentY(GUIItem.Align_Center)
    self.spawnText:SetColor(kFontColor)
    
    self.respawnIcon = GUIManager:CreateGraphicItem()
    self.respawnIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.respawnIcon:SetTexture(kRespawnIconTexture)
    self.respawnIcon:SetIsVisible(false) -- to prevent 1-frame pop-in
    
    self.respawnCount = GUIManager:CreateTextItem()
    self.respawnCount:SetFontName(kTextFontName)
    self.respawnCount:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.respawnCount:SetTextAlignmentX(GUIItem.Align_Min)
    self.respawnCount:SetTextAlignmentY(GUIItem.Align_Center)
    self.respawnCount:SetColor(kFontColor)
    
    self.respawnIcon:AddChild(self.respawnCount)
    
    UpdateItemsGUIScale(self)
    
    self.visible = true
    
end

function GUITeamSpectatorHUD:SetIsVisible(state)
    
    self.visible = state
    self:Update(0)
    
end

function GUITeamSpectatorHUD:GetIsVisible()
    
    return self.visible
    
end

function GUITeamSpectatorHUD:Uninitialize()

    assert(self.spawnText)
    
    GUI.DestroyItem(self.spawnText)
    self.spawnText = nil
    
    GUI.DestroyItem(self.respawnIcon)
    self.respawnIcon = nil
    respawnCount = nil
    
end

function GUITeamSpectatorHUD:Update(deltaTime)

    PROFILE("GUITeamSpectatorHUD:Update")
    
    local waitingForTeamBalance = PlayerUI_GetIsWaitingForTeamBalance()

    local isVisible = self.visible and not waitingForTeamBalance and GetPlayerIsSpawning()
    self.spawnText:SetIsVisible(isVisible)
    self.respawnIcon:SetIsVisible(isVisible and not StatsUIVisible)
    
    if isVisible then
    
        local timeToWave = math.max(0, math.floor(TeamUI_GetWaveSpawnTime()))
        local teamType,respawnCount = PlayerUI_GetTeamRespawnInfo()
        
        local teamString = tostring(teamType)
        if timeToWave == 0 then
            self.spawnText:SetText(Locale.ResolveString("WAITING_SPAWN_TEAM"..teamString))
        else
            self.spawnText:SetText(string.format(Locale.ResolveString("NEXT_SPAWN_IN_TEAM"..teamString), ToString(timeToWave)))
        end
        
        
        self.respawnCount:SetText(string.format("x %s", ToString(respawnCount)))
        
        local hasRespawns = respawnCount > 0
        self.respawnCount:SetColor(hasRespawns and kWhite or kNoEggsColor)
        self.respawnIcon:SetColor(hasRespawns and kWhite or kNoEggsColor)
        self.respawnIcon:SetTexturePixelCoordinates(0,192*(teamType-1),384,192*(teamType))
        
    end
    
end