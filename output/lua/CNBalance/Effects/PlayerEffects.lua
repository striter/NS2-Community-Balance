kPlayerEffectData =
{
    eject_exo_begin =
    {
        effects =
        {
            {private_sound = "sound/NS2.fev/marine/common/pickup_heavy", done = true}
        }
    },

    spawn_exo =
    {
        effects =
        {
            {cinematic = "cinematics/marine/structures/spawn_building_big.cinematic", done = true},
        }
    },

    -- TODO: hook up correct sound
    exo_thruster_start =
    {
        exoThrusterStartEffects =
        {
            {cinematic = "cinematics/marine/jetpack/impact.cinematic"},
            {parented_sound = "sound/NS2.fev/marine/heavy/thrusters", done = true},
        }
    },

    -- TODO: hook up correct sound
    exo_thruster_end =
    {
        exoThrusterEndEffects =
        {
            {stop_sound = "sound/NS2.fev/marine/heavy/thrusters", done = true},
        }
    },

    -- when hit by emp blast
    emp_blasted =
    {
        empBlastedEffects =
        {
            {cinematic = "cinematics/alien/emphit.cinematic", class = "Alien", done = true},
        }
    },

    enzymed =
    {
        enzymedEffects =
        {
            {parented_cinematic = "cinematics/alien/enzymed.cinematic", done = true},
        }
    },

    celerity_start =
    {
        celerityStartEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/common/celerity_start", done = true}
        }
    },

    celerity_end =
    {
        celerityEndEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/common/celerity_end", done = true}
        }
    },

    flap =
    {
        flapSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/lerk/flap", classname = "Lerk", done = true}
        }
    },

    jump_best =
    {
        jumpBestSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/jump_best", classname = "Skulk", done = true},
        }
    },

    jump_good =
    {
        jumpGoodSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/jump_good", classname = "Skulk", done = true},
        }
    },

    --[[
    Removed as FMOD event was muted during Sweets sounds-update, b323
    strafe_jump =
    {
        effects =
        {
            {player_sound = "sound/NS2.fev/marine/common/sprint_start", done = true},
        }
    },
    --]]

    jump =
    {
        jumpSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},

            {player_sound = "sound/NS2.fev/alien/skulk/jump", classname = "Skulk", done = true},
            {player_sound = "sound/NS2.fev/alien/gorge/jump", classname = "Gorge", done = true},
            {player_sound = "sound/NS2.fev/alien/fade/jump", classname = "Fade", done = true},
            {player_sound = "sound/NS2.fev/alien/onos/jump", classname = "Onos", done = true},
            {player_sound = "sound/NS2.fev/marine/heavy/jump", classname = "Exo", done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/jump", classname = "Prowler", done = true},
            {player_sound = "sound/NS2.fev/alien/fade/jump", classname = "Vokex", done = true},
            {player_sound = "sound/NS2.fev/marine/common/jump", classname = "Marine", done = true},
        },
    },
    -- triggered server side only since the required data on client is missing
    flinch =
    {
        flinchEffects =
        {
            -- marine flinch effects
            {sound = "sound/NS2.fev/marine/common/wound_bigmac", classname = "Marine", sex="bigmac", damagetype = kDamageType.Gas, world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/wound_bigmac", classname = "Marine", sex="bigmac", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/wound_bigmac_serious", classname = "Marine", sex = "bigmac", flinch_severe = true, world_space = true, done = true},

            {sound = "sound/NS2.fev/marine/common/spore_wound_female", classname = "Marine", sex = "female", damagetype = kDamageType.Gas, world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/spore_wound", classname = "Marine", damagetype = kDamageType.Gas, world_space = true, done = true},

            {sound = "sound/NS2.fev/marine/common/wound_serious_female", classname = "Marine", sex = "female", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/wound_serious", classname = "Marine", flinch_severe = true, world_space = true, done = true},

            {sound = "sound/NS2.fev/marine/common/wound_female", classname = "Marine", sex = "female", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/wound", classname = "Marine", world_space = true, done = true},

            {sound = "sound/NS2.fev/marine/structures/mac/pain", classname = "MAC", world_space = true, done = true},

            -- alien flinch effects
            {sound = "sound/NS2.fev/alien/skulk/wound_serious", classname = "Skulk", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/wound", classname = "Skulk", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/drifter/wound", classname = "Prowler", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/drifter/wound", classname = "Prowler", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/gorge/wound_serious", classname = "Gorge", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/gorge/wound", classname = "Gorge", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/lerk/wound_serious", classname = "Lerk", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/lerk/wound", classname = "Lerk", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/wound_serious", classname = "Fade", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/wound", classname = "Fade", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/wound_serious", classname = "Vokex", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/wound", classname = "Vokex", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/wound_serious", classname = "Onos", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/wound", classname = "Onos", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/drifter/wound", classname = "Drifter", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/shade/wound", classname = "Shade", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/hydra/wound", classname = "Hydra", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/crag/wound", classname = "Crag", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/whip/wound", classname = "Whip", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/harvester_wound", classname = "Harvester", world_space = true, done = true},
        },
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
            {cinematic = "cinematics/alien/onos/explode.cinematic", classname = "Onos", doer = "Railgun", done = true},
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

    footstep =
    {
        footstepSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            -- Use private_sounds (ie, don't send network message) because this is generated on the client
            -- when animation plays and conserves bandwidth
            -- TODO: Add looping metal layer ("sound/NS2.fev/materials/metal/skulk_layer")

            {sound = "", classname = "Drifter", done = true}, -- Hallucinations call this "footstep" effect

            -- Skulk
            {sound = "sound/NS2.fev/materials/metal/skulk_step_for_enemy", classname = "Skulk", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/skulk_step", classname = "Skulk", surface = "metal", done = true},

            {sound = "sound/NS2.fev/materials/thin_metal/skulk_step_for_enemy", classname = "Skulk", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/skulk_step", classname = "Skulk", surface = "thin_metal", done = true},

            {sound = "sound/NS2.fev/materials/organic/skulk_step_for_enemy", classname = "Skulk", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/skulk_step", classname = "Skulk", surface = "organic", done = true},

            {sound = "sound/NS2.fev/materials/rock/skulk_step_for_enemy", classname = "Skulk", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/skulk_step", classname = "Skulk", surface = "rock", done = true},

            -- Gorge
            {sound = "sound/NS2.fev/materials/metal/gorge_step_for_enemy", classname = "Gorge", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/gorge_step", classname = "Gorge", surface = "metal", done = true},

            {sound = "sound/NS2.fev/materials/thin_metal/gorge_step_for_enemy", classname = "Gorge", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/gorge_step", classname = "Gorge", surface = "thin_metal", done = true},

            {sound = "sound/NS2.fev/materials/organic/gorge_step_for_enemy", classname = "Gorge", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/gorge_step", classname = "Gorge", surface = "organic", done = true},

            {sound = "sound/NS2.fev/materials/rock/gorge_step_for_enemy", classname = "Gorge", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/gorge_step", classname = "Gorge", surface = "rock", done = true},

            -- Lerk
            {sound = "sound/NS2.fev/materials/metal/lerk_step_for_enemy", classname = "Lerk", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/lerk_step", classname = "Lerk", surface = "metal", done = true},

            {sound = "sound/NS2.fev/materials/thin_metal/lerk_step_for_enemy", classname = "Lerk", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/lerk_step", classname = "Lerk", surface = "thin_metal", done = true},

            {sound = "sound/NS2.fev/materials/organic/lerk_step_for_enemy", classname = "Lerk", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/lerk_step", classname = "Lerk", surface = "organic", done = true},

            {sound = "sound/NS2.fev/materials/rock/lerk_step_for_enemy", classname = "Lerk", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/lerk_step", classname = "Lerk", surface = "rock", done = true},

            -- Fade
            {sound = "sound/NS2.fev/materials/metal/fade_step_for_enemy", classname = "Fade", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/fade_step", classname = "Fade", surface = "metal", done = true},

            {sound = "sound/NS2.fev/materials/thin_metal/fade_step_for_enemy", classname = "Fade", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/fade_step", classname = "Fade", surface = "thin_metal", done = true},

            {sound = "sound/NS2.fev/materials/organic/fade_step_for_enemy", classname = "Fade", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/fade_step", classname = "Fade", surface = "organic", done = true},

            {sound = "sound/NS2.fev/materials/rock/fade_step_for_enemy", classname = "Fade", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/fade_step", classname = "Fade", surface = "rock", done = true},

            -- Onos
            {sound = "sound/NS2.fev/materials/metal/onos_step_for_enemy", classname = "Onos", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/onos_step", classname = "Onos", surface = "metal", done = true},

            {sound = "sound/NS2.fev/materials/thin_metal/onos_step_for_enemy", classname = "Onos", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/onos_step", classname = "Onos", surface = "thin_metal", done = true},

            {sound = "sound/NS2.fev/materials/organic/onos_step_for_enemy", classname = "Onos", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/onos_step", classname = "Onos", surface = "organic", done = true},

            {sound = "sound/NS2.fev/materials/rock/onos_step_for_enemy", classname = "Onos", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/onos_step", classname = "Onos", surface = "rock", done = true},

            {sound = "sound/NS2.fev/alien/onos/onos_step", classname = "Onos", done = true},

            --Prowler
            {sound = "sound/ns2plus.fev/prowler/step_metal_for_enemy", classname = "Prowler", surface = "metal", enemy = true, done = true},
            {sound = "sound/ns2plus.fev/prowler/step_metal", classname = "Prowler", surface = "metal", done = true},

            {sound = "sound/ns2plus.fev/prowler/step_thin_metal_for_enemy", classname = "Prowler", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/ns2plus.fev/prowler/step_thin_metal", classname = "Prowler", surface = "thin_metal", done = true},

            {sound = "sound/ns2plus.fev/prowler/step_organic_for_enemy", classname = "Prowler", surface = "organic", enemy = true, done = true},
            {sound = "sound/ns2plus.fev/prowler/step_organic", classname = "Prowler", surface = "organic", done = true},

            {sound = "sound/ns2plus.fev/prowler/step_rock_for_enemy", classname = "Prowler", surface = "rock", enemy = true, done = true},
            {sound = "sound/ns2plus.fev/prowler/step_rock", classname = "Prowler", surface = "rock", done = true},

            --Vokex
            {sound = "sound/NS2.fev/materials/metal/fade_step_for_enemy", classname = "Vokex", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/fade_step", classname = "Vokex", surface = "metal", done = true},

            {sound = "sound/NS2.fev/materials/thin_metal/fade_step_for_enemy", classname = "Vokex", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/fade_step", classname = "Vokex", surface = "thin_metal", done = true},

            {sound = "sound/NS2.fev/materials/organic/fade_step_for_enemy", classname = "Vokex", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/fade_step", classname = "Vokex", surface = "organic", done = true},

            {sound = "sound/NS2.fev/materials/rock/fade_step_for_enemy", classname = "Vokex", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/fade_step", classname = "Vokex", surface = "rock", done = true},
            -- Exo
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "Exo", surface = "metal", done = true},
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "Exo", surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "Exo", surface = "organic", done = true},
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "Exo", surface = "rock", done = true},

            -- Marine

            -- Sprint
            {sound = "sound/NS2.fev/materials/metal/sprint_left_for_enemy", left = true, sprinting = true, surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/sprint_left", left = true, sprinting = true, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/metal/sprint_right_for_enemy", left = false, sprinting = true, surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/sprint_right", left = false, sprinting = true, surface = "metal", done = true},

            {sound = "sound/NS2.fev/materials/thin_metal/sprint_left_for_enemy", left = true, sprinting = true, surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/sprint_left", left = true, sprinting = true, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/sprint_right_for_enemy", left = false, sprinting = true, surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/sprint_right", left = false, sprinting = true, surface = "thin_metal", done = true},

            {sound = "sound/NS2.fev/materials/organic/sprint_left_for_enemy", left = true, sprinting = true, surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/sprint_left", left = true, sprinting = true, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/organic/sprint_right_for_enemy", left = false, sprinting = true, surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/sprint_right", left = false, sprinting = true, surface = "organic", done = true},

            {sound = "sound/NS2.fev/materials/rock/sprint_left_for_enemy", left = true, sprinting = true, surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/sprint_left", left = true, sprinting = true, surface = "rock", done = true},
            {sound = "sound/NS2.fev/materials/rock/sprint_right_for_enemy", left = false, sprinting = true, surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/sprint_right", left = false, sprinting = true, surface = "rock", done = true},

            -- Backpedal
            {sound = "sound/NS2.fev/materials/metal/backpedal_left", left = true, forward = false, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/metal/backpedal_right", left = false, forward = false, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/backpedal_left", left = true, forward = false, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/backpedal_right", left = false, forward = false, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/organic/backpedal_left", left = true, forward = false, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/organic/backpedal_right", left = false, forward = false, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/rock/backpedal_left", left = true, forward = false, surface = "rock", done = true},
            {sound = "sound/NS2.fev/materials/rock/backpedal_right", left = false, forward = false, surface = "rock", done = true},

            -- Crouch
            {sound = "sound/NS2.fev/materials/metal/crouch_left", left = true, crouch = true, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/metal/crouch_right", left = false, crouch = true, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/crouch_left", left = true, crouch = true, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/crouch_right", left = false, crouch = true, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/organic/crouch_left", left = true, crouch = true, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/organic/crouch_right", left = false, crouch = true, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/rock/crouch_left", left = true, crouch = true, surface = "rock", done = true},
            {sound = "sound/NS2.fev/materials/rock/crouch_right", left = false, crouch = true, surface = "rock", done = true},

            -- Normal walk
            {sound = "sound/NS2.fev/materials/metal/footstep_left_for_enemy", left = true, surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/footstep_left", left = true, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/metal/footstep_right_for_enemy", left = false, surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/footstep_right", left = false, surface = "metal", done = true},

            {sound = "sound/NS2.fev/materials/thin_metal/footstep_left_for_enemy", left = true, surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/footstep_left", left = true, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/footstep_right_for_enemy", left = false, surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/footstep_right", left = false, surface = "thin_metal", done = true},

            {sound = "sound/NS2.fev/materials/organic/footstep_left_for_enemy", left = true, surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/footstep_left", left = true, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/organic/footstep_right_for_enemy", left = false, surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/footstep_right", left = false, surface = "organic", done = true},

            {sound = "sound/NS2.fev/materials/rock/footstep_left_for_enemy", left = true, surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/footstep_left", left = true, surface = "rock", done = true},
            {sound = "sound/NS2.fev/materials/rock/footstep_right_for_enemy", left = false, surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/footstep_right", left = false, surface = "rock", done = true},

        },
    },

    land =
    {
        landSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},

            {player_sound = "sound/NS2.fev/alien/skulk/land", classname = "Skulk", done = true},
            {player_sound = "sound/NS2.fev/alien/lerk/land", classname = "Lerk", done = true},
            {player_sound = "sound/NS2.fev/alien/gorge/land", classname = "Gorge", done = true},
            {player_sound = "sound/NS2.fev/alien/fade/land", classname = "Fade", done = true},
            {player_sound = "sound/NS2.fev/alien/onos/land", classname = "Onos", done = true},
            {player_sound = "sound/NS2.fev/marine/heavy/land", classname = "Exo", done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/land", classname = "Prowler", done = true},
            {player_sound = "sound/NS2.fev/alien/fade/land", classname = "Vokex", done = true},

            {player_sound = "sound/NS2.fev/materials/organic/fall", surface = "organic", classname = "Marine", done = true},
            {player_sound = "sound/NS2.fev/materials/thin_metal/fall", surface = "thin_metal", classname = "Marine", done = true},
            {player_sound = "sound/NS2.fev/materials/rock/fall", surface = "rock", classname = "Marine", done = true},
            {player_sound = "sound/NS2.fev/materials/metal/fall", classname = "Marine", done = true},

            {player_sound = "sound/NS2.fev/materials/organic/fall", surface = "organic", classname = "ReadyRoomPlayer", done = true},
            {player_sound = "sound/NS2.fev/materials/thin_metal/fall", surface = "thin_metal", classname = "ReadyRoomPlayer", done = true},
            {player_sound = "sound/NS2.fev/materials/rock/fall", surface = "rock", classname = "ReadyRoomPlayer", done = true},
            {player_sound = "sound/NS2.fev/materials/metal/fall", classname = "ReadyRoomPlayer", done = true},

        },

        landCinematics =
        {
            {cinematic = "cinematics/marine/heavy/land.cinematic", classname = "Exo", done = true},
        },
    },

    momentum_change =
    {
        momentumChangeEffects =
        {
            {cinematic = "cinematics/materials/metal/onos_momentum_change.cinematic",  doer = "Onos", surface = "metal", done = true},
            {cinematic = "cinematics/materials/thin_metal/onos_momentum_change.cinematic",  doer = "Onos", surface = "thin_metal", done = true},
            {cinematic = "cinematics/materials/organic/onos_momentum_change.cinematic",  doer = "Onos", surface = "organic", done = true},
            {cinematic = "cinematics/materials/rock/onos_momentum_change.cinematic",  doer = "Onos", surface = "rock", done = true},
        }
    },

    taunt =
    {
        tauntSound =
        {
            {sound = "", silenceupgrade = true, done = true},

            {sound = "sound/NS2.fev/alien/skulk/taunt", classname = "Skulk", done = true},
            {sound = "sound/NS2.fev/alien/gorge/taunt", classname = "Gorge", done = true},
            {sound = "sound/NS2.fev/alien/lerk/taunt", classname = "Lerk", done = true},
            {sound = "sound/NS2.fev/alien/fade/taunt", classname = "Fade", done = true},
            {sound = "sound/NS2.fev/alien/onos/taunt", classname = "Onos", done = true},
            {sound = "sound/NS2.fev/alien/common/swarm", classname = "Prowler", done = true},
            {sound = "sound/NS2.fev/alien/fade/taunt", classname = "Vokex", done = true},
            {sound = "sound/NS2.fev/marine/voiceovers/taunt_female", classname = "Marine", sex = "female", done = true},
            {sound = "sound/NS2.fev/marine/voiceovers/taunt", classname = "Marine", done = true},

        }
    },

    teleport =
    {
        teleportSound =
        {
            {private_sound = "sound/NS2.fev/marine/structures/phase_gate_teleport_2D", classname = "Marine"},
        }
    },

    player_beacon =
    {
        playerBeaconEffects =
        {
            {parented_cinematic = "cinematics/marine/beacon_big.cinematic", classname = "Exosuit", done = true},
            {parented_cinematic = "cinematics/marine/beacon.cinematic"},
        }
    },

}

GetEffectManager():AddEffectData("PlayerEffectData", kPlayerEffectData)
