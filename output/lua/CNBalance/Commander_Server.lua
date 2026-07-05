
--Hook Commander:ProcessSuccessAction to track aggressive commander spending
local baseProcessSuccessAction = Commander.ProcessSuccessAction
function Commander:ProcessSuccessAction(techId)
    local team = self:GetTeam()
    if team then
        team:OnProcessAggressiveTechSuccessful(techId)
    end
    baseProcessSuccessAction(self, techId)
end
