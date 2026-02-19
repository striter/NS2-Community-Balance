
Shared.LinkClassToMap("Player", Player.kMapName, {playerScale = "float (0 to 4 by 0.02)"}, true)

local oldOnCreate = Player.OnCreate
function Player:OnCreate()
    oldOnCreate(self)
    self.playerScale = 1
end

local baseOnInitialized = Player.OnInitialized
function Player:OnInitialized()
    baseOnInitialized(self)
    self.playerScale = 1
end

function Player:GetPlayerScale()
    return self.playerScale
end

function Player:SetPlayerScale(_scale)
    self.playerScale = _scale
    self:UpdateControllerFromEntity()
end

function Player:GetCanDieOverride()     --Just die Anyway
    local teamNumber = self:GetTeamNumber()
    return (teamNumber == kTeam1Index or teamNumber == kTeam2Index or teamNumber == kTeamReadyRoom)
end

function Player:OnAdjustModelCoords(modelCoords)
    local coords = modelCoords
    local scale = self:GetPlayerScale()
    coords.xAxis = coords.xAxis * scale
    coords.yAxis = coords.yAxis * scale
    coords.zAxis = coords.zAxis * scale
    return coords
end

local baseGetTraceCapsule = Player.GetTraceCapsule
function Player:GetTraceCapsule()
    local height,radius = baseGetTraceCapsule(self)
    local scale = self:GetPlayerScale()
    height = height * scale
    radius = radius * scale
    return height,radius
end

local baseGetControllerSize = Player.GetControllerSize
function Player:GetControllerSize()
    local scale = self:GetPlayerScale()
    local height,radius = baseGetControllerSize(self)
    height = height * scale
    radius = radius * scale
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
    self:SetViewOffsetHeight(self:GetMaxViewOffsetHeight() * self:GetPlayerScale())
end

local kCrouchShrinkAmount = 0.7
function Player:GetCrouchShrinkAmount()
    return kCrouchShrinkAmount * self:GetPlayerScale()
end
