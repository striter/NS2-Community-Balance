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
        },    
    },
    damage =
    {
        damageEffects =
        {
			{player_cinematic = "cinematics/materials/%s/axe.cinematic", doer = "Knife", done = true},
        },        
    },
    
    damage_sound =
    {
        
        damageSounds =
        {
            {sound = "sound/combat.fev/combat/materials/metal/knife/knife", surface = "metal", doer = "Knife", volume=0.5,  world_space = true, done = true},
            {sound = "sound/combat.fev/combat/materials/organic/knife/knife", surface = "organic", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/combat.fev/combat/materials/organic/knife/knife", surface = "infestation", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/combat.fev/combat/materials/rock/knife/knife", surface = "rock", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/combat.fev/combat/materials/thin_metal/knife/knife", surface = "thin_metal", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/combat.fev/combat/materials/armor/knife/knife", surface = "armor", doer = "Knife",["volume"]=0.5, world_space = true, done = true},
            {sound = "sound/combat.fev/combat/materials/flesh/knife/knife", surface = "flesh", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/combat.fev/combat/materials/membrane/knife/knife", surface = "membrane", doer = "Knife",volume=0.5, world_space = true, done = true},
            {sound = "sound/combat.fev/combat/materials/organic/knife/knife", doer = "Knife",volume=0.5,  world_space = true,done = true},

            {sound = "sound/NS2.fev/alien/skulk/parasite_hit", doer = "VolleyRappel", world_space = true, done = true},
        }
    },
}

GetEffectManager():AddEffectData("DamageEffects", kAdditionalEffects)