local kAdditionalEffects =
{
    combat_devour_stomach_outside = 
    {
        devourOutsideEffects = 
        {
            {parented_sound = "sound/ns2plus.fev/abilities/onos/devour", volume = 0.2, done = true},
        },
    },
    
    combat_devour_stomach_inside = 
    {
        devourInsideEffects = 
        {
            {private_sound = "sound/ns2plus.fev/abilities/onos/devour", done = true},
        },
    },
    
    combat_devour_eat = 
    {
        devourEatEffects = 
        {
            {sound = "sound/ns2plus.fev/common/alien/devour_in"},
            {cinematic = "cinematics/alien/onos/devour_escape.cinematic", done = true},
        },
    },
    
    combat_devour_escape = 
    {
        devourEscapeEffects = 
        {
            {sound = "sound/ns2plus.fev/common/alien/devour_out"},
            {cinematic = "cinematics/alien/onos/devour_escape.cinematic", done = true},
        },
    },
    
    volley_attack =
    {
        volleyHitSounds = 
        {
            {sound = "sound/NS2.fev/alien/skulk/parasite", done = true},
        },
    },

    draw = 
    {
		alienWeaponDrawSounds =
        {
			{player_sound = "sound/ns2plus.fev/abilities/fade/acid_rocket/deploy", classname = "AcidRocket", done = true},
        }
    },

    acidrocket_attack =
    {
        bilebombFireEffects = 
        {   
            {sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/ns2plus.fev/abilities/fade/acid_rocket/rocket_fire"},
        },
    },

    acidrocket_hit =
    {
        bilebombHitEffects = 
        {          
            {cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic"},
            {parented_sound = "sound/ns2plus.fev/abilities/fade/acid_rocket/rocket_hit", done = true},
        },
    },
}

GetEffectManager():AddEffectData("kAdditionalEffects", kAdditionalEffects)
