


local oldFunc = GUIAlienBuyMenu._InitializeBackground
function GUIAlienBuyMenu:_InitializeBackground()
	oldFunc(self)
	local prowlerXpos = 3
	local vokexXpos = 6
	for k, alienType in ipairs(GUIAlienBuyMenu.kAlienTypes) do

		if alienType.XPos >= prowlerXpos then
			alienType.XPos = alienType.XPos + 1
		end

		--if alienType.XPos >= vokexXpos then
		--	alienType.XPos = alienType.XPos + 1
		--end
	end
	
	table.insert(GUIAlienBuyMenu.kAlienTypes, { LocaleName = "Prowler", Name = "Prowler", Width = GUIScale(240), Height = GUIScale(170), XPos = prowlerXpos, Index = kProwlerTechIdIndex })
	--table.insert(GUIAlienBuyMenu.kAlienTypes, { LocaleName = "Vokex", Name = "Vokex", Width = GUIScale(240), Height = GUIScale(170), XPos = vokexXpos, Index = kVokexTechIdIndex })

	local invisibleCount = 0
	for k, alienType in ipairs(GUIAlienBuyMenu.kAlienTypes) do		--Dude who invented that XPOS STUFF
		alienType.isVisible = AlienBuy_IsAlienVisible(alienType.Index)
		if not alienType.isVisible then
			invisibleCount = invisibleCount + 1
			for _, alienType2 in ipairs(GUIAlienBuyMenu.kAlienTypes) do
				if alienType2.XPos > alienType.XPos then
					alienType2.XPos = alienType2.XPos - 1
				end
			end
		end
	end

	for _, alienType in ipairs(GUIAlienBuyMenu.kAlienTypes) do
		alienType.XPos = alienType.XPos + invisibleCount / 2.0
	end
end

function GUIAlienBuyMenu:_UpdateAlienButtons()

	local numAlienTypes = self:_GetNumberOfAliensAvailable()
	local totalAlienButtonsWidth = GUIAlienBuyMenu.kAlienButtonSize * numAlienTypes

	local mouseX, mouseY = Client.GetCursorPosScreen()
	for k, alienButton in ipairs(self.alienButtons) do

		-- Info needed for the rest of this code.
		local researched, researchProgress, researching = self:_GetAlienTypeResearchInfo(alienButton.TypeData.Index)

		local buttonIsVisible = researched or researching
		buttonIsVisible = buttonIsVisible and alienButton.TypeData.isVisible
		
		alienButton.Button:SetIsVisible(buttonIsVisible)

		-- Don't bother updating anything else unless it is visible.
		if buttonIsVisible then
		
			local isCurrentAlien = AlienBuy_GetCurrentAlien() == alienButton.TypeData.Index
			if researched and (isCurrentAlien or self:_GetCanAffordAlienType(alienButton.TypeData.Index)) then
				alienButton.Button:SetColor(GUIAlienBuyMenu.kEnabledColor)
			elseif researched and not self:_GetCanAffordAlienType(alienButton.TypeData.Index) then
				alienButton.Button:SetColor(GUIAlienBuyMenu.kCannotBuyColor)
			elseif researching then
				alienButton.Button:SetColor(GUIAlienBuyMenu.kDisabledColor)
			end

			local mouseOver = self:_GetIsMouseOver(alienButton.Button)

			if mouseOver then

				local classStats = AlienBuy_GetClassStats(GUIAlienBuyMenu.kAlienTypes[alienButton.TypeData.Index].Index)
				local mouseOverName = GUIAlienBuyMenu.kAlienTypes[alienButton.TypeData.Index].LocaleName
				local health = classStats[2]
				local armor = classStats[3]
				self:_ShowMouseOverInfo(mouseOverName, GetTooltipInfoText(IndexToAlienTechId(alienButton.TypeData.Index)), classStats[4], health, armor)

			end

			-- Only show the background if the mouse is over this button.
			alienButton.SelectedBackground:SetColor(Color(1, 1, 1, ((mouseOver and 1) or 0)))

			local offset = Vector((((alienButton.TypeData.XPos - 1) / numAlienTypes) * (GUIAlienBuyMenu.kAlienButtonSize * numAlienTypes)) - (totalAlienButtonsWidth / 2), 0, 0)
			alienButton.SelectedBackground:SetPosition(Vector(-GUIAlienBuyMenu.kAlienButtonSize / 2, -GUIAlienBuyMenu.kAlienSelectedButtonSize / 2 - alienButton.ARAdjustedHeight / 2, 0) + offset)

			alienButton.PlayersText:SetText("x" .. ToString(ScoreboardUI_GetNumberOfAliensByType(alienButton.TypeData.Name)))

			alienButton.ResearchText:SetIsVisible(researching)
			if researching then
				alienButton.ResearchText:SetText(string.format("%d%%", researchProgress * 100))
			end

		end

	end

end