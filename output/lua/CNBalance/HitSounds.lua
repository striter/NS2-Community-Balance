if Server then
    local kHitSoundEnabledForWeapon = debug.getupvaluex(HitSound_IsEnabledForWeapon, "kHitSoundEnabledForWeapon")
    kHitSoundEnabledForWeapon[kTechId.Volley] = true
    kHitSoundEnabledForWeapon[kTechId.SwipeShadowStep] = true
    kHitSoundEnabledForWeapon[kTechId.Revolver] = true
    kHitSoundEnabledForWeapon[kTechId.SubMachineGun] = true
    kHitSoundEnabledForWeapon[kTechId.LightMachineGun] = true
    kHitSoundEnabledForWeapon[kTechId.Knife] = true
    kHitSoundEnabledForWeapon[kTechId.Cannon] = true
end