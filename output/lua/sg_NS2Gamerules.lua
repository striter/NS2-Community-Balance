--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

NS2Gamerules.kFrontDoorSound = PrecacheAsset("sound/siegeroom.fev/door/frontdoor")
NS2Gamerules.kSiegeDoorSound = PrecacheAsset("sound/siegeroom.fev/door/siege")
NS2Gamerules.kSuddenDeathSound = PrecacheAsset("sound/siegeroom.fev/door/SD")

function NS2Gamerules:GetFrontDoorsOpen()
    local gameLength = Shared.GetTime() - self:GetGameStartTime()
    return self:GetGameStarted() and gameLength > self.FrontDoorTime
end

function NS2Gamerules:GetSiegeDoorsOpen()
    local gameLength = Shared.GetTime() - self:GetGameStartTime()
    return self:GetGameStarted() and gameLength > self.SiegeDoorTime
end

function NS2Gamerules:GetSuddenDeathActivated()
    local gameLength = Shared.GetTime() - self:GetGameStartTime()
    return self:GetGameStarted() and gameLength > self.SuddenDeathTime
end

local oldOnInitialized = NS2Gamerules.OnInitialized
function NS2Gamerules:OnInitialized()
    oldOnInitialized(self)
    kMaxRelevancyDistance = self.RelevancyDistance or 40
    kPlayingTeamInitialTeamRes = self.StartingTeamRes or kPlayingTeamInitialTeamRes
    kMarineInitialIndivRes = self.StartingPlayerRes or kMarineInitialIndivRes
    kAlienInitialIndivRes = self.StartingPlayerRes or kAlienInitialIndivRes
	
end

if Server then

    local function TestFrontDoorTime(client)
        if Shared.GetCheatsEnabled() or Shared.GetDevMode() then
            local ns2gamerules = GetGamerules()
            ns2gamerules:OpenFuncDoors(kFrontDoorType, NS2Gamerules.kFrontDoorSound)
            ns2gamerules.frontDoors = true
            ns2gamerules.FrontDoorTime = 0
            GetGameInfoEntity().FrontDoorTime = 0
            Shared.Message("= Front Doors =")
        end
    end
    Event.Hook("Console_frontdoor", TestFrontDoorTime)

    local function TestSiegeDoorTime(client)
        if Shared.GetCheatsEnabled() or Shared.GetDevMode() then
            local ns2gamerules = GetGamerules()
            ns2gamerules:OpenFuncDoors(kSiegeDoorType, NS2Gamerules.kSiegeDoorSound)
            ns2gamerules.siegeDoors = true
            ns2gamerules.SiegeDoorTime = 1
            GetGameInfoEntity().SiegeDoorTime = 1
            Shared.Message("= Siege Doors =")
        end
    end
    Event.Hook("Console_siegedoor", TestSiegeDoorTime)

    local function TestSuddenDeathTime(client)
        if Shared.GetCheatsEnabled() or Shared.GetDevMode() then
            local ns2gamerules = GetGamerules()
            ns2gamerules:ActivateSuddenDeath()
            ns2gamerules.suddenDeath = true
            ns2gamerules.SuddenDeathTime = 2
            GetGameInfoEntity().SuddenDeathTime = 2
            Shared.Message("= Sudden Death =")
        end
    end
    Event.Hook("Console_suddendeath", TestSuddenDeathTime)

    function NS2Gamerules:OpenFuncDoors(doorType, soundEffectType)

        -- update tech tree for playing team to allow forcefully disabled tech
        self.team1:GetTechTree():SetTechChanged()
        self.team2:GetTechTree():SetTechChanged()

        local siegeMessageType = kDoorTypeToSiegeMessage[doorType]
        SendSiegeMessage(self.team1, siegeMessageType)
        SendSiegeMessage(self.team2, siegeMessageType)

        for _, door in ientitylist(Shared.GetEntitiesWithClassname("FuncDoor")) do
            door:BeginOpenDoor(doorType)
        end

        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            if player:GetIsOnPlayingTeam() then
                StartSoundEffectForPlayer(soundEffectType, player)
            end
        end

    end

    function NS2Gamerules:ActivateSuddenDeath()
        local siegeMessageType = kSiegeMessageTypes.SuddenDeathActivated
        SendSiegeMessage(self.team1, siegeMessageType)
        SendSiegeMessage(self.team2, siegeMessageType)

        local soundEffectType = NS2Gamerules.kSuddenDeathSound
        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            if player:GetIsOnPlayingTeam() then
                StartSoundEffectForPlayer(soundEffectType, player)
            end
        end

    end

    -- Update doors status (techpoints are close enough method)
    local ns2_UpdateTechPoints = NS2Gamerules.UpdateTechPoints
    function NS2Gamerules:UpdateTechPoints()
        ns2_UpdateTechPoints(self)

        if not self.frontDoors and self:GetFrontDoorsOpen() then
            self:OpenFuncDoors(kFrontDoorType, NS2Gamerules.kFrontDoorSound)
            self.frontDoors = true
        end

        if not self.siegeDoors and self:GetSiegeDoorsOpen() then
            self:OpenFuncDoors(kSiegeDoorType, NS2Gamerules.kSiegeDoorSound)
            self.siegeDoors = true
        end

        if not self.suddenDeath and self:GetSuddenDeathActivated() then
            self:ActivateSuddenDeath()
            self.suddenDeath = true
        end
    end

    -- Reset door status
    local ns2_ResetGame = NS2Gamerules.ResetGame
    function NS2Gamerules:ResetGame()
        ns2_ResetGame(self)

        self.frontDoors = false
        self.siegeDoors = false
        self.suddenDeath = false
    end
end