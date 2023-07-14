GUIMarineHUD.kTeamCountIconStart = Vector(25, 30, 0)
GUIMarineHUD.kMinimapPowerPos = Vector(25, 30 + 32, 0)
GUIMarineHUD.kLocationTextOffset = Vector(75, 30 + 32, 0)
GUIMarineHUD.kMinimapPos = Vector(30, 64 + 32, 0)

GUIMarineHUD.kUpgradeSize = Vector(80, 80, 0)

GUIMarineHUD.kTeamIconSize =  GUIScale( Vector( 48, 24, 0 ) )
GUIMarineHUD.kCountNoUsed = Color(0.3 , 0.3 , 0.3 , 1)
GUIMarineHUD.kCountHaveUser = Color(0x01 / 0xFF, 0x8F / 0xFF, 0xFF / 0xFF, 1)

local function ResetTeamCountIcon(element)
    element.count = 0
    element:SetColor(GUIMarineHUD.kCountNoUsed)
    element.text:SetIsVisible(false)
end

local function CreateTeamCountElement(techID)
    local teamCountIcon = GetGUIManager():CreateGraphicItem()
    teamCountIcon:SetSize(GUIMarineHUD.kTeamIconSize)
    teamCountIcon:SetTexture(kInventoryIconsTexture)
    teamCountIcon:SetTexturePixelCoordinates(GetTexCoordsForTechId(techID))
    teamCountIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamCountIcon:SetColor(GUIMarineHUD.kBackgroundColor)

    local countText = GUIManager:CreateTextItem()
    countText:SetPosition(Vector( -9 , -12, 0 ) )
    countText:SetAnchor( GUIItem.Right, GUIItem.Bottom )
    countText:SetFontName( Fonts.kAgencyFB_Large_Bold )
    countText:SetColor( GUIMarineHUD.kBackgroundColor )
    countText:SetScale(  GUIScale( Vector(1,1,0) * 0.4725 ))  --Scaled???
    countText:SetLayer( kGUILayerPlayerHUDForeground2 )
    teamCountIcon:AddChild(countText)

    teamCountIcon.text = countText
    teamCountIcon.techId = techID
    
    ResetTeamCountIcon(teamCountIcon)
    return teamCountIcon
end


local function UpdateTeamCount(self,teamInfo,element)
    local techMapName = GUIMarineBuyMenu._GetMapNameForNetvar(nil,element.techId)       --???
    assert(techMapName)
    if  techMapName then
        local netVarName = TeamInfo_GetUserTrackerNetvarName(techMapName)
        local numUsers = teamInfo[netVarName]
        if element.count ~= numUsers then
            element.count = numUsers
            element.text:SetText(string.format("x%i",element.count))
            
            element:SetColor(numUsers ~= 0 and self.kCountHaveUser or self.kCountNoUsed)
            element.text:SetIsVisible(numUsers > 1)
        end
    end
end

local function CreateTechIcon( techId)
    local techIcon = GetGUIManager():CreateGraphicItem()
    techIcon:SetTexture(GUIMarineHUD.kUpgradesTexture)
    techIcon:SetAnchor(GUIItem.Right, GUIItem.Center)
    techIcon:SetIsVisible(false)
    techIcon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(techId)))
    techIcon:SetColor(kIconColors[kMarineTeamType])
    return techIcon
end

local function CreateRequestIcon(techId, position)
    local techIcon = GetGUIManager():CreateGraphicItem()
    techIcon:SetTexture(GUIMarineHUD.kUpgradesTexture)
    techIcon:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    techIcon:SetSize(GUIMarineHUD.kUpgradeSize/2)
    techIcon:SetIsVisible(false)
    techIcon:SetPosition(position)
    techIcon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(techId)))
    techIcon:SetColor(kIconColors[kMarineTeamType])
    return techIcon
end

local baseInitialize = GUIMarineHUD.Initialize
function GUIMarineHUD:Initialize()
    
    self.militaryProtocol = CreateTechIcon(kTechId.MilitaryProtocol)
    local midCenter = GUIPlayerResource.kBackgroundPos + Vector(GUIPlayerResource.kBackgroundSize.x/2,0,0)
    self.autoMedPack = CreateRequestIcon(kTechId.MedPack,midCenter + Vector(-52 - 32, -36, 0))
    self.autoAmmoPack = CreateRequestIcon(kTechId.AmmoPack,midCenter + Vector(52 - 32, -36, 0))

    self.lastMilitaryProtocol = nil
    
    self.teamCountElements = {}
    table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Shotgun))
    table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.HeavyMachineGun))
    table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.GrenadeLauncher))
    table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Flamethrower))
    table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.Jetpack))
    table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.DualRailgunExosuit))
    table.insert(self.teamCountElements,CreateTeamCountElement(kTechId.DualMinigunExosuit))
    baseInitialize(self)

    self.background:AddChild(self.militaryProtocol)
    self.background:AddChild(self.autoMedPack)
    self.background:AddChild(self.autoAmmoPack)
    --........ or i should totally rewrite initialize
    for index,element in ipairs(self.teamCountElements) do
        --Vector(25, 46, 0)
        local offset = index - 1
        element:SetPosition(GUIMarineHUD.kTeamCountIconStart + Vector(offset * 50, offset * 2,0))
        self.background:AddChild(element)
    end
end

local baseReset = GUIMarineHUD.Reset
function GUIMarineHUD:Reset()
    baseReset(self)
    self.militaryProtocol:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y - GUIMarineHUD.kUpgradeSize.y - 8, 0) * self.scale)
    self.militaryProtocol:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.militaryProtocol:SetIsVisible(false)
    
    local marineHudBars = GetAdvancedOption("hudbars_m")
    if marineHudBars > 0 then
        if marineHudBars == 2 then
            local pos = self.militaryProtocol:GetPosition()
            self.militaryProtocol:SetPosition(Vector(pos.x, pos.y-100, 0))
        end
    end

    for _,element in ipairs(self.teamCountElements) do
        ResetTeamCountIcon(element)
    end
end

local baseUpdate = GUIMarineHUD.Update
function GUIMarineHUD:Update(deltaTime)
    baseUpdate(self,deltaTime)
    local player = Client.GetLocalPlayer()
    local hasMilitaryProtocol = GetHasTech(player,kTechId.MilitaryProtocol)
    if hasMilitaryProtocol ~= self.lastMilitaryProtocol then
        self.lastMilitaryProtocol = hasMilitaryProtocol
        self.militaryProtocol:SetIsVisible(self.lastMilitaryProtocol)
    end

    local autoMed = player.timeLastAutoMedPack and not hasMilitaryProtocol or false
    if autoMed then
        local time = Shared.GetTime()
        local color = kIconColors[kMarineTeamType]
        local percentage = math.Clamp((time - player.timeLastAutoMedPack)/kAutoMedCooldown,0,1)
        local medColor = color * (percentage * percentage)
        medColor.a = percentage >= 1 and 1 or 0.5
        self.autoMedPack:SetColor(medColor)

        percentage = math.Clamp((time - player.timeLastAutoAmmoPack)/kAutoAmmoCooldown,0,1)
        local ammoColor = color * (percentage * percentage)
        ammoColor.a = percentage >= 1 and 1 or 0.5
        percentage = percentage * percentage
        self.autoAmmoPack:SetColor(ammoColor)
    end

    self.autoAmmoPack:SetIsVisible(autoMed)
    self.autoMedPack:SetIsVisible(autoMed)
    
    local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
    if teamInfo then
        for _,element in ipairs(self.teamCountElements) do
            UpdateTeamCount(self,teamInfo,element)
        end
    end

end