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

     local baseHandleButtons = Alien.HandleButtons
     function Alien:HandleButtons(input)
         PROFILE("Alien:HandleButtons")
         baseHandleButtons(self, input)

         if not self:GetIsDestroyed() then
             local useDown = bit.band(input.commands, Move.Use) ~= 0
             if useDown then
                 if not self._returnToHiveHoldStart then
                     self._returnToHiveHoldStart = Shared.GetTime()
                 end
             else
                 self._returnToHiveHoldStart = nil
             end
         end

     end

     local baseOnCreate = Alien.OnCreate
     function Alien:OnCreate()
         self.condenseScale = 1
         baseOnCreate(self)
     end


     local baseOnProcessMove = Alien.OnProcessMove
     function Alien:OnProcessMove(input)
         PROFILE("Alien:OnProcessMove")
         baseOnProcessMove(self, input)
         if not self:GetIsDestroyed() then
             self:UpdateReturnToHive()
         end
     end

     function Alien:UpdateReturnToHive()
         PROFILE("UpdateReturnToHive")
         if not self._returnToHiveHoldStart or not GetHasTech(self, kTechId.ShiftHive) then
             return
         end
         
         -- Check proximity to any active Shift
         local shifts = GetEntitiesForTeam("Shift", self:GetTeamNumber())
         local nearShift = false
         local echoLocationId = 0
         if shifts then
             for _, shift in ipairs(shifts) do
                 if GetIsUnitActive(shift) then
                     if (self:GetOrigin() - shift:GetOrigin()):GetLengthSquared() <= 6.25 then
                         nearShift = true
                         echoLocationId = shift.echoLocationId
                         break
                     end
                 end
             end
         end
         
         if not nearShift then
             self._returnToHiveHoldStart = nil
         elseif Shared.GetTime() - self._returnToHiveHoldStart >= 0.6 then
             self._returnToHiveHoldStart = nil
             self:ReturnToLocation(echoLocationId)
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
         return 0.09
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

     function Alien:ReturnToLocation(echoLocationId)

         PROFILE("Alien:ReturnToLocation")

         -- Don't return if already gestating or dead
         if self:GetIsDestroyed() or not self:GetIsAlive() then return end

         local spawnPos
         local spawnAngles
         local eggs = GetEntitiesForTeam("Egg", self:GetTeamNumber())
         local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
         
         -- Check if this location has an alive hive
         local targetHive = nil
         if hives and echoLocationId and echoLocationId > 0 then
             for _, hive in ipairs(hives) do
                 if hive:GetIsAlive() and hive:GetIsBuilt() and hive:GetLocationId() == echoLocationId then
                     targetHive = hive
                     break
                 end
             end
         end

         if not targetHive then
             Server.PlayPrivateSound(self, "sound/NS2.fev/interface/error", self, 1.0, Vector(0, 0, 0))
             return
         end
         
         -- Try to find an unselected Egg near this hive
         if eggs then
             for _, egg in ipairs(eggs) do
                 if not egg:GetIsDestroyed() and egg:GetIsFree() and (egg:GetOrigin() - targetHive:GetOrigin()):GetLengthSquared() <= 900 then
                     spawnPos = Vector(egg:GetOrigin())
                     spawnAngles = egg:GetAngles()
                     DestroyEntity(egg)
                     break
                 end
             end
         end

         if not spawnPos then
             -- No available egg, use hive's spawn points
             if targetHive.eggSpawnPoints and #targetHive.eggSpawnPoints > 0 then
                 spawnPos = targetHive.eggSpawnPoints[math.random(1, #targetHive.eggSpawnPoints)]
             else
                 spawnPos = Vector(targetHive:GetOrigin())
             end
         end

         -- Save data before replacement
         local healthScalar = self:GetHealthScalar()
         local armorScalar = self:GetArmorScalar()
         local currentTechId = self:GetTechId()
         local upgrades = self:GetUpgrades() or {}

         -- Replace current player with Embryo
         local newPlayer = self:Replace(Embryo.kMapName)

         if newPlayer and newPlayer:isa("Embryo") then
             -- Teleport to spawn position
             newPlayer:SetOrigin(spawnPos)
             if spawnAngles then
                 newPlayer:SetAngles(spawnAngles)
             end
             newPlayer:SetVelocity(Vector(0, 0, 0))
             newPlayer:DropToFloor()
             newPlayer:SetCameraDistance(kGestateCameraDistance)
             newPlayer:SetIsDroppedEmbryo(true)

             -- Setup gestation data (lifeform techId + all upgrades preserved)
             local techIds = { currentTechId }
             for _, upgradeId in ipairs(upgrades) do
                 table.insertunique(techIds, upgradeId)
             end

             newPlayer:SetGestationData(techIds, currentTechId, healthScalar, armorScalar)
         end

     end

     
     function Alien:OnDetectedChange(detected)
         if not detected then return end
         TrySpawnPhantom(self)
     end
 end
 
 if Client then
 
     local baseHandleButtons = Alien.HandleButtons
     function Alien:HandleButtons(input)
         PROFILE("Alien:HandleButtonsClient")
         baseHandleButtons(self, input)
 
         if self == Client.GetLocalPlayer() and not self:GetIsDestroyed() then
             local useDown = bit.band(input.commands, Move.Use) ~= 0
             if useDown then
                 if not self._clientEHoldStart then
                     self._clientEHoldStart = Shared.GetTime()
                 end
             else
                 self._clientEHoldStart = nil
             end
         end
 
     end
 
 end