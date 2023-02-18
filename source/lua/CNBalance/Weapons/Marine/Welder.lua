function Welder:GetReplacementWeaponMapName()
    return Axe.kMapName or Knife.kMapName
end

function Welder:GetObseleteWeaponNames()
    return Axe.kMapName , Knife.kMapName
end
