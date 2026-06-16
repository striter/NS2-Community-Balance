Script.Load("lua/BiomassHealthMixin.lua")

local kEchoLocationUpdateInterval = 1.0

local networkVars = {
    echoLocationId = "integer (0 to 255)",
}
Shared.LinkClassToMap("Shift", Shift.kMapName, networkVars)

local function CleanupConnector(self)
    if self.connectorId then
        local connector = Shared.GetEntity(self.connectorId)
        if connector then
            DestroyEntity(connector)
        end
    end
    self.connectorId = nil
    self._echoTarget = nil
    self._echoNextCheck = nil
end

if Server then
    function Shift:GetIsConnectionOneSided()
        return true
    end

    function Shift:GetConnectionEndPoint()
        return GetIsUnitActive(self) and  self._echoTarget
    end
    
    function Shift:GetConnectionStartPoint()
        return self:GetOrigin()
    end

    local baseOnUpdate = Shift.OnUpdate
    function Shift:OnUpdate(deltaTime)

        
        baseOnUpdate(self, deltaTime)
        
        if not GetIsUnitActive(self) then
            CleanupConnector(self)
            return
        end
        
        if not self._echoNextCheck or Shared.GetTime() >= self._echoNextCheck then
            self._echoNextCheck = Shared.GetTime() + kEchoLocationUpdateInterval

            local techTree = GetTechTree(self:GetTeamNumber())
            if not techTree or not techTree:GetHasTech(kTechId.ShiftHive, true) then
                CleanupConnector(self)
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
            self._echoTarget = bestHive and bestHive:GetOrigin() or nil
        end
    end

    function Shift:OnKill()
        CleanupConnector(self)

    end

    function Shift:OnDestroy()
        ScriptActor.OnDestroy(self)
        CleanupConnector(self)
    end
end


local baseOnCreate = Shift.OnCreate
function Shift:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
    InitMixin(self, MinimapConnectionMixin)
end

function Shift:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = player:isa("Alien") and player:GetTeamNumber() == self:GetTeamNumber() 
        and player:GetIsAlive() and not player:GetIsDestroyed()
        and GetIsUnitActive(self)
        and self.echoLocationId ~= nil and self.echoLocationId > 0
end

function Shift:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kShiftHealthPerBioMass * techLevel
end
