--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

-- don't delete old network vars, simply replace them if their type has changed or add them if new
local networkVarsExt = {
    FrontDoorTime = "time",
    SiegeDoorTime = "time",
    SuddenDeathTime = "time"
}

if Server then

    local ns2_SetStartTime = GameInfo.SetStartTime
    function GameInfo:SetStartTime(startTime)
        ns2_SetStartTime(self, startTime)

        local ns2gr = GetGamerules()
        self.FrontDoorTime = ns2gr.FrontDoorTime
        self.SiegeDoorTime = ns2gr.SiegeDoorTime
        self.SuddenDeathTime = ns2gr.SuddenDeathTime
    end

end

function GameInfo:GetSiegeTimes()
    local gameLength = ConditionalValue(self:GetGameStarted(), Shared.GetTime() - self:GetStartTime(), 0)
    local frontDoorTime = Clamp(self.FrontDoorTime - gameLength, 0, self.FrontDoorTime)
    local siegeDoorTime = Clamp(self.SiegeDoorTime - gameLength, 0, self.SiegeDoorTime)
    local suddenDeathTime = Clamp(self.SuddenDeathTime - gameLength, 0, self.SuddenDeathTime)

    return frontDoorTime, siegeDoorTime, suddenDeathTime, gameLength
end

Shared.LinkClassToMap("GameInfo", GameInfo.kMapName, networkVarsExt)
