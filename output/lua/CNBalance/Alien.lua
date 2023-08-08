Alien.kBountyThreshold = kBountyClaimMinAlien
Alien.kBountyDamageReceive = true

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


-- if Server then
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
-- end