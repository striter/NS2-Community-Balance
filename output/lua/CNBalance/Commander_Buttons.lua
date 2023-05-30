

local function GetIsMenu(techId)

    local techTree = GetTechTree()
    if techTree then

        local techNode = techTree:GetTechNode(techId)
        return techNode and techNode:GetIsMenu()

    end

    return false

end

function CommanderUI_MenuButtonOffset(index)

    local player = Client.GetLocalPlayer()
    if index <= table.icount(player.menuTechButtons) then

        local techId = player.menuTechButtons[index]

        if index == 4 then
            local selectedEnts = player:GetSelection()
            if selectedEnts and selectedEnts[1] then
                techId = selectedEnts[1]:GetTechId()
            end
        else

            -- show the back arrow when a menu button is at the bottom right
            if index == 12 and GetIsMenu(techId)  then
                if techId ~= kTechId.ProtosMenu then
                    techId = kTechId.Return
                end
                -- override upgrade structures for alien commander
            elseif player:isa("AlienCommander") then

                if techId == kTechId.Shell then

                    if player.shellCount == 1 then
                        techId = kTechId.SecondShell
                    elseif player.shellCount == 2 then
                        techId = kTechId.ThirdShell
                    elseif player.shellCount > 2 then
                        techId = kTechId.FullShell
                    end

                elseif techId == kTechId.Spur then

                    if player.spurCount == 1 then
                        techId = kTechId.SecondSpur
                    elseif player.spurCount == 2 then
                        techId = kTechId.ThirdSpur
                    elseif player.spurCount > 2 then
                        techId = kTechId.FullSpur
                    end

                elseif techId == kTechId.Veil then

                    if player.veilCount == 1 then
                        techId = kTechId.SecondVeil
                    elseif player.veilCount == 2 then
                        techId = kTechId.ThirdVeil
                    elseif player.veilCount > 2 then
                        techId = kTechId.FullVeil
                    end

                end

            end

        end
        return GetMaterialXYOffset(techId, player:isa("MarineCommander"))

    end

    return -1, -1

end
