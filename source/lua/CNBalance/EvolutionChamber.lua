EvolutionChamber.kUpgradeButtons [kTechId.SkulkMenu] = { kTechId.Leap, kTechId.Xenocide, kTechId.XenocideFuel, kTechId.None,
                                                         kTechId.None, kTechId.None, kTechId.None, kTechId.None }
                                                        
EvolutionChamber.kUpgradeButtons[kTechId.OnosMenu]= { kTechId.Devour, kTechId.BoneShield, kTechId.Stomp, kTechId.None,
                                                      kTechId.None, kTechId.None, kTechId.None, kTechId.None }

EvolutionChamber.kUpgradeButtons[kTechId.ProwlerMenu] = { kTechId.AcidSpray,kTechId.None, kTechId.None, kTechId.None,
                                                      kTechId.None, kTechId.None, kTechId.None, kTechId.None }
                      
EvolutionChamber.kUpgradeButtons[kTechId.VokexMenu] = { kTechId.ShadowStep,kTechId.AcidRocket, kTechId.None, kTechId.None,
                                                       kTechId.None, kTechId.None, kTechId.None, kTechId.None }

function EvolutionChamber:GetTechButtons(techId)

    local techButtons = { kTechId.SkulkMenu, kTechId.GorgeMenu, kTechId.LerkMenu, kTechId.FadeMenu,
                        kTechId.OnosMenu, kTechId.ProwlerMenu, kTechId.VokexMenu, kTechId.None }

    local returnButton = kTechId.Return
    if self.kUpgradeButtons[techId] then
        techButtons = self.kUpgradeButtons[techId]
        returnButton = kTechId.RootMenu
    end

    techButtons[8] = returnButton

    if self:GetIsResearching() then
        techButtons[7] = kTechId.Cancel
    else
        techButtons[7] = kTechId.None
    end

    return techButtons

end