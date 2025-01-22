Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Harvester.OnCreate
function Harvester:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

function Harvester:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return extraPlayers * Clamp(-50 -25 * recentWins,-150,150)
end
