
local Plugin = Shine.Plugin( ... )

Plugin.HasConfig = false

function Plugin:Initialise()
	self:CreateCommands()
	return true
end

function Plugin:CreateCommands()
	local function AdminScalePlayer( _client, _target, scale )
        local player = _target:GetControllingPlayer()
        if not player or not player.SetPlayerScale then return end
        player:SetPlayerScale(scale)
        Shine:AdminPrint( nil, "%s set %s scale to %s", true,  Shine.GetClientInfo( _client ), Shine.GetClientInfo( target ), scale )
	end

    self:BindCommand( "sh_scale", "scale", AdminScalePlayer )
    :AddParam{ Type = "client" }
    :AddParam{ Type = "number", Round = false, Min = 0.1, Max = 5, Optional = true, Default = 0.5 }
    :Help( "设置ID对应玩家的大小." )

    local function AdminSetAllScale( _client, scale )
        for client in Shine.IterateClients() do
            local player = client:GetControllingPlayer()
            if not player.SetPlayerScale then return end
            player:SetPlayerScale(scale)
		end

        Shine:AdminPrint( nil, "%s set all scale to %s", true,  Shine.GetClientInfo( _client ), scale )
	end

    self:BindCommand( "sh_scale_all", "scale_all", AdminSetAllScale )
    :AddParam{ Type = "number", Round = false, Min = 0.1, Max = 5, Optional = true, Default = 0.5 }
    :Help( "设置所有玩家的大小." )
end

return Plugin
