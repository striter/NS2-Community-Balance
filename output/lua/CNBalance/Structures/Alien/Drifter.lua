Drifter.kMoveSpeed = 9
Drifter.kCelerityMoveSpeed = 11
Drifter.kTurnSpeed = 4 * math.pi

function Drifter:GetTechButtons(techId)

    local techButtons = { kTechId.EnzymeCloud, kTechId.Hallucinate, kTechId.MucousMembrane, kTechId.SelectHallucinations,
                          kTechId.Grow, kTechId.Move, kTechId.Patrol, kTechId.None }
    --[[
        if self.hasCelerity then
            techButtons[6] = kTechId.DrifterCelerity
        end

        if self.hasRegeneration then
            techButtons[7] = kTechId.DrifterRegeneration
        end

        if self.hasCamouflage then
            techButtons[8] = kTechId.DrifterCamouflage
        end
    --]]
    return techButtons

end