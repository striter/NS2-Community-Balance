local kAdditionalDamageEffects =
{
    damage_sound =
    {
        damageSounds =
        {
            {sound = "sound/NS2.fev/alien/skulk/parasite_hit", doer = "VolleyRappel", world_space = true, done = true},
        }
    },
}

GetEffectManager():AddEffectData("DamageEffects", kAdditionalDamageEffects)


local kRevolverDamageEffects = 
{
    damage_decal =
    {
        damageDecals = 
        {
          
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.2, doer = "Revolver", done = true}, 
  
        },    
    },
}
GetEffectManager():AddEffectData("DamageEffects", kRevolverDamageEffects)


local kCannonDamageEffects =
{
 damage_decal =
    {
        damageDecals = 
        {
                  

			{decal = "cinematics/vfx_materials/decals/blast_01.material", scale = 0.5, doer = "Cannon", done = true},


		}
	},
}

GetEffectManager():AddEffectData("CannonDamageEffects", kCannonDamageEffects)