local kAdditionalEffects =
{
    combat_devour_stomach_outside = 
    {
        devourOutsideEffects = 
        {
            {parented_sound = "sound/Devour.fev/Devour/devour_ambience", volume = 0.2, done = true},
        },
    },
    
    combat_devour_stomach_inside = 
    {
        devourInsideEffects = 
        {
            {private_sound = "sound/Devour.fev/Devour/devour_ambience", done = true},
        },
    },
    
    combat_devour_eat = 
    {
        devourEatEffects = 
        {
            {sound = "sound/Devour.fev/Devour/devour_in"},
            {cinematic = "cinematics/alien/onos/devour_escape.cinematic", done = true},
        },
    },
    
    combat_devour_escape = 
    {
        devourEscapeEffects = 
        {
            {sound = "sound/Devour.fev/Devour/devour_out"},
            {cinematic = "cinematics/alien/onos/devour_escape.cinematic", done = true},
        },
    },
    
    
    combat_stop_effects = 
    {
        stopEffects = 
        {
            {stop_effects = ""},
        },
    },
    
    volley_attack =
    {
        volleyHitSounds = 
        {
            {sound = "sound/NS2.fev/alien/skulk/parasite", done = true},
        },
    },
}

GetEffectManager():AddEffectData("kAdditionalEffects", kAdditionalEffects)
