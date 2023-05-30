class 'RevolverAmmo' (WeaponAmmoPack)
RevolverAmmo.kMapName = "revolverammo"
RevolverAmmo.kModelName = PrecacheAsset("models/marine/rifle/RifleAmmo.model")

function RevolverAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)    
    self:SetModel(RevolverAmmo.kModelName)

end

function RevolverAmmo:GetWeaponClassName()
    return "Revolver"
end

Shared.LinkClassToMap("RevolverAmmo", RevolverAmmo.kMapName)

------------
class 'SubMachineGunAmmo' (WeaponAmmoPack)
SubMachineGunAmmo.kMapName = "SubMachineGunAmmo"
SubMachineGunAmmo.kModelName = PrecacheAsset("models/marine/rifle/RifleAmmo.model")

function SubMachineGunAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)    
    self:SetModel(SubMachineGunAmmo.kModelName)

end

function SubMachineGunAmmo:GetWeaponClassName()
    return "SubMachineGun"
end

Shared.LinkClassToMap("SubMachineGunAmmo", SubMachineGunAmmo.kMapName)


------------
class 'LightMachineGunAmmo' (WeaponAmmoPack)
LightMachineGunAmmo.kMapName = "LightMachineGunAmmo"
LightMachineGunAmmo.kModelName = PrecacheAsset("models/marine/rifle/RifleAmmo.model")

function LightMachineGunAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)    
    self:SetModel(LightMachineGunAmmo.kModelName)

end

function LightMachineGunAmmo:GetWeaponClassName()
    return "LightMachineGun"
end

Shared.LinkClassToMap("LightMachineGunAmmo", LightMachineGunAmmo.kMapName)

--------
class 'CannonAmmo' (WeaponAmmoPack)
CannonAmmo.kMapName = "cannonammo"
CannonAmmo.kModelName = PrecacheAsset("models/marine/rifle/RifleAmmo.model")

function CannonAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)    
    self:SetModel(CannonAmmo.kModelName)

end

function CannonAmmo:GetWeaponClassName()
    return "Cannon"
end

Shared.LinkClassToMap("CannonAmmo", CannonAmmo.kMapName)