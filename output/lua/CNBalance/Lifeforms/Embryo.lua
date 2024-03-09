Script.Load("lua/CNBalance/Mixin/RequestHandleMixin.lua")
local networkVars =
{
    evolvePercentage = "float",
    gestationTypeTechId = "enum kTechId"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(EggVariantMixin, networkVars)
AddMixinNetworkVars(RequestHandleMixin,networkVars)

local baseOnCreate = Embryo.OnCreate
function Embryo:OnCreate()
    baseOnCreate(self)
    InitMixin(self,RequestHandleMixin)
end


Shared.LinkClassToMap("Embryo", Embryo.kMapName, networkVars)
