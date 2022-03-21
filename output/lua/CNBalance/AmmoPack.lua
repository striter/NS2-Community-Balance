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