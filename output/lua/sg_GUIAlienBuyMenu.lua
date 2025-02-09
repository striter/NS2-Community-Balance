--将牛的数量限制在队伍规模（打手）的0.4(取整)
--牛的索引是4
local kOnosIndex = 4

local old_UpdateAlienButtons = GUIAlienBuyMenu._UpdateAlienButtons
function GUIAlienBuyMenu:_UpdateAlienButtons()
    old_UpdateAlienButtons(self)
    
    --for k, alienButton in ipairs(self.alienButtons) do
    
    -- if alienButtons.alienType.Name == "Onos" then
    --     -- Info needed for the rest of this code.
    --     local researched, researchProgress, researching = self:_GetAlienTypeResearchInfo(alienButton.TypeData.Index)

    --     local buttonIsVisible = researched or researching
        
    --     if buttonIsVisible then
    --         local hardCap = self:_GetAlienTypeHardCap(alienButton.TypeData.Index)
    --         if (hardCap and hardCap ~= 0) then
    --             alienButton.PlayersText:SetText(ToString(ScoreboardUI_GetNumberOfAliensByType(alienButton.TypeData.Name)) .. "/" .. hardCap)
    --         end
    --     end
      
    -- end
    --end
end
--设置最大可以购买异形数量
function GUIAlienBuyMenu:_GetAlienTypeHardCap(idx)

    local cap = 1
    local player = Client.GetLocalPlayer()
    local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
    local playerCount = teamInfo:GetPlayerCount()
    
    local upgrade = self:SG_AlienBuy_GetTechIdForAlien(idx)
    if (upgrade and self:_GetHardCapScale() and self:_GetHardCapScale() ~= 0) then
        cap = self:_GetHardCapScale()
    end
    return math.ceil(cap * playerCount)
end


--获取异形队伍打手数量
function GUIAlienBuyMenu:_GetHardCapScale()
    local player = Client.GetLocalPlayer()
    local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
    local scale = (teamInfo:GetPlayerCount() - 1)*0.4
    return scale
end

--将索引数字转换为techId
--1.fade 2.gorge 3.lerk 4.Onos 5.skulk
function GUIAlienBuyMenu:SG_AlienBuy_GetTechIdForAlien(idx)

    return IndexToAlienTechId(idx)

end



--设置是否可以继续购买牛
--local old_SendKeyEvent = GUIAlienBuyMenu.SendKeyEvent
function GUIAlienBuyMenu:SendKeyEvent(key, down)

    --old_SendKeyEvent(self)

    local closeMenu = false
    local inputHandled = false
    
    if key == InputKey.MouseButton0 and self.mousePressed ~= down then
    
        self.mousePressed = down
        
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if down then
        
            -- Check if the evolve button was selected.
            local allowedToEvolve = GetCanAffordAlienTypeAndUpgrades(self, self.selectedAlienType)
            allowedToEvolve = allowedToEvolve and GetAlienOrUpgradeSelected(self)
            if allowedToEvolve and self:_GetIsMouseOver(self.evolveButtonBackground) then
            
                local purchases = { }
                -- Buy the selected alien if we have a different one selected.
                
                if self.selectedAlienType ~= AlienBuy_GetCurrentAlien() then
                    if AlienBuy_GetCurrentAlien() == AlienTechIdToIndex(kTechId.Skulk)  then
                        -- only buy another class when youre a skulk
                        table.insert(purchases, AlienBuy_GetTechIdForAlien(self.selectedAlienType))
                    end
                end

                -- Buy all selected upgrades.
                for i, currentButton in ipairs(self.upgradeButtons) do

                    if currentButton.Selected then
                        table.insert(purchases, currentButton.TechId ) -- Combat uses only the techIds !!!
                    end

                end
                
                closeMenu = true
                inputHandled = true

                if #purchases > 0 then
                    AlienBuy_Purchase(purchases)
                end
                
                AlienBuy_OnPurchase()
                
            end
            
            inputHandled = self:_HandleUpgradeClicked(mouseX, mouseY) or inputHandled
            
            if not inputHandled then
            
                -- Check if an alien was selected.
                for k, buttonItem in ipairs(self.alienButtons) do
                    
                    local researched, researchProgress, researching = self:_GetAlienTypeResearchInfo(buttonItem.TypeData.Index)
                    --判断牛是否达到了最大购买数量
                    if self.selectedAlienType == kOnosIndex then
                        if (researched or researching) and self:_GetIsMouseOver(buttonItem.Button) and 
                        ScoreboardUI_GetNumberOfAliensByType(buttonItem.TypeData.Name) <  self:SG_GetAlienTypeHardCap(buttonItem.TypeData.Index)  then
                            
                           
                            -- Deselect all upgrades when a different alien type is selected.
                            if self.selectedAlienType ~= buttonItem.TypeData.Index  then
                                AlienBuy_OnSelectAlien(GUIAlienBuyMenu.kAlienTypes[buttonItem.TypeData.Index].Name)
                            end
                                
                            self.selectedAlienType = buttonItem.TypeData.Index
                            inputHandled = true
                            break
        
                        end
                    else
                        -- Deselect all upgrades when a different alien type is selected.
                        if (researched or researching) and self:_GetIsMouseOver(buttonItem.Button) then

                            -- Deselect all upgrades when a different alien type is selected.
                            if self.selectedAlienType ~= buttonItem.TypeData.Index then
    
                                AlienBuy_OnSelectAlien(GUIAlienBuyMenu.kAlienTypes[buttonItem.TypeData.Index].Name)
    
                            end
    
                            self.selectedAlienType = buttonItem.TypeData.Index
                            MarkAlreadyPurchased( self )
                            self:SetPurchasedSelected()
    
                            inputHandled = true
                            break
    
                        end
                    end
                    
                end

                if self:_GetIsMouseOver(self.refundButtonBackground) then
                    ClickRefundButton(self)
                    closeMenu = true
                    inputHandled = true
                    AlienBuy_OnClose()
                end
                
                -- Check if the close button was pressed.
                if not closeMenu then
                    if self:_GetIsMouseOver(self.closeButton) then

                        closeMenu = true
                        inputHandled = true
                        AlienBuy_OnClose()

                    end
                end
                
            end
            
        end
        
    end
    
    -- AlienBuy_Close() must be the last thing called.
    if closeMenu then
    
        self.closingMenu = true
        local player = Client.GetLocalPlayer()
        player:CloseMenu(true)
        
    end
    
    -- No matter what, this menu consumes MouseButton0/1.
    if key == InputKey.MouseButton0 or key == InputKey.MouseButton1 then
        inputHandled = true
    end
    
    return inputHandled
    
    
end

