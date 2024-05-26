
--Called via timed callback defined in CommandStructure.lua - OnCreate
function CommandStructure:UpdateDangerMusicState()

    local time = Shared.GetTime()

    if not self.dangerMusicActive then

        local isValidStructure =
        self:GetIsAlive() and self:GetIsBuilt() and GetGamerules():GetGameStarted() and
                self:GetIsInCombat() and self:GetHealthScalar() <= kDangerMusicHealthStartAmount and
                not self.dangerMusicActive and self:GetTeam():GetNumCommandStructures() == 1

        if isValidStructure then

            self.dangerMusicActive = true
            self.lastDangerMusicTime = time

            --send to all, reliable channel
            Server.SendNetworkMessage("DangerMusicUpdate", { origin = self:GetOrigin(), teamIndex = self:GetTeamNumber(), active = self.dangerMusicActive }, true )

        end

    else

        --Only send no danger when game is still going
        local noDanger =
        not self:GetIsInCombat() and self.lastDangerMusicTime + kDangerMusicMinDelayTime <= time and
                not GetGameInfoEntity():GetGameEnded() and self:GetIsAlive() and
                self:GetTeam():GetNumCommandStructures() == 1

        if noDanger then

            self.dangerMusicActive = false
            self.lastDangerMusicTime = time

            --send to all, reliable channel
            Server.SendNetworkMessage("DangerMusicUpdate", { origin = self:GetOrigin(), teamIndex = self:GetTeamNumber(), active = self.dangerMusicActive }, true )

        end

    end

    --always repeat callback
    return true

end


function CommandStructure:OnDestroy()

    -- NOTE: Shared.GetEntity(self.objectiveInfoEntId) shouldn't be needed here.
    -- Please remove this code once we have the EntityRef() object implemented.
    if self.objectiveInfoEntId and self.objectiveInfoEntId ~= Entity.invalidId and Shared.GetEntity(self.objectiveInfoEntId) then

        DestroyEntity(Shared.GetEntity(self.objectiveInfoEntId))
        self.objectiveInfoEntId = Entity.invalidId

    end

    -- NOTE: immediately cancels danger music when chair destroyed as this chair will no longer be around to ensure it's stopped "at the right time"
    -- Danger music is allowed to continue as "end game" music if this was the last structure on the team
    if self.dangerMusicActive then
        Server.SendNetworkMessage("DangerMusicUpdate", { origin = self:GetOrigin(), teamIndex = self:GetTeamNumber(), active = false })
    end

    ScriptActor.OnDestroy(self)

end