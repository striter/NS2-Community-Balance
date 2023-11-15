Gorge.kAdrenalineEnergyRecuperationRate = 15.0  -- 17 -> 15
Gorge.kContinuousDeathMaxDamageReduction = 0.3

Script.Load("lua/CNBalance/Mixin/RequestHandleMixin.lua")
local networkVars =
{
    bellyYaw = "private compensated float",
    timeSlideEnd = "private time",
    startedSliding = "private boolean",
    sliding = "compensated boolean",
    hasBellySlide = "private compensated boolean",
    timeOfLastPhase = "private time",
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(JumpMoveMixin, networkVars)
AddMixinNetworkVars(CrouchMoveMixin, networkVars)
AddMixinNetworkVars(CelerityMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(BabblerClingMixin, networkVars)
AddMixinNetworkVars(BabblerOwnerMixin, networkVars)
AddMixinNetworkVars(TunnelUserMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(GorgeVariantMixin, networkVars)
AddMixinNetworkVars(RequestHandleMixin,networkVars)

local baseOnCreate = Gorge.OnCreate
function Gorge:OnCreate()
    baseOnCreate(self)
    InitMixin(self,RequestHandleMixin)
end

if Server then
    
    function Gorge:InitWeapons()
        Alien.InitWeapons(self)

        self:GiveItem(SpitSpray.kMapName)
        self:GiveItem(DropStructureAbility.kMapName)
        --self:GiveItem(DropTeamStructureAbility.kMapName)

        self:SetActiveWeapon(SpitSpray.kMapName)
    end
    
end

Shared.LinkClassToMap("Gorge", Gorge.kMapName, networkVars, true)
