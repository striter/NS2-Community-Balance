

function PrototypeLab:GetTechButtons(techId)
    local techTable = { kTechId.JetpackTech, kTechId.None, kTechId.None, kTechId.None, 
             kTechId.ExosuitTech, kTechId.None, kTechId.None, kTechId.None }
             
    return techTable
end


--function PrototypeLab:GetCanBeUsed(player, useSuccessTable)
--
--    if player:isa("Exo") then
--        useSuccessTable.useSuccess = false
--    end
--
--end