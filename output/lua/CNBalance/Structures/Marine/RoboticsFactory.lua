

function RoboticsFactory:GetTechButtons(techId)

    local techButtons = {  kTechId.ARC, kTechId.None, kTechId.None, kTechId.None,
                           kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    if self:GetTechId() ~= kTechId.ARCRoboticsFactory then
        techButtons[5] = kTechId.UpgradeRoboticsFactory
    end

    return techButtons

end

if Server then

    local baseOnCreate = RoboticsFactory.OnCreate
    function RoboticsFactory:OnCreate()
        baseOnCreate(self)
        self.spawnedFreeMACID = Entity.invalidId
    end
    
    function RoboticsFactory:OnUpdate()

        local time = Shared.GetTime()
        if self.freeMACCheck and time - self.freeMACCheck < 1 then return end
        self.freeMACCheck = time
        
        if not self.deployed or not GetIsUnitActive(self) then return end
        if self.open or self:GetIsResearching() then return end
        
        if self.spawnedFreeMACID ~= Entity.invalidId then
            local MAC = Shared.GetEntity(self.spawnedFreeMACID)
            if MAC == nil or not MAC:isa("MAC") or not MAC:GetIsAlive() then
                self.spawnedFreeMACID = Entity.invalidId
            end
        end
    
        if self.spawnedFreeMACID == Entity.invalidId then
            self.spawnedFreeMACID = self:OverrideCreateManufactureEntity(kTechId.MAC):GetId()
        end
    end
end

function GetRoboticsFactoryBuildValid(techId, origin, normal, player)
    local ents = GetEntitiesWithinXZRange("ScriptActor", origin, 2)
    return (#ents == 0)
end