Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PickupableMixin.lua")
Script.Load("lua/JetpackOnBack.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/LOSMixin.lua")

class 'Heavy' (ScriptActor)

Heavy.kMapName = "heavy"
Heavy.kModelName = PrecacheAsset("models/misc/target/target.model")

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)


function Heavy:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })
    
end

function Heavy:OnInitialized()

    ScriptActor.OnInitialized(self)    
    self:SetModel(Heavy.kModelName)
    
    local coords = self:GetCoords()

    self.physicsBody = Shared.CreatePhysicsSphereBody(false, 0.4, 0, coords)
    self.physicsBody:SetCollisionEnabled(true)    
    self.physicsBody:SetGroup(PhysicsGroup.WeaponGroup)    
    self.physicsBody:SetEntity(self)
    
end

function Heavy:OnDestroy() 

    ScriptActor.OnDestroy(self)

    if self.physicsBody then
    
        Shared.DestroyCollisionObject(self.physicsBody)
        self.physicsBody = nil
        
    end

end

function Heavy:OnTouch(recipient)    
end

function Heavy:OverrideCheckVision()
    return false
end

function Heavy:GetIsValidRecipient(recipient)
    return not recipient:isa("JetpackMarine") and not recipient:isa("Exo") and not recipient:isa("HeavyMarine")
end

function Heavy:GetIsPermanent()
    return true
end  

function Heavy:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self:GetIsValidRecipient(player)      
end  

function Heavy:_GetNearbyRecipient()
end

if Server then
    
    function Heavy:OnUseDeferred()
        
        local player = self.useRecipient 
        self.useRecipient = nil
        
        if player and not player:GetIsDestroyed() and self:GetIsValidRecipient(player) then
            
            player:GiveHeavy()
            --self:TriggerEffects("pickup")
            player:TriggerEffects("pickup", { effecthostcoords = self:GetCoords() })
            DestroyEntity(self)
            
        end
    
    end

    function Heavy:OnUse(player, elapsedTime, useSuccessTable)
    
        if self:GetIsValidRecipient( player ) and ( not self.useRecipient or self.useRecipient:GetIsDestroyed() ) then
            
            self.useRecipient = player
            self:AddTimedCallback( self.OnUseDeferred, 0 )
            
        end
        
    end
    
end

Shared.LinkClassToMap("Heavy", Heavy.kMapName, networkVars)