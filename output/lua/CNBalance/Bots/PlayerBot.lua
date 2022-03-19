Script.Load("lua/Prowler/bots/ProwlerBrain.lua")
function PlayerBot:_LazilyInitBrain()

    local player = self:GetPlayer()
    if not player then return end

    if self.brain == nil then

        if player:isa("Marine") then
            self.brain = MarineBrain()
        elseif player:isa("Skulk") then
            self.brain = SkulkBrain()
        elseif player:isa("Prowler") then
            self.brain = ProwlerBrain()
        elseif player:isa("Gorge") then
            self.brain = GorgeBrain()
        elseif player:isa("Lerk") then
            self.brain = LerkBrain()
        elseif player:isa("Fade") then
            self.brain = FadeBrain()
        elseif player:isa("Onos") then
            self.brain = OnosBrain()
        end

        if self.brain ~= nil then
            self.brain:Initialize()
            player.botBrain = self.brain
            self.aim = BotAim()
            self.aim:Initialize(self)
        end

    else

        -- destroy brain if we are ready room
        if player:isa("ReadyRoomPlayer") then
            self.brain = nil
            player.botBrain = nil
        end

    end

end