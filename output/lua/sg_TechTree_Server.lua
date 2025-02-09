--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

-- disable specific techs to be available before BOTH doors are opened:
-- - 'contamination' .. as it allows exploits

-- Add to list as needed to disable techs
local techDisableList = {
    [kTechId.Contamination] = true,
    [kTechId.TeleportEgg] = true
}

local ns2_SetTechNodeChanged = TechTree.SetTechNodeChanged
function TechTree:SetTechNodeChanged(node, logMsg)
    if techDisableList[node:GetTechId()] then
        local front, siege, suddendeath = GetGameInfoEntity():GetSiegeTimes()
        if front > 0 and siege > 0 then
            node.available = false
            return
        end

    end
    ns2_SetTechNodeChanged(self, node, logMsg)
end
