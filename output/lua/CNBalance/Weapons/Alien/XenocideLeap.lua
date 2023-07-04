local function CheckForDestroyedEffects(self)
    if self.XenocideSoundName and not IsValid(self.XenocideSoundName) then
        self.XenocideSoundName = nil
    end
end

local function CleanUI(self)

    if self.xenocideGui ~= nil then
    
        GetGUIManager():DestroyGUIScript(self.xenocideGui)
        self.xenocideGui = nil
        
    end
    
end
    
function XenocideLeap:OnProcessMove(input)

    BiteLeap.OnProcessMove(self, input)

    local player = self:GetParent()
    if self.xenociding then

        if player:isa("Commander") then
            StopXenocide(self)
        elseif Server then

            CheckForDestroyedEffects( self )

            self.xenocideTimeLeft = math.max(self.xenocideTimeLeft - input.time, 0)

            if self.xenocideTimeLeft == 0 and player:GetIsAlive() then

                local xenoOrigin = player.GetEngagementPoint and player:GetEngagementPoint() or (player:GetOrigin() + Vector(0,0.5,0))

                player:TriggerEffects("xenocide", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})

                local xenocideFuel = GetIsTechUnlocked(self,kTechId.XenocideFuel)
                local damage = xenocideFuel and kXenocideFuelDamage or kXenocideDamage
                local range = xenocideFuel and kXenocideFuelRange or kXenocideRange
                local hitEntities = GetEntitiesWithMixinWithinRange("Live", xenoOrigin, range)
                table.removevalue(hitEntities, player)

                RadiusDamage(hitEntities, xenoOrigin, range, damage, self)

                player.spawnReductionTime = xenocideFuel and kXenocideFuelSpawnReduction or kXenocideSpawnReduction

                player:SetBypassRagdoll(true)

                player:Kill(player, self)

                if self.XenocideSoundName then
                    self.XenocideSoundName:Stop()
                    self.XenocideSoundName = nil
                end
            end
            if Server and not player:GetIsAlive() and self.XenocideSoundName and self.XenocideSoundName:GetIsPlaying() == true then
                self.XenocideSoundName:Stop()
                self.XenocideSoundName = nil
            end

        elseif Client and not player:GetIsAlive() and self.xenocideGui then
            CleanUI(self)
        end

    end

end
