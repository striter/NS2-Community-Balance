Script.Load("lua/BiomassHealthMixin.lua")

local kEchoLocationUpdateInterval = 1.0

local networkVars = {
    echoLocationId = "integer (0 to 255)",
}
Shared.LinkClassToMap("Shift", Shift.kMapName, networkVars)

if Server then
    function Shift:UpdateEchoLocation()
        -- Throttle to once per second
        if self._echoCheckTime and Shared.GetTime() - self._echoCheckTime < kEchoLocationUpdateInterval then
            return
        end
        self._echoCheckTime = Shared.GetTime()
        
        -- Only update if ShiftHive tech is researched
        local techTree = GetTechTree(self:GetTeamNumber())
        if not techTree or not techTree:GetHasTech(kTechId.ShiftHive, true) then
            self.echoLocationId = 0
            return
        end
        
        local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
        local bestHive = nil
        local bestScore = 0
        if hives then
            for _, hive in ipairs(hives) do
                if hive:GetIsAlive() and hive:GetIsBuilt() then
                    local distSq = (self:GetOrigin() - hive:GetOrigin()):GetLengthSquared()
                    if distSq >= 2500 then
                        local inCombat = HasMixin(hive, "Combat") and hive:GetIsInCombat()
                        -- Combat gives a huge distance bonus so it always beats non-combat
                        local score = distSq - (inCombat and 100000000 or 0)
                        if not bestHive or score < bestScore then
                            bestHive = hive
                            bestScore = score
                        end
                    end
                end
            end
        end
        self.echoLocationId = bestHive and bestHive:GetLocationId() or 0
    end
    
    local baseOnUpdate = Shift.OnUpdate
    function Shift:OnUpdate(deltaTime)
        baseOnUpdate(self, deltaTime)
        self:UpdateEchoLocation()
    end
end

local baseOnCreate = Shift.OnCreate
function Shift:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
    if Server then
        self:UpdateEchoLocation()
    end
end

function Shift:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kShiftHealthPerBioMass * techLevel
end

function Shift:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = player:isa("Alien") and player:GetTeamNumber() == self:GetTeamNumber() 
        and player:GetIsAlive() and not player:GetIsDestroyed()
        and GetIsUnitActive(self)
        and self.echoLocationId ~= nil and self.echoLocationId > 0
end
