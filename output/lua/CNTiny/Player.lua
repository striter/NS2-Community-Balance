
Shared.LinkClassToMap("Player", Player.kMapName, {scale = "float (0.1 to 4 by 0.01)"}, true)

Player.kScaleDeltaPerSecond = 0.1

local oldOnCreate = Player.OnCreate
function Player:OnCreate()
    self.scale = 1
    self.playerScale = 1
    oldOnCreate(self)
end

local baseOnInitialized = Player.OnInitialized
function Player:OnInitialized()
    self.scale = 1
    self.playerScale = 1
    baseOnInitialized(self)
end

if Server then
    local baseOnProcessMove = Player.OnProcessMove
    function Player:OnProcessMove(input)
        baseOnProcessMove(self,input)

        local deltaTime = input.time
        local newScale = self:GetPlayerScale(deltaTime)
        
        if newScale ~= self.scale then
            local backward = self.scale > newScale
            local delta = (backward and -1 or 1) * self.kScaleDeltaPerSecond
            local deltaScale = self.scale + delta * input.time
            local desireScale = backward and math.max(deltaScale,newScale) or math.min(deltaScale,newScale)

            self.scale = desireScale
            self:UpdateControllerFromEntity()
        end
    end

    function Player:SetScale(_scale)
        self.playerScale = _scale
    end

    function Player:GetPlayerScale(deltaTime)
        return self.playerScale
    end
end

function Player:GetCanDieOverride()     --Just die Anyway
    local teamNumber = self:GetTeamNumber()
    return (teamNumber == kTeam1Index or teamNumber == kTeam2Index or teamNumber == kTeamReadyRoom)
end

function Player:OnAdjustModelCoords(modelCoords)
    local coords = modelCoords
    coords.xAxis = coords.xAxis * self.scale
    coords.yAxis = coords.yAxis * self.scale
    coords.zAxis = coords.zAxis * self.scale
    return coords
end

local baseGetTraceCapsule = Player.GetTraceCapsule
function Player:GetTraceCapsule()
    local height,radius = baseGetTraceCapsule(self)
    height = height * self.scale
    radius = radius * self.scale
    return height,radius
end

local baseGetControllerSize = Player.GetControllerSize
function Player:GetControllerSize()
    local height,radius = baseGetControllerSize(self)
    height = height * self.scale
    radius = radius * self.scale
    return height,radius
end


local baseGetMaxSpeed =  Player.GetMaxSpeed
function Player:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible)  * GTinySpeedMultiplier(self)
end

-- local baseModifyGravityForce = Player.ModifyGravityForce
-- function Player:ModifyGravityForce(gravityTable)
--     baseModifyGravityForce(self,gravityTable)
--     gravityTable.gravity = gravityTable.gravity* (self.scale == 1 and 1 or 0.35)
-- end

function Player:OnPostUpdateCamera(deltaTime)
    self:SetViewOffsetHeight(self:GetMaxViewOffsetHeight() * self.scale)
end

local kCrouchShrinkAmount = 0.7
function Player:GetCrouchShrinkAmount()
    return kCrouchShrinkAmount * self.scale
end
