--________________________________
--
--  NS2: Combat
--    Copyright 2014 Faultline Games Ltd.
--  and Unknown Worlds Entertainment Inc.
--
--________________________________

Script.Load("lua/Player.lua")
Script.Load("lua/Devour/DevouredViewModel.lua")

class 'DevouredPlayer' (Marine)

DevouredPlayer.kMapName = "DevouredPlayer"
DevouredPlayer.kMaterialDelay = 0.1
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/devour_goop.surface_shader")

local networkVars =
{
    devouringScalar = "float (0 to 1 by .01)",
	isOnosDying = "boolean",
	devouringOnosId = "integer",
}

function DevouredPlayer:OnCreate()

    Marine.OnCreate(self)
    
end

function DevouredPlayer:OnInitialized()

    Marine.OnInitialized(self)
    

    self:SetIsVisible(false)       
    self:SetModel()
    
    self:SetPropagate(Entity.Propagate_Never) 

    self.devouringScalar = 1 - self:GetHealthFraction()
	self.isOnosDying = false
    if Server then
        self:TriggerEffects("player_start_gestate")
	elseif Client and self:GetIsLocalPlayer() then
		self.devourFlashlight = Client.CreateRenderLight()
		self.devourFlashlight:SetType(RenderLight.Type_Spot)
        self.devourFlashlight:SetColor(Color(.7, .4, .3))
        self.devourFlashlight:SetInnerCone(math.rad(12))
        self.devourFlashlight:SetOuterCone(math.rad(20))
        self.devourFlashlight:SetIntensity(4)
        self.devourFlashlight:SetRadius(8)
		self.devourFlashlight:SetAtmosphericDensity(0.5)
		self.devourFlashlight:SetCastsShadows(true)
		self.devourFlashlight:SetGoboTexture("models/marine/male/flashlight.dds")
		
        self:TriggerEffects("combat_devour_stomach_inside") 
	end
    
end

if Client then
	function DevouredPlayer:OnUpdateRender()
	
		Marine.OnUpdateRender(self)
		
		local coords = Coords(self:GetViewCoords())
        coords.origin = coords.origin - (coords.zAxis * 0.75) + (coords.yAxis * 0.3)
		local fwdCoords = Coords(self:GetViewCoords())
		--fwdCoords.origin = coords.origin - (coords.zAxis * 2)
		local direction = fwdCoords.origin - coords.origin
		coords = Coords.GetLookIn(coords.origin, direction)
		
		if self.devourFlashlight then
		    self.devourFlashlight:SetCoords(coords)
        end
	
	end
	
	-- override far plane distance, default value is 400
	function DevouredPlayer:GetCameraFarPlane()
		return 8
	end
end

function DevouredPlayer:OnDestroy()
	Marine.OnDestroy(self)

	if self.devourFlashlight ~= nil then
        Client.DestroyRenderLight(self.devourFlashlight)
    end
	
    if Server then
        self:TriggerEffects("player_end_gestate")
    end
    self:SetViewModel(nil, nil)    
	if Client then
		Client.SetSoundGeometryEnabled(true)
		local player = Client.GetLocalPlayer()
		if player == self then
			self:SetCameraYOffset(0)
		end
	end
end


-- let the player chat, but not move
function DevouredPlayer:OverrideInput(input)
  
		ClampInputPitch(input)
		
		-- Completely override movement and commands
		input.move.x = 0
		input.move.y = 0
		input.move.z = 0
		
	return input
    
end


function DevouredPlayer:InitWeapons()
    self:GiveItem(DevouredViewModel.kMapName)
    self:SetActiveWeapon(DevouredViewModel.kMapName)
end

function DevouredPlayer:GetDevourScalar()
    return self.devouringScalar
end

function DevouredPlayer:GetPlayFootsteps()
    return false
end

function DevouredPlayer:GetMovePhysicsMask()
    return PhysicsMask.All
end

function DevouredPlayer:GetControllerSize()
    return 0, 0
end
-- Devoured players crouching makes the onos fly!
function DevouredPlayer:GetCanCrouch()
    return false
end

function DevouredPlayer:GetTraceCapsule()
    return 0, 0
end

function DevouredPlayer:GetHasController()
	return false
end

function DevouredPlayer:GetHasOutterController()
	return false
end

function DevouredPlayer:GetCanTakeDamageOverride()
    return true
end

--[[function DevouredPlayer:GetCanDieOverride()
	if self:GetHealth() <= 0 then
		return true
	end
end--]]

function DevouredPlayer:AdjustGravityForce(input, gravity)
    return 0
end

-- ERASE OR REFACTOR
-- Handle player transitions to egg, new lifeforms, etc.
function DevouredPlayer:OnEntityChange(oldEntityId, newEntityId)

    if oldEntityId ~= Entity.invalidId and oldEntityId ~= nil then
    
        if oldEntityId == self.specTargetId then
            self.specTargetId = newEntityId
        end
        
        if oldEntityId == self.lastTargetId then
            self.lastTargetId = newEntityId
        end
        
    end
    
end

function DevouredPlayer:GetPlayerStatusDesc()
    return kPlayerStatus.Devoured
end

function DevouredPlayer:GetTechId()
    return kTechId.Marine
end

function DevouredPlayer:OnTag(tagName)
    --Print(tagName)
end

function DevouredPlayer:SetIsOnosDying(newValue)
	self.isOnosDying = newValue
end

function DevouredPlayer:GetIsOnosDying()
	return self.isOnosDying
end

function DevouredPlayer:SetDevouringOnosId(newValue)
	self.devouringOnosId = newValue
end

function DevouredPlayer:GetDevouringOnosId()
	return self.devouringOnosId
end

function DevouredPlayer:OnUpdatePoseParameters()    
        
	if not Shared.GetIsRunningPrediction() then
    
		local viewModel = self:GetViewModelEntity()
		if viewModel ~= nil then
		
			local activeWeapon = self:GetActiveWeapon()
			if activeWeapon and activeWeapon.UpdateViewModelPoseParameters then
				activeWeapon:UpdateViewModelPoseParameters(viewModel, input)
			end
			
		end
	
	end

end

function DevouredPlayer:ModifyDamageTaken(damageTable, attacker, doer, damageType)
    if not (doer:isa("DevouredViewModel") or doer:isa("Devour")) then
        damageTable.damage = 0
    end
end

Shared.LinkClassToMap("DevouredPlayer", DevouredPlayer.kMapName, networkVars)
