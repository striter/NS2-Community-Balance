kAdditionalEffects =
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
            
      
			{player_sound = "sound/revolver.fev/Revolver/revolver_draw", classname = "Revolver", done = true},
          
            
        },

    },
    
--Revolver
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
--
}

GetEffectManager():AddEffectData("MarineWeaponEffects", kAdditionalEffects)