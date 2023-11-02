Script.Load("lua/BiomassHealthMixin.lua")

local baseOnCreate = Shade.OnCreate
function Shade:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
end

local baseOnInitialized = Shade.OnInitialized
function Shade:OnInitialized()
    baseOnInitialized(self)
    self.timeLastInked = Shared.GetTime() - kShadeInkCooldown
end

function Shade:GetHealthPerBioMass()
    return kCragHealthPerBioMass
end

function Shade:GetTechButtons(techId)

    local techButtons = { kTechId.None, kTechId.Move, kTechId.ShadeCloak, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.Consume }

    if self.moving then
        techButtons[2] = kTechId.Stop
    end

    return techButtons

end

function Shade:TriggerInk()
    if not GetIsUnitActive(self) then return false end
    
    local now = Shared.GetTime()
    if (now - self.timeLastInked) < kShadeInkCooldown then
        return false
    end

    self:ResetInk()

    -- Create ShadeInk entity in world at this position with a small offset
    CreateEntity(ShadeInk.kMapName, self:GetOrigin() + Vector(0, 0.2, 0), self:GetTeamNumber())
    self:TriggerEffects("shade_ink")
    return true
    
end

function Shade:ResetInk()
    self.timeLastInked = Shared.GetTime()
end

function Shade:OnTeleportEnd()
    self:ResetInk()
    self:ResetPathing()
end
