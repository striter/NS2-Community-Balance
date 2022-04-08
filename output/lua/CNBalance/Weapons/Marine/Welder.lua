function Welder:GetReplacementWeaponMapName()
    return GetHasTech(self,kTechId.AxeUpgrade) and Axe.kMapName or Knife.kMapName
end

function Welder:GetObseleteWeaponNames()
    return Axe.kMapName, Knife.kMapName
end
