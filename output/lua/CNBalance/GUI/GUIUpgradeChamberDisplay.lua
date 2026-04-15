-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/GUIUpgradeChamberDisplay.lua
--
-- Shows how many shells, spurs, veils you have
--
-- Created by Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Globals.lua")
Script.Load("lua/GUIScript.lua")
Script.Load("lua/Hud/Alien/GUIAlienHUDStyle.lua")

class 'GUIUpgradeChamberDisplay' (GUIScript)

local kMinBioMass = 0
local kMaxBioMass = 9

local kBackgroundPos
local kBackgroundColor = Color(0, 0, 0, 0)

local kIconSize
local kIconTexture = "ui/buildmenu.dds"

local kIconOffset
local kIconColor = Color( 1, 190/255, 50/255, 1 ) --kIconColors[kAlienTeamType]

local kUpgradeLevelFunc =
{
    "GetSpurLevel",
    "GetVeilLevel",
    "GetShellLevel",
}

-- first entry is tech id to use if the player has none of the upgrades in the list
local kIndexToUpgrades =
{
    { kTechId.Spur, kTechId.Crush, kTechId.Celerity, kTechId.Adrenaline , kTechId.Silence},
    { kTechId.Veil, kTechId.Camouflage, kTechId.Aura, kTechId.Focus },
    { kTechId.Shell, kTechId.Vampirism, kTechId.Carapace, kTechId.Regeneration ,kTechId.Condense},
}

local function CreateUpgradeIcon()

    local icon = GetGUIManager():CreateGraphicItem()
    icon:SetSize(Vector(kIconSize, kIconSize, 0))
    icon:SetTexture(kIconTexture)
    icon:SetPosition(kIconOffset)
    icon:SetColor(kIconColor)
    
    return icon

end

local function CreateIcons( background )

    local icons = {}

    for type = 1, 3 do

        local category = {}

        local upgradeLevelOne = CreateUpgradeIcon()
        background:AddChild(upgradeLevelOne)        
        table.insert(category, upgradeLevelOne)
        
        upgradeLevelTwo = CreateUpgradeIcon()
        upgradeLevelOne:AddChild(upgradeLevelTwo)
        table.insert(category, upgradeLevelTwo)
        
        upgradeLevelThree = CreateUpgradeIcon()
        upgradeLevelTwo:AddChild(upgradeLevelThree)
        table.insert(category, upgradeLevelThree)
        
        upgradeLevelOne:SetPosition( Vector(0, (type - 1) * ( kIconSize * 0.75 ), 0) )
        
        table.insert(icons, category)
    
    end
    
    return icons

end

function GUIUpgradeChamberDisplay:Initialize()

    kIconSize = GUIScale(48)
    kIconOffset = GUIScale(Vector( 18, 2, 0 ))

    local hudBarsOffset = ConditionalValue(GetAdvancedOption("hudbars_a") == 2, 115, 0)
    kBackgroundPos = Vector(-((kIconOffset.x * 3) + kIconSize - GUIScale(15)), GUIScale(450 - hudBarsOffset), 0 )

    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetAnchor( GUIItem.Right, GUIItem.Top )
    self.background:SetPosition( kBackgroundPos )
    self.background:SetColor( kBackgroundColor )

    self.upgradeIcons = CreateIcons( self.background )
    
    self:SetIsVisible(not HelpScreen_GetHelpScreen():GetIsBeingDisplayed())

end

function GUIUpgradeChamberDisplay:SetIsVisible(state)
    
    self.visible = state
    self.background:SetIsVisible(state)
    
end

function GUIUpgradeChamberDisplay:GetIsVisible(state)
    
    return self.visible
    
end

function GUIUpgradeChamberDisplay:Uninitialize()

    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end

end

function GUIUpgradeChamberDisplay:OnResolutionChanged(oldX, oldY, newX, newY)
    self:Uninitialize()
    self:Initialize()
end

local function GetTechIdToUse(playerUpgrades, categoryUpgrades)

    for i = 1, #categoryUpgrades do
    
        if table.icontains(playerUpgrades, categoryUpgrades[i]) then
            return categoryUpgrades[i], true
        end
    
    end
    
    return categoryUpgrades[1], false

end

function GUIUpgradeChamberDisplay:Update(deltaTime)

    PROFILE("GUIUpgradeChamberDisplay:Update")

    local player = Client.GetLocalPlayer()
    if player then

        local upgrades = player:GetUpgrades()

        for i = 1, 3 do
        
            local levelFuncName = kUpgradeLevelFunc[i]
            local playerUpgradeLevel, teamUpgradeLevel = player[levelFuncName](player)
            local techId, upgraded = GetTechIdToUse(upgrades, kIndexToUpgrades[i])
            local alpha = (upgraded or player:isa("Commander")) and 1 or (0.25 + (1 + math.sin(Shared.GetTime() * 5)) * 0.5) * 0.75

            local numIconsPerCategory = 3
            for upgradeLevel = 1, numIconsPerCategory do

                if teamUpgradeLevel == 0 then
                
                    self.upgradeIcons[i][upgradeLevel]:SetIsVisible(false)
                    break
                
                else
                    local color = Color(kIconColor.r, kIconColor.g, kIconColor.b, alpha)
                    if teamUpgradeLevel < upgradeLevel then
                        
                        color.r = 0
                        color.g = 0
                        color.b = 0
                        color.a = 1
                        
                    elseif playerUpgradeLevel < upgradeLevel then
                        color.a = 0.5
                        if upgradeLevel - playerUpgradeLevel == 1 then
                            color.a = (0.5 + (1 + math.sin(Shared.GetTime() * 5)) * 0.5) * 0.5
                        end
                    end

                    -- Flip texture on x axis since these were originally meant to be on the left.
                    local texCoords = GetTextureCoordinatesForIcon(techId)

                    self.upgradeIcons[i][upgradeLevel]:SetTexturePixelCoordinates(GUIUnpackCoords(texCoords))
                    self.upgradeIcons[i][upgradeLevel]:SetColor(color)
                    self.upgradeIcons[i][upgradeLevel]:SetIsVisible(true)
                    
                end    
                
            end
            
        end
    
    end

end