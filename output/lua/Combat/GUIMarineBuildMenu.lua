Script.Load("lua/GUIAnimatedScript.lua")

local kMouseOverSound = "sound/NS2.fev/common/hovar"
local kSelectSound = "sound/NS2.fev/common/open"
local kCloseSound = "sound/NS2.fev/common/tooltip"
local kFontName = Fonts.kAgencyFB_Small
Client.PrecacheLocalSound(kMouseOverSound)
Client.PrecacheLocalSound(kSelectSound)
Client.PrecacheLocalSound(kCloseSound)

function MarineBuild_OnClose()
    Shared.PlaySound(nil, kCloseSound)
end

function MarineBuild_OnSelect()
    Shared.PlaySound(nil, kSelectSound)
end

function MarineBuild_OnMouseOver()
    --Shared.PlaySound(nil, kMouseOverSound)
end

function MarineBuild_Close()

    local player = Client.GetLocalPlayer()
    local dropStructureAbility = player:GetWeapon(CombatBuilder.kMapName)

    if dropStructureAbility then
        dropStructureAbility:DestroyBuildMenu()
    end

end

function MarineBuild_SendSelect(index)

    local player = Client.GetLocalPlayer()

    if player then
    
        local dropStructureAbility = player:GetWeapon(CombatBuilder.kMapName)
        if dropStructureAbility then
            dropStructureAbility:SetActiveStructure(index)
        end
        
    end
    
end

function MarineBuild_GetIsAbilityAvailable(index)

    return CombatBuilder.kSupportedStructures[index] and CombatBuilder.kSupportedStructures[index]:IsAllowed(Client.GetLocalPlayer())

end

function MarineBuild_AllowConsumeDrop(techId)
    return LookupTechData(techId, kTechDataAllowConsumeDrop, false)
end

function MarineBuild_GetCanAffordAbility(techId)

    local player = Client.GetLocalPlayer()
    -- local abilityCost = LookupTechData(techId, kTechDataCostKey, 0)
    local exceededLimit = not MarineBuild_AllowConsumeDrop(techId) and MarineBuild_GetNumStructureBuilt(techId) >= MarineBuild_GetMaxNumStructure(techId)

    return Shared.GetCheatsEnabled() or not exceededLimit

end

function MarineBuild_GetStructureCost(techId)
    return LookupTechData(techId, kTechDataCostKey, 0)
end

local function MarineBuild_GetKeybindForIndex(index)
    return "Weapon" .. ToString(index)
end

function MarineBuild_GetNumStructureBuilt(techId)

    local player = Client.GetLocalPlayer()
    local weapon = player:GetActiveWeapon()
    
    if weapon and weapon:isa("CombatBuilder") then
        return weapon:GetNumStructuresBuilt(techId)
    end
    
    return -1

end

function MarineBuild_GetMaxNumStructure(techId)

    return LookupTechData(techId, kTechDataMaxAmount, -1)

end

class 'GUIMarineBuildMenu' (GUIAnimatedScript)

GUIMarineBuildMenu.kBaseYResolution = 1200

GUIMarineBuildMenu.kButtonWidth = 180
GUIMarineBuildMenu.kButtonHeight = 180

GUIMarineBuildMenu.kBackgroundYOffset = GUIMarineBuildMenu.kButtonHeight * 0.5

GUIMarineBuildMenu.kButtonTexture = "ui/Combat/BuildMenu/marine_build_menu.dds"
GUIMarineBuildMenu.kBuyMenuTexture = "ui/alien_buymenu.dds"
GUIMarineBuildMenu.kSmokeSmallTextureCoordinates = { { 916, 4, 1020, 108 }, { 916, 15, 1020, 219 }, { 916, 227, 1020, 332 }, { 916, 332, 1020, 436 } }

GUIMarineBuildMenu.kPixelSize = 128

GUIMarineBuildMenu.kAvailableColor = kMarineTeamColorFloat
GUIMarineBuildMenu.kTooExpensiveColor = Color(1, 0, 0, 1)
GUIMarineBuildMenu.kUnavailableColor = Color(0.4, 0.4, 0.4, 0.7)

-- selection circle animation:
GUIMarineBuildMenu.kPulseInAnimationDuration = 0.6
GUIMarineBuildMenu.kPulseOutAnimationDuration = 0.3
GUIMarineBuildMenu.kLowColor = Color(1, 0.4, 0.4, 0.5)
GUIMarineBuildMenu.kHighColor = Color(1, 1, 1, 1)

GUIMarineBuildMenu.kPersonalResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 144, Y1 = 363, X2 = 192, Y2 = 411} }
GUIMarineBuildMenu.kPersonalResourceIcon.Width = 32
GUIMarineBuildMenu.kPersonalResourceIcon.Height = 32
GUIMarineBuildMenu.kResourceTexture = "ui/alien_commander_textures.dds"
GUIMarineBuildMenu.kIconTextXOffset = 5

local kBackgroundNoiseTexture = "ui/alien_commander_bg_smoke.dds"
local kSmokeyBackgroundSize = GUIScale(Vector(220, 400, 0))

local kDefaultStructureCountPos = Vector(-48, -24, 0)
local kCenteredStructureCountPos = Vector(0, -24, 0)

--selection circle animation callbacks
function PulseOutAnimation(script, item)
    item:SetColor(GUIMarineBuildMenu.kHighColor, GUIMarineBuildMenu.kPulseInAnimationDuration, "PULSE", AnimateLinear, PulseInAnimation)
end

function PulseInAnimation(script, item)
    item:SetColor(GUIMarineBuildMenu.kLowColor, GUIMarineBuildMenu.kPulseOutAnimationDuration, "PULSE", AnimateLinear, PulseOutAnimation)
end

local rowTable = nil
local function GetRowForTechId(techId)

    if not rowTable then
    
        rowTable = {}
        rowTable[kTechId.Sentry] = 1
        rowTable[kTechId.WeaponCache] = 2
		rowTable[kTechId.Observatory] = 3
		rowTable[kTechId.PhaseGate] = 4
    
    end
    
    return rowTable[techId]

end

function GUIMarineBuildMenu:Initialize()

    GUIAnimatedScript.Initialize(self)

    self.scale = Client.GetScreenHeight() / GUIMarineBuildMenu.kBaseYResolution
    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetColor(Color(0,0,0,0))
    
    self.buttons = {}
    
    self:Reset()

end

function GUIMarineBuildMenu:Uninitialize()
    
    GUIAnimatedScript.Uninitialize(self)

end

function GUIMarineBuildMenu:GetIsVisible()
    return self.background:GetIsVisible()
end

function GUIMarineBuildMenu:SetIsVisible(isVisible)
    self.background:SetIsVisible(isVisible == true)
end

function GUIMarineBuildMenu:_HandleMouseOver(onItem)
    
    if onItem ~= self.lastActiveItem then
        MarineBuild_OnMouseOver()
        self.lastActiveItem = onItem
    end
    
end

local function UpdateButton(button, index)

    local col = 1
    local color = GUIMarineBuildMenu.kAvailableColor

    if not MarineBuild_GetCanAffordAbility(button.techId) then
        col = 2
        color = GUIMarineBuildMenu.kTooExpensiveColor
    end
    
    if not MarineBuild_GetIsAbilityAvailable(index) then
        col = 2
        color = GUIMarineBuildMenu.kUnavailableColor
    end
    
    local row = GetRowForTechId(button.techId)
   
    local spriteRow = math.min(row, 4)
    button.graphicItem:SetTexturePixelCoordinates(GUIGetSprite(col, spriteRow, GUIMarineBuildMenu.kPixelSize, GUIMarineBuildMenu.kPixelSize))
    button.description:SetColor(color)
    -- button.costIcon:SetColor(color)
    -- button.costText:SetColor(color)

    local numLeft = MarineBuild_GetNumStructureBuilt(button.techId)
    -- if numLeft == -1 then
        -- button.structuresLeft:SetIsVisible(false)
    -- else
        button.structuresLeft:SetIsVisible(true)
        local amountString = ToString(numLeft)
        local maxNum = MarineBuild_GetMaxNumStructure(button.techId)
        
        if maxNum > 0 then
            amountString = amountString .. "/" .. ToString(maxNum)
        end
        
        if numLeft >= maxNum then
            color = GUIMarineBuildMenu.kTooExpensiveColor
        end
        
        button.structuresLeft:SetColor(color)
        button.structuresLeft:SetText(amountString)
        
    -- end    
    
    -- local cost = MarineBuild_GetStructureCost(button.techId)
    -- if cost == 0 then        
    
        -- button.costIcon:SetIsVisible(false)
        button.structuresLeft:SetPosition(kCenteredStructureCountPos)
        
    -- else
    
        -- button.costIcon:SetIsVisible(true)
        -- button.costText:SetText(ToString(cost))
        -- button.structuresLeft:SetPosition(kDefaultStructureCountPos)
        
        
    -- end
    
    
end



function GUIMarineBuildMenu:Update(deltaTime)

    GUIAnimatedScript.Update(self, deltaTime)
    
    for index, button in ipairs(self.buttons) do
        
        UpdateButton(button, index)
        
        if self:_GetIsMouseOver(button.graphicItem) then
            self:_HandleMouseOver(button.graphicItem)
        end
       
    end

end

function GUIMarineBuildMenu:Reset()
    
    self.background:SetUniformScale(self.scale)

    for index, structureAbility in ipairs(CombatBuilder.kSupportedStructures) do
    
        -- TODO: pass keybind from options instead of index
        table.insert( self.buttons, self:CreateButton(structureAbility.GetDropStructureId(), self.scale, self.background, MarineBuild_GetKeybindForIndex(index), index - 1) )
    
    end
    
    local backgroundXOffset = (#self.buttons * GUIMarineBuildMenu.kButtonWidth) * -.5
    self.background:SetPosition(Vector(backgroundXOffset, GUIMarineBuildMenu.kBackgroundYOffset, 0))
    
end

function GUIMarineBuildMenu:OnResolutionChanged(oldX, oldY, newX, newY)

    self.scale = newY / GUIMarineBuildMenu.kBaseYResolution
    self:Reset()

end

function GUIMarineBuildMenu:CreateButton(techId, scale, frame, keybind, position)

    local button =
    {
        frame = self:CreateAnimatedGraphicItem(),
        background = self:CreateAnimatedGraphicItem(),
        graphicItem = self:CreateAnimatedGraphicItem(),
        description = self:CreateAnimatedTextItem(),
        keyIcon = GUICreateButtonIcon(keybind, false),
        keybind = keybind,
        techId = techId,
        structuresLeft = self:CreateAnimatedTextItem(),
        -- costIcon = self:CreateAnimatedGraphicItem(),
        -- costText = self:CreateAnimatedTextItem(),
    }
    
    button.frame:SetUniformScale(scale)
    button.frame:SetSize(Vector(GUIMarineBuildMenu.kButtonWidth, GUIMarineBuildMenu.kButtonHeight, 0))
    button.frame:SetColor(Color(1,1,1,0))
    button.frame:SetPosition(Vector(position * GUIMarineBuildMenu.kButtonWidth, 0, 0))
    frame:AddChild(button.frame)
    
    button.background:SetUniformScale(scale)
    button.graphicItem:SetUniformScale(scale)    
    button.frame:AddChild(button.background)
    
    button.description:SetUniformScale(scale) 
    
    button.background:SetSize(Vector(GUIMarineBuildMenu.kButtonWidth, GUIMarineBuildMenu.kButtonHeight * 1.5, 0))
    button.background:SetColor(Color(0,0,0,0))
    
    button.graphicItem:SetSize(Vector(GUIMarineBuildMenu.kButtonWidth, GUIMarineBuildMenu.kButtonHeight, 0))
    button.graphicItem:SetTexture(GUIMarineBuildMenu.kButtonTexture)
     
    --button.description:SetText(LookupTechData(techId, kTechDataDisplayName, "") .. " (".. keybind ..")")
    button.description:SetText(Locale.ResolveString(LookupTechData(techId, kTechDataDisplayName, "")))
    button.description:SetAnchor(GUIItem.Middle, GUIItem.Top)
    button.description:SetTextAlignmentX(GUIItem.Align_Center)
    button.description:SetTextAlignmentY(GUIItem.Align_Center)
    button.description:SetFontSize(22)
    button.description:SetFontName(kFontName)
    button.description:SetPosition(Vector(0, 0, 0))
    button.description:SetFontIsBold(true)
    
    button.keyIcon:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    button.keyIcon:SetFontName(kFontName)
    local pos = Vector(-button.keyIcon:GetSize().x/2, 0.5*button.keyIcon:GetSize().y, 0)
    button.keyIcon:SetPosition(pos)
    
    button.structuresLeft:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    button.structuresLeft:SetTextAlignmentX(GUIItem.Align_Center)
    button.structuresLeft:SetTextAlignmentY(GUIItem.Align_Center)
    button.structuresLeft:SetFontSize(28)
    button.structuresLeft:SetFontName(kFontName)
    button.structuresLeft:SetPosition(kDefaultStructureCountPos)
    button.structuresLeft:SetFontIsBold(true)
    button.structuresLeft:SetColor(GUIMarineBuildMenu.kAvailableColor)
    
    -- Personal display.
    -- button.costIcon:SetSize(Vector(GUIMarineBuildMenu.kPersonalResourceIcon.Width, GUIMarineBuildMenu.kPersonalResourceIcon.Height, 0))
    -- button.costIcon:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    -- button.costIcon:SetTexture(GUIMarineBuildMenu.kResourceTexture)
    -- button.costIcon:SetPosition(Vector(0, -GUIMarineBuildMenu.kPersonalResourceIcon.Height * .5 - 24, 0))
    -- button.costIcon:SetUniformScale(scale)
    -- GUISetTextureCoordinatesTable(button.costIcon, GUIMarineBuildMenu.kPersonalResourceIcon.Coords)

    -- button.costText:SetUniformScale(scale)
    -- button.costText:SetAnchor(GUIItem.Right, GUIItem.Center)
    -- button.costText:SetTextAlignmentX(GUIItem.Align_Min)
    -- button.costText:SetTextAlignmentY(GUIItem.Align_Center)
    -- button.costText:SetPosition(Vector(GUIMarineBuildMenu.kIconTextXOffset, 0, 0))
    -- button.costText:SetColor(Color(1, 1, 1, 1))
    -- button.costText:SetFontIsBold(true)    
    -- button.costText:SetFontSize(28)
    -- button.costText:SetFontName(kFontName)
    -- button.costText:SetColor(GUIMarineBuildMenu.kAvailableColor)
    -- button.costIcon:AddChild(button.costText)
    
    button.background:AddChild(button.graphicItem)    
    button.graphicItem:AddChild(button.description)
    button.graphicItem:AddChild(button.structuresLeft)
    button.graphicItem:AddChild(button.keyIcon)   
    -- button.graphicItem:AddChild(button.costIcon)

    return button

end

function GUIMarineBuildMenu:OverrideInput(input)

    -- Assume the user wants to switch the top-level weapons
    if HasMoveCommand( input.commands, Move.SelectNextWeapon )
    or HasMoveCommand( input.commands, Move.SelectPrevWeapon ) then

        MarineBuild_OnClose()
        MarineBuild_Close()
        return input

    end

    local weaponSwitchCommands = { Move.Weapon1, Move.Weapon2, Move.Weapon3, Move.Weapon4, Move.Weapon5 }

    local selectPressed = false

    for index, weaponSwitchCommand in ipairs(weaponSwitchCommands) do
    
        if HasMoveCommand( input.commands, weaponSwitchCommand ) then

            if MarineBuild_GetIsAbilityAvailable(index) and MarineBuild_GetCanAffordAbility(self.buttons[index].techId)  then

                MarineBuild_SendSelect(index)
                input.commands = RemoveMoveCommand( input.commands, weaponSwitchCommand )

            end
            
            selectPressed = true
            break
            
        end
        
    end  
    
    if selectPressed then

        MarineBuild_OnClose()
        MarineBuild_Close()

    elseif HasMoveCommand( input.commands, Move.SecondaryAttack )
        or HasMoveCommand( input.commands, Move.PrimaryAttack ) then

        --DebugPrint("before override: %d",input.commands)

        -- close menu
        MarineBuild_OnClose()
        MarineBuild_Close()

        -- leave the secondary attack command so the drop-ability can handle it
        input.commands = AddMoveCommand( input.commands, Move.SecondaryAttack )
        input.commands = RemoveMoveCommand( input.commands, Move.PrimaryAttack )
        //DebugPrint("after override: %d",input.commands)
        //DebugPrint("primary = %d secondary = %d", Move.PrimaryAttack, Move.SecondaryAttack)

    end

    return input, selectPressed

end

function GUIMarineBuildMenu:_GetIsMouseOver(overItem)

    return GUIItemContainsPoint(overItem, Client.GetCursorPosScreen())
    
end

function GUIMarineBuildMenu:OnAnimationCompleted(animatedItem, animationName, itemHandle)
end

-- called when the last animation remaining has completed this frame
function GUIMarineBuildMenu:OnAnimationsEnd(item)
end
