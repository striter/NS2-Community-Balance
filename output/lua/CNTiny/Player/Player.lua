
Script.Load("lua/CNBooting/ModPanelActionFinderMixin.lua")

Shared.LinkClassToMap("Player", Player.kMapName, {scale = "float (0 to 4 by 0.02)"}, true)

local oldOnCreate = Player.OnCreate
function Player:OnCreate()
    oldOnCreate(self)
    self.scale = 1
    InitMixin(self, ReadyRoomPlayerActionFinderMixin)
end

local baseOnInitialized = Player.OnInitialized
function Player:OnInitialized()
    baseOnInitialized(self)
    self.scale = 1
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

function Player:SetScale(_scale)
    self.scale = _scale
    self:UpdateControllerFromEntity()
end


local kCrouchShrinkAmount = 0.7
function Player:GetCrouchShrinkAmount()
    return kCrouchShrinkAmount * self.scale
end
