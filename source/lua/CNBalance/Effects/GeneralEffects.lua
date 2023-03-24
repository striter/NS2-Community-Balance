local kAdditionalEffects = {
    deploy =
    {
        deploySoundEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/sentry_deploy", classname = "WeaponCache", done = true},
            {sound = "sound/NS2.fev/marine/structures/sentry_deploy", classname = "MarineSentry", done = true},
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


}

GetEffectManager():AddEffectData("GeneralEffectData", kAdditionalEffects)
