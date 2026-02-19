if not Server then return end
    
local baseOnReadyRoomPlayerCreate = ReadyRoomPlayer.OnCreate
function ReadyRoomPlayer:OnCreate()
    baseOnReadyRoomPlayerCreate(self)
    self.estimateScale = 1
end

local function SwitchScale(self,estimateScale, thirdpersonOffset)
    local reset =  self.estimateScale == estimateScale
    self.estimateScale = reset and 1 or estimateScale
    self:SetIsThirdPerson(self.isThirdPerson and self.estimateScale or 0)
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
    
    if self.playerScale == self.estimateScale then
        return
    end

    local backward = self.playerScale > self.estimateScale
    local delta = backward and -4 or 4
    local deltedScale = self.playerScale + delta * input.time
    local desireScale = backward and math.max(deltedScale,self.estimateScale) or math.min(deltedScale,self.estimateScale)
    
    Player.SetPlayerScale(self,desireScale)
end