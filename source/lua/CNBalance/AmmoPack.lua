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

class 'SMGAmmo' (WeaponAmmoPack)
SMGAmmo.kMapName = "smgammo"
SMGAmmo.kModelName = PrecacheAsset("models/marine/rifle/RifleAmmo.model")

function SMGAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)    
    self:SetModel(SMGAmmo.kModelName)

end

function SMGAmmo:GetWeaponClassName()
    return "Submachinegun"
end

Shared.LinkClassToMap("SMGAmmo", SMGAmmo.kMapName)

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