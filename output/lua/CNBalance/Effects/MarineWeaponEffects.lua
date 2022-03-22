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
}

GetEffectManager():AddEffectData("MarineWeaponEffects", kAdditionalEffects)

local kRevolverEffects = {
    draw =
    {
        marineWeaponDrawSounds =
        {
            
      
			{player_sound = "sound/revolver.fev/Revolver/revolver_draw", classname = "Revolver", done = true},
          
            
        },

    },
    
    reload_speed0 = 
    {
        gunReloadEffects =
        {
		
			{player_sound = "sound/revolver.fev/Revolver/revolver_reload0", classname = "Revolver", done = true},
           
        },
    },
	
	reload_speed1 = 
    {
        gunReloadEffects =
        {
			
			{player_sound = "sound/revolver.fev/Revolver/revolver_reload1", classname = "Revolver", done = true},
           
        },
    },
	
    reload_cancel =
    {
        gunReloadCancelEffects =
        {

			{stop_sound = "sound/revolver.fev/Revolver/revolver_reload0", classname = "Revolver"},
			{stop_sound = "sound/revolver.fev/Revolver/revolver_reload1", classname = "Revolver", done = true},
          
        },
    },
    
	revolver_attack = 
    {
        revolverAttackEffects = 
        {
            {viewmodel_cinematic = "cinematics/marine/Revolver_muzzle.cinematic", attach_point = "fxnode_revolvermuzzle"},
            
            {weapon_cinematic = "cinematics/marine/Revolver_muzzle.cinematic", attach_point = "fxnode_revolvermuzzle"},
            
            // Sound effect
            {player_sound = "sound/revolver.fev/Revolver/revolver_fire"},
        },
    },
}

GetEffectManager():AddEffectData("MarineWeaponEffects", kRevolverEffects)

local kSubmachinegunEffects =
{
    draw =
    {
        marineWeaponDrawSounds =
        {
            
            {player_sound = "sound/Submachinegun.fev/submachinegun/lmg_draw", classname = "Submachinegun", done = true},
            
        },
    },


    reload_speed0 = 
    {
        gunReloadEffects =
        {

            {player_sound = "sound/Submachinegun.fev/submachinegun/lmg_reload", classname = "Submachinegun", done = true},
        },
    },

    reload_speed1 = 
    {
        gunReloadEffects =
        {

            {player_sound = "sound/Submachinegun.fev/submachinegun/lmg_reload1", classname = "Submachinegun", done = true},
        },
    },

    reload_cancel =
    {
        gunReloadCancelEffects =
        {

            {stop_sound = "sound/Submachinegun.fev/submachinegun/lmg_reload", classname = "Submachinegun"},
            {stop_sound = "sound/Submachinegun.fev/submachinegun/lmg_reload1", classname = "Submachinegun", done = true},
        },
    },


    rifle_alt_attack = 
    {
        rifleAltAttackEffects = 
        {
            { player_sound = "sound/NS2.fev/marine/rifle/alt_swing_female", sex = "female", done = true },
            { player_sound = "sound/NS2.fev/marine/rifle/alt_swing" },
        },
    },
}

GetEffectManager():AddEffectData("MarineWeaponEffects", kSubmachinegunEffects)

local kCannonEffects =

{
	draw =
    {
        marineWeaponDrawSounds =
        {
            {player_sound = "sound/NS2.fev/marine/rifle/draw", classname = "Cannon", done = true},
        },

    },
   reload_speed0 = 
    {
        gunReloadEffects =
        {

            {player_sound = "sound/Cannon.fev/combat_cannon/cannon_reload", classname = "Cannon", done = true},
		
        },
    },
	
	reload_speed1 = 
    {
        gunReloadEffects =
        {
	
            {player_sound = "sound/Cannon.fev/combat_cannon/cannon_reload1", classname = "Cannon", done = true},

        },
    },
	
    reload_cancel =
    {
        gunReloadCancelEffects =
        {

			{stop_sound = "sound/Cannon.fev/combat_cannon/cannon_reload", classname = "Cannon"},
			{stop_sound = "sound/Cannon.fev/combat_cannon/cannon_reload1", classname = "Cannon", done = true},

        },
    },
	cannon_attack = 
    {
        cannonAttackEffects = 
        {
            {viewmodel_cinematic = "cinematics/marine/cannon_muzzle_flash.cinematic", attach_point = "fxnode_hcmuzzle", empty = false},            
            //{weapon_cinematic = "cinematics/marine/pistol/muzzle_flash.cinematic", attach_point = "fxnode_hcmuzzle", empty = false},
			
			{player_sound = "sound/Cannon.fev/combat_cannon/cannon_fire", done = true},
        },
    },
}
GetEffectManager():AddEffectData("MarineWeaponEffects", kCannonEffects)