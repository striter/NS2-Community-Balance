
local function OnCommandChangeClass(className, teamNumber, extraValues)

    return function(client)
    
        local player = client:GetControllingPlayer()
        
        -- Don't allow to use these commands if you're in the RR
        if player:GetTeamNumber() == kTeam1Index or player:GetTeamNumber() == kTeam2Index then
        
            -- Switch teams if necessary
            if player:GetTeamNumber() ~= teamNumber then
                if Shared.GetCheatsEnabled() and not player:GetIsCommander() then
                
                    -- Remember position and team for calling player for debugging
                    local playerOrigin = player:GetOrigin()
                    local playerViewAngles = player:GetViewAngles()
                    
                    local newTeamNumber = kTeam1Index
                    if player:GetTeamNumber() == kTeam1Index then
                        newTeamNumber = kTeam2Index
                    end
                    
                    local success, newPlayer = GetGamerules():JoinTeam(player, kTeamReadyRoom)
                    success, newPlayer = GetGamerules():JoinTeam(newPlayer, newTeamNumber)
                    
                    newPlayer:SetOrigin(playerOrigin)
                    newPlayer:SetViewAngles(playerViewAngles)
                    
                    player = client:GetControllingPlayer()
                                    
                end
            end
            
            -- Respawn shenanigans
            if Shared.GetCheatsEnabled() then
                local newPlayer = player:Replace(className, player:GetTeamNumber(), nil, nil, extraValues)
                
                -- Always disable 3rd person
                newPlayer:SetDesiredCameraDistance(0)

                -- Turns out if you give weapons to exos the game implodes! Who would've thought!
                if teamNumber == kTeam1Index and (className == "marine" or className == "jetpackmarine") and newPlayer.lastWeaponList then
                    -- Restore weapons in reverse order so the main weapons gets selected on respawn
                    for i = #newPlayer.lastWeaponList, 1, -1 do
                        if newPlayer.lastWeaponList[i] ~= "axe" then
                            newPlayer:GiveItem(newPlayer.lastWeaponList[i])
                        end
                    end
                end
                
                if teamNumber == kTeam2Index and newPlayer.lastUpgradeList then            
                    -- I have no idea if this will break, but I don't care!
                    -- Thug life!
                    -- Ghetto code incoming, you've been warned
                    newPlayer.upgrade1 = newPlayer.lastUpgradeList[1] or 1
                    newPlayer.upgrade2 = newPlayer.lastUpgradeList[2] or 1
                    newPlayer.upgrade3 = newPlayer.lastUpgradeList[3] or 1
                end
                
            end
            
        end
        
    end
    
end

Event.Hook("Console_prowler", OnCommandChangeClass("prowler", kTeam2Index))