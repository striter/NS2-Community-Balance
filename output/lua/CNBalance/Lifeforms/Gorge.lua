Gorge.kAdrenalineEnergyRecuperationRate = 15.0  -- 17 -> 15
Gorge.kKDRatioMaxDamageReduction = 0.3

Script.Load("lua/CNBalance/Weapons/Alien/Gorge/DropTeamStructureAbility.lua")
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

local baseOnInitialized = Gorge.OnInitialized
function Gorge:OnInitialized()
    baseOnInitialized(self)
end

if Server then
    
    function Gorge:InitWeapons()
        Alien.InitWeapons(self)

        self:GiveItem(SpitSpray.kMapName)
        self:GiveItem(DropStructureAbility.kMapName)
        self:GiveItem(DropTeamStructureAbility.kMapName)
        self:SetActiveWeapon(SpitSpray.kMapName)
    end

end


if Client then

    function Gorge:OverrideInput(input)

        -- Always let the DropStructureAbility override input, since it handles client-side-only build menu

        local ability = self:GetActiveWeapon()
        if ability then
            local mapName = ability:GetMapName()
            if mapName == DropStructureAbility.kMapName or mapName == DropTeamStructureAbility.kMapName then
                input = ability:OverrideInput(input)
            end
        end

        return Player.OverrideInput(self, input)

    end
end

function Gorge:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud
    local reduction = kGorgeDamageReduction[doer:GetClassName()]
    if reduction then
        damageTable.damage = damageTable.damage * reduction
    end
end

function Gorge:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kGorgeHealthPerBioMass * techLevel + extraPlayers * 2.5 + recentWins * -5
end

Shared.LinkClassToMap("Gorge", Gorge.kMapName, networkVars, true)
