local kAdditionalEffects = {
    deploy =
    {
        deploySoundEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/sentry_deploy", classname = "WeaponCache", done = true},                   
        },

    }, 

    spawn =
    {
    
        spawnEffects =
        {
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "WeaponCache", done = true},
        
        },
        
        spawnSoundEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "WeaponCache", done = true},
        }
        
    },
    
}

GetEffectManager():AddEffectData("GeneralEffectData", kAdditionalEffects)
