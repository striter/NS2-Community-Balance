
if Server then

    function Exosuit:OnUseDeferred()

        local player = self.useRecipient
        self.useRecipient = nil

        if player and not player:GetIsDestroyed() and self:GetIsValidRecipient(player) then

            local weapons = player:GetWeapons()
            for i = 1, #weapons do
                weapons[i]:SetParent(nil)
            end

            local exoPlayer

            if self.layout == "MinigunMinigun" then
                exoPlayer = player:GiveDualExo()
            elseif self.layout == "RailgunRailgun" then
                exoPlayer = player:GiveDualRailgunExo()
            elseif self.layout == "ClawRailgun" then
                exoPlayer = player:GiveClawRailgunExo()
            else
                exoPlayer = player:GiveExo()
            end

            if exoPlayer then

                for i = 1, #weapons do
                    exoPlayer:StoreWeapon(weapons[i])
                end

                exoPlayer:SetMaxArmor(self:GetMaxArmor())
                exoPlayer:SetArmor(self:GetArmor())
                exoPlayer:SetFlashlightOn(self:GetFlashlightOn())
                exoPlayer:TransferParasite(self)
                exoPlayer:TransferExoVariant(self)

                -- Set the auto-weld cooldown of the player exo to match the cooldown of the dropped
                -- exo.
                local now = Shared.GetTime()
                local timeLastDamage = self:GetTimeOfLastDamage() or 0
                local waitEnd = timeLastDamage + kCombatTimeOut
                local cooldownEnd = math.max(waitEnd, self.timeNextWeld)
                local cooldownRemaining = math.max(0, cooldownEnd - now)
                exoPlayer.timeNextWeld = now + cooldownRemaining

                local newAngles = player:GetViewAngles()
                newAngles.pitch = 0
                newAngles.roll = 0
                newAngles.yaw = GetYawFromVector(self:GetCoords().zAxis)
                exoPlayer:SetOffsetAngles(newAngles)
                -- the coords of this entity are the same as the players coords when he left the exo, so reuse these coords to prevent getting stuck
                exoPlayer:SetCoords(self:GetCoords())

                player:TriggerEffects("pickup", { effectshostcoords = self:GetCoords() })

                DestroyEntity(self)

            end

        end

    end

end