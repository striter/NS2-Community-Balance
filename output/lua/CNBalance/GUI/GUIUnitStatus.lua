
-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIUnitStatus.lua
--
-- Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- Manages the blips that are displayed on the HUD, indicating status of nearby units.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Badges_Shared.lua")

class 'GUIUnitStatus' (GUIAnimatedScript)

GUIUnitStatus.kProgressFontName = Fonts.kArial_15
GUIUnitStatus.kFontName = Fonts.kAgencyFB_Small
GUIUnitStatus.kActionFontName = Fonts.kAgencyFB_Small

GUIUnitStatus.kAlphaPerSecond = 0.8
GUIUnitStatus.kImpulseIntervall = 2.5
GUIUnitStatus.kMaxUnitStatusDistance = 13
GUIUnitStatus.kMaxMarkedUnitStatusDistance = 20

local kMaxUnitStatusDistanceSq = GUIUnitStatus.kMaxUnitStatusDistance * GUIUnitStatus.kMaxUnitStatusDistance

GUIUnitStatus.kUseColoredWrench = GetAdvancedOption("wrenchicon") == 1
GUIUnitStatus.kUseSmallNameplates = GetAdvancedOption("smallnps")

GUIUnitStatus.kBlackTexture = "ui/black_dot.dds"

local kStatusBgTexture = { [kMarineTeamType] = "ui/unitstatus_marine.dds", [kAlienTeamType] = "ui/unitstatus_alien.dds", [kNeutralTeamType] = "ui/unitstatus_neutral.dds" }
local kStatusFontColor = { [kMarineTeamType] = Color(kMarineTeamColorFloat), [kAlienTeamType] = Color(kAlienTeamColorFloat), [kNeutralTeamType] = Color(1,1,1,1) }

local kStatusBgSizeUnscaled = Vector(168, 80, 0)

GUIUnitStatus.kStatusBackgroundPixelCoords = { 259, 896 , 259 + 174, 896 + 53}

GUIUnitStatus.kUnpoweredColor = Color(1,0.2,0.2,1)
GUIUnitStatus.kEnemyColor = Color(1,0.3,0.3,1)

GUIUnitStatus.kUnitStatusBarTexCoords = { 256, 0, 256 + 512, 64 }
GUIUnitStatus.kProgressingIconCoords = { 256, 68, 256 + 128, 68 + 128 }

GUIUnitStatus.kRotationDuration = 8
GUIUnitStatus.kResearchRotationDuration = 2

local kHealthBarWidth
local kHealthBarHeight

local kArmorBarWidth
local kArmorBarHeight

local kNameDefaultPos
local kActionDefaultPos

local kAmmoBarColors =
{
    [kTechId.Rifle] = Color(0,1,1,1),            -- teal
    [kTechId.Shotgun] = Color(0,1,0,1),          -- green
    [kTechId.Flamethrower] = Color(1,1,0,1),     -- yellow
    [kTechId.GrenadeLauncher] = Color(1,0,1,1),  -- magenta
    [kTechId.HeavyMachineGun] = Color(0.9,0,0,1),  -- red
}

local kAbilityBarColor = Color(0.65, 0.65, 0.65, 1)

local function GetUnitStatusTextureCoordinates(unitStatus)

    local x1 = 0
    local x2 = 256

    local y1 = (unitStatus - 1) * 256
    local y2 = unitStatus * 256

    return x1, y1, x2, y2

end

local function DestroyActiveBlips(self)

    for _, blip in ipairs(self.activeBlipList) do
        GUI.DestroyItem(blip.statusBg)
        blip.GraphicsItem:Destroy()
    end

    self.activeBlipList = { }

end

local function UpdateItemsGUIScale()
    local oldGUIScale = GUIScale
    local function GUIScale(v) return oldGUIScale(v) * 0.9 end

    GUIUnitStatus.kUnitStatusSize = GUIScale(Vector(60, 60, 0))

    GUIUnitStatus.kBadgeSize = GUIScale(Vector(18, 18, 0))
    GUIUnitStatus.kBadgesYOffset = GUIScale(68)

    GUIUnitStatus.kStatusBgSize = GUIScale( kStatusBgSizeUnscaled )
    GUIUnitStatus.kStatusBgNoHintSize = GUIScale( Vector(168, 66, 0) )

    GUIUnitStatus.kStatusBgOffset = GUIScale( Vector(0, -16, 0) )

    if GUIUnitStatus.kUseSmallNameplates then
        GUIUnitStatus.kFontScale = GUIScale( Vector(1,1,1) ) * 0.8
        GUIUnitStatus.kActionFontScale = GUIScale( Vector(1,1,1) ) * 0.7
        GUIUnitStatus.kFontScaleProgress = GUIScale( Vector(1,1,1) ) * 0.6
        GUIUnitStatus.kFontScaleSmall = GUIScale( Vector(1,1,1) ) * 0.65
    else
        GUIUnitStatus.kFontScale = GUIScale( Vector(1,1,1) ) * 1.2
        GUIUnitStatus.kActionFontScale = GUIScale( Vector(1,1,1) )
        GUIUnitStatus.kFontScaleProgress = GUIScale( Vector(1,1,1) ) * 0.8
        GUIUnitStatus.kFontScaleSmall = GUIScale( Vector(1,1,1) ) * 0.9
    end


    GUIUnitStatus.kUnitStatusBarWidth = GUIScale(512) * 0.4
    GUIUnitStatus.kUnitStatusBarHeight = GUIScale(48) * 0.4
    GUIUnitStatus.kBarYOffset = GUIScale(-40)

    GUIUnitStatus.kProgressingIconSize = GUIScale(Vector(128, 128, 0))
    GUIUnitStatus.kProgressingIconOffset = GUIScale(Vector(0, 128, 0))

    kHealthBarWidth = GUIScale(130)
    kHealthBarHeight = GUIScale(8)

    kArmorBarWidth = GUIScale(130)
    kArmorBarHeight = GUIScale(4)

    kNameDefaultPos = GUIScale(Vector(0, 4, 0))
    kActionDefaultPos = GUIScale(Vector(0, -16, 0))
end

function GUIUnitStatus:Initialize()

    GUIAnimatedScript.Initialize(self, kUpdateIntervalFull)

    self.nextUnitStatusUpdate = 0

    self.activeStatusInfo =  {}

    self.activeBlipList = {}
    self.dirtyBlipList = {}

    self.useMarineStyle = false
    self.fullHUD = Client.GetHudDetail() == kHUDMode.Full

    UpdateItemsGUIScale(self)

    self.visible = true

end

function GUIUnitStatus:SetIsVisible(state)

    self.visible = state
    self:Update(0)

end

function GUIUnitStatus:GetIsVisible()

    return self.visible

end

function GUIUnitStatus:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)

    DestroyActiveBlips(self)

end

function GUIUnitStatus:OnResolutionChanged()
    self:Uninitialize()
    self:Initialize()
end

function GUIUnitStatus:EnableMarineStyle()
    self.useMarineStyle = true
end

function GUIUnitStatus:EnableAlienStyle()
    self.useMarineStyle = false
end

local function GetPixelCoordsForFraction(fraction)

    local width = GUIUnitStatus.kUnitStatusBarTexCoords[3] - GUIUnitStatus.kUnitStatusBarTexCoords[1]
    local x1 = GUIUnitStatus.kUnitStatusBarTexCoords[1]
    local x2 = x1 + width * fraction
    local y1 = GUIUnitStatus.kUnitStatusBarTexCoords[2]
    local y2 = GUIUnitStatus.kUnitStatusBarTexCoords[4]

    return x1, y1, x2, y2

end

local function GetPixelCoordsForFractionPiece(fractionStart, fractionEnd)

    local width = GUIUnitStatus.kUnitStatusBarTexCoords[3] - GUIUnitStatus.kUnitStatusBarTexCoords[1]
    local x1 = GUIUnitStatus.kUnitStatusBarTexCoords[1] + width * fractionStart
    local x2 = GUIUnitStatus.kUnitStatusBarTexCoords[1] + width * fractionEnd
    local y1 = GUIUnitStatus.kUnitStatusBarTexCoords[2]
    local y2 = GUIUnitStatus.kUnitStatusBarTexCoords[4]

    return x1, y1, x2, y2

end

local function CreateBlipItem(self)

    local newBlip = {}
    local teamType = PlayerUI_GetTeamType()
    local neutralTexture = "ui/unitstatus_neutral.dds"

    newBlip.teamType = teamType

    newBlip.ScreenX = 0
    newBlip.ScreenY = 0

    local texture = kStatusBgTexture[teamType]
    local fontColor = kStatusFontColor[teamType]

    newBlip.GraphicsItem = self:CreateAnimatedGraphicItem()
    newBlip.GraphicsItem:SetAnchor(GUIItem.Left, GUIItem.Top)

    newBlip.GraphicsItem:SetSize(GUIUnitStatus.kUnitStatusSize)
    newBlip.GraphicsItem:SetIsScaling(false)
    newBlip.GraphicsItem:SetColor(Color(1,1,1,0.9))
    newBlip.GraphicsItem:SetTexture(texture)
    newBlip.GraphicsItem:SetLayer(kGUILayerPlayerNameTags)
    newBlip.GraphicsItem:SetIsVisible(self.visible)

    newBlip.ProgressingIcon = GetGUIManager():CreateGraphicItem()
    newBlip.ProgressingIcon:SetTexture(texture)
    newBlip.ProgressingIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    newBlip.ProgressingIcon:SetBlendTechnique(GUIItem.Add)
    newBlip.ProgressingIcon:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kProgressingIconCoords))
    newBlip.ProgressingIcon:SetSize(GUIUnitStatus.kProgressingIconSize)
    newBlip.ProgressingIcon:SetPosition(-GUIUnitStatus.kProgressingIconSize/2 + GUIUnitStatus.kProgressingIconOffset )
    newBlip.ProgressingIcon:SetIsVisible(false)

    newBlip.ProgressBackground = GetGUIManager():CreateGraphicItem()
    newBlip.ProgressBackground:SetTexture(GUIUnitStatus.kBlackTexture)
    newBlip.ProgressBackground:SetSize(GUIUnitStatus.kProgressingIconSize)
    newBlip.ProgressingIcon:AddChild(newBlip.ProgressBackground)

    newBlip.ProgressText = GetGUIManager():CreateTextItem()
    newBlip.ProgressText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    newBlip.ProgressText:SetTextAlignmentX(GUIItem.Align_Center)
    newBlip.ProgressText:SetTextAlignmentY(GUIItem.Align_Center)
    newBlip.ProgressText:SetScale(GetScaledVector())
    newBlip.ProgressText:SetColor(fontColor)
    newBlip.ProgressText:SetFontName(GUIUnitStatus.kProgressFontName)
    GUIMakeFontScale(newBlip.ProgressText)
    newBlip.ProgressingIcon:AddChild(newBlip.ProgressText)

    newBlip.statusBg = GetGUIManager():CreateGraphicItem() -- This function creates a root GUIItem
    newBlip.statusBg:SetLayer(kGUILayerPlayerNameTags)
    newBlip.statusBg:SetSize(GUIUnitStatus.kStatusBgSize)
    newBlip.statusBg:SetPosition(-GUIUnitStatus.kStatusBgSize * .5 + GUIUnitStatus.kStatusBgOffset )
    newBlip.statusBg:SetClearsStencilBuffer(true)
    newBlip.statusBg:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kStatusBackgroundPixelCoords))


    newBlip.HealthBarBg = GetGUIManager():CreateGraphicItem()
    newBlip.HealthBarBg:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    newBlip.HealthBarBg:SetSize(Vector(kHealthBarWidth, kHealthBarHeight, 0))
    newBlip.HealthBarBg:SetPosition(Vector(-kHealthBarWidth / 2, -kHealthBarHeight - kArmorBarHeight - GUIScale(10), 0))
    newBlip.HealthBarBg:SetTexture(neutralTexture)
    newBlip.HealthBarBg:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kUnitStatusBarTexCoords))
    newBlip.HealthBarBg:SetColor(Color(0,0,0,0))

    newBlip.RegenBar = GetGUIManager():CreateGraphicItem()
    newBlip.RegenBar:SetColor(kRegenBarFriendlyColor)
    newBlip.RegenBar:SetSize(Vector(0, kHealthBarHeight, 0))
    newBlip.RegenBar:SetTexture(neutralTexture)
    newBlip.RegenBar:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kUnitStatusBarTexCoords))
    newBlip.RegenBar:SetBlendTechnique(GUIItem.Add)
    newBlip.HealthBarBg:AddChild(newBlip.RegenBar)

    newBlip.HealthBar = GetGUIManager():CreateGraphicItem()
    newBlip.HealthBar:SetColor(kHealthBarColors[teamType])
    newBlip.HealthBar:SetSize(Vector(kHealthBarWidth, kHealthBarHeight, 0))
    newBlip.HealthBar:SetTexture(neutralTexture)
    newBlip.HealthBar:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kUnitStatusBarTexCoords))
    newBlip.HealthBar:SetBlendTechnique(GUIItem.Add)
    newBlip.HealthBarBg:AddChild(newBlip.HealthBar)

    newBlip.ArmorBarBg = GetGUIManager():CreateGraphicItem()
    newBlip.ArmorBarBg:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    newBlip.ArmorBarBg:SetSize(Vector(kArmorBarWidth, kArmorBarHeight, 0))
    newBlip.ArmorBarBg:SetPosition(Vector(-kArmorBarWidth / 2, -kArmorBarHeight - GUIScale(10), 0))
    newBlip.ArmorBarBg:SetTexture(neutralTexture)
    newBlip.ArmorBarBg:SetColor(Color(0,0,0,0))
    newBlip.ArmorBarBg:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kUnitStatusBarTexCoords))

    newBlip.ArmorBar = GUIManager:CreateGraphicItem()
    newBlip.ArmorBar:SetColor(kArmorBarColors[teamType])
    newBlip.ArmorBar:SetSize(Vector(kArmorBarWidth, kArmorBarHeight, 0))
    newBlip.ArmorBar:SetTexture(neutralTexture)
    newBlip.ArmorBar:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kUnitStatusBarTexCoords))
    newBlip.ArmorBar:SetBlendTechnique(GUIItem.Add)
    newBlip.ArmorBarBg:AddChild(newBlip.ArmorBar)

    newBlip.NameText = GUIManager:CreateTextItem()
    newBlip.NameText:SetAnchor(GUIItem.Middle, GUIItem.Top)
    newBlip.NameText:SetFontName(GUIUnitStatus.kFontName)
    newBlip.NameText:SetTextAlignmentX(GUIItem.Align_Center)
    newBlip.NameText:SetTextAlignmentY(GUIItem.Align_Min)
    newBlip.NameText:SetScale(GUIUnitStatus.kFontScale)
    GUIMakeFontScale(newBlip.NameText)
    newBlip.NameText:SetPosition(kNameDefaultPos)

    newBlip.ActionTextShadow = GUIManager:CreateTextItem()
    newBlip.ActionTextShadow:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    newBlip.ActionTextShadow:SetFontName(GUIUnitStatus.kActionFontName)
    newBlip.ActionTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
    newBlip.ActionTextShadow:SetTextAlignmentY(GUIItem.Align_Min)
    newBlip.ActionTextShadow:SetScale(GUIUnitStatus.kActionFontScale)
    GUIMakeFontScale(newBlip.ActionTextShadow)
    newBlip.ActionTextShadow:SetPosition(Vector(kActionDefaultPos.x + GUIScale(2), kActionDefaultPos.y + GUIScale(2), 0))

    newBlip.ActionText = GUIManager:CreateTextItem()
    newBlip.ActionText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    newBlip.ActionText:SetFontName(GUIUnitStatus.kActionFontName)
    newBlip.ActionText:SetTextAlignmentX(GUIItem.Align_Center)
    newBlip.ActionText:SetTextAlignmentY(GUIItem.Align_Min)
    newBlip.ActionText:SetScale(GUIUnitStatus.kActionFontScale)
    GUIMakeFontScale(newBlip.ActionText)
    newBlip.ActionText:SetPosition(kActionDefaultPos)

    newBlip.HintText = GUIManager:CreateTextItem()
    newBlip.HintText:SetAnchor(GUIItem.Middle, GUIItem.Top)
    newBlip.HintText:SetFontName(GUIUnitStatus.kFontName)
    newBlip.HintText:SetTextAlignmentX(GUIItem.Align_Center)
    newBlip.HintText:SetTextAlignmentY(GUIItem.Align_Min)
    newBlip.HintText:SetScale(GUIUnitStatus.kFontScaleSmall)
    GUIMakeFontScale(newBlip.HintText)
    newBlip.HintText:SetPosition(GUIScale(Vector(0, 31, 0)))

    newBlip.MaturityText = GUIManager:CreateTextItem()
    newBlip.MaturityText:SetAnchor(GUIItem.Middle, GUIItem.Top)
    newBlip.MaturityText:SetFontName(GUIUnitStatus.kFontName)
    newBlip.MaturityText:SetTextAlignmentX(GUIItem.Align_Center)
    newBlip.MaturityText:SetTextAlignmentY(GUIItem.Align_Min)
    newBlip.MaturityText:SetScale(GUIUnitStatus.kFontScaleSmall)
    GUIMakeFontScale(newBlip.MaturityText)
    newBlip.MaturityText:SetPosition(GUIScale(Vector(0, 64, 0)))

    -- Create badge icon items
    newBlip.Badges = {}
    for i = 1, Badges_GetMaxBadges() do

        local badge = GUIManager:CreateGraphicItem()
        badge:SetAnchor(GUIItem.Left, GUIItem.Top)
        badge:SetSize(self.kBadgeSize)
        badge:SetPosition(Vector(i * (self.kBadgeSize.x+2), self.kBadgesYOffset , 0))
        badge:SetIsVisible(false)

        table.insert( newBlip.Badges, badge )
        newBlip.statusBg:AddChild(badge)

    end

    newBlip.statusBg:AddChild(newBlip.HealthBarBg)
    newBlip.statusBg:AddChild(newBlip.ArmorBarBg)
    newBlip.statusBg:AddChild(newBlip.NameText)
    newBlip.statusBg:AddChild(newBlip.HintText)
    newBlip.statusBg:AddChild(newBlip.MaturityText)

    newBlip.statusBg:SetColor(Color(0,0,0,0))

    newBlip.GraphicsItem:AddChild(newBlip.ProgressingIcon)

    newBlip.ProgressingIcon:AddChild(newBlip.ActionTextShadow)
    newBlip.ProgressingIcon:AddChild(newBlip.ActionText)

    return newBlip

end

local function UpdateBlipTeamType(blip)
    local teamType = PlayerUI_GetTeamType()
    if blip.teamType == teamType then
        return
    end

    blip.teamType = teamType

    local texture = kStatusBgTexture[teamType]
    local fontColor = kStatusFontColor[teamType]

    blip.GraphicsItem:SetTexture(texture)
    blip.GraphicsItem:SetColor(Color(1,1,1,0.9))

    blip.ProgressingIcon:SetTexture(texture)
    blip.ProgressText:SetColor(fontColor)

    blip.HealthBar:SetColor(kHealthBarColors[teamType])
    blip.ArmorBar:SetColor(kArmorBarColors[teamType])

end

local function GetNewBlipItem(self)
    if #self.dirtyBlipList > 0 then
        local dirtyBlip = table.remove(self.dirtyBlipList)
        UpdateBlipTeamType(dirtyBlip) -- We may need to update the teamType

        return dirtyBlip
    end

    return CreateBlipItem(self)
end

local function AddAbilityBar(blipItem)

    blipItem.AbilityBarBg = GetGUIManager():CreateGraphicItem()
    blipItem.AbilityBarBg:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    blipItem.AbilityBarBg:SetSize(Vector(kArmorBarWidth, kArmorBarHeight * 2, 0))
    blipItem.AbilityBarBg:SetPosition(Vector(-kArmorBarWidth / 2, -kArmorBarHeight * 2, 0))
    blipItem.AbilityBarBg:SetTexture("ui/unitstatus_neutral.dds")
    blipItem.AbilityBarBg:SetColor(Color(0,0,0,1))
    blipItem.AbilityBarBg:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kUnitStatusBarTexCoords))

    blipItem.AbilityBar = GUIManager:CreateGraphicItem()
    blipItem.AbilityBar:SetColor(kAbilityBarColor)
    blipItem.AbilityBar:SetSize(Vector(kArmorBarWidth, kArmorBarHeight *2, 0))
    blipItem.AbilityBar:SetTexture("ui/unitstatus_neutral.dds")
    blipItem.AbilityBar:SetTexturePixelCoordinates(GUIUnpackCoords(GUIUnitStatus.kUnitStatusBarTexCoords))
    blipItem.AbilityBar:SetBlendTechnique(GUIItem.Add)
    blipItem.AbilityBarBg:AddChild(blipItem.AbilityBar)

    blipItem.statusBg:AddChild(blipItem.AbilityBarBg)

end

function GUIUnitStatus:UpdateUnitStatusBlip(blipIndex, localPlayerIsCommander, baseResearchRot, showHints, playerTeamType )

    PROFILE("GUIUnitStatus:UpdateUnitStatusBlip")

    local blipData = self.activeStatusInfo[blipIndex]

    -- status icon, color and unit name

    local updateBlip = self.activeBlipList[blipIndex]
    updateBlip.GraphicsItem:SetTexturePixelCoordinates(GetUnitStatusTextureCoordinates(blipData.Status))
    updateBlip.GraphicsItem:SetPosition(blipData.Position - GUIUnitStatus.kUnitStatusSize * .5 )
    updateBlip.GraphicsItem:SetIsVisible(self.visible and blipData.LOSSighted)

    local teamType = blipData.TeamType
    local isEnemy = false
    local isCrosshairTarget = blipData.IsCrossHairTarget
    local commHealthBarsShown = blipData.CommHealthBarsToggle
    if playerTeamType ~= kNeutralTeamType then
        isEnemy = (playerTeamType ~= teamType) and (teamType ~= kNeutralTeamType)
        teamType = playerTeamType
    end

    local nameplates = GetAdvancedOption("nameplates")
    local displayPercentages = (nameplates == 1 or nameplates == 3) and (not blipData.IsPlayer or (not isEnemy and not localPlayerIsCommander))

    local blipNameText = ConditionalValue(displayPercentages and blipData.HealthAndArmorPercentage, blipData.HealthAndArmorPercentage, blipData.Name)
    local blipHintText = blipData.Hint
    local maturityFraction = 0
    local healthFraction = 0
    local regenFraction = 0
    local armorFraction = 0
    local abilityFraction = 0
    local statusFraction = 0

    local alpha = 0

    if isCrosshairTarget or commHealthBarsShown then
        healthFraction = blipData.HealthFraction
        regenFraction = blipData.RegenFraction
        armorFraction = blipData.ArmorFraction
        abilityFraction = blipData.AbilityFraction
        statusFraction = blipData.StatusFraction
        maturityFraction = blipData.MaturityFraction
        alpha = 1
    end

    if blipData.SpawnFraction ~= nil and not isEnemy then
        -- Show spawn progress
        if isCrosshairTarget then
            if showHints then
                blipHintText = string.format(Locale.ResolveString( "INFANTRY_PORTAL_SPAWNING_HINT" ), blipData.SpawnerName )
            else
                blipHintText = blipData.SpawnerName
            end
            showHints = true
        else

            if displayPercentages then
                blipNameText = string.format("%s (%d%%)", blipData.SpawnerName, blipData.SpawnFraction*100)
            end

            blipNameText = blipData.SpawnerName
            showHints = false
        end
        abilityFraction = math.max(0.01, blipData.SpawnFraction ) -- always show at least 1% so there is a black bar
        alpha = 1
    end

    if blipData.EvolvePercentage ~= nil and not isEnemy and ( blipData.IsPlayer or isCrosshairTarget ) then

        if not localPlayerIsCommander then
            blipHintText = blipData.EvolveClass or blipHintText
            showHints = true
        end

        if displayPercentages then
            if blipData.EvolveClass ~= nil then
                blipNameText = string.format("%s (%s)", blipData.HealthAndArmorFraction, blipData.EvolveClass)
            else
                blipNameText = string.format("%s (%d%%)", blipData.Name, blipData.EvolvePercentage*100)
            end
        end

        -- If evolving show evolve progress and hide the researching spinner
        abilityFraction = math.max(0.01, blipData.EvolvePercentage ) -- always show at least 1% so there is a black bar
        statusFraction = 0
        alpha = 1
    end

    if blipData.Destination and not isEnemy then
        if isCrosshairTarget then
            if not showHints then
                blipHintText = blipData.Destination
            end

            if displayPercentages then
                blipNameText = string.format("%s (%s)", blipData.Destination, blipData.HealthAndArmorPercentage)
            end

            showHints = true
            alpha = 1
        elseif blipData.ShowDestination ~= nil then
            if blipData.ShowDestination == true then
                blipNameText = blipData.Destination
                showHints = false
                alpha = 1
            end
        elseif not localPlayerIsCommander then
            blipNameText = blipData.Destination
            showHints = false
            alpha = 1
        end

        if not isCrosshairTarget and displayPercentages then
            blipNameText = blipData.Destination
        end
    end

    local textColor
    if isEnemy then
        textColor = GUIUnitStatus.kEnemyColor
    elseif blipData.IsParasited and blipData.IsFriend then
        textColor = kCommanderColorFloat
    elseif blipData.IsSteamFriend then
        textColor = kSteamFriendColor
    else
        textColor = kNameTagFontColors[teamType]
    end

    local color = kWhite
    if playerTeamType == kTeam1Index and (blipData.Status == kUnitStatus.Unrepaired or blipData.Status == kUnitStatus.Damaged) then
        if GUIUnitStatus.kUseColoredWrench then
            local percentage = blipData.IsPlayer and blipData.ArmorFraction or (blipData.HealthFraction + blipData.ArmorFraction)/2
            color = (percentage < 0.5 and LerpColor(kRed, kYellow, percentage*2)) or (percentage >= 0.5 and LerpColor(kYellow, kWhite, (percentage-0.5)*2))
        else
            if blipData.Status == kUnitStatus.Unrepaired then
                color = kYellow
            end
        end

        color.a = updateBlip.GraphicsItem:GetColor().a -- to not override the pulsate
    end
    updateBlip.GraphicsItem:SetColor(color)

    updateBlip.statusBg:SetColor(Color(1,1,1,1))
    updateBlip.statusBg:SetTexture(kTransparentTexture)
    updateBlip.statusBg:SetPosition(blipData.HealthBarPosition - GUIUnitStatus.kStatusBgSize * .5 )

    -- Name
    local showName = alpha > 0 and (not localPlayerIsCommander or isCrosshairTarget)
    showName = showName and (not blipData.IsPlayer or not isEnemy)
    if ( blipData.ForceName and blipData.IsPlayer ) or showName then
        updateBlip.NameText:SetIsVisible(self.visible)
        updateBlip.NameText:SetText(blipNameText)
        updateBlip.NameText:SetColor(textColor) -- use the entities team color here, so you can make a difference between enemy or friend
    else
        updateBlip.NameText:SetIsVisible(false)
    end

    local hideBars = nameplates == 1 -- numbers only.

    -- Health Bar
    local displayHBar = alpha > 0 and healthFraction ~= 0 -- only diplay when health > 0 and unitstatus visible
    --displayHBar = displayHBar and (localPlayerIsCommander or (not hideBars and (not blipData.IsPlayer or not isEnemy))) -- don't display health bar for enemies
    if displayHBar then
        updateBlip.HealthBarBg:SetIsVisible(self.visible)

        if blipData.IsPlayer and isEnemy and not blipData.EvolvePercentage then
            updateBlip.HealthBarBg:SetColor( kHealthBarBgEnemyPlayerColor )
            updateBlip.HealthBar:SetColor( kHealthBarEnemyPlayerColor )
            updateBlip.RegenBar:SetColor( kRegenBarEnemyColor )
        else
            updateBlip.HealthBarBg:SetColor( kHealthBarBgColors[teamType] )
            updateBlip.HealthBar:SetColor( kHealthBarColors[teamType] )
            updateBlip.HealthBar:SetColor( kHealthBarColors[teamType] )
            updateBlip.RegenBar:SetColor( kRegenBarFriendlyColor )
        end

        if healthFraction < regenFraction then
            updateBlip.RegenBar:SetIsVisible(self.visible)
            updateBlip.RegenBar:SetSize(Vector(kHealthBarWidth * ( regenFraction - healthFraction ), kHealthBarHeight, 0))
            updateBlip.RegenBar:SetTexturePixelCoordinates(GetPixelCoordsForFractionPiece(healthFraction,regenFraction))
            updateBlip.RegenBar:SetPosition(Vector(kHealthBarWidth * healthFraction,0,0))
        else
            updateBlip.RegenBar:SetIsVisible(false)
        end

        updateBlip.HealthBar:SetSize(Vector(kHealthBarWidth * healthFraction, kHealthBarHeight, 0))
        updateBlip.HealthBar:SetTexturePixelCoordinates(GetPixelCoordsForFraction(healthFraction))
    else
        updateBlip.HealthBarBg:SetIsVisible(false)
    end

    -- Armor Bar
    local displayABar = alpha > 0 and armorFraction ~= 0 -- only diplay when armor > 0 and unitstatus visible
    --displayABar = displayABar and (localPlayerIsCommander or (not hideBars and (not blipData.IsPlayer or not isEnemy))) -- don't display armor bar for enemies
    if displayABar then
        updateBlip.ArmorBarBg:SetIsVisible(self.visible)
        if blipData.IsPlayer and isEnemy and not blipData.EvolvePercentage then
            updateBlip.ArmorBarBg:SetColor(kArmorBarBgEnemyPlayerColor)
            updateBlip.ArmorBar:SetColor(kArmorBarEnemyPlayerColor)
        else
            updateBlip.ArmorBarBg:SetColor(kArmorBarBgColors[teamType])
            updateBlip.ArmorBar:SetColor(kArmorBarColors[teamType])
        end
        updateBlip.ArmorBar:SetSize(Vector(kArmorBarWidth * armorFraction, kArmorBarHeight, 0))
        updateBlip.ArmorBar:SetTexturePixelCoordinates(GetPixelCoordsForFraction(armorFraction))
    else
        updateBlip.ArmorBarBg:SetIsVisible(false)
    end

    -- Ammo/Ability Bar
    if abilityFraction > 0 then
        if not updateBlip.AbilityBarBg then
            AddAbilityBar(updateBlip)
        end

        if alpha > 0 then
            updateBlip.AbilityBarBg:SetIsVisible( self.visible )
            updateBlip.AbilityBarBg:SetColor(kAbilityBarBgColors[teamType])
            updateBlip.AbilityBar:SetSize(Vector(kArmorBarWidth * abilityFraction, kArmorBarHeight * 2, 0))
            updateBlip.AbilityBar:SetTexturePixelCoordinates(GetPixelCoordsForFraction(abilityFraction))

            if blipData.IsWorldWeapon and GUIPickups.kExpirationBarMode > 0 then
                local ammoBarColor = GUIPickups_GetExpirationBarColor( blipData.AbilityFraction, 1 )
                updateBlip.AbilityBar:SetColor(ammoBarColor)
            else
                local ammoBarColor = blipData.PrimaryWeapon and kAmmoBarColors[blipData.PrimaryWeapon]
                if ammoBarColor then
                    updateBlip.AbilityBar:SetColor(ammoBarColor)
                    updateBlip.AbilityBarBg:SetColor(Color(ammoBarColor.r * 0.5, ammoBarColor.g * 0.5, ammoBarColor.b * 0.5, 1))
                else
                    updateBlip.AbilityBar:SetColor(kAbilityBarColors[teamType])
                end
            end

        else
            updateBlip.AbilityBarBg:SetIsVisible( false )
        end
    else
        if updateBlip.AbilityBarBg then
            updateBlip.AbilityBarBg:SetIsVisible( false )
        end
    end

    -- Hints

    if displayPercentages then
        blipHintText = blipData.HealthAndArmorFraction

        if blipData.EvolveClass ~= nil then
            updateBlip.HintText:SetText(string.format("%s (%s)", blipHintText, blipData.EvolveClass))
        end
    end

    showHints = showHints and (not localPlayerIsCommander or isCrosshairTarget) or displayPercentages

    if showHints and blipHintText and blipHintText ~= "" and alpha > 0 then
        updateBlip.HintText:SetIsVisible(self.visible)
        updateBlip.HintText:SetText(blipHintText)
        updateBlip.HintText:SetColor(textColor)

        local bgsize = GUIUnitStatus.kStatusBgSize
        local hintTextWidth = updateBlip.HintText:GetTextWidth(blipHintText) + 8
        if kStatusBgSizeUnscaled.x < hintTextWidth then
            bgsize = Vector( kStatusBgSizeUnscaled )
            bgsize.x = hintTextWidth
            bgsize = GUIScale( bgsize )
        end

        updateBlip.statusBg:SetSize(bgsize)
        updateBlip.statusBg:SetPosition(blipData.HealthBarPosition - updateBlip.statusBg:GetSize() * .5 )
    else
        updateBlip.HintText:SetIsVisible(false)
        updateBlip.statusBg:SetSize(GUIUnitStatus.kStatusBgNoHintSize)
    end

    -- Research Progress
    if isCrosshairTarget and statusFraction > 0 and statusFraction < 1 then
        updateBlip.ProgressingIcon:SetIsVisible(self.visible)
        updateBlip.ProgressingIcon:SetRotation(Vector(0, 0, -2 * math.pi * baseResearchRot))
        updateBlip.ProgressText:SetText(math.floor(statusFraction * 100) .. "%")
        updateBlip.ActionText:SetText(blipData.Action)
        updateBlip.ActionText:SetColor(textColor)
        updateBlip.ActionTextShadow:SetText(blipData.Action)
        updateBlip.ActionTextShadow:SetColor(Color(0, 0, 0, 1))
    else
        updateBlip.ProgressingIcon:SetIsVisible(false)
    end

    -- Badges
    if alpha > 0 and not GetGameInfoEntity():GetGameStarted() then
        assert( #updateBlip.Badges >= #blipData.BadgeTextures )
        for i = 1, #updateBlip.Badges do

            local badge = updateBlip.Badges[i]
            local texture = blipData.BadgeTextures[i]

            if texture then

                badge:SetTexture(texture)
                badge:SetIsVisible(self.visible)

            else
                badge:SetIsVisible(false)
            end

        end
    else
        for i = 1, #updateBlip.Badges do
            updateBlip.Badges[i]:SetIsVisible(false)
        end
    end

    -- Maturity
    if maturityFraction ~= -1 and alpha > 0 and isCrosshairTarget then
        local text = string.format("Maturity: %.f%%", maturityFraction * 100)
        updateBlip.MaturityText:SetIsVisible(self.visible)
        updateBlip.MaturityText:SetText(text)
        updateBlip.MaturityText:SetColor(textColor)
    else
        updateBlip.MaturityText:SetIsVisible(false)
    end

    if GetAdvancedOption("nameplates") == 2 and blipData.IsPlayer == false then
        updateBlip.NameText:SetIsVisible(false)
        updateBlip.HintText:SetIsVisible(false)
        updateBlip.MaturityText:SetIsVisible(false)
    end

end

function GUIUnitStatus:UpdateUnitStatusList()

    PROFILE("GUIUnitStatus:UpdateUnitStatusList")

    local numBlips = #self.activeStatusInfo

    while numBlips > #self.activeBlipList do

        local newBlipItem = GetNewBlipItem(self)
        table.insert(self.activeBlipList, newBlipItem)

        newBlipItem.GraphicsItem:SetIsVisible(true)
        newBlipItem.statusBg:SetIsVisible(true)

    end

    while numBlips < #self.activeBlipList do

        -- hide unused blips
        local blip = table.remove(self.activeBlipList, 1)
        blip.GraphicsItem:SetIsVisible(false)
        blip.statusBg:SetIsVisible(false)

        table.insert(self.dirtyBlipList, blip)

    end

    local localPlayerIsCommander = Client.GetLocalPlayer() and Client.GetLocalPlayer():isa("Commander")
    local baseResearchRot = (Shared.GetTime() % GUIUnitStatus.kResearchRotationDuration) / GUIUnitStatus.kResearchRotationDuration
    local showHints = Client.GetOptionBoolean("showHints", true) == true
    local playerTeamType = PlayerUI_GetTeamType()

    -- Update current blip state.
    for i = 1, #self.activeBlipList do

        self:UpdateUnitStatusBlip( i, localPlayerIsCommander, baseResearchRot, showHints, playerTeamType )

    end

end


function GUIUnitStatus:UpdatePerFrameInfo()

    PROFILE("GUIUnitStatus:UpdatePerFrameInfo")

    local player = Client.GetLocalPlayer()

    if not player then
        return
    end

    local localPlayerIsCommander = Client.GetLocalPlayer() and Client.GetLocalPlayer():isa("Commander")
    local baseResearchRot = (Shared.GetTime() % GUIUnitStatus.kResearchRotationDuration) / GUIUnitStatus.kResearchRotationDuration
    local showHints = Client.GetOptionBoolean("showHints", true) == true
    local playerTeamType = PlayerUI_GetTeamType()

    -- only update the status of units we directly aim at
    for i = #self.activeStatusInfo, 1, -1 do

        local blipData = self.activeStatusInfo[i]
        if blipData then

            local unit = Shared.GetEntity(blipData.UnitId)
            if unit and not unit:GetIsDestroyed() then

                blipData = PlayerUI_GetStatusInfoForUnit(player, unit)

                if blipData then

                    self.activeStatusInfo[i] = blipData
                    self:UpdateUnitStatusBlip( i, localPlayerIsCommander, baseResearchRot, showHints, playerTeamType )

                end

            end

        end

    end

end

local function FindUnitsToDisplayStatusFor(player)

    PROFILE("GUIUnitStatus:FindUnitsToDisplayStatusFor")

    -- commanders will show entities that are selected
    if player:isa("Commander") then
        local result = {}

        for _, selectable in ipairs(GetEntitiesWithMixin("UnitStatus")) do
            table.insert(result, selectable)
        end

        return result
    end

    local isOverheadSpec = player:isa("Spectator") and player.specMode ~= nil and player.specMode == kSpectatorMode.Overhead
    -- Overhead specs don't need UnitStatus, they have Insight instead
    if isOverheadSpec then
        return {}
    end

    -- Normal player case

    -- check crosshair
    local result = {}
    local teamNumber = player:GetTeamNumber()
    local crosshairTarget = player:GetCrossHairTarget()
    if crosshairTarget
            and HasMixin(crosshairTarget, "UnitStatus")
            and HasMixin(crosshairTarget, "Selectable")
            and crosshairTarget:GetIsSelectable(teamNumber) then
        table.insert(result, crosshairTarget)
    end

    -- add in players on our own team and in fov and not ourself
    local maxDist = GUIUnitStatus.kMaxMarkedUnitStatusDistance
    if player:isa("Spectator") then
        maxDist = 30
    end

    local targets = GetEntitiesWithMixinWithinRange("UnitStatus", player:GetOrigin(), maxDist )
    for i = 1, #targets do
        local target = targets[i]

        local inRange = player:GetHasMarkedTarget(target) or GetDistanceSquaredToEntity( player, target ) <= kMaxUnitStatusDistanceSq
        if target ~= player and target ~= crosshairTarget and inRange then
            table.insert(result, target)
        end
    end

    return result
end

--
-- So, the original code did a full-frame rate collection of all entity data
-- around the player, then after an expensive round of collection whose cost
-- increases with entity count, THEN choose to display only for players and
-- the crosshair item.
--
-- The current code collects data for players and crosshair items only, and
-- updates the list of those only 12 times per second.
--
--

local kUnitStatusUpdateInterval = 0.016 -- update 60 times a second

function GUIUnitStatus:Update(deltaTime)

    PROFILE("GUIUnitStatus:Update")

    GUIAnimatedScript.Update(self, deltaTime)

    local now = Shared.GetTime()
    if now > self.nextUnitStatusUpdate then

        self.nextUnitStatusUpdate = now + kUnitStatusUpdateInterval

        local fullHUD = Client.GetHudDetail() == kHUDMode.Full
        if self.fullHUD ~= fullHUD then

            self.fullHUD = fullHUD
            DestroyActiveBlips(self)

        end

        local player = Client.GetLocalPlayer()

        local statusUnits = FindUnitsToDisplayStatusFor(player)

        self.activeStatusInfo = {}
        for _, unit in ipairs(statusUnits) do
            table.insert(self.activeStatusInfo, PlayerUI_GetStatusInfoForUnit(player, unit))
        end

        self:UpdateUnitStatusList(deltaTime)

    else

        self:UpdatePerFrameInfo()

    end

end
