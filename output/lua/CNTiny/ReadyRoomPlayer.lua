if not Server then return end
    
local function SwitchScale(self,estimateScale)
    local reset =  self.estimateScale == estimateScale
    self.estimateScale = reset and 1 or estimateScale
    self:SetIsThirdPerson(self.isThirdPerson and self.estimateScale or 0)
    Player.SetScale(self,self.estimateScale)
end

local function SwitchThirdPerson(self)
    self.isThirdPerson = not self.isThirdPerson
    self:SetIsThirdPerson(self.isThirdPerson and self.estimateScale or 0)
end

local baseHandleButtons = ReadyRoomPlayer.HandleButtons
function ReadyRoomPlayer:HandleButtons(input)
    baseHandleButtons(self,input)
    if not self.scalePressed and bit.band(input.commands, Move.Weapon1 + Move.Weapon2 + Move.Weapon3 + Move.Reload) ~= 0 then
        self.scalePressed=true
        if bit.band(input.commands,Move.Weapon1) ~= 0 then
            SwitchScale(self,0.3)
        end
        
        if bit.band(input.commands,Move.Weapon2) ~= 0 then
            SwitchScale(self,2)
        end

        if bit.band(input.commands,Move.Weapon3) ~= 0 then
            SwitchScale(self,3)
        end

        if bit.band(input.commands,Move.Reload) ~= 0 then
            SwitchThirdPerson(self)
        end

    else
        self.scalePressed=false
    end
    
end