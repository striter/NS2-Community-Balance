
Script.Load("lua/bots/PlayerBrain.lua")
Script.Load("lua/Prowler/bots/ProwlerBrain_Data.lua")
--Script.Load("lua/bots/ProwlerBrain_Data.lua")

------------------------------------------
--
------------------------------------------
class 'ProwlerBrain' (PlayerBrain)

function ProwlerBrain:Initialize()

    PlayerBrain.Initialize(self)
    self.senses = CreateProwlerBrainSenses()
end

function ProwlerBrain:GetExpectedPlayerClass()
    return "Prowler"
end

function ProwlerBrain:GetExpectedTeamNumber()
    return kAlienTeamType
end

function ProwlerBrain:GetActions()
    return kProwlerBrainActions
end

function ProwlerBrain:GetSenses()
    return self.senses
end
