local kAdditionalEffects =
{
    death =
    {
        marineStructureDeathCinematics =
        {
            {cinematic = "cinematics/marine/sentry/death.cinematic", classname = "WeaponCache", done = true},
        },
        
        marineStructureDeathSounds =
        {
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "WeaponCache", done = true},
        },
    },
}

GetEffectManager():AddEffectData("MarineStructureEffects", kAdditionalEffects)
