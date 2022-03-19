if Server then
    local kAllowedLOSWeapon = debug.getupvaluex(IsAllowedWeaponToMarkEnemy, "kAllowedLOSWeapon")
    local kAllowedOtherWeapon = debug.getupvaluex(IsAllowedWeaponToMarkEnemy, "kAllowedOtherWeapon")
    
    kAllowedLOSWeapon[kTechId.Volley] = true
    kAllowedOtherWeapon[kTechId.AcidSpray] = true
end