local GetWeaponClassesToPreload = WeaponDisplayManager.GetWeaponClassesToPreload
function WeaponDisplayManager:GetWeaponClassesToPreload()
    local classList = GetWeaponClassesToPreload(self)
    assert(Submachinegun)    table.insert(classList, Submachinegun)
    assert(Revolver)    table.insert(classList, Revolver)
    assert(Cannon)    table.insert(classList, Cannon)
    return classList
end