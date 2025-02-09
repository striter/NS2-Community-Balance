Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Harvester.OnCreate
function Harvester:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Harvester:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return 50 * (-extraPlayers - recentWins * 2)
end
