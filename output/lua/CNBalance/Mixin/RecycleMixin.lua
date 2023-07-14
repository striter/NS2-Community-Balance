

function RecycleMixin:OnRecycled()
    if self.PreOnKill then
        self:PreOnKill(nil,nil,nil,nil) --The nil army!
    end
end

function RecycleMixin:OnResearchComplete(researchId)

    if researchId == kTechId.Recycle then

        -- Do not display new killfeed messages during concede sequence
        if GetConcedeSequenceActive() then
            return
        end

        self:TriggerEffects("recycle_end")

        -- Amount to get back, accounting for upgraded structures too
        local upgradeLevel = 0
        if self.GetUpgradeLevel then
            upgradeLevel = self:GetUpgradeLevel()
        end

        local amount = GetRecycleAmount(self:GetTechId(), upgradeLevel) or 0
        -- returns a scalar from 0-1 depending on health the structure has (at the present moment)
        local scalar = self:GetRecycleScalar() * kRecyclePaybackScalar

        -- We round it up to the nearest value thus not having weird
        -- fracts of costs being returned which is not suppose to be
        -- the case.
        local finalRecycleAmount = math.round(amount * scalar)

        self:GetTeam():AddTeamResources(finalRecycleAmount)

        self:GetTeam():PrintWorldTextForTeamInRange(kWorldTextMessageType.Resources, finalRecycleAmount, self:GetOrigin() + kWorldMessageResourceOffset, kResourceMessageRange)

        Server.SendNetworkMessage( "Recycle", BuildRecycleMessage(amount - finalRecycleAmount, self:GetTechId(), finalRecycleAmount), true )

        local team = self:GetTeam()
        local deathMessageTable = team:GetDeathMessage(team:GetCommander(), kDeathMessageIcon.Recycled, self)
        local func = Closure [=[
            self deathMessageTable
            args player
            Server.SendNetworkMessage(player:GetClient(), "DeathMessage", deathMessageTable, true)
        ]=]{deathMessageTable}
        team:ForEachPlayer(func)

        self.recycled = true
        self.timeRecycled = Shared.GetTime()

        self:OnRecycled()

    end

end