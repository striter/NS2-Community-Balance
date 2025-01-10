
Script.Load("lua/BiomassHealthMixin.lua")

local kAuxPowerBackupSound = PrecacheAsset("sound/NS2.fev/marine/power_node/backup")
local baseOnCreate = PowerPoint.OnCreate
function PowerPoint:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

if Server then

    local function PowerUp(self)

        self:SetInternalPowerState(PowerPoint.kPowerState.socketed)
        self:SetLightMode(kLightMode.Normal)
        self:StopSound(kAuxPowerBackupSound)
        self:TriggerEffects("fixed_power_up")
        self:SetPoweringState(true)

        --Ensure rebuilt (infested, destroyed, rebuilt, still in infestation range) nodes are updated
        self:InfestationNeedsUpdate()

    end

    local function GetPowerPointMaxHealth(self)
        local maxHealth = kPowerPointHealth
        local locationName = self:GetLocationName()
        if #locationName > 0 then
            if GetLocationContention():GetGroupHasTechPoint(locationName) then
                maxHealth = maxHealth + kPowerPointHealthAddOnTechPoint
            end
        end
        return maxHealth
    end
    -- Repaired by marine with welder or MAC
    function PowerPoint:OnWeldOverride(entity, elapsedTime)

        local welded = false

        -- Marines can repair power points
        if entity:isa("Welder") then

            local amount = kWelderPowerRepairRate * elapsedTime
            welded = (self:AddHealth(amount) > 0)

        elseif entity:isa("MAC") then

            welded = self:AddHealth(MAC.kRepairHealthPerSecond * elapsedTime) > 0

        else

            local amount = kBuilderPowerRepairRate * elapsedTime
            welded = (self:AddHealth(amount) > 0)

        end

        if self:GetHealthScalar() > self.kDamagedPercentage then

            self:StopDamagedSound()

            if self:GetLightMode() == kLightMode.LowPower and self:GetIsPowering() then
                self:SetLightMode(kLightMode.Normal)
            end

        end

        if self:GetPowerState() == PowerPoint.kPowerState.destroyed then
            if self:GetHealthScalar() == 1 then

                self:StopDamagedSound()
                local maxHealth = GetPowerPointMaxHealth(self)
                self.health = maxHealth
                self.armor = kPowerPointArmor
                self:SetMaxHealth(maxHealth)
                self:SetMaxArmor(kPowerPointArmor)
                self.alive = true

                PowerUp(self)
            else
                --Required here as in this state PowerPoint doesn't "read" as infestable (aka, it's dead, Jim)
                self:InfestationNeedsUpdate()
            end
        end

        if welded then
            self:AddAttackTime(-0.1)
        end

    end

    function PowerPoint:OnConstructionComplete()

        self:StopDamagedSound()

        local maxHealth = GetPowerPointMaxHealth(self)
        
        self.health = maxHealth
        self.armor = kPowerPointArmor

        self:SetMaxHealth(maxHealth)
        self:SetMaxArmor(kPowerPointArmor)

        self.alive = true

        PowerUp(self)

    end
    
end

function PowerPoint:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kPowerPointHealthPerPlayerAdd * extraPlayers
end
