
local kNotEnoughEnergyColor = Color(0.6, 0, 0, 1)

local baseInitialize = GUIAlienHUD.Initialize
function GUIAlienHUD:Initialize()
    baseInitialize(self)
    self.nutrientMist = GUIUtility_CreateRequestIcon(kTechId.NutrientMist,Vector(- 62, -36, 0),kAlienTeamType)
    self.resourceDisplay.background:AddChild(self.nutrientMist)
end

local baseUpdate = GUIAlienHUD.Update
function GUIAlienHUD:Update(deltaTime)
    baseUpdate(self,deltaTime)

    local player = Client.GetLocalPlayer()
    local nutrientMist = player.timeLastPrimaryRequestHandle ~= nil
    if nutrientMist then
        local color = kIconColors[kAlienTeamType]
        percentage = math.Clamp(1 - (player.timeLastPrimaryRequestHandle - Shared.GetTime())/kAutoMistCooldown,0,1)
        local mist = color * (percentage * percentage)
        mist.a = percentage >= 1 and 1 or 0.5
        percentage = percentage * percentage
        self.nutrientMist:SetColor(mist)
    end
    
    self.nutrientMist:SetIsVisible(nutrientMist)
end


function GUIAlienHUD:UpdateAbilities(deltaTime)

    local activeHudSlot = 0

    local abilityData = PlayerUI_GetAbilityData()
    local currentIndex = 1

    if table.icount(abilityData) > 0 then

        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        local techId = abilityData[currentIndex + 2]
        local visibility = abilityData[currentIndex + 3]
        activeHudSlot = abilityData[currentIndex + 4]
        local cooldown = abilityData[currentIndex + 5] or 0


        local x1, y1, x2, y2 = GetTexCoordsForTechId(techId)

        self.activeAbilityIcon:SetIsVisible(true)
        self.activeAbilityIcon:SetTexturePixelCoordinates(x1,y1,x2,y2)

        if cooldown > 0 then
            local offset = kInventoryIconTextureHeight * ( 0.925 - 0.925 * cooldown ) -- [1,0] -> [0, 0.95]
            self.activeAbilityCooldownIcon:SetIsVisible(true)
            self.activeAbilityCooldownIcon:SetSize(Vector(GUIScale(kInventoryIconTextureWidth*0.75), GUIScale(( kInventoryIconTextureHeight - offset )*0.75), 0))
            self.activeAbilityCooldownIcon:SetTexturePixelCoordinates(x1,y1,x2,y2 - offset)
        else
            self.activeAbilityCooldownIcon:SetIsVisible(false)
        end


        local setColor = kNotEnoughEnergyColor

        if totalPower >= minimumPower then
            setColor = Color(1, 1, 1, 1)
        end

        local currentBackgroundColor = self.energyBall:GetBackground():GetColor()
        currentBackgroundColor.r = setColor.r
        currentBackgroundColor.g = setColor.g
        currentBackgroundColor.b = setColor.b

        self.energyBall:GetBackground():SetColor(currentBackgroundColor)
        self.activeAbilityIcon:SetColor(setColor)
        self.energyBall:GetLeftSide():SetColor(setColor)
        self.energyBall:GetRightSide():SetColor(setColor)

    else
        self.activeAbilityIcon:SetIsVisible(false)
    end

    -- The the player changed abilities, force show the energy ball and
    -- the inactive abilities bar.
    if activeHudSlot ~= self.lastActiveHudSlot then

        self.energyBall:GetBackground():SetIsVisible(true)
        self:ForceUnfade(self.energyBall:GetBackground())
        --[[
        for i, ability in ipairs(self.inactiveAbilityIconList) do
            self:ForceUnfade(ability.Background)
        end
        --]]

    end

    self.lastActiveHudSlot = activeHudSlot

    local player = Client.GetLocalPlayer()
    local gorgeBuiltTextVisible = false
    if player and player:isa("Gorge") and GUIGorgeBuildMenu then

        local activeWeapon = player:GetActiveWeapon()
        if activeWeapon and activeWeapon:isa("DropStructureAbility") then

            local structure = activeWeapon:GetActiveStructure()
            local structureId = structure and structure:GetDropStructureId() or -1
            gorgeBuiltTextVisible = structureId ~= -1

            if gorgeBuiltTextVisible then
                local text,scale = activeWeapon:GetHUDText(structureId)
                self.gorgeBuiltText:SetText(text)
                self.gorgeBuiltText:SetScale(GetScaledVector() * scale)
                self.gorgeBuiltText:SetColor(GorgeBuild_GetCanAffordAbility(structureId) and kAlienFontColor or kRed)
            end

        end

    end

    self.gorgeBuiltText:SetIsVisible(gorgeBuiltTextVisible)
    self.activeAbilityIcon:SetIsVisible(not gorgeBuiltTextVisible)

    -- Secondary ability.
    abilityData = PlayerUI_GetSecondaryAbilityData()
    currentIndex = 1
    if table.icount(abilityData) > 0 then

        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        local techId = abilityData[currentIndex + 2]
        local visibility = abilityData[currentIndex + 3]
        local hudSlot = abilityData[currentIndex + 4]

        if techId ~= kTechId.None then
            self.secondaryAbilityBackground:SetIsVisible(self.visible)
            self.secondaryAbilityIcon:SetTexturePixelCoordinates(GetTexCoordsForTechId(techId))
        else
            self.secondaryAbilityBackground:SetIsVisible(false)
        end

        if totalPower < minimumPower then

            self.secondaryAbilityIcon:SetColor(kNotEnoughEnergyColor)
            self.secondaryAbilityBackground:SetColor(kNotEnoughEnergyColor)

        else

            local enoughEnergyColor = Color(1, 1, 1, 1)
            self.secondaryAbilityIcon:SetColor(enoughEnergyColor)
            self.secondaryAbilityBackground:SetColor(enoughEnergyColor)

        end

    else
        self.secondaryAbilityBackground:SetIsVisible(false)
    end

    -- self:UpdateInactiveAbilities(deltaTime, activeHudSlot)

end