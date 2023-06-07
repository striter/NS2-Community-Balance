local kAdditionalEffects =
{
    death =
    {
        alienStructureDeathParticleEffect =
        {
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "SporeMine", done = true},
        },

        alienStructureDeathSounds =
        {
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "SporeMine", done = true},
        },
    },
}
GetEffectManager():AddEffectData("AlienStructureEffects", kAdditionalEffects)
