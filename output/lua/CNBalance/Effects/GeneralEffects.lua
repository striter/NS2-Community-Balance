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

    death =
    {
        -- Structure effects in other lua files
        -- If death animation isn't played, and ragdoll isn't triggered, entity will be destroyed and removed immediately.
        -- Otherwise, effects are responsible for setting ragdoll/death time.
        generalDeathCinematicEffects =
        {
            {cinematic = "cinematics/marine/exo/explosion.cinematic", classname = "Exo", done = true},
            {cinematic = "cinematics/marine/exo/explosion.cinematic", classname = "Exosuit", done = true},
            {cinematic = "cinematics/alien/skulk/explode.cinematic", classname = "Skulk", doer = "Railgun", done = true},
            {cinematic = "cinematics/alien/gorge/explode.cinematic", classname = "Gorge", doer = "Railgun", done = true},
            {cinematic = "cinematics/alien/lerk/explode.cinematic", classname = "Lerk", doer = "Railgun", done = true},
            {cinematic = "cinematics/alien/fade/explode.cinematic", classname = "Fade", doer = "Railgun", done = true},
            {cinematic = "cinematics/alien/fade/explode.cinematic", classname = "Vokex", doer = "Railgun", done = true},
            {cinematic = "cinematics/alien/onos/explode.cinematic", classname = "Onos", doer = "Railgun", done = true},
            { cinematic = "cinematics/alien/skulk/explode.cinematic", classname = "Prowler", doer = "Railgun", done = true },
            -- TODO: Substitute material properties?
            {cinematic = "cinematics/materials/%s/grenade_explosion.cinematic", classname = "Grenade", done = true},
            {cinematic = "cinematics/marine/mac/death.cinematic", classname = "MAC", done = true},
            {cinematic = "cinematics/marine/arc/destroyed.cinematic", classname = "ARC", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Drifter", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "DrifterEgg", done = true},
        },

        -- Play world sound instead of parented sound as entity is going away?
        deathSoundEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "Exo", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "Exosuit", done = true},

            {sound = "sound/NS2.fev/alien/skulk/bite_kill", doer = "BiteLeap"},

            {stop_sound = "sound/NS2.fev/marine/structures/mac/thrusters", classname = "MAC"},

            {stop_sound = "sound/NS2.fev/marine/structures/arc/fire", classname = "ARC"},

            {sound = "sound/NS2.fev/marine/structures/mac/death", classname = "MAC", done = true},
            {sound = "sound/NS2.fev/alien/drifter/death", classname = "Drifter", done = true},
            {sound = "sound/NS2.fev/alien/drifter/death", classname = "DrifterEgg", done = true},
            {sound = "sound/NS2.fev/alien/drifter/death", classname = "Prowler", done = true},
            {sound = "sound/NS2.fev/alien/skulk/death", classname = "Skulk", done = true},
            {sound = "sound/NS2.fev/alien/gorge/death", classname = "Gorge", done = true},
            {sound = "sound/NS2.fev/alien/lerk/death", classname = "Lerk", done = true},
            {stop_sound = "sound/NS2.fev/alien/fade/blink_loop", classname = "Fade"},
            {sound = "sound/NS2.fev/alien/fade/death", classname = "Fade", done = true},
            {sound = "sound/NS2.fev/alien/fade/death", classname = "Vokex", done = true},
            {sound = "sound/NS2.fev/alien/onos/death", classname = "Onos", done = true},
            {sound = "sound/NS2.fev/marine/common/death_bigmac", classname = "Marine", sex = "bigmac", done = true},
            {sound = "sound/NS2.fev/marine/common/death_female", classname = "Marine", sex = "female", done = true},
            {sound = "sound/NS2.fev/marine/common/death", classname = "Marine", done = true},
            {sound = "sound/NS2.fev/marine/structures/arc/death", classname = "ARC", done = true},

        },

    },

}

GetEffectManager():AddEffectData("GeneralEffectData", kAdditionalEffects)
