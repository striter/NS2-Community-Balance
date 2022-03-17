-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\MarineWeaponEffects.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kAdditionalEffects =
{
    shotgun_attack_secondary = 
    {
        shotgunAttacksSecondary = 
        {
            {viewmodel_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle", empty = false},
            {weapon_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle", empty = false},

            {player_sound = "sound/NS2.fev/marine/shotgun/fire_upgrade_3", done = true},
        },
        
    },
}

GetEffectManager():AddEffectData("MarineWeaponEffects", kAdditionalEffects)