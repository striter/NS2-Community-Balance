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

     local baseOnCreate = Alien.OnCreate
     function Alien:OnCreate()
         self.condenseScale = 1
         baseOnCreate(self)
     end


     function Alien:OnProcessMove(input)
         PROFILE("Alien:OnProcessMove")

         self.hasAdrenalineUpgrade = GetHasAdrenalineUpgrade(self)

         -- Update energy (server)
         self:GetEnergy()

         -- need to clear this value or spectators would see the hatch effect every time they cycle through players
         if self.hatched and self.creationTime + 3 < Shared.GetTime() then
             self.hatched = false
         end

         if GetIsUnitActive(self) then
             self:UpdateCondenseLevel()
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
             self:UpdatePhantom()
         end
     end

     function Alien:UpdateCondenseLevel()
         if GetHasCondenseUpgrade(self) then
             self.condenseScale =  1 - self:GetCondenseScalePerLevel() * self:GetShellLevel()
         else
             self.condenseScale = 1
         end
     end

     function Alien:GetPlayerScale(deltaTime)
         return Player.GetPlayerScale(self,deltaTime) * self.condenseScale
     end

     function Alien:GetCondenseScalePerLevel()
         return 0.08
     end


     local kPhantomHallucinationClassNameMap

     local function TrySpawnPhantom(self)
         if not GetHasPhantomUpgrade(self) then return end
         if not self:GetIsAlive() then return end
         if self.isHallucination then return end
         
         local veilLevel = self:GetVeilLevel()
         if veilLevel == 0 then return end
         local cooldown = kPhantomCooldown[veilLevel] or kPhantomCooldown[1]
         if self.timeLastPhantom and (Shared.GetTime() - self.timeLastPhantom) < cooldown then
             return
         end

         local mapName = self:GetMapName()
         if not kPhantomHallucinationClassNameMap then
             kPhantomHallucinationClassNameMap = debug.getupvaluex(HallucinationCloud.Perform, "kHallucinationClassNameMap")
         end
         local hallucinationClassName = kPhantomHallucinationClassNameMap[mapName] or SkulkHallucination.kMapName

         local extents = LookupTechData(self:GetTechId(), kTechDataMaxExtents, Vector(Skulk.kXExtents, Skulk.kYExtents, Skulk.kZExtents))
         local _, capsuleRadius = GetTraceCapsuleFromExtents(extents)
         local spawnPoint
         for _ = 1, 3 do
             spawnPoint = GetRandomSpawnForCapsule(extents.y, capsuleRadius, self:GetModelOrigin(), 0.5, 5)
             if spawnPoint then break end
         end

         if spawnPoint then
             local phantom = CreateEntity(hallucinationClassName, spawnPoint, self:GetTeamNumber())
             phantom:SetEmulation(self)

             self:TriggerEffects("phantom_spawn", { effecthostcoords = Coords.GetTranslation(self:GetOrigin()) })

             local randomDestinations = GetRandomPointsWithinRadius(self:GetOrigin(), 4, 15, 10, 1, 1, nil, nil)
             if randomDestinations[1] then
                 phantom:GiveOrder(kTechId.Move, nil, randomDestinations[1], nil, true, true)
             end

             self.timeLastPhantom = Shared.GetTime()
         end
     end


     local kPhantomCheckInterval = 1
     function Alien:UpdatePhantom()
         -- Throttle first (cheap subtraction) before any expensive calls
         if not self.timeLastPhantomCheck or (Shared.GetTime() - self.timeLastPhantomCheck) >= kPhantomCheckInterval then
             self.timeLastPhantomCheck = Shared.GetTime()
             
             if GetIsUnitActive(self) and self:GetIsSighted() and GetHasPhantomUpgrade(self) then
                 TrySpawnPhantom(self)
             end
         end
     end

     
     function Alien:OnDetectedChange(detected)
         if not detected then return end
         TrySpawnPhantom(self)
     end
 end