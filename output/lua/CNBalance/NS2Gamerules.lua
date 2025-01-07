 if Server then

     NS2Gamerules.kBalanceConfig = LoadConfigFile("NS2.0Config.json", {
         bountyActive = false,
         resourceEfficiency = false,
     }, true)

     NS2Gamerules.kRecentRoundStatus = LoadConfigFile("NS2.0RoundStatus.json",{
         
     },true)
     
     local kRandomTencentage = 4
     
     function NS2Gamerules:RandomTechPoint(techPoints, teamNumber)
         local chosenIndex = math.random(1,#techPoints)
         local chosenTechPoint = techPoints[chosenIndex]
          table.removevalue(techPoints, chosenTechPoint)
         return chosenTechPoint
     end

     local baseSetGameState = NS2Gamerules.SetGameState
     function NS2Gamerules:SetGameState(_state)
         baseSetGameState(self,_state)
         self.team1:OnGameStateChanged(_state)
         self.team2:OnGameStateChanged(_state)
     end
     
     function NS2Gamerules:ResetGame()

         StatsUI_ResetStats()

         self:SetGameState(kGameState.NotStarted)

         TournamentModeOnReset()

         -- save commanders for later re-login
         local team1CommanderClient = self.team1:GetCommander() and self.team1:GetCommander():GetClient()
         local team2CommanderClient = self.team2:GetCommander() and self.team2:GetCommander():GetClient()

         -- Cleanup any peeps currently in the commander seat by logging them out
         -- have to do this before we start destroying stuff.
         self:LogoutCommanders()

         -- Destroy any map entities that are still around
         DestroyLiveMapEntities()

         -- Reset all players, delete other not map entities that were created during 
         -- the game (hives, command structures, initial resource towers, etc)
         -- We need to convert the EntityList to a table since we are destroying entities
         -- within the EntityList here.
         for _, entity in ientitylist(Shared.GetEntitiesWithClassname("Entity")) do

             local allowDestruction = true

             for _, className in ipairs(self.resetProtectedEntities) do
                 allowDestruction = allowDestruction and not entity:isa(className)
             end

             if allowDestruction and entity:GetParent() == nil then

                 -- Reset all map entities and all player's that have a valid Client (not ragdolled players for example).
                 local resetEntity = entity:isa("TeamInfo") or entity:GetIsMapEntity() or (entity:isa("Player") and entity:GetClient() ~= nil)
                 if resetEntity then

                     if entity.Reset then
                         entity:Reset()
                     end

                 else
                     DestroyEntity(entity)
                 end

             end

         end

         -- Clear out obstacles from the navmesh before we start repopualating the scene
         RemoveAllObstacles()

         -- Build list of tech points
         local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
         if #techPoints < 2 then
             Print("Warning -- Found only %d %s entities.", table.maxn(techPoints), TechPoint.kMapName)
         end

         local resourcePoints = Shared.GetEntitiesWithClassname("ResourcePoint")
         if resourcePoints:GetSize() < 2 then
             Print("Warning -- Found only %d %s entities.", resourcePoints:GetSize(), ResourcePoint.kPointMapName)
         end

         -- add obstacles for resource points back in
         for _, resourcePoint in ientitylist(resourcePoints) do
             resourcePoint:AddToMesh()
         end


         local randomSpawn = math.random(1,10)<= kRandomTencentage
         local team1TechPoint, team2TechPoint

         if randomSpawn then
             team1TechPoint = self:RandomTechPoint(techPoints, kTeam1Index)
             team2TechPoint = self:RandomTechPoint(techPoints, kTeam2Index)
         elseif Server.teamSpawnOverride and #Server.teamSpawnOverride > 0 then

             for t = 1, #techPoints do

                 local techPointName = string.lower(techPoints[t]:GetLocationName())
                 local selectedSpawn = Server.teamSpawnOverride[1]
                 if techPointName == selectedSpawn.marineSpawn then
                     team1TechPoint = techPoints[t]
                 elseif techPointName == selectedSpawn.alienSpawn then
                     team2TechPoint = techPoints[t]
                 end

             end

             if not team1TechPoint or not team2TechPoint then
                 Shared.Message("Invalid spawns, defaulting to normal spawns")
                 if Server.spawnSelectionOverrides then

                     local selectedSpawn = self.techPointRandomizer:random(1, #Server.spawnSelectionOverrides)
                     selectedSpawn = Server.spawnSelectionOverrides[selectedSpawn]

                     for t = 1, #techPoints do

                         local techPointName = string.lower(techPoints[t]:GetLocationName())
                         if techPointName == selectedSpawn.marineSpawn then
                             team1TechPoint = techPoints[t]
                         elseif techPointName == selectedSpawn.alienSpawn then
                             team2TechPoint = techPoints[t]
                         end

                     end

                 else

                     -- Reset teams (keep players on them)
                      team1TechPoint = self:ChooseTechPoint(techPoints, kTeam1Index)
                      team2TechPoint = self:ChooseTechPoint(techPoints, kTeam2Index)

                 end

             end

         elseif Server.spawnSelectionOverrides then

             local selectedSpawn = self.techPointRandomizer:random(1, #Server.spawnSelectionOverrides)
             selectedSpawn = Server.spawnSelectionOverrides[selectedSpawn]

             for t = 1, #techPoints do

                 local techPointName = string.lower(techPoints[t]:GetLocationName())
                 if techPointName == selectedSpawn.marineSpawn then
                     team1TechPoint = techPoints[t]
                 elseif techPointName == selectedSpawn.alienSpawn then
                     team2TechPoint = techPoints[t]
                 end

             end

         else

             -- Reset teams (keep players on them)
             team1TechPoint = self:ChooseTechPoint(techPoints, kTeam1Index)
             team2TechPoint = self:ChooseTechPoint(techPoints, kTeam2Index)

         end

         self.team1:ResetPreservePlayers(team1TechPoint)
         self.team2:ResetPreservePlayers(team2TechPoint)

         assert(self.team1:GetInitialTechPoint() ~= nil)
         assert(self.team2:GetInitialTechPoint() ~= nil)

         -- Save data for end game stats later.
         self.startingLocationNameTeam1 = team1TechPoint:GetLocationName()
         self.startingLocationNameTeam2 = team2TechPoint:GetLocationName()
         self.startingLocationsPathDistance = GetPathDistance(team1TechPoint:GetOrigin(), team2TechPoint:GetOrigin())
         self.initialHiveTechId = nil

         self.worldTeam:ResetPreservePlayers(nil)
         self.spectatorTeam:ResetPreservePlayers(nil)

         -- Reset all bot brains
         for i = 1, #gServerBots do
             gServerBots[i]:Reset()
         end

         for i = 1, #gCommanderBots do
             gCommanderBots[i]:Reset()
         end

         -- Reset location contention variables after resetting players to ensure old data is cleared
         GetLocationContention():ResetAllGroups()

         -- Reset location staleness after all entities are destroyed
         GetLocationContention():ResetAllGroupsStaleness()
         Log("Reset location group stale timers")

         -- Replace players with their starting classes with default loadouts at spawn locations
         self.team1:ReplaceRespawnAllPlayers()
         self.team2:ReplaceRespawnAllPlayers()

         self.clientpres = {}

         -- Create team specific entities
         local commandStructure1 = self.team1:ResetTeam()
         local commandStructure2 = self.team2:ResetTeam()

         -- login the commanders again
         local function LoginCommander(commandStructure, client)
             local player = client and client:GetControllingPlayer()

             if commandStructure and player and commandStructure:GetIsBuilt() then

                 -- make up for not manually moving to CS and using it
                 commandStructure.occupied = not client:GetIsVirtual()

                 player:SetOrigin(commandStructure:GetDefaultEntryOrigin())

                 commandStructure:LoginPlayer( player, true )
             else
                 if player then
                     Log("%s| Failed to Login commander[%s - %s(%s)] on ResetGame", self:GetClassName(), player:GetClassName(), player:GetId(),
                             client:GetIsVirtual() and "BOT" or "HUMAN"
                     )
                 end
             end
         end

         LoginCommander(commandStructure1, team1CommanderClient)
         LoginCommander(commandStructure2, team2CommanderClient)
         
         -- Create living map entities fresh
         CreateLiveMapEntities()

         self.forceGameStart = false
         self.preventGameEnd = nil

         -- Reset banned players for new game
         if not self.bannedPlayers then
             self.bannedPlayers = unique_set()
         end
         self.bannedPlayers:Clear()

         -- Send scoreboard and tech node update, ignoring other scoreboard updates (clearscores resets everything)
         for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
             Server.SendCommand(player, "onresetgame")
             player.sendTechTreeBase = true
         end

         self.team1:OnResetComplete()
         self.team2:OnResetComplete()

         StatsUI_InitializeTeamStatsAndTechPoints(self)
     end

     function NS2Gamerules:OnUpdate(timePassed)

         PROFILE("NS2Gamerules:OnUpdate")

         if Server then

             if self.justCreated then
                 if not self.gameStarted then
                     self:ResetGame()
                 end
                 self.justCreated = false
             end

             if self:GetMapLoaded() then

                 self:CheckGameStart()
                 self:CheckGameEnd()

                 self:UpdateWarmUp()

                 self:UpdatePregame(timePassed)
                 self:UpdateToReadyRoom()
                 self:UpdateMapCycle()
                 self:ServerAgeCheck()
                 self:UpdateAutoTeamBalance(timePassed)

                 self.timeSinceGameStateChanged = self.timeSinceGameStateChanged + timePassed

                 self.worldTeam:Update(timePassed)
                 self.team1:Update(timePassed)
                 self.team2:Update(timePassed)
                 self.spectatorTeam:Update(timePassed)

                 self:UpdatePings()
                 self:UpdateHealth()
                 self:UpdateTechPoints()

                 self:CheckForNoCommander(self.team1, "MarineCommander")
                 --self:CheckForNoCommander(self.team2, "AlienCommander")
                 self:KillEnemiesNearCommandStructureInPreGame(timePassed)

                 self:UpdatePlayerSkill()
                 self:UpdateNumPlayersForScoreboard()

                 if Shared.GetThunderdomeEnabled() then
                     GetThunderdomeRules():CheckForAutoConcede(self)
                 end

             end

         end

     end
     
     function NS2Gamerules:BroadCastVO(_name)
         self.worldTeam:PlayPrivateTeamSound(_name)
         self.team1:PlayPrivateTeamSound(_name)
         self.team2:PlayPrivateTeamSound(_name)
         self.spectatorTeam:PlayPrivateTeamSound(_name)
     end
     
     local baseEndGame = NS2Gamerules.EndGame
     function NS2Gamerules:EndGame(winningTeam, autoConceded)
         baseEndGame(self,winningTeam,autoConceded)
         local lastRoundData = CHUDGetLastRoundStats();
         
         if not lastRoundData then
             Shared.Message("[NS2.0] ERROR Option 'savestats' not enabled ")
             return
         end
         
         
         local roundLength = lastRoundData.RoundInfo.roundLength
         local playerCount = #lastRoundData.PlayerStats
         if roundLength < 300 or playerCount < 12 then return end
         
         table.insert(self.kRecentRoundStatus, 1,
                 {time = os.time() ,winningTeam = lastRoundData.RoundInfo.winningTeam,length = roundLength,playerCount = playerCount }
         )
         self.kRecentRoundStatus[11] = nil
         SaveConfigFile("NS2.0RoundStatus.json",self.kRecentRoundStatus)
     end
 end