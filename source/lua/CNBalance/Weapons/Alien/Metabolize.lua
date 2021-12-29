--
-- lua\Weapons\Alien\Metabolize.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'Metabolize' (Blink)

Metabolize.kMapName = "metabolize"

local networkVars =
{
    lastPrimaryAttackTime = "time",
    useHudSlot = "boolean",
}

kMetabolizeDelay = 2.0
local kMetabolizeEnergyRegain = 37
local kMetabolizeHealthRegain = 25

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

function Metabolize:OnCreate()

    Blink.OnCreate(self)

    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0

    if Server then
        self.useHudSlot = GetAlienWeaponSelectModeForPlayer(self:GetParent()) == 1
    end

end

if Server then

    function Metabolize:UpdateHUDSlot()
        self.useHudSlot = GetAlienWeaponSelectModeForPlayer(self:GetParent()) == 1
    end

end

function Metabolize:GetAnimationGraphName()
    return kAnimationGraph
end

function Metabolize:GetEnergyCost()
    return kMetabolizeEnergyCost
end

function Metabolize:GetHUDSlot()

    if not self.useHudSlot then
        return kNoWeaponSlot
    end

    return 2
end

function Metabolize:GetDeathIconIndex()
    return kDeathMessageIcon.Metabolize
end

function Metabolize:GetBlinkAllowed()
    return true
end

function Metabolize:GetAttackDelay()
    return kMetabolizeDelay
end

function Metabolize:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Metabolize:GetSecondaryTechId()
    return kTechId.Blink
end

function Metabolize:GetHasAttackDelay()
    local parent = self:GetParent()
    return self.lastPrimaryAttackTime + kMetabolizeDelay > Shared.GetTime() or parent and parent:GetIsStabbing()
end

function Metabolize:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay() then
        self.primaryAttacking = true
        player.timeMetabolize = Shared.GetTime()
    else
        self:OnPrimaryAttackEnd()
    end

end

function Metabolize:OnPrimaryAttackEnd()

    Blink.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false

end

function Metabolize:OnHolster(player)

    Blink.OnHolster(self, player)
    self.primaryAttacking = false

end

function Metabolize:OnTag(tagName)

    PROFILE("Metabolize:OnTag")

    if tagName == "metabolize" and not self:GetHasAttackDelay() then
        local player = self:GetParent()
        if player then
            player:DeductAbilityEnergy(kMetabolizeEnergyCost)
            player:TriggerEffects("metabolize")
            if player:GetCanMetabolizeHealth() then
                local totalHealed = player:AddHealth(kMetabolizeHealthRegain, false, false, nil, self, true)
                if Client and totalHealed > 0 then
                    local GUIRegenerationFeedback = ClientUI.GetScript("GUIRegenerationFeedback")
                    GUIRegenerationFeedback:TriggerRegenEffect()
                    local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                    cinematic:SetCinematic(kRegenerationViewCinematic)
                end
            end
            player:AddEnergy(kMetabolizeEnergyRegain)
            self.lastPrimaryAttackTime = Shared.GetTime()
            self.primaryAttacking = false
        end
    elseif tagName == "metabolize_end" then
        local player = self:GetParent()
        if player then
            self.primaryAttacking = false
        end
    end

    if tagName == "hit" then

        local stabWep = self:GetParent():GetWeapon(StabBlink.kMapName)
        if stabWep and stabWep.stabbing then
            stabWep:DoAttack()
        end
    end

end

function Metabolize:OnUpdateAnimationInput(modelMixin)

    PROFILE("Metabolize:OnUpdateAnimationInput")

    Blink.OnUpdateAnimationInput(self, modelMixin)

    modelMixin:SetAnimationInput("ability", "vortex")

    local player = self:GetParent()
    local activityString = (self.primaryAttacking and "primary") or "none"
    if player and player:GetHasMetabolizeAnimationDelay() then
        activityString = "primary"
    end

    modelMixin:SetAnimationInput("activity", activityString)

end

Shared.LinkClassToMap("Metabolize", Metabolize.kMapName, networkVars)
