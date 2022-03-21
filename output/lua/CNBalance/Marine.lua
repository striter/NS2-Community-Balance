
local function CheckResearch(self)
    self.nanoArmorResearched = GetHasTech(self,kTechId.NanoArmor)
    self.lifeSustainResearched = GetHasTech(self,kTechId.LifeSustain)
    return true
end


local baseOnInitialized = Marine.OnInitialized
function Marine:OnInitialized()
    baseOnInitialized(self)

    if Server then
        self.timeNextWeld = 0
        self.timeNextSustain = 0
        self.nanoArmorResearched = false
        self.lifeSustainResearched = false
        self:AddTimedCallback(CheckResearch, 1)
    end
end

if Server then
    
    local function SharedUpdate(self)
    
        if self:GetIsInCombat() then
            return
        end

        local now = Shared.GetTime()
        if self.nanoArmorResearched and now > self.timeNextWeld then 
            self.timeNextWeld = now + AutoWeldMixin.kWeldInterval
            self:OnWeld(self, AutoWeldMixin.kWeldInterval, self, kNanoArmorHealPerSecond)
        end

        if self.lifeSustainResearched and  now > self.timeNextSustain then
            self.timeNextSustain = now + kLifeSustainHealInterval
            self:AddRegeneration(kLifeSustainHealInterval * kLifeSustainHealPerSecond)
        end
    end
    
    local baseOnProcessMove=Marine.OnProcessMove
    function Marine:OnProcessMove(input)
        baseOnProcessMove(self,input)
        SharedUpdate(self)
    end
    
    local baseOnUpdate = Marine.OnUpdate
    function Marine:OnUpdate(deltaTime)
        baseOnUpdate(self,deltaTime)
        SharedUpdate(self)
    end
    
    function Marine:GetCanSelfWeld()
        return true
    end
end


Script.Load("lua/Devour/DevouredPlayer.lua")

Marine.kDevourEscapeScreenEffectDuration = 4

local oldOnCreate = Marine.OnCreate
function Marine:OnCreate()
	oldOnCreate(self)
	self.clientTimeDevourEscaped = -20
end

function Marine:DevourEscape()
	if Server then
		Server.SendNetworkMessage(self, "DevourEscape", {  }, true)
	elseif Client then
		local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
		cinematic:SetCinematic(kTunnelUseScreenCinematic)
		cinematic:SetRepeatStyle(Cinematic.Repeat_None)
		
		self.clientTimeDevourEscaped = Shared.GetTime()
	end
end

local oldGetStatusDesc = Marine.GetPlayerStatusDesc
function Marine:GetPlayerStatusDesc()
		  
	local weapon = self:GetActiveWeapon()
	if (weapon) then
		if (weapon:isa("Revolver")) then
			return kPlayerStatus.Revolver
		end
	end
		
	return oldGetStatusDesc(self)
end