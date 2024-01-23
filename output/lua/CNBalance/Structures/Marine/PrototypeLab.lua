

function PrototypeLab:GetTechButtons(techId)
    local techTable = { kTechId.JetpackTech, kTechId.CannonTech, kTechId.None, kTechId.None, 
             kTechId.ExosuitTech, kTechId.None, kTechId.None, kTechId.None }
             
    return techTable
end

function PrototypeLab:GetItemList(forPlayer)

    return { kTechId.Jetpack, kTechId.DualMinigunExosuit, kTechId.DualRailgunExosuit, kTechId.Cannon}

end

--local baseGetCanBeUsed = PrototypeLab.GetCanBeUsed
--function PrototypeLab:GetCanBeUsed(player, useSuccessTable)
--
--    baseGetCanBeUsed(self,player,useSuccessTable)
--    if GetHasTech(self,kTechId.MilitaryProtocol) then
--        useSuccessTable.useSuccess = false
--    end
--
--end