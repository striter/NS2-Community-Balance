

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

function GetCNCommWinsRequired(techId)
    return techId and kCommWinsRequired[techId] or nil
end

function GetCNCommanderWins()
    -- The Scoreboard player record extra-data whitelist does NOT carry roundWinCommander,
    -- so it reads 0 here. The authoritative local-player value lives in the Shine
    -- communityrank client store (populated by the Shine_CommunityTier network message,
    -- PascalCase field). Read it first; fall back to scoreboard only if plugin absent.
    if Shine and Shine.IsExtensionEnabled then
        local enabled, plugin = Shine:IsExtensionEnabled("communityrank")
        if enabled and plugin and plugin.GetCommunityData then
            local data = plugin:GetCommunityData()
            if data and data.RoundWinCommander then
                return data.RoundWinCommander
            end
        end
    end
    local player = Client.GetLocalPlayer()
    if not player then
        return 0
    end
    local record = Scoreboard_GetPlayerRecord(player:GetClientIndex())
    return record and record.roundWinCommander or 0
end

-- true when this tech is win-gated and the local commander has NOT reached the required wins (client only)
function IsCNCommWinsBlocked(techId)
    if not Client then
        return false
    end
    local need = GetCNCommWinsRequired(techId)
    return need ~= nil and GetCNCommanderWins() < need
end

-- belt-and-suspenders: force the button grayed even before GetTechAllowed propagates
local baseMenuButtonStatus = CommanderUI_MenuButtonStatus
function CommanderUI_MenuButtonStatus(index)
    local status = baseMenuButtonStatus(index)
    if status == 1 or status == 2 then
        local player = Client.GetLocalPlayer()
        if player and index <= table.icount(player.menuTechButtons) and IsCNCommWinsBlocked(player.menuTechButtons[index]) then
            status = 3
        end
    end
    return status
end

-- The tooltip the commander quickbar ACTUALLY shows is built by
-- PlayerUI_GetTooltipDataFromTechId (Player_Client.lua), NOT CommanderUI_MenuButtonTooltip.
-- Append the win requirement to its "requires" line so a blocked tech explains why.
if PlayerUI_GetTooltipDataFromTechId and not CNBalance_CommWinsTooltipHooked then
    CNBalance_CommWinsTooltipHooked = true
    local baseGetTooltipDataFromTechId = PlayerUI_GetTooltipDataFromTechId
    function PlayerUI_GetTooltipDataFromTechId(techId, hotkeyIndex)
        local tooltipData = baseGetTooltipDataFromTechId(techId, hotkeyIndex)
        if tooltipData and IsCNCommWinsBlocked and IsCNCommWinsBlocked(techId) then
            local extra = string.format('需要指挥胜场%d(当前%d)', GetCNCommWinsRequired(techId), GetCNCommanderWins())
            local requiresText = tooltipData.requires
            if requiresText and requiresText ~= '' then
                tooltipData.requires = requiresText .. ', ' .. extra
            else
                tooltipData.requires = extra
            end
        end
        return tooltipData
    end
end
