local kAdditionalEffects =
{
    death =
    {
        marineStructureDeathCinematics =
        {
            {cinematic = "cinematics/marine/sentry/death.cinematic", classname = "WeaponCache", done = true},
            {cinematic = "cinematics/marine/sentry/death.cinematic", classname = "MarineSentry", done = true},
        },
        
        marineStructureDeathSounds =
        {
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "WeaponCache", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "MarineSentry", done = true},
        },

    },

    powered_extractor_blast =
    {
        poweredExtractorBlastEffects =
        {
            { sound = "sound/NS2.fev/marine/grenades/pulse/explode"},
            { cinematic = "cinematics/marine/mac/empblast.cinematic", done = true},
        },
    },

}

GetEffectManager():AddEffectData("MarineStructureEffects", kAdditionalEffects)
