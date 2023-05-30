ScoringMixin.networkVars.killsCurrentLife = "integer"

local baseInitMixin = ScoringMixin.__initmixin
function ScoringMixin:__initmixin()
    baseInitMixin(self)
    self.killsCurrentLife = 0
end

function ScoringMixin:GetKillsCurrentLife()
    return self.killsCurrentLife
end

local baseOnKill = ScoringMixin.OnKill
function ScoringMixin:OnKill()
    baseOnKill(self)
    self.killsCurrentLife = 0
end

local baseAddKill = ScoringMixin.AddKill
function ScoringMixin:AddKill()
    baseAddKill(self)
    
    if GetWarmupActive() then return end
    self.killsCurrentLife = Clamp(self.killsCurrentLife + 1, 0, kMaxKills)
end

if Server then
    local baseCopyPlayerDataFrom = ScoringMixin.CopyPlayerDataFrom
    function ScoringMixin:CopyPlayerDataFrom(player)
        baseCopyPlayerDataFrom(self,player)    
        self.killsCurrentLife = player.killsCurrentLife
    end


    local baseResetScores = ScoringMixin.ResetScores
    function ScoringMixin:ResetScores()
        baseResetScores(self)
        self.killsCurrentLife = 0
    end
end 

