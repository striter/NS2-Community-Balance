
ModLoader.SetupFileHook( "lua/Globals.lua", "lua/CNTiny/Globals.lua", "post")
ModLoader.SetupFileHook( "lua/ServerAdminCommands.lua", "lua/CNTiny/ServerAdminCommands.lua", "post" )
ModLoader.SetupFileHook( "lua/CrouchMoveMixin.lua", "lua/CNTiny/CrouchMoveMixin.lua", "post" )
ModLoader.SetupFileHook( "lua/MarineVariantMixin.lua", "lua/CNTiny/MarineVariantMixin.lua", "post" )

ModLoader.SetupFileHook( "lua/Player.lua", "lua/CNTiny/Player.lua", "post" )
ModLoader.SetupFileHook( "lua/Alien.lua", "lua/CNTiny/Alien.lua", "post" )
ModLoader.SetupFileHook( "lua/ReadyRoomPlayer.lua", "lua/CNTiny/ReadyRoomPlayer.lua", "post" )

ModLoader.SetupFileHook( "lua/Marine.lua", "lua/CNTiny/Marine.lua", "post" )
ModLoader.SetupFileHook( "lua/Exo.lua", "lua/CNTiny/Exo.lua", "post" )
ModLoader.SetupFileHook( "lua/JetpackMarine.lua", "lua/CNTiny/JetpackMarine.lua", "post" )

ModLoader.SetupFileHook( "lua/Skulk.lua", "lua/CNTiny/Skulk.lua", "post" )
ModLoader.SetupFileHook( "lua/Gorge.lua", "lua/CNTiny/Gorge.lua", "post" )
ModLoader.SetupFileHook( "lua/Lerk.lua", "lua/CNTiny/Lerk.lua", "post" )
ModLoader.SetupFileHook( "lua/Fade.lua", "lua/CNTiny/Fade.lua", "post" )
ModLoader.SetupFileHook( "lua/Onos.lua", "lua/CNTiny/Onos.lua", "post" )

ModLoader.SetupFileHook( "lua/Prowler/Prowler.lua", "lua/CNTiny/Prowler.lua", "post" )

ModLoader.SetupFileHook( "lua/Voting.lua", "lua/CNTiny/Voting.lua", "post" )
function GTinySpeedMultiplier(player)
    return 0.8  + player:GetPlayerScale() * 0.2
end