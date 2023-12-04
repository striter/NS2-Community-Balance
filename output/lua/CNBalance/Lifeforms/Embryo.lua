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

function Embryo:Replace(mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)

    if Server then
        local team = self:GetTeam()
        if team.IsOriginForm and team:IsOriginForm() then
            local teamRes = math.min(team:GetTeamResources(),60)
            if teamRes > 0 and self.gestationClass == Gorge.kMapName then
                local res = self:AddResources(teamRes)
                team:AddTeamResources(-res)
            end
        end
    end
    
    return Player.Replace(self,mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
end


Shared.LinkClassToMap("Embryo", Embryo.kMapName, networkVars)
