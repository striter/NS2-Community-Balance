--________________________________
--
--  NS2: Combat
--    Copyright 2014 Faultline Games Ltd.
--  and Unknown Worlds Entertainment Inc.
--
--________________________________

Script.Load("lua/Weapons/Weapon.lua")

class 'DevouredViewModel' (Weapon)

DevouredViewModel.kMapName = "devoured_view_model"

DevouredViewModel.kViewModelName = PrecacheAsset("models/alien/devour/onos_stomach_view.model")
local kAnimationGraph = PrecacheAsset("models/alien/devour/onos_stomach_view.animation_graph")
DevouredViewModel.kDevourGoopMaterial = "cinematics/vfx_materials/devour_goop.material"
local kPunchSoundLeft = PrecacheAsset("sound/combat.fev/combat/common/marine/onos_punch_l")
local kPunchSoundRight = PrecacheAsset("sound/combat.fev/combat/common/marine/onos_punch_r")

local kWoundSound = PrecacheAsset("sound/NS2.fev/marine/common/wound")
local kRange = 0.0001
local kPunchSelfDamage = 5

local networkVars =
{
}

function DevouredViewModel:OnCreate()
    Weapon.OnCreate(self)
end

function DevouredViewModel:OnInitialized()

    Weapon.OnInitialized(self) 
	local player = self:GetParent()
	if Client then
		self.timeToApplyGoop = Shared.GetTime() + 0.2
	end

end

function DevouredViewModel:GetViewModelName()
    return DevouredViewModel.kViewModelName
end

function DevouredViewModel:GetAnimationGraphName()
    return kAnimationGraph
end

function DevouredViewModel:OnUpdateRender()
	-- Add the devour goop material to the view model, only for local players
	local model = self:GetRenderModel()
    if (not self.devouredViewMaterial) and model then
		local player = Client.GetLocalPlayer()
		if self == player and Shared.GetTime() > self.timeToApplyGoop then
			local viewModelEnt = self:GetViewModelEntity()
			if viewModelEnt and viewModelEnt:GetRenderModel() then
				self.devouredViewMaterial = AddMaterial(viewModelEnt:GetRenderModel(), DevouredViewModel.kDevourGoopMaterial)
			end
		end
	end
end

function DevouredViewModel:GetHUDSlot()
    return kTertiaryWeaponSlot
end

function DevouredViewModel:GetRange()
    return kRange
end

function DevouredViewModel:GetShowDamageIndicator()
    return true
end

function DevouredViewModel:GetSprintAllowed()
    return false
end

function DevouredViewModel:GetDeathIconIndex()
    return kDeathMessageIcon.Devour
end

function DevouredViewModel:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    -- Attach weapon to parent's hand
    --self:SetAttachPoint(Weapon.kHumanAttachPoint)

end

function DevouredViewModel:OnHolster(player)

    Weapon.OnHolster(self, player)
    self.primaryAttacking = false
    
end

function DevouredViewModel:OnPrimaryAttack(player)

    if not self.attacking then
        self.primaryAttacking = true        
    end

end

function DevouredViewModel:OnPrimaryAttackEnd(player)
    self.primaryAttacking = false
end

function DevouredViewModel:GetHasSecondary(player)
    return true
end

function DevouredViewModel:GetSecondaryAttackRequiresPress()
    return true
end

function DevouredViewModel:OnSecondaryAttack(player)

    if not self.attacking then
        self.secondaryAttacking = true        
    end

end

function DevouredViewModel:OnSecondaryAttackEnd(player)
    self.secondaryAttacking = false
end

function DevouredViewModel:OnTag(tagName)  

	local parent = self:GetParent()
	if parent then
		local coords = parent:GetViewCoords()
		if Client and parent and parent:GetIsLocalPlayer() then
			if tagName == "attack_left_start" then
				Shared.PlayPrivateSound(parent, kPunchSoundLeft, nil, 1.0, coords.origin + coords.xAxis - 0.1)
			elseif tagName == "attack_right_start" then
				Shared.PlayPrivateSound(parent, kPunchSoundRight, nil, 1.0, coords.origin + coords.xAxis + 0.1)
			end
		end
		
		if tagName == "attack_left_end" or tagName == "attack_right_end" then
			local onos = Shared.GetEntity(parent:GetDevouringOnosId())
			local coords = self:GetParent():GetViewCoords().origin + Vector(0,-40,0.6)
			if onos then
				self:DoDamage(kDevourPunchDamage, onos, coords, nil, "none")
                parent:DeductHealth(kPunchSelfDamage, onos, self , true)
                --[[if Server then
                    Print(ToString(Shared.GetTime()))
                end--]]
			end
		end
	end
end

function DevouredViewModel:UpdateViewModelPoseParameters(viewModel, input)
	local parent = self:GetParent()
	if parent then
		local devourPercent = (1 - self:GetParent():GetHealthScalar()) * 100
		viewModel:SetPoseParam("devour_percent", devourPercent)
	end
	
end

function DevouredViewModel:OnUpdateAnimationInput(modelMixin)

	local player = self:GetParent()
    local activity = "idle1"
	if player and player.isOnosDying then
		activity = "freedom"
    elseif self.primaryAttacking then
        activity = "primary"
	elseif self.secondaryAttacking then
		activity = "secondary"
	end
	
    modelMixin:SetAnimationInput("activity", activity)     
    
	if Client and player and player:GetIsLocalPlayer() then
		if activity == "freedom" then
			if not self.hasStartedEscaping then
				Client.SetSoundGeometryEnabled(true)
				player:SetCameraYOffset(0)
				self.hasStartedEscapting = true
			end
		else
			Client.SetSoundGeometryEnabled(false)
			player:SetCameraYOffset(-20)
		end
	end
	
end


Shared.LinkClassToMap("DevouredViewModel", DevouredViewModel.kMapName, networkVars)