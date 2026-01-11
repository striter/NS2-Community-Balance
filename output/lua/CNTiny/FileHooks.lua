
ModLoader.SetupFileHook( "lua/Globals.lua", "lua/CNTiny/Globals.lua", "post")
ModLoader.SetupFileHook( "lua/ServerAdminCommands.lua", "lua/CNTiny/ServerAdminCommands.lua", "post" )
ModLoader.SetupFileHook( "lua/WallMovementMixin.lua", "lua/CNTiny/WallMovementMixin.lua", "post" )
ModLoader.SetupFileHook( "lua/CrouchMoveMixin.lua", "lua/CNTiny/CrouchMoveMixin.lua", "post" )
ModLoader.SetupFileHook( "lua/MarineVariantMixin.lua", "lua/CNTiny/MarineVariantMixin.lua", "post" )


ModLoader.SetupFileHook( "lua/Player.lua", "lua/CNTiny/Player/Player.lua", "post" )
ModLoader.SetupFileHook( "lua/ReadyRoomPlayer.lua", "lua/CNTiny/Player/ReadyRoomPlayer.lua", "post" )

ModLoader.SetupFileHook( "lua/Marine.lua", "lua/CNTiny/Player/Marine.lua", "post" )
ModLoader.SetupFileHook( "lua/Exo.lua", "lua/CNTiny/Player/Exo.lua", "post" )
ModLoader.SetupFileHook( "lua/JetpackMarine.lua", "lua/CNTiny/Player/JetpackMarine.lua", "post" )

ModLoader.SetupFileHook( "lua/Skulk.lua", "lua/CNTiny/Player/Skulk.lua", "post" )
ModLoader.SetupFileHook( "lua/Gorge.lua", "lua/CNTiny/Player/Gorge.lua", "post" )
ModLoader.SetupFileHook( "lua/Lerk.lua", "lua/CNTiny/Player/Lerk.lua", "post" )
ModLoader.SetupFileHook( "lua/Fade.lua", "lua/CNTiny/Player/Fade.lua", "post" )
ModLoader.SetupFileHook( "lua/Onos.lua", "lua/CNTiny/Player/Onos.lua", "post" )

ModLoader.SetupFileHook( "lua/Prowler/Prowler.lua", "lua/CNTiny/Player/Prowler.lua", "post" )

ModLoader.SetupFileHook( "lua/Voting.lua", "lua/CNTiny/Voting.lua", "post" )
function GTinySpeedMultiplier(player)
    return 0.5  + player.scale * 0.5
end