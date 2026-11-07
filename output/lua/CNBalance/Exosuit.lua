Script.Load("lua/PointGiverMixin.lua")

local baseOnCreate = Exosuit.OnCreate
function Exosuit:OnCreate()
    baseOnCreate(self)
    InitMixin(self, PointGiverMixin)
end

function Exosuit:GetTechId()
    return kTechId.Exosuit
end

-- Vanilla registers only the dual weapon layouts here, so the claw models are carried by a
-- local copy of the table. The graph stays the eject one for every layout like vanilla does:
-- the dropped suit only has to play the eject animation, the full state machines belong to the
-- Exo a marine is driving, and entering those as an idle model leaves the suit standing up.
local kAnimationGraphEject = PrecacheAsset("models/marine/exosuit/exosuit_spawn_animated.animation_graph")
local kLayoutModels = {
    MinigunMinigun = PrecacheAsset("models/marine/exosuit/exosuit_mm.model"),
    RailgunRailgun = PrecacheAsset("models/marine/exosuit/exosuit_rr.model"),
    ClawMinigun = PrecacheAsset("models/marine/exosuit/exosuit_cm.model"),
    ClawRailgun = PrecacheAsset("models/marine/exosuit/exosuit_cr.model"),
}

function Exosuit:SetLayout(layout)
    self:SetModel(kLayoutModels[layout] or Exosuit.kModelName, kAnimationGraphEject)
    self.layout = layout
end

if Server then

    local kLayoutGiveFuncs = {
        MinigunMinigun = "GiveDualExo",
        RailgunRailgun = "GiveDualRailgunExo",
        ClawMinigun    = "GiveClawMinigunExo",
        ClawRailgun    = "GiveClawRailgunExo",
    }

    function Exosuit:OnUseDeferred()
        local player = self.useRecipient
        self.useRecipient = nil
        if player and not player:GetIsDestroyed() and self:GetIsValidRecipient(player) then
            local weapons = player:GetWeapons()
            for i = 1, #weapons do
                weapons[i]:SetParent(nil)
            end
            local giveFunc = kLayoutGiveFuncs[self.layout] or "GiveExo"
            local exoPlayer = player[giveFunc](player, nil, true)
            if exoPlayer then
                for i = 1, #weapons do
                    exoPlayer:StoreWeapon(weapons[i])
                end
                exoPlayer:SetMaxArmor(self:GetMaxArmor())
                exoPlayer:SetArmor(self:GetArmor())
                exoPlayer:SetFlashlightOn(self:GetFlashlightOn())
                exoPlayer:TransferParasite(self)
                exoPlayer:TransferExoVariant(self)
                local now = Shared.GetTime()
                local timeLastDamage = self:GetTimeOfLastDamage() or 0
                local waitEnd = timeLastDamage + kCombatTimeOut
                local cooldownEnd = math.max(waitEnd, self.timeNextWeld)
                local cooldownRemaining = math.max(0, cooldownEnd - now)
                exoPlayer.timeNextWeld = now + cooldownRemaining
                local newAngles = player:GetViewAngles()
                newAngles.pitch = 0
                newAngles.roll = 0
                newAngles.yaw = GetYawFromVector(self:GetCoords().zAxis)
                exoPlayer:SetOffsetAngles(newAngles)
                exoPlayer:SetCoords(self:GetCoords())
                player:TriggerEffects("pickup", { effectshostcoords = self:GetCoords() })
                DestroyEntity(self)
            end
        end
    end

    function Exosuit:GetAutoWeldArmorPerSecond(nanoArmorResearched)
        return nanoArmorResearched and kExoNanoArmorPerSecond or kExoArmorPerSecond
    end

end

function Exosuit:GetExoVariantOverride(variant)
    if GetHasTech(self, kTechId.MilitaryProtocol) then
        return kExoVariants.chroma
    end
    return variant
end
