
local kCommanderIcons = PrecacheAsset("ui/alien_hivestatus_commicons.dds")
local function ResetTeamCountIcon(element)
    element.count = 0
    element:SetColor(GUIMarineHUD.kCountNoUsed)
    element.text:SetIsVisible(false)
end

local kTechIdToIndex = {
    [kTechId.Skulk] = 5,
    [kTechId.Gorge] = 4,
    [kTechId.Prowler] = 6,
    [kTechId.Lerk] = 3,
    [kTechId.Fade] = 2,
    [kTechId.Vokex] = 7,
    [kTechId.Onos] = 1,
}

local function CreateTeamCountElement(techID)
    local teamCountIcon = GetGUIManager():CreateGraphicItem()
    if PlayerUI_GetTeamType() == kMarineTeamType  then
        teamCountIcon:SetTexture(kInventoryIconsTexture)
        teamCountIcon:SetTexturePixelCoordinates(GetTexCoordsForTechId(techID))
        teamCountIcon:SetSize(GUIMarineHUD.kTeamIconSize)
    else
        local iconIndex = kTechIdToIndex[techID]
        teamCountIcon:SetTexture(kCommanderIcons)
        teamCountIcon:SetTexturePixelCoordinates(( iconIndex - 1)* 72 ,0 ,iconIndex * 72 ,68)
        teamCountIcon:SetSize(GUIScale( Vector( 35, 32, 0 ) ))
    end
    teamCountIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamCountIcon:SetColor(GUIMarineHUD.kBackgroundColor)

    local countText = GUIManager:CreateTextItem()
    countText:SetPosition(Vector( -9 , -12, 0 ) )
    countText:SetAnchor( GUIItem.Right, GUIItem.Bottom )
    countText:SetFontName( Fonts.kAgencyFB_Large_Bold )
    countText:SetColor( PlayerUI_GetTeamType() == kMarineTeamType and kMarineTeamColorFloat or kAlienTeamColorFloat)
    countText:SetScale(  GUIScale( Vector(1,1,0) * 0.4725 ))  --Scaled???
    countText:SetLayer( kGUILayerPlayerHUDForeground2 )
    teamCountIcon:AddChild(countText)

    teamCountIcon.text = countText
    teamCountIcon.techId = techID

    ResetTeamCountIcon(teamCountIcon)
    return teamCountIcon
end

GUICommanderButtons.kAlienTechIdToNetworkVar = {
    [kTechId.Skulk] = "teamSkulkCount",
    [kTechId.Gorge] = "teamGorgeCount",
    [kTechId.Prowler] = "teamProwlerCount",
    [kTechId.Vokex] = "teamVokexCount",
    [kTechId.Lerk] = "teamLerkCount",
    [kTechId.Fade] = "teamFadeCount",
    [kTechId.Onos] = "teamOnosCount",
}

local function UpdateTeamCount(self, _teamInfo, _element)
    local netVarName = nil
    if PlayerUI_GetTeamType() == kMarineTeamType then
        local techMapName = GUIMarineBuyMenu._GetMapNameForNetvar(nil, _element.techId)       --???
        assert(techMapName)
        netVarName = TeamInfo_GetUserTrackerNetvarName(techMapName)
    else
        netVarName = GUICommanderButtons.kAlienTechIdToNetworkVar[_element.techId]
    end

    assert(netVarName)
    local count = _teamInfo[netVarName]
    if _element.count ~= count then
        _element.count = count
        _element.text:SetText(string.format("x%i", _element.count))
        if PlayerUI_GetTeamType() == kMarineTeamType then
            _element:SetColor(numUsers ~= 0 and GUIMarineHUD.kCountHaveUser or GUIMarineHUD.kCountNoUsed)
        else
            _element:SetColor(numUsers ~= 0 and GUIHiveStatus.kTeamCountIconColor or GUIHiveStatus.kTeamCountZeroedIconColor)
        end
        _element.text:SetIsVisible(count > 1)
    end
end

local baseInitialize = GUICommanderButtons.Initialize
function GUICommanderButtons:Initialize()
    baseInitialize(self)
    self.teamCountElements = {}
    if PlayerUI_GetTeamType() == kMarineTeamType then
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Shotgun))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.HeavyMachineGun))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.GrenadeLauncher))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Flamethrower))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Cannon))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.DualRailgunExosuit))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.DualMinigunExosuit))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Jetpack))

    else
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Skulk))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Gorge))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Prowler))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Lerk))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Fade))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Vokex))
        table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Onos))
    end

    local text = GUIManager:CreateTextItem()
    text:SetAnchor( GUIItem.Top, GUIItem.Left )
    text:SetFontName( Fonts.kAgencyFB_Large_Bold )
    text:SetColor(  PlayerUI_GetTeamType() == kMarineTeamType and kMarineTeamColorFloat or kAlienTeamColorFloat)
    text:SetScale(  GUIScale( Vector(1,1,0) * 0.4725 ))  --Scaled???
    text:SetPosition( PlayerUI_GetTeamType() == kMarineTeamType and Vector( 25 , 60, 0 ) or Vector(25,210,0))
    self.text = text
    
    for index,element in ipairs(self.teamCountElements) do
        local offset = index - 1
        local gap = PlayerUI_GetTeamType() == kMarineTeamType and 48 or 35
        element:SetPosition(Vector(25 + offset * gap,30,0))
    end
end 

local baseUninitialize = GUICommanderButtons.Uninitialize
function GUICommanderButtons:Uninitialize()
    if self.teamCountElements then
        for k,v in pairs(self.teamCountElements) do
            GUI.DestroyItem(v)
        end
    end
    self.teamCountElements = nil

    if self.text then
        GUI.DestroyItem(self.text)
    end
    self.text = nil
    baseUninitialize(self)
    
end


local baseReset = GUICommanderButtons.Reset
function GUICommanderButtons:Reset()
    baseReset(self)
    for _,element in ipairs(self.teamCountElements) do
        ResetTeamCountIcon(element)
    end
end

local kErrorColor = Color(1, 0, 0, 1)
local baseUpdate = GUICommanderButtons.Update
function GUICommanderButtons:Update(deltaTime)
    baseUpdate(self,deltaTime)
    local player = Client.GetLocalPlayer()
    local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
    if teamInfo then
        for _,element in ipairs(self.teamCountElements) do
            UpdateTeamCount(self,teamInfo,element)
        end
    end
    self.text:SetText(PlayerUI_GetGameTimeString())
    self.text:SetColor(PlayerUI_DeadlockActivated() and kErrorColor or (PlayerUI_GetTeamType() == kMarineTeamType and kMarineTeamColorFloat or kAlienTeamColorFloat))
end