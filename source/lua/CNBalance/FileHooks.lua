ModLoader.SetupFileHook("lua/Balance.lua", "lua/CNBalance/Balance.lua", "post")
ModLoader.SetupFileHook("lua/BalanceHealth.lua", "lua/CNBalance/BalanceHealth.lua", "post")
ModLoader.SetupFileHook("lua/BalanceMisc.lua", "lua/CNBalance/BalanceMisc.lua", "post")
ModLoader.SetupFileHook("lua/SentryBattery.lua", "lua/CNBalance/SentryBattery.lua", "post")

ModLoader.SetupFileHook("lua/CloakableMixin.lua", "lua/CNBalance/Mixin/CloakableMixin.lua", "replace")
ModLoader.SetupFileHook("lua/BabblerOwnerMixin.lua", "lua/CNBalance/Mixin/BabblerOwnerMixin.lua", "post")

ModLoader.SetupFileHook("lua/DamageTypes.lua", "lua/CNBalance/DamageTypes.lua", "replace")
ModLoader.SetupFileHook("lua/TechData.lua", "lua/CNBalance/TechData.lua", "post")
ModLoader.SetupFileHook("lua/BuildUtility.lua", "lua/CNBalance/BuildUtility.lua", "post")

ModLoader.SetupFileHook("lua/AlienTeam.lua", "lua/CNBalance/AlienTeam.lua", "post")
ModLoader.SetupFileHook("lua/AlienTechMap.lua", "lua/CNBalance/AlienTechMap.lua", "post")
ModLoader.SetupFileHook("lua/AlienTunnelManager.lua", "lua/CNBalance/AlienTunnelManager.lua", "replace")
ModLoader.SetupFileHook("lua/TunnelEntrance.lua", "lua/CNBalance/TunnelEntrance.lua", "post")
ModLoader.SetupFileHook("lua/Hydra.lua", "lua/CNBalance/Hydra.lua", "post")

ModLoader.SetupFileHook("lua/Weapons/Alien/Metabolize.lua", "lua/CNBalance/Weapons/Alien/Metabolize.lua", "replace")
ModLoader.SetupFileHook("lua/Weapons/Alien/BoneShield.lua", "lua/CNBalance/Weapons/Alien/BoneShield.lua", "replace")
ModLoader.SetupFileHook("lua/Weapons/Alien/HydraAbility.lua", "lua/CNBalance/Weapons/Alien/HydraAbility.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/HeavyMachineGun.lua", "lua/CNBalance/Weapons/Marine/HeavyMachineGun.lua", "post")
ModLoader.SetupFileHook("lua/Weapons/Marine/GrenadeThrower.lua", "lua/CNBalance/Weapons/Marine/GrenadeThrower.lua", "post")

ModLoader.SetupFileHook("lua/Skulk.lua", "lua/CNBalance/Lifeforms/Skulk.lua", "post")
ModLoader.SetupFileHook("lua/Lerk.lua", "lua/CNBalance/Lifeforms/Lerk.lua", "post")
ModLoader.SetupFileHook("lua/Fade.lua", "lua/CNBalance/Lifeforms/Fade.lua", "post")
ModLoader.SetupFileHook("lua/Gorge.lua", "lua/CNBalance/Lifeforms/Gorge.lua", "post")
ModLoader.SetupFileHook("lua/Onos.lua", "lua/CNBalance/Lifeforms/Onos.lua", "post")

ModLoader.SetupFileHook("lua/ARC.lua", "lua/CNBalance/ARC.lua", "post")
ModLoader.SetupFileHook("lua/Exo.lua", "lua/CNBalance/Exo.lua", "post")

if AddHintModPanel then
    local panelMaterial = PrecacheAsset("materials/CNPlaygroundBalance/Banner.material")
    AddHintModPanel(panelMaterial, "https://docs.qq.com/doc/DUEZSeUtrR0tWTGJ4","阅读平衡修改文档")
end