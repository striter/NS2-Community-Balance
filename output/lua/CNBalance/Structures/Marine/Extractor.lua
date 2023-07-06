-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Extractor.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- Marine resource extractor. Gathers resources when built on a nozzle.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/RecycleMixin.lua")

Script.Load("lua/ResourceTower.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ExtractorVariantMixin.lua")
Script.Load("lua/DamageMixin.lua")

Script.Load("lua/BiomassHealthMixin.lua")


class 'Extractor' (ResourceTower)

Extractor.kMapName = "extractor"

Extractor.kModelName = PrecacheAsset("models/marine/extractor/extractor.model")

local kAnimationGraph = PrecacheAsset("models/marine/extractor/extractor.animation_graph")

Shared.PrecacheModel(Extractor.kModelName)

local networkVars = {
    charged = "boolean",
}

AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(PowerConsumerMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(HiveVisionMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(ExtractorVariantMixin, networkVars)


function Extractor:OnCreate()

    ResourceTower.OnCreate(self)

    InitMixin(self, CorrodeMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    InitMixin(self, HiveVisionMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, BiomassHealthMixin)

    if Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self.charged = false
    if Server then
        self.chargeTime = Shared.GetTime()
    end
end

function Extractor:OnInitialized()

    ResourceTower.OnInitialized(self)

    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)

    self:SetModel(Extractor.kModelName, kAnimationGraph)

    if Server then

        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        InitMixin(self, InfestationTrackerMixin)

    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end

    InitMixin(self, IdleMixin)

    --Must be init'd last
    if not Predict then
        InitMixin(self, ExtractorVariantMixin)
        self:ForceSkinUpdate()
    end

end


function Extractor:OnUpdate(deltaTime)
    if Server then
        ResourceTower.OnUpdate(self,deltaTime)
    end
        
    if not self:GetIsAlive() then return end

    if Server then
        local techID = self:GetTechId()
        
        self.charged = techID == kTechId.PoweredExtractor and Shared.GetTime() - self.chargeTime > kPoweredExtractorChargingInterval
    end

    if Client then
        if self.electrifiedClient ~= self.charged then
            self.electrifiedClient = self.charged

            local thirdpersonModel = self:GetRenderModel()
            if thirdpersonModel then

                if self.electrifiedClient then
                    self.electrifiedMaterial = AddMaterial(thirdpersonModel, MAC.kElectrifiedThirdpersonMaterialName)
                else
                    if RemoveMaterial(thirdpersonModel, self.electrifiedMaterial) then
                        self.electrifiedMaterial = nil
                    end
                end
            end
        end
    end
end

function Extractor:GetRequiresPower()
    return true
end

function Extractor:GetResetsPathing()
    return true
end

function Extractor:GetDamagedAlertId()
    return kTechId.MarineAlertExtractorUnderAttack
end

if Server then

    function Extractor:GetIsCollecting()
        return ResourceTower.GetIsCollecting(self) and self:GetIsPowered()
    end

end


function Extractor:OnResearchComplete(researchId)
    if researchId == kTechId.PoweredExtractorUpgrade then
        self:UpgradeToTechId(kTechId.PoweredExtractor)
    end
end

function Extractor:GetTechButtons()
    local techId = self:GetTechId()
    if techId == kTechId.Extractor then
        return {
            kTechId.PoweredExtractorUpgrade, kTechId.None, kTechId.None, kTechId.None,
            kTechId.CollectResources, kTechId.None, kTechId.None, kTechId.None,
        }
    end

    return {
        kTechId.CollectResources, kTechId.None, kTechId.None, kTechId.None,
        kTechId.None, kTechId.None, kTechId.None, kTechId.None,
    }
end

function Extractor:GetHealthbarOffset()
    return 2.0
end

function Extractor:GetDeathIconIndex()
    return kDeathMessageIcon.EMPBlast
end

function Extractor:GetHealthPerTeamExceed()
    return kExtractorHealthPerPlayerAdd
end
if Server then
    function Extractor:OnTakeDamage(_, attacker, doer)

        if not attacker then return end
        
        if attacker:isa("Player") and GetAreEnemies(self,attacker) then
            if  (attacker:GetOrigin() - self:GetOrigin()):GetLengthXZ() > kPoweredExtractorDamageDistance then return end   --Don't damage out of distance

            if not self.charged then return end
            self.charged = false
            self.chargeTime = Shared.GetTime()

            self:DoDamage(kPoweredExtractorDamage,attacker,self:GetOrigin())
            if attacker.SetElectrified then
                attacker:SetElectrified(kPoweredExtractorElectrifyDuration)
            end
            attacker:TriggerEffects("emp_blasted")
        end

    end
    
end

Shared.LinkClassToMap("Extractor", Extractor.kMapName, networkVars)


class 'PoweredExtractor' (Extractor)
PoweredExtractor.kMapName = Extractor.kMapName
PoweredExtractor.kElectrifiedThirdpersonMaterialName = "cinematics/vfx_materials/pulse_gre_elec.material"
--Shared.LinkClassToMap("PoweredExtractor",PoweredExtractor.kMapName , {})
