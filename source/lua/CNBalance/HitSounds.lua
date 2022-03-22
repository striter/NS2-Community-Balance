if Server then
    local kHitSoundEnabledForWeapon = debug.getupvaluex(HitSound_IsEnabledForWeapon, "kHitSoundEnabledForWeapon")
    kHitSoundEnabledForWeapon[kTechId.Volley] = true
    kHitSoundEnabledForWeapon[kTechId.Revolver] = true
    kHitSoundEnabledForWeapon[kTechId.Submachinegun] = true
    kHitSoundEnabledForWeapon[kTechId.Cannon] = true
end