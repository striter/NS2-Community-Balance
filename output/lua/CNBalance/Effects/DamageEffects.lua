kAdditionalDamageEffects =
{
    damage_sound =
    {
        damageSounds =
        {
            {sound = "sound/NS2.fev/alien/skulk/parasite_hit", doer = "VolleyRappel", world_space = true, done = true},
        }
    },
    damage_decal =
    {
        damageDecals = 
        {
          
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.2, doer = "Revolver", done = true}, 
  
        },    
    },
}
GetEffectManager():AddEffectData("DamageEffects", kAdditionalDamageEffects)