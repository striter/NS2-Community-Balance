function TeamDeathMessageMixin:OnEntityKilled(targetEntity, killer, doer)

    if Server then

        -- Do not display new killfeed messages during concede sequence
        if GetConcedeSequenceActive() then
            return
        end

        if not targetEntity or targetEntity:GetSendDeathMessage(self, killer) then

            local index = kDeathMessageIcon.None

            if targetEntity.consumed then

                index = kDeathMessageIcon.Consumed
--------------
            elseif targetEntity.recycled then

                index = kDeathMessageIcon.Recycled
---------------
            elseif doer and doer.GetDeathIconIndex then

                index = doer:GetDeathIconIndex()
                assert(type(index) == "number")

            end

            local deathMessageTable = self:GetDeathMessage(killer, index, targetEntity)
            local func = Closure [==[
                self deathMessageTable
                args player
                if player:GetClient() then Server.SendNetworkMessage(player:GetClient(), "DeathMessage", deathMessageTable, true) end
            ]==] {deathMessageTable}
            self:ForEachPlayer(func)
        end
    end
end