ModLoader.SetupFileHook("lua/Balance.lua", "lua/CNBalance/Balance.lua", "post")
ModLoader.SetupFileHook("lua/BalanceHealth.lua", "lua/CNBalance/BalanceHealth.lua", "post")
ModLoader.SetupFileHook("lua/BalanceMisc.lua", "lua/CNBalance/BalanceMisc.lua", "post")
ModLoader.SetupFileHook("lua/SentryBattery.lua", "lua/CNBalance/SentryBattery.lua", "post")

ModLoader.SetupFileHook("lua/CloakableMixin.lua", "lua/CNBalance/Mixin/CloakableMixin.lua", "replace")
ModLoader.SetupFileHook("lua/BabblerOwnerMixin.lua", "lua/CNBalance/Mixin/BabblerOwnerMixin.lua", "post")

ModLoader.SetupFileHook("lua/AlienTeam.lua", "lua/CNBalance/AlienTeam.lua", "post")
ModLoader.SetupFileHook("lua/AlienTechMap.lua", "lua/CNBalance/AlienTechMap.lua", "post")

ModLoader.SetupFileHook("lua/Weapons/Alien/Metabolize.lua", "lua/CNBalance/Weapons/Alien/Metabolize.lua", "replace")
ModLoader.SetupFileHook("lua/Weapons/Alien/BoneShield.lua", "lua/CNBalance/Weapons/Alien/BoneShield.lua", "replace")
ModLoader.SetupFileHook("lua/Weapons/Marine/HeavyMachineGun.lua", "lua/CNBalance/Weapons/Marine/HeavyMachineGun.lua", "post")

ModLoader.SetupFileHook("lua/Skulk.lua", "lua/CNBalance/Lifeforms/Skulk.lua", "post")
ModLoader.SetupFileHook("lua/Lerk.lua", "lua/CNBalance/Lifeforms/Lerk.lua", "post")
ModLoader.SetupFileHook("lua/Fade.lua", "lua/CNBalance/Lifeforms/Fade.lua", "post")
ModLoader.SetupFileHook("lua/Gorge.lua", "lua/CNBalance/Lifeforms/Gorge.lua", "post")
ModLoader.SetupFileHook("lua/Onos.lua", "lua/CNBalance/Lifeforms/Onos.lua", "post")

ModLoader.SetupFileHook("lua/ARC.lua", "lua/CNBalance/ARC.lua", "post")
ModLoader.SetupFileHook("lua/Exo.lua", "lua/CNBalance/Exo.lua", "post")
