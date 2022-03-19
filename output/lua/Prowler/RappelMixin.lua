
RappelMixin = CreateMixin( RappelMixin )
RappelMixin.type = "Rappel"

RappelMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
--  "GetBarrelPoint",
    "PerformSecondaryAttack",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",
    "GetTracerEffectName"
}

kRappelTracerEffectName = PrecacheAsset("cinematics/prowler/rappeltracer.cinematic")

local kRange = kRappelRange
local kRappelCooldown = 0.4 --0.49
local kRappelDuration = 1.99
local kRappelProjectileSize = 0.1

RappelMixin.networkVars =
{
    rappelling                    = "private boolean",
    lastSecondaryAttackStartTime  = "private float",  -- todo: removed some networkvars if possible
    lastSecondaryAttackEndTime    = "private float",
}

function RappelMixin:__initmixin()
    
    PROFILE("RappelMixin:__initmixin")
    
    self.rappelling = false
    self.secondaryAttackingsecondaryAttacking = false
    self.lastSecondaryAttackStartTime = 0
    self.lastSecondaryAttackEndTime = 0

end

function RappelMixin:GetHasSecondary(player)
    return player.twoHives
end

function RappelMixin:GetSecondaryEnergyCost(player)
    return kRappelEnergyCost
end

function RappelMixin:EndRappel()
    local player = self:GetParent()
    if self.rappelling then
        self:OnSecondaryAttackEnd(self, player)
    end
    
    return false
end

function RappelMixin:EndRappelCallback()
    self:EndRappel()
end

function RappelMixin:GetSecondaryAttackRequiresPress()
    return true
end

function RappelMixin:PerformSecondaryAttack(player)
    
    local parent = self:GetParent()
    if parent and self:GetHasSecondary(player) and self.lastSecondaryAttackStartTime + kRappelCooldown < Shared.GetTime() then
        
        self.lastSecondaryAttackStartTime = Shared.GetTime()
        
        local viewAngles = player:GetViewAngles()
        local shootCoords = viewAngles:GetCoords()
        local filter = EntityFilterOneAndIsa(player, "Babbler")
        local startPoint = player:GetEyePos()
        --local endPoint = startPoint + shootCoords.zAxis * kRange
        
        local extents = GetDirectedExtentsForDiameter(shootCoords.zAxis, kRappelProjectileSize)
        local trace = Shared.TraceBox(extents, startPoint, startPoint + shootCoords.zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        
        if trace.fraction < 1 then

            local hitObject = trace.entity
            local direction = GetNormalizedVector(trace.endPoint - startPoint)
            local impactPoint = trace.endPoint - direction * kHitEffectOffset
            
            if hitObject and HasMixin(hitObject, "Team") and hitObject:GetTeamNumber() ~= self:GetTeamNumber() then
                self:DoDamage(20, hitObject, impactPoint, direction, trace.surface, true, true)
            else
                self:DoDamage(20, nil, impactPoint, direction, trace.surface, true, true)
            end
            
            self.rappelling = true
            player:DeductAbilityEnergy(self:GetSecondaryEnergyCost())
            player:OnRappel(trace.endPoint, hitObject)
            --player:TriggerEffects("spikes_attack")
            --self:TriggerEffects("spit_hit", { effecthostcoords = trace.endPoint:GetCoords() })
            self:TriggerEffects("parasite_attack")
            
            return true
        end        
        
    end
    
    return false
    
end

function RappelMixin:OnSecondaryAttack(player)

    if not player:GetSecondaryAttackLastFrame() and player:GetEnergy() >= self:GetSecondaryEnergyCost() and not self.rappelling then
        self.secondaryAttacking = true
        return self:PerformSecondaryAttack(player)       
    end
    
    --[[if Server then
        self:AddTimedCallback(RappelMixin.EndRappel, kRappelDuration)
    end---]]
    
    return false
    
end

function RappelMixin:OnSecondaryAttackEnd(player)

    local now = Shared.GetTime()
    Ability.OnSecondaryAttackEnd(self, player)
    self.secondaryAttacking = false
    self.rappelling = false
    self.lastSecondaryAttackEndTime = now
    
end

function RappelMixin:ProcessMoveOnWeapon(player, input)

    if not player.rappelling then
        self:OnSecondaryAttackEnd(self, player)
    elseif not self.secondaryAttacking and player.rappelling and (player.timeRappelStart + 0.2 < Shared.GetTime()) then
        player.rappelling = false
    end
end

function RappelMixin:GetTracerEffectName()
    return kRappelTracerEffectName --kSpikeTracerEffectName
end

function RappelMixin:GetTracerResidueEffectName()

    local parent = self:GetParent()
    if parent and parent:GetIsLocalPlayer() and not parent:GetIsThirdPerson() then
        return kSpikeTracerFirstPersonResidueEffectName
    else
        return kSpikeTracerResidueEffectName
    end 
    
end

function RappelMixin:GetDeathIconIndex()
    return kDeathMessageIcon.Claw
end

--[[function RappelMixin:GetGhostModelName()
    return Bomb.kModelName
end--]]

--[[function RappelMixin:GetGhostModelTechId()
    return self.rappelling and kTechId.Bomb or nil
end--]]

if Client then

    function RappelMixin:CreateRappelInfo()
    
        if not self.rappelInfo then
            self.rappelInfo = GetGUIManager():CreateGUIScript("Prowler/GUIRappelInfo")
        end
        
    end
    
    function RappelMixin:DestroyRappelInfo()
        if self.rappelInfo ~= nil then
            GetGUIManager():DestroyGUIScript(self.rappelInfo)
            self.rappelInfo = nil
        end
    end
    
    local function UpdateGUI(self, player)
        local localPlayer = Client.GetLocalPlayer()
        if localPlayer == player then
            self:CreateRappelInfo()
        end
        
        if self.rappelInfo then
            self.rappelInfo:SetIsVisible(player and localPlayer == player and self:GetIsActive() and self.rappelling)
        end
    end
    
    function RappelMixin:OnUpdateRender()
        UpdateGUI(self, self:GetParent())    
    end
    
    function RappelMixin:OnDestroy()
        self:DestroyRappelInfo()
    end

    local function CleanUI(self)

        self:DestroyRappelInfo()
        
    end


    function RappelMixin:OnProcessIntermediate(input)

        local player = self:GetParent()
        
        if player then
            local isRappelling = self.rappelling
            self.showGhost = isRappelling
            self.ghostCoords = player.rappelPoint
            self.placementValid = isRappelling
            
        end

    end
    
end