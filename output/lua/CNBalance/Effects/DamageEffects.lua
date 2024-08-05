kAdditionalEffects =
{

    damage_decal =
    {
        damageDecals = 
        {
			{decal = "cinematics/vfx_materials/decals/clawmark_03.material", scale = 0.2, doer = "Knife", done = true},
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.2, doer = "Revolver", done = true}, 
            {decal = "cinematics/vfx_materials/decals/clawmark_01.material", scale = 0.35, doer = "LightMachineGun", alt_mode = true, done = true}, 
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.125, doer = "LightMachineGun", alt_mode = false, done = true},        
            {decal = "cinematics/vfx_materials/decals/clawmark_01.material", scale = 0.35, doer = "SubMachineGun", alt_mode = true, done = true}, 
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.125, doer = "SubMachineGun", alt_mode = false, done = true},        
			{decal = "cinematics/vfx_materials/decals/blast_01.material", scale = 0.5, doer = "Cannon", done = true},
            
            {decal = {{.25, "cinematics/vfx_materials/decals/clawmark_01.material"},
                      {.25, "cinematics/vfx_materials/decals/clawmark_02.material"},
                      {.25, "cinematics/vfx_materials/decals/clawmark_03.material"},
                      {.25, "cinematics/vfx_materials/decals/clawmark_04.material"}}, scale = 0.25, doer = "SwipeShadowStep", done = true},
        },    
    },
    damage =
    {
        damageEffects =
        {
			{player_cinematic = "cinematics/materials/%s/axe.cinematic", doer = "Knife", done = true},
            {player_cinematic = "cinematics/marine/cannon_impact_explos.cinematic", doer = "Cannon", done = true},

            {player_cinematic = "cinematics/materials/robot/scrape.cinematic", surface = "robot", doer="SwipeShadowStep", done = true},
            {player_cinematic = "cinematics/materials/%s/scrape.cinematic", doer = "SwipeShadowStep", done = true},
        },        
    },
    
    damage_sound =
    {
        
        damageSounds =
        {
            {sound = "sound/ns2plus.fev/materials/metal/knife", surface = "metal", doer = "Knife", volume=0.5,  world_space = true, done = true},
            {sound = "sound/ns2plus.fev/materials/organic/knife", surface = "organic", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/ns2plus.fev/materials/organic/knife", surface = "infestation", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/ns2plus.fev/materials/rock/knife", surface = "rock", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/ns2plus.fev/materials/thin_metal/knife", surface = "thin_metal", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/ns2plus.fev/materials/armor/knife", surface = "armor", doer = "Knife",["volume"]=0.5, world_space = true, done = true},
            {sound = "sound/ns2plus.fev/materials/flesh/knife", surface = "flesh", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/ns2plus.fev/materials/membrane/knife", surface = "membrane", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/ns2plus.fev/materials/organic/knife", doer = "Knife",volume=0.5,  world_space = true,done = true},

            {sound = "sound/NS2.fev/alien/skulk/parasite_hit", doer = "VolleyRappel", world_space = true, done = true},

            {sound = "sound/NS2.fev/materials/metal/metal_scrape", surface = "metal", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/scrape", surface = "thin_metal", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/scrape", surface = "electronic", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/scrape", surface = "organic", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/scrape", surface = "infestation", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/scrape", surface = "rock", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/swipe_hit_marine", surface = "armor", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/swipe_hit_marine", surface = "flesh", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/scrape", surface = "membrane", doer = "SwipeShadowStep", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/metal_scrape", doer = "SwipeShadowStep", world_space = true, done = true},
        }
    },
}

GetEffectManager():AddEffectData("DamageEffects", kAdditionalEffects)