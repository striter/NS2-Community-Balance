Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Harvester.OnCreate
function Harvester:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

if Server then
    local baseOninitialized = Harvester.OnInitialized
    function Harvester:OnInitialized()
        baseOninitialized(self)
        local team = self:GetTeam()
        if team then
            team:OnDeadlockExtend(self:GetTechId())
        end
    end
end

function Harvester:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return 75 * (extraPlayers - recentWins * 2)
end