

if Server then
    local kDestroyedSound = PrecacheAsset("sound/NS2.fev/marine/power_node/destroyed")
    local kDestroyedPowerDownSound = PrecacheAsset("sound/NS2.fev/marine/power_node/destroyed_powerdown")
    local kAuxPowerBackupSound = PrecacheAsset("sound/NS2.fev/marine/power_node/backup")
    
    local function PlayAuxSound(self)

        if not self:GetIsDisabled() then
            self:PlaySound(kAuxPowerBackupSound)
        end

    end
    
    function PowerPoint:OnKill(attacker, doer, point, direction)

        ScriptActor.OnKill(self, attacker, doer, point, direction)

        self:StopDamagedSound()

        self:MarkBlipDirty()

        self:PlaySound(kDestroyedSound)
        self:PlaySound(kDestroyedPowerDownSound)

        self:SetInternalPowerState(PowerPoint.kPowerState.destroyed)

        self:SetLightMode(kLightMode.NoPower)

        -- Remove effects such as parasite when destroyed.
        self:ClearGameEffects()
        
        --if attacker and attacker:isa("Player") and GetEnemyTeamNumber(self:GetTeamNumber()) == attacker:GetTeamNumber() then
        --    attacker:AddScore(self:GetPointValue())
        --end

        -- Let the team know the power is down.
        SendTeamMessage(self:GetTeam(), kTeamMessageTypes.PowerLost, self:GetLocationId())

        -- A few seconds later, switch on aux power.
        self:AddTimedCallback(PlayAuxSound, 4)
        self.timeOfDestruction = Shared.GetTime()

    end

end 