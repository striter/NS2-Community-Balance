Alien.kBountyThreshold = kBountyClaimMinAlien

function Alien:GetPlayerStatusDesc()

    local status = kPlayerStatus.Void
    
    if (self:GetIsAlive() == false) then
        status = kPlayerStatus.Dead
    else
        if (self:isa("Embryo")) then
            if self.gestationTypeTechId == kTechId.Skulk then
                status = kPlayerStatus.SkulkEgg
            elseif self.gestationTypeTechId == kTechId.Gorge then
                status = kPlayerStatus.GorgeEgg
            elseif self.gestationTypeTechId == kTechId.Lerk then
                status = kPlayerStatus.LerkEgg
            elseif self.gestationTypeTechId == kTechId.Fade then
                status = kPlayerStatus.FadeEgg
            elseif self.gestationTypeTechId == kTechId.Onos then
                status = kPlayerStatus.OnosEgg
            elseif self.gestationTypeTechId == kTechId.Prowler then
                status = kPlayerStatus.ProwlerEgg
            elseif self.gestationTypeTechId == kTechId.Vokex then
                status = kPlayerStatus.VokexEgg
            else
                status = kPlayerStatus.Embryo
            end
        else
            status = kPlayerStatus[self:GetClassName()]
        end
    end
    
    return status
end


 if Server then
--     -- ThirdPerson Codes
--     local function ThirdPerson(self)
--         if HasMixin(self, "CameraHolder") then

--             local numericDistance = 3
--             if self:GetIsThirdPerson() then
--                 numericDistance = 0
--             end
            
--             self:SetIsThirdPerson(numericDistance)
--         end
--     end

--     local baseHandleButtons = Alien.HandleButtons

--     local tpPressed = false

--     function Alien:HandleButtons(input)

--         baseHandleButtons(self,input)

--             if bit.band(input.commands, Move.Reload) ~= 0 then
--                 if not tpPressed then
--                     tpPressed=true
--                     ThirdPerson(self)
--                 end
--             else
--                 tpPressed=false
--             end
        
--     end

     function Alien:OnProcessMove(input)
         PROFILE("Alien:OnProcessMove")

         self.hasAdrenalineUpgrade = GetHasAdrenalineUpgrade(self)

         -- Update energy (server)
         self:GetEnergy()

         -- need to clear this value or spectators would see the hatch effect every time they cycle through players
         if self.hatched and self.creationTime + 3 < Shared.GetTime() then
             self.hatched = false
         end

         Player.OnProcessMove(self, input)

         -- In rare cases, Player.OnProcessMove() above may cause this entity to be destroyed.
         -- The below code assumes the player is not destroyed.
         if not self:GetIsDestroyed() then

             -- Calculate two and three hives so abilities for abilities
             UpdateAbilityAvailability(self, self:GetTierOneTechId(), self:GetTierTwoTechId(), self:GetTierThreeTechId())

             self.enzymed = self.timeWhenEnzymeExpires > Shared.GetTime()
             self.electrified = self.timeElectrifyEnds > Shared.GetTime()

             self:UpdateAutoHeal()
             self:UpdateSilenceLevel()
         end

     end
 end