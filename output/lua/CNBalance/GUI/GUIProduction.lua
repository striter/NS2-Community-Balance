local baseUpdateTech = GUIProduction.UpdateTech

function GUIProduction:UpdateTech(onChange)

    local teamInfo = GetEntitiesForTeam("TeamInfo", self.TeamIndex)[1]
    if not teamInfo then
        baseUpdateTech(self, onChange)
        return
    end

    local _, techIds2 = teamInfo:GetRelevantTech(2)
    if #techIds2 == 0 then
        baseUpdateTech(self, onChange)
        return
    end

    self.PrevTechActive = self.prevTechActive1 or 0
    self.PrevTechOwned = self.prevTechOwned1 or 0
    teamInfo.techGroupIndex = 1
    baseUpdateTech(self, onChange)
    self.prevTechActive1 = self.PrevTechActive
    self.prevTechOwned1 = self.PrevTechOwned

    self.PrevTechActive = self.prevTechActive2 or 0
    self.PrevTechOwned = self.prevTechOwned2 or 0
    teamInfo.techGroupIndex = 2
    baseUpdateTech(self, onChange)
    teamInfo.techGroupIndex = nil
    self.prevTechActive2 = self.PrevTechActive
    self.prevTechOwned2 = self.PrevTechOwned

end

local baseSetTeam = GUIProduction.SetTeam
function GUIProduction:SetTeam(teamIndex)
    baseSetTeam(self, teamIndex)
    self.prevTechActive1 = nil
    self.prevTechOwned1 = nil
    self.prevTechActive2 = nil
    self.prevTechOwned2 = nil
    self.PrevTechActive = 0
    self.PrevTechOwned = 0
    self:UpdateTech()
end
