local function SetScale(client,scale)
    local player = client:GetControllingPlayer()
    if player then
        player:SetScale(tonumber(scale))
    end
end
CreateServerAdminCommand("Console_sv_setscale", SetScale, "<scale>, estimate player scale")
