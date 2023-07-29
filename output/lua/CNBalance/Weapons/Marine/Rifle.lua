local baseOnInitialized = Rifle.OnInitialized
function Rifle:OnInitialized()
    baseOnInitialized(self)
    self.ammo = self:GetMaxClips() * self:GetClipSize()
    self.clip = self:GetClipSize()
end

function Rifle:GetClipSize()
    return GetHasTech(self,kTechId.MilitaryProtocol) and kMPRifleClipSize[NS2Gamerules_GetPlayerWeaponUpgradeIndex(self)] or kRifleClipSize
end

if Client then
    function Rifle:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/CNBalance/GUI/GUIRifleDisplay.lua", variant = self:GetRifleVariant() }
    end
end

if Server then
    function Rifle:GetVariantOverride(variant)
        if GetHasTech(self,kTechId.MilitaryProtocol) then
            return kRifleVariants.chroma
        end
        return variant
    end
end

local kButtRange = 1.5
function Rifle:PerformMeleeAttack(player)

    player:TriggerEffects("rifle_alt_attack")

    local didHit, lastTarget,_,_ = AttackMeleeCapsule(self, player, kRifleMeleeDamage, kButtRange, nil, true)

    if didHit and lastTarget then
        if lastTarget:isa("Player") then
            local mass = lastTarget.GetMass and lastTarget:GetMass() or Player.kMass
            if mass < 100 then
                local direction = player:GetViewCoords().zAxis
                direction.y = 0
                direction:Normalize()
                ApplyPushback(lastTarget,0.2,direction * 4.5)
            end
        end 
    end
end