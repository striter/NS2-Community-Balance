
function ArmsLab:GetTechButtons(techId)
    local techButtons = { kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3,kTechId.None,
    kTechId.Armor1, kTechId.Armor2, kTechId.Armor3, kTechId.None }

    if GetHasTech(self,kTechId.Weapons1) then
        techButtons[1] = kTechId.RifleUpgrade
    end

    if GetHasTech(self,kTechId.Armor1) then
        techButtons[5] = kTechId.NanoArmor
    end

    return techButtons
    
end