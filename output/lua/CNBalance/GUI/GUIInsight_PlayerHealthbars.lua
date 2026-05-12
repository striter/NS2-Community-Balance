-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIInsight_PlayerHealthbars.lua
--
-- Created by: Jon 'Huze' Hughes (jon@jhuze.com)
--
-- Spectator: Displays player name and healthbars
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_PlayerHealthbars' (GUIScript)

local playerList
local reusebackgrounds

local kPlayerHealthDrainRate = 0.75 --Percent per ???

local kFontName = Fonts.kInsight
local kPlayerHealthBarTexture = "ui/healthbarplayer.dds"
local kPlayerHealthBarTextureSize = Vector(100, 7, 0)

local kEnergyBarTexture = "ui/healthbarsmall.dds"
local kEnergyBarTextureSize = Vector(100, 6, 0)

local kNameFontScale
local kPlayerHealthBarSize
local kPlayerEnergyBGSize
local kPlayerEnergyBarSize
local kPlayerEnergyBarOffest
local kHealthbarOffset

-- Color constants.
local kDefaultColor = Color(0.5, 0.5, 0.5, 1)
local kTeamHealthColors = {[kMarineTeamType] = kBlueColor, [kAlienTeamType] = kRedColor}
local kTeamArmorColors = {[kMarineTeamType] = Color(0.5, 1, 1, 1), [kAlienTeamType] = Color(1,0.8,0,1)}

local kParasiteColor = Color(1, 1, 0, 1)
-- local kPoisonColor = Color(0, 1, 0, 1)
local kHealthDrainColor = Color(1, 0, 0, 1)
local kEnergyColor = Color(1,1,0,1)

GUIInsight_PlayerHealthbars.kAmmoColors = {
    ["rifle"] = Color(0,0,1,1), -- blue
    ["pistol"] = Color(0,1,1,1), -- teal
    ["axe"] = Color(1,1,1,1), -- white
    ["welder"] = Color(1,1,1,1), -- white
    ["builder"] = Color(1,1,1,1), -- white
    ["mine"] = Color(1,1,1,1), -- white
    ["shotgun"] = Color(0,1,0,1), -- green
    ["flamethrower"] = Color(1,1,0,1), -- yellow
    ["grenadelauncher"] = Color(1,0,1,1), -- magenta
    ["hmg"] = Color(1,0,0,1), -- red
    ["minigun"] = Color(1,0,0,1), -- red
    ["railgun"] = Color(1,0.5,0,1), -- orange
    ["lightmachinegun"] = Color(0,0,1,1),
    ["submachinegun"] = Color(0,0,1,1),
    ["cannon"] = Color(1,0.5,0,1),
    ["revolver"] = Color(0,1,1,1),
    ["combatbuilder"] = Color(1,1,1,1), -- white
    ["knife"] = Color(1,1,1,1), -- white
}


function GUIInsight_PlayerHealthbars:Initialize()

    self.updateInterval = 0

    kNameFontScale = GUIScale(Vector(1,1,1)) * 0.8
    kPlayerHealthBarSize = GUIScale(Vector(100, 7, 0))
    kPlayerEnergyBGSize = GUIScale(Vector(100, 6, 0))
    kPlayerEnergyBarSize = GUIScale(Vector(98, 5, 0))
    kPlayerEnergyBarOffest = GUIScale(Vector(1, 0, 0))
    kHealthbarOffset = Vector(0, -kPlayerHealthBarSize.y - GUIScale(16), 0)

    playerList = {}
    reusebackgrounds = {}

    self.showHpText = false
end

function GUIInsight_PlayerHealthbars:Uninitialize()

    -- Players
    for id, player in pairs(playerList) do
        GUI.DestroyItem(player.Background)
    end

    playerList = nil

    -- Reuse items
    for _, background in ipairs(reusebackgrounds) do
        GUI.DestroyItem(background["Background"])
    end
    reusebackgrounds = nil

end

function GUIInsight_PlayerHealthbars:OnResolutionChanged()

    self:Uninitialize()
    kNameFontScale = GUIScale(Vector(1,1,1)) * 0.8
    kPlayerHealthBarSize = GUIScale(Vector(100, 7, 0))
    kPlayerEnergyBGSize = GUIScale(Vector(100, 6, 0))
    kPlayerEnergyBarSize = GUIScale(Vector(98, 5, 0))
    kPlayerEnergyBarOffest = GUIScale(Vector(1, 0, 0))
    kHealthbarOffset = Vector(0, -kPlayerHealthBarSize.y - GUIScale(16), 0)
    self:Initialize()

end

function GUIInsight_PlayerHealthbars:Update(deltaTime)

    PROFILE("GUIInsight_PlayerHealthbars:Update")

    local player = Client.GetLocalPlayer()
    if not player then
        return
    end

    self:UpdatePlayers(deltaTime)

end

function GUIInsight_PlayerHealthbars:UpdatePlayers(deltaTime)

    local playerMap = {}
    for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        playerMap[player:GetId()] = player
    end

    -- Remove old players

    for id, playerGUI in pairs(playerList) do

        if not playerMap[id] then

            self:RemovePlayerGUIItem(id)
        end
    end

    -- Add new and Update all players

    for playerIndex, player in pairs(playerMap) do

        -- local playerIndex = player:GetId()
        local relevant = player:GetIsVisible() and player:GetIsAlive() and not player:isa("Commander") and not player:isa("Spectator") and not player:isa("ReadyRoomPlayer")

        if relevant then
            PROFILE("GUIInsight_PlayerHealthbars:UpdatePlayers.for(player)")

            local _, max = player:GetModelExtents()
            local nameTagWorldPosition = player:GetOrigin() + Vector(0, max.y, 0)

            local health = player:GetIgnoreHealth() and 0 or math.floor(player:GetHealth())
            local armor = player:GetArmor() * kHealthPointsPerArmor
            local maxHealth = player:GetIgnoreHealth() and 0 or player:GetMaxHealth()
            local maxArmor = player:GetMaxArmor() * kHealthPointsPerArmor
            local regen = HasMixin(player, "Regeneration") and player:GetRegeneratingHealth() or 0

            local regenFraction = regen/(maxHealth+maxArmor)
            local healthFraction = health/(maxHealth+maxArmor)
            local armorFraction = armor/(maxHealth+maxArmor)

            local nameTagInScreenspace = Client.WorldToScreen(nameTagWorldPosition) + kHealthbarOffset

            -- local isPoisoned = player.poisoned
            local isParasited = player.parasited

            -- Get/Create Player GUI Item
            local playerGUI
            if not playerList[playerIndex] then -- Add new GUI for new players

                playerGUI = self:CreatePlayerGUIItem()
                playerGUI.StoredValues.TotalFraction = healthFraction+armorFraction
                table.insert(playerList, playerIndex, playerGUI)

            else

                playerGUI = playerList[playerIndex]

            end

            -- Set the font and item colors as needed.
            local teamType = player:GetTeamType()
            if playerGUI.StoredValues.Team ~= teamType then
                self:SetGUIItemColor(playerGUI, teamType)
                playerGUI.StoredValues.Team = teamType
            end

            -- Set player info --

            -- background
            local background = playerGUI.Background
            PROFILE("GUIInsight_PlayerHealthbars:UpdatePlayers.SetPosition()")
            background:SetPosition(nameTagInScreenspace)

            -- name
            local name = player:GetName()
            local nameItem = playerGUI.Name
            if playerGUI.StoredValues.Name ~= name then
                nameItem:SetText(name)
                playerGUI.StoredValues.Name = name
            end

            -- parasited color
            if playerGUI.StoredValues.Parasited ~= isParasited then
                local normalColor = Color(kNameTagFontColors[teamType] or kDefaultColor)
                nameItem:SetColor(ConditionalValue(isParasited, kParasiteColor, normalColor))
                playerGUI.StoredValues.Parasited = isParasited
            end

            -- hpText
            local hpText = playerGUI.HPText

            if self.showHpText then
                local offset = -(nameItem:GetTextHeight(name) * nameItem:GetScale().y) + GUIScale(5)
                nameItem:SetPosition(Vector(0,offset,0))

                if playerGUI.StoredValues.LastHealth ~= health or playerGUI.StoredValues.LastArmor ~= armor then
                    if player:GetIgnoreHealth() then
                        hpText:SetText(tostring(math.max(armor, 1)))
                    else
                        hpText:SetText(string.format("%s / %s", health, armor))
                    end
                end

                if not hpText:GetIsVisible() then
                    hpText:SetIsVisible(true)
                end

            elseif hpText:GetIsVisible() then
                nameItem:SetPosition(Vector(0,0,0))
                hpText:SetIsVisible(false)
            end


            -- health bar
            local healthBar = playerGUI.HealthBar
            local healthBarSize = healthFraction * kPlayerHealthBarSize.x
            local healthBarTextureSize = healthFraction * kPlayerHealthBarTextureSize.x
            if health ~= playerGUI.StoredValues.LastHealth then
                healthBar:SetTexturePixelCoordinates(0, 0, healthBarTextureSize, kPlayerHealthBarTextureSize.y)
                healthBar:SetSize(Vector(healthBarSize, kPlayerHealthBarSize.y, 0))
                playerGUI.StoredValues.LastHealth = health
            end

            --regen bar
            local regenBar = playerGUI.RegenBar
            local regenBarSize = regenFraction * kPlayerHealthBarSize.x
            local regenTextureSize = regenFraction * kPlayerHealthBarTextureSize.x
            regenBar:SetTexturePixelCoordinates(healthBarTextureSize, 0, healthBarTextureSize + regenTextureSize, kPlayerHealthBarTextureSize.y)
            regenBar:SetSize(Vector(regenBarSize, kPlayerHealthBarSize.y, 0))
            regenBar:SetPosition(Vector(healthBarSize, 0, 0))

            -- armor bar
            local armorBar = playerGUI.ArmorBar
            local armorBarSize = armorFraction * kPlayerHealthBarSize.x
            local armorBarTextureSize = armorFraction * kPlayerHealthBarTextureSize.x
            if armor ~= playerGUI.StoredValues.LastArmor then
                armorBar:SetTexturePixelCoordinates(healthBarTextureSize + regenTextureSize, 0, healthBarTextureSize + regenTextureSize + armorBarTextureSize, kPlayerHealthBarTextureSize.y)
                armorBar:SetSize(Vector(armorBarSize, kPlayerHealthBarSize.y, 0))
                armorBar:SetPosition(Vector(healthBarSize + regenBarSize, 0, 0))
                playerGUI.StoredValues.LastArmor = armor
            end

            -- health change bar
            local healthChangeBar = playerGUI.HealthChangeBar
            local totalFraction = healthFraction+armorFraction
            local prevTotalFraction = playerGUI.StoredValues.TotalFraction
            if prevTotalFraction > totalFraction then

                if not healthChangeBar:GetIsVisible() then
                    healthChangeBar:SetIsVisible(true)
                end

                local changeBarSize = (prevTotalFraction - totalFraction) * kPlayerHealthBarSize.x
                local changeBarTextureSize = (prevTotalFraction - totalFraction) * kPlayerHealthBarTextureSize.x
                healthChangeBar:SetTexturePixelCoordinates(armorBarTextureSize+healthBarTextureSize, 0,  armorBarTextureSize+healthBarTextureSize + changeBarTextureSize, kPlayerHealthBarTextureSize.y)
                healthChangeBar:SetSize(Vector(changeBarSize, kPlayerHealthBarSize.y, 0))
                healthChangeBar:SetPosition(Vector(healthBarSize + armorBarSize, 0, 0))
                playerGUI.StoredValues.TotalFraction = math.max(totalFraction, prevTotalFraction - (deltaTime * kPlayerHealthDrainRate))

            else

                if healthChangeBar:GetIsVisible() then
                    healthChangeBar:SetIsVisible(false)
                end

                playerGUI.StoredValues.TotalFraction = totalFraction

            end

            -- energy / ammo bar
            local energyBG = playerGUI.EnergyBG
            local energyBar = playerGUI.EnergyBar
            local energyFraction = 1.0
            -- Energy bar for aliems
            if player:isa("Alien") then
                energyFraction = player:GetEnergy() / player:GetMaxEnergy()

                -- Ammo bar for marimes
            else
                local activeWeapon = player:GetActiveWeapon()
                if activeWeapon then
                    local ammoColor = self.kAmmoColors[activeWeapon.kMapName] or kEnergyColor
                    if activeWeapon:isa("ClipWeapon") then
                        energyFraction = activeWeapon:GetClip() / activeWeapon:GetClipSize()
                    elseif activeWeapon:isa("ExoWeaponHolder") then
                        local leftWeapon = Shared.GetEntity(activeWeapon.leftWeaponId)
                        local rightWeapon = Shared.GetEntity(activeWeapon.rightWeaponId)
                        -- Exo weapons. Dual wield will just show as the averaged value for now. Maybe 2 bars eventually?
                        if rightWeapon:isa("Railgun") then
                            energyFraction = rightWeapon:GetChargeAmount()
                            if leftWeapon:isa("Railgun") then
                                energyFraction = (energyFraction + leftWeapon:GetChargeAmount()) / 2.0
                            end
                        elseif rightWeapon:isa("Minigun") then
                            energyFraction = rightWeapon.heatAmount
                            if leftWeapon:isa("Minigun") then
                                energyFraction = (energyFraction + leftWeapon.heatAmount) / 2.0
                            end
                            energyFraction = 1 - energyFraction
                        end
                        ammoColor = self.kAmmoColors[rightWeapon.kMapName]
                    end
                    energyBar:SetColor(ammoColor)
                end
            end
            if energyFraction ~= playerGUI.StoredValues.EnergyFraction then
                energyBar:SetTexturePixelCoordinates(0, 0, energyFraction * kEnergyBarTextureSize.x, kEnergyBarTextureSize.y)
                energyBar:SetSize(Vector(kPlayerEnergyBarSize.x * energyFraction, kPlayerEnergyBarSize.y, 0))
                playerGUI.StoredValues.EnergyFraction = energyFraction
            end

        else -- No longer relevant, remove if necessary

            if playerList[playerIndex] then
                self:RemovePlayerGUIItem(playerIndex)
            end

        end

    end

end

function GUIInsight_PlayerHealthbars:CreatePlayerGUIItem()

    -- Reuse an existing healthbar item if there is one.
    local count = table.icount(reusebackgrounds)
    if count > 0 then
        reusebackgrounds[count].Background:SetIsVisible(true)
        return table.remove(reusebackgrounds, count)
    end

    local playerBackground = GUIManager:CreateGraphicItem()
    playerBackground:SetLayer(kGUILayerPlayerNameTags)
    playerBackground:SetColor(Color(0,0,0,0))

    local playerNameItem = GUIManager:CreateTextItem()
    playerNameItem:SetFontName(kFontName)
    playerNameItem:SetScale(kNameFontScale)
    playerNameItem:SetTextAlignmentX(GUIItem.Align_Center)
    playerNameItem:SetTextAlignmentY(GUIItem.Align_Max)
    GUIMakeFontScale(playerNameItem)
    playerBackground:AddChild(playerNameItem)

    local playerHPItem = GUIManager:CreateTextItem()
    playerHPItem:SetFontName(kFontName)
    playerHPItem:SetScale(kNameFontScale)
    playerHPItem:SetTextAlignmentX(GUIItem.Align_Center)
    playerHPItem:SetTextAlignmentY(GUIItem.Align_Max)
    playerBackground:AddChild(playerHPItem)

    local playerHealthBackground = GUIManager:CreateGraphicItem()
    playerHealthBackground:SetSize(Vector(kPlayerHealthBarSize.x, kPlayerHealthBarSize.y, 0))
    playerHealthBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerHealthBackground:SetColor(Color(0,0,0,0.75))
    playerHealthBackground:SetPosition(Vector(-kPlayerHealthBarSize.x/2, 0, 0))
    playerBackground:AddChild(playerHealthBackground)

    local playerHealthBar = GUIManager:CreateGraphicItem()
    playerHealthBar:SetSize(kPlayerHealthBarSize)
    playerHealthBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerHealthBar:SetTexture(kPlayerHealthBarTexture)
    playerHealthBackground:AddChild(playerHealthBar)

    local playerRegenBar = GUIManager:CreateGraphicItem()
    playerRegenBar:SetSize(kPlayerHealthBarSize)
    playerRegenBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerRegenBar:SetTexture(kPlayerHealthBarTexture)
    playerHealthBackground:AddChild(playerRegenBar)

    local playerArmorBar = GUIManager:CreateGraphicItem()
    playerArmorBar:SetSize(kPlayerHealthBarSize)
    playerArmorBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerArmorBar:SetTexture(kPlayerHealthBarTexture)
    playerHealthBackground:AddChild(playerArmorBar)

    local playerHealthChangeBar = GUIManager:CreateGraphicItem()
    playerHealthChangeBar:SetSize(kPlayerHealthBarSize)
    playerHealthChangeBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerHealthChangeBar:SetTexture(kPlayerHealthBarTexture)
    playerHealthChangeBar:SetColor(kHealthDrainColor)
    playerHealthChangeBar:SetIsVisible(false)
    playerHealthBackground:AddChild(playerHealthChangeBar)

    local playerEnergyBackground = GUIManager:CreateGraphicItem()
    playerEnergyBackground:SetSize(kPlayerEnergyBGSize)
    playerEnergyBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerEnergyBackground:SetColor(Color(0,0,0,0.75))
    playerEnergyBackground:SetPosition(Vector(-kPlayerEnergyBGSize.x/2, kPlayerHealthBarSize.y, 0))
    playerBackground:AddChild(playerEnergyBackground)

    local playerEnergyBar = GUIManager:CreateGraphicItem()
    playerEnergyBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerEnergyBar:SetTexture(kEnergyBarTexture)
    playerEnergyBar:SetPosition(kPlayerEnergyBarOffest)
    playerEnergyBackground:AddChild(playerEnergyBar)

    return {
        Background = playerBackground,
        Name = playerNameItem,
        HPText = playerHPItem,
        HealthBar = playerHealthBar,
        RegenBar = playerRegenBar,
        ArmorBar = playerArmorBar,
        HealthChangeBar = playerHealthChangeBar,
        EnergyBG = playerEnergyBackground,
        EnergyBar = playerEnergyBar,
        StoredValues = {
            TotalFraction = -1,
            EnergyFraction = -1,
            LastHealth = 0,
            LastArmor = 0,
            Team = -1,
            Name = "",
            Parasited = false
        }
    }
end

function GUIInsight_PlayerHealthbars:SetGUIItemColor(playerGUI, teamType)
    local textColor = Color(kNameTagFontColors[teamType] or kDefaultColor)
    local healthColor = Color(kTeamHealthColors[teamType] or kDefaultColor)
    local armorColor = Color(kTeamArmorColors[teamType] or kDefaultColor)
    local regenColor = Color(0/255, 255/255, 33/255, 1)

    playerGUI.Name:SetColor(textColor)
    playerGUI.HPText:SetColor(textColor)
    playerGUI.HealthBar:SetColor(healthColor)
    playerGUI.ArmorBar:SetColor(armorColor)
    playerGUI.RegenBar:SetColor(regenColor)

    -- This will be set for marines by the weapon they're using, so we only
    -- need to set it here it for aliens
    if teamType == kAlienTeamType then
        playerGUI.EnergyBar:SetColor(kEnergyColor)
    end
end

function GUIInsight_PlayerHealthbars:RemovePlayerGUIItem(playerIndex)
    local playerGUI = playerList[playerIndex]
    -- already deleted? bad player? Who knows. Should never be hit, in any case.
    if not playerGUI then return end

    -- Store unused elements for later
    playerGUI.Background:SetIsVisible(false)
    table.insert(reusebackgrounds, playerGUI)

    -- reset the stored values to just-created state
    playerGUI.StoredValues = {
        TotalFraction = -1,
        EnergyFraction = -1,
        LastHealth = 0,
        LastArmor = 0,
        Team = -1,
        Name = "",
        Parasited = false
    }

    playerList[playerIndex] = nil
end

function GUIInsight_PlayerHealthbars:SendKeyEvent(key, down)
    if GetIsBinding(key, "Use") and down
            and not ChatUI_EnteringChatMessage() and not MainMenu_GetIsOpened() then

        self.showHpText = not self.showHpText

        return true
    end
end
