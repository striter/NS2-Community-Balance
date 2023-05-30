local kAdditionalEffects =
{
    jump =
    {
        jumpSoundEffects =
        {
            --{sound = "", silenceupgrade = true, done = true},        

            {player_sound = "sound/NS2.fev/alien/skulk/jump_good", classname = "Prowler", done = true},
            {player_sound = "sound/NS2.fev/alien/fade/jump", classname = "Vokex", done = true},
        },
    },
    jump_best =
    {
        jumpBestSoundEffects =
        {
            --{sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/jump_best", classname = "Prowler", done = true},
        }
    },   
    
    jump_good =
    {
        jumpGoodSoundEffects =
        {
            --{sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/jump_good", classname = "Prowler", done = true},
        }
    },
    footstep =
    {
        footstepSoundEffects =
        {
            --{private_sound = "sound/NS2.fev/materials/metal/skulk_step_for_enemy", classname = "Prowler", surface = "metal", enemy = true, done = true},
            --{private_sound = "sound/NS2.fev/materials/metal/skulk_step", classname = "Prowler", surface = "metal", done = true},
    
            --{private_sound = "sound/NS2.fev/materials/thin_metal/skulk_step_for_enemy", classname = "Prowler", surface = "thin_metal", enemy = true, done = true},
            --{private_sound = "sound/NS2.fev/materials/thin_metal/skulk_step", classname = "Prowler", surface = "thin_metal", done = true},
            
            --{private_sound = "sound/NS2.fev/materials/organic/lerk_step_for_enemy", classname = "Prowler", surface = "organic", enemy = true, done = true},
            --{private_sound = "sound/NS2.fev/materials/organic/lerk_step", classname = "Prowler", surface = "organic", done = true},
            
            --{private_sound = "sound/NS2.fev/materials/rock/skulk_step_for_enemy", classname = "Prowler", surface = "rock", enemy = true, done = true},
            --{private_sound = "sound/NS2.fev/materials/rock/skulk_step", classname = "Prowler", surface = "rock", done = true},
            
            {sound = "sound/NS2.fev/materials/metal/skulk_step_for_enemy", classname = "Prowler", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/skulk_step", classname = "Prowler", surface = "metal", done = true},
            
            {sound = "sound/NS2.fev/materials/thin_metal/skulk_step_for_enemy", classname = "Prowler", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/skulk_step", classname = "Prowler", surface = "thin_metal", done = true},
            
            {sound = "sound/NS2.fev/materials/organic/skulk_step_for_enemy", classname = "Prowler", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/skulk_step", classname = "Prowler", surface = "organic", done = true},
            
            {sound = "sound/NS2.fev/materials/rock/skulk_step_for_enemy", classname = "Prowler", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/skulk_step", classname = "Prowler", surface = "rock", done = true},

            {sound = "sound/NS2.fev/materials/metal/fade_step_for_enemy", classname = "Vokex", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/fade_step", classname = "Vokex", surface = "metal", done = true},
            
            {sound = "sound/NS2.fev/materials/thin_metal/fade_step_for_enemy", classname = "Vokex", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/fade_step", classname = "Vokex", surface = "thin_metal", done = true},
            
            {sound = "sound/NS2.fev/materials/organic/fade_step_for_enemy", classname = "Vokex", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/fade_step", classname = "Vokex", surface = "organic", done = true},
            
            {sound = "sound/NS2.fev/materials/rock/fade_step_for_enemy", classname = "Vokex", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/fade_step", classname = "Vokex", surface = "rock", done = true},
        },
    },
    
    land = 
    {
        landSoundEffects = 
        {
            {player_sound = "sound/NS2.fev/alien/skulk/land", classname = "Prowler", done = true},
            {player_sound = "sound/NS2.fev/alien/fade/land", classname = "Vokex", done = true},
        }
    },
    
    taunt = 
    {
        tauntSound =
        {        
            {sound = "sound/NS2.fev/alien/common/swarm", classname = "Prowler", done = true},
            {sound = "sound/NS2.fev/alien/fade/taunt", classname = "Vokex", done = true},
        }
    },
}

GetEffectManager():AddEffectData("PlayerEffectData", kAdditionalEffects)
