local kAdditionalEffects =
{
    shotgun_attack_secondary = 
    {
        shotgunAttacksSecondary = 
        {
            {viewmodel_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle", empty = false},
            {weapon_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle", empty = false},

            {player_sound = "sound/NS2.fev/marine/shotgun/fire_upgrade_3", done = true},
        },
    },

	draw =
    {
        marineWeaponDrawSounds =
        {
            {player_sound = "sound/NS2.fev/marine/rifle/draw", classname = "Cannon", done = true},
			{player_sound = "sound/ns2plus.fev/weapons/marine/revolver/draw", classname = "Revolver", volume = 0.5, done = true},
            {player_sound = "sound/ns2plus.fev/weapons/marine/knife/deploy", classname = "Knife", done = true},
			{player_sound = "sound/ns2plus.fev/weapons/marine/lmg/draw", classname = "LightMachineGun", done = true},
            {player_sound = "sound/ns2plus.fev/weapons/marine/lmg/draw", classname = "SubMachineGun", done = true},
        },
    },
    
   reload_speed0 = 
    {
        gunReloadEffects =
        {
			{player_sound = "sound/ns2plus.fev/weapons/marine/revolver/reload0", classname = "Revolver", done = true},
            {player_sound = "sound/ns2plus.fev/weapons/marine/heavy_cannon/reload0", classname = "Cannon", done = true},
			{player_sound = "sound/ns2plus.fev/weapons/marine/lmg/reload0", classname = "LightMachineGun", done = true},
            {player_sound = "sound/ns2plus.fev/weapons/marine/lmg/reload0", classname = "SubMachineGun", done = true},
        },
    },
	
	reload_speed1 = 
    {
        gunReloadEffects =
        {
			{player_sound = "sound/ns2plus.fev/weapons/marine/revolver/reload1", classname = "Revolver", done = true},
            {player_sound = "sound/ns2plus.fev/weapons/marine/heavy_cannon/reload1", classname = "Cannon", done = true},
			{player_sound = "sound/ns2plus.fev/weapons/marine/lmg/reload1", classname = "LightMachineGun", done = true},
            {player_sound = "sound/ns2plus.fev/weapons/marine/lmg/reload1", classname = "SubMachineGun", done = true},
        },
    },
	
    reload_cancel =
    {
        gunReloadCancelEffects =
        {
			{stop_sound = "sound/ns2plus.fev/weapons/marine/revolver/reload0", classname = "Revolver"},
			{stop_sound = "sound/ns2plus.fev/weapons/marine/revolver/reload1", classname = "Revolver", done = true},
			{stop_sound = "sound/ns2plus.fev/weapons/marine/heavy_cannon/reload0", classname = "Cannon"},
			{stop_sound = "sound/ns2plus.fev/weapons/marine/heavy_cannon/reload1", classname = "Cannon", done = true},
			{stop_sound = "sound/ns2plus.fev/weapons/marine/lmg/reload0", classname = "LightMachineGun"},
			{stop_sound = "sound/ns2plus.fev/weapons/marine/lmg/reload1", classname = "LightMachineGun", done = true},
            {stop_sound = "sound/ns2plus.fev/weapons/marine/lmg/reload0", classname = "SubMachineGun"},
            {stop_sound = "sound/ns2plus.fev/weapons/marine/lmg/reload1", classname = "SubMachineGun", done = true},
        },
    },

	revolver_attack = 
    {
        revolverAttackEffects = 
        {
            {viewmodel_cinematic = "cinematics/marine/revolver_muzzle.cinematic", attach_point = "fxnode_revolvermuzzle"},
            {weapon_cinematic = "cinematics/marine/revolver_muzzle.cinematic", attach_point = "fxnode_revolvermuzzle"},
            {player_sound = "sound/ns2plus.fev/weapons/marine/revolver/fire"},
        },
    },

	cannon_attack = 
    {
        cannonAttackEffects = 
        {
            {viewmodel_cinematic = "cinematics/marine/cannon_muzzle_flash.cinematic", attach_point = "fxnode_hcmuzzle", empty = false},            
			
			{player_sound = "sound/ns2plus.fev/weapons/marine/heavy_cannon/fire", done = true},
        },
    },

    
    knife_attack = 
    {
        knifeAttackEffects = 
        {
            { player_sound = "sound/ns2plus.fev/weapons/marine/knife/attack", sex = "female", done = true },
            { player_sound = "sound/ns2plus.fev/weapons/marine/knife/attack" },
        },
    },
}
GetEffectManager():AddEffectData("AdditionalEffects", kAdditionalEffects)
