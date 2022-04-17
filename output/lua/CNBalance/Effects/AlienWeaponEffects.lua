local kAdditionalEffects =
{
    combat_devour_stomach_outside = 
    {
        devourOutsideEffects = 
        {
            {parented_sound = "sound/ns2remake_combat.fev/combat/abilities/alien/onos/devour", volume = 0.2, done = true},
        },
    },
    
    combat_devour_stomach_inside = 
    {
        devourInsideEffects = 
        {
            {private_sound = "sound/ns2remake_combat.fev/combat/abilities/alien/onos/devour", done = true},
        },
    },
    
    combat_devour_eat = 
    {
        devourEatEffects = 
        {
            {sound = "sound/ns2remake_combat.fev/combat/common/alien/devour_in"},
            {cinematic = "cinematics/alien/onos/devour_escape.cinematic", done = true},
        },
    },
    
    combat_devour_escape = 
    {
        devourEscapeEffects = 
        {
            {sound = "sound/ns2remake_combat.fev/combat/common/alien/devour_out"},
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
}

GetEffectManager():AddEffectData("kAdditionalEffects", kAdditionalEffects)
