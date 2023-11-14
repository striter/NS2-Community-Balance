-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\XenocideLeap.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
--    First primary attack is xenocide, every next attack is bite. Secondary is leap.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/BiteLeap.lua")

local kRange = 1.4

class 'XenocideLeap' (BiteLeap)

XenocideLeap.kMapName = "xenocide"

-- after kDetonateTime seconds the skulk goes 'boom!'
local kDetonateTime = 2.0
local kXenocideSoundName = PrecacheAsset("sound/NS2.fev/alien/common/xenocide_start")


local networkVars = { }

local function CheckForDestroyedEffects(self)
    if self.XenocideSoundName and not IsValid(self.XenocideSoundName) then
        self.XenocideSoundName = nil
    end
end

local function TriggerXenocide(self, player)

    if Server then
        CheckForDestroyedEffects( self )

        if not self.XenocideSoundName then
            self.XenocideSoundName = Server.CreateEntity(SoundEffect.kMapName)
            self.XenocideSoundName:SetAsset(kXenocideSoundName)
            self.XenocideSoundName:SetParent(self)
            self.XenocideSoundName:Start()
        else
            self.XenocideSoundName:Start()
        end
        --StartSoundEffectOnEntity(kXenocideSoundName, player)
        self.xenocideTimeLeft = kDetonateTime

    elseif Client and Client.GetLocalPlayer() == player then

        if not self.xenocideGui then
            self.xenocideGui = GetGUIManager():CreateGUIScript("GUIXenocideFeedback")
        end

        self.xenocideGui:TriggerFlash(kDetonateTime)
        player:SetCameraShake(.01, 15, kDetonateTime)

    end

end

local function CleanUI(self)

    if self.xenocideGui ~= nil then

        GetGUIManager():DestroyGUIScript(self.xenocideGui)
        self.xenocideGui = nil

    end

end

function XenocideLeap:OnDestroy()

    BiteLeap.OnDestroy(self)

    if Client then
        CleanUI(self)
    end

end

function XenocideLeap:GetDeathIconIndex()
    return kDeathMessageIcon.Xenocide
end

function XenocideLeap:GetEnergyCost()

    if not self.xenociding then
        return kXenocideEnergyCost
    else
        return BiteLeap.GetEnergyCost(self)
    end

end

function XenocideLeap:GetIsXenociding()
    return self.xenociding
end

function XenocideLeap:GetHUDSlot()
    return 3
end

function XenocideLeap:GetRange()
    return kRange
end

function XenocideLeap:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() then

        if not self.xenociding then

            TriggerXenocide(self, player)
            self.xenociding = true

        else

            if self.xenocideTimeLeft and self.xenocideTimeLeft < kDetonateTime * 0.8 then
                BiteLeap.OnPrimaryAttack(self, player)
            end

        end

    end

end

local function StopXenocide(self)

    CleanUI(self)

    self.xenociding = false

end

function XenocideLeap:OnProcessMove(input)

    BiteLeap.OnProcessMove(self, input)

    local player = self:GetParent()
    if self.xenociding then

        if player:isa("Commander") then
            StopXenocide(self)
        elseif Server then

            CheckForDestroyedEffects( self )

            self.xenocideTimeLeft = math.max(self.xenocideTimeLeft - input.time, 0)

            local alive = player:GetIsAlive()
            if self.xenocideTimeLeft == 0 or not alive then
                self.xenociding = false
                self.xenocideTimeLeft = 0

                local xenoOrigin = player.GetEngagementPoint and player:GetEngagementPoint() or (player:GetOrigin() + Vector(0,0.5,0))

                player:TriggerEffects("xenocide", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})

                
                local xenocideFuel = GetIsTechUnlocked(self,kTechId.XenocideFuel)
                local damage = xenocideFuel and kXenocideFuelDamage or kXenocideDamage
                local range = xenocideFuel and kXenocideFuelRange or kXenocideRange
                local hitEntities = GetEntitiesWithMixinWithinRange("Live", xenoOrigin, range)
                table.removevalue(hitEntities, player)

                local healthScalar = player:GetHealthScalar()
                damage = damage * (kXenocideDamageScalarEmptyHealth + kXenocideDamageHealthScalar *healthScalar )
                
                RadiusDamage(hitEntities, xenoOrigin, range, damage, self)

                player.spawnReductionTime = xenocideFuel and kXenocideFuelSpawnReduction or kXenocideSpawnReduction

                player:SetBypassRagdoll(true)

                player:Kill(player, self)
                if self.XenocideSoundName then
                    self.XenocideSoundName:Stop()
                    self.XenocideSoundName = nil
                end
            end
            
            --if Server and not player:GetIsAlive() and self.XenocideSoundName and self.XenocideSoundName:GetIsPlaying() == true then
            --    self.XenocideSoundName:Stop()
            --    self.XenocideSoundName = nil
            --end

        elseif Client and not player:GetIsAlive() and self.xenocideGui then
            CleanUI(self)
        end

    end

end

if Server then

    function XenocideLeap:GetDamageType()

        if self.xenocideTimeLeft == 0 then
            return kXenocideDamageType
        else
            return kBiteDamageType
        end

    end

end

Shared.LinkClassToMap("XenocideLeap", XenocideLeap.kMapName, networkVars)