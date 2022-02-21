
function ArmsLab:GetTechButtons(techId)
    local techButtons = { kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3,kTechId.LifeSustain,
    kTechId.Armor1, kTechId.Armor2, kTechId.Armor3, kTechId.None }

    if GetHasTech(self,kTechId.LifeSustain) then
        techButtons[4] = kTechId.NanoArmor
    end

    return techButtons
    
end