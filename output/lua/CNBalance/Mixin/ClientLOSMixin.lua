if Server then
    local kAllowedLOSWeapon = debug.getupvaluex(IsAllowedWeaponToMarkEnemy, "kAllowedLOSWeapon")
    local kAllowedOtherWeapon = debug.getupvaluex(IsAllowedWeaponToMarkEnemy, "kAllowedOtherWeapon")

    kAllowedLOSWeapon[kTechId.Revolver] = true
    kAllowedLOSWeapon[kTechId.SubMachineGun] = true
    kAllowedLOSWeapon[kTechId.LightMachineGun] = true
    kAllowedLOSWeapon[kTechId.Cannon] = true
    kAllowedLOSWeapon[kTechId.Volley] = true
    kAllowedOtherWeapon[kTechId.AcidSpray] = true
end