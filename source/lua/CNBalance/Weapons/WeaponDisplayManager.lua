local GetWeaponClassesToPreload = WeaponDisplayManager.GetWeaponClassesToPreload
function WeaponDisplayManager:GetWeaponClassesToPreload()
    local classList = GetWeaponClassesToPreload(self)
    assert(Revolver)    table.insert(classList, Revolver)
    assert(SubMachineGun)    table.insert(classList, SubMachineGun)
    assert(LightMachineGun)    table.insert(classList, LightMachineGun)
    assert(Cannon)    table.insert(classList, Cannon)
    return classList
end