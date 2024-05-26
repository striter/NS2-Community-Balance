local kAdditionalEffects = {
    deploy =
    {
        deploySoundEffects =
        {
            {sound = "sound/ns2plus.fev/structures/marine/weaponcache_deploy", classname = "WeaponCache", done = true},
            {sound = "sound/ns2plus.fev/structures/marine/sentry_deploy2", classname = "MarineSentry", done = true},
        },

    }, 

    spawn =
    {
    
        spawnEffects =
        {
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "WeaponCache", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "MarineSentry", done = true},
        
        },
        
        spawnSoundEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "WeaponCache", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "MarineSentry", done = true},
        }
        
    },
    
    vortexed_start =
    {
        vortexEffects = 
        {
            {sound = "", silenceupgrade = true, done = true},
            {cinematic = "cinematics/alien/fade/vortex.cinematic"},
            {sound = "sound/NS2.fev/alien/fade/vortex_start", done = true},   
        }
    },
    
    vortexed_end =
    {
        vortexEndEffects =
        {
            {cinematic = "cinematics/alien/fade/vortex_destroy.cinematic"},
            {sound = "sound/NS2.fev/alien/fade/vortex_end", done = true}, 
        }
    },

    death = {
        generalDeathCinematicEffects = {
            { cinematic = "cinematics/alien/skulk/explode.cinematic", classname = "Prowler", doer = "Railgun", done = true },
        },
    }
}

GetEffectManager():AddEffectData("GeneralEffectData", kAdditionalEffects)
