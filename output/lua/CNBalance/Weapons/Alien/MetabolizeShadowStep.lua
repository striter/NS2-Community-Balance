--
-- lua\Weapons\Alien\Metabolize.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/CNBalance/Weapons/Alien/ShadowStep.lua")

class 'MetabolizeShadowStep' (ShadowStep)

MetabolizeShadowStep.kMapName = "metabolizeshadowstep"
MetabolizeShadowStep.kKeepCloakWhenPrimary = true
MetabolizeShadowStep.kKeepCloakWhenSecondary = true

local networkVars =
{
    lastPrimaryAttackTime = "time",
    useHudSlot = "boolean",
}
kMetabolizeDelay = 2.0
local kMetabolizeEnergyRegain = 35
local kMetabolizeHealthRegain = 20

local kAnimationGraph = PrecacheAsset("models/alien/vokex/vokex_view.animation_graph")

function MetabolizeShadowStep:OnCreate()

    ShadowStep.OnCreate(self)

    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0

    if Server then
        self.useHudSlot = GetAlienWeaponSelectModeForPlayer(self:GetParent()) == 1
    end

end

if Server then

    function MetabolizeShadowStep:UpdateHUDSlot()
        self.useHudSlot = GetAlienWeaponSelectModeForPlayer(self:GetParent()) == 1
    end

end

function MetabolizeShadowStep:GetAnimationGraphName()
    return kAnimationGraph
end

function MetabolizeShadowStep:GetEnergyCost()
    return kMetabolizeEnergyCost
end

function MetabolizeShadowStep:GetHUDSlot()

    if not self.useHudSlot then
        return kNoWeaponSlot
    end

    return 2
end

function MetabolizeShadowStep:GetDeathIconIndex()
    return kDeathMessageIcon.Metabolize
end

function MetabolizeShadowStep:GetAttackDelay()
    return kMetabolizeDelay
end

function MetabolizeShadowStep:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function MetabolizeShadowStep:GetSecondaryTechId()
    return kTechId.ShadowStep
end

function MetabolizeShadowStep:GetHasAttackDelay()
    local parent = self:GetParent()
    return self.lastPrimaryAttackTime + kMetabolizeDelay > Shared.GetTime() or parent and parent:GetIsStabbing()
end

function MetabolizeShadowStep:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay() then
        self.primaryAttacking = true
        player.timeMetabolize = Shared.GetTime()
    else
        self:OnPrimaryAttackEnd()
    end

end

function MetabolizeShadowStep:OnPrimaryAttackEnd()

    Blink.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false

end

function MetabolizeShadowStep:OnHolster(player)

    ShadowStep.OnHolster(self, player)
    self.primaryAttacking = false

end

function MetabolizeShadowStep:OnTag(tagName)

    PROFILE("MetabolizeShadowStep:OnTag")

    if tagName == "metabolize" and not self:GetHasAttackDelay() then
        local player = self:GetParent()
        if player then
            player:DeductAbilityEnergy(kMetabolizeEnergyCost)
            player:TriggerEffects("metabolize")
            --if player:GetCanMetabolizeHealth() then
            --    local totalHealed = player:AddHealth(kMetabolizeHealthRegain, false, false, nil, self, true)
            --    if Client and totalHealed > 0 then
            --        local GUIRegenerationFeedback = ClientUI.GetScript("GUIRegenerationFeedback")
            --        GUIRegenerationFeedback:TriggerRegenEffect()
            --        local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
            --        cinematic:SetCinematic(kRegenerationViewCinematic)
            --    end
            --end
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

        local stabWep = self:GetParent():GetWeapon(VortexShadowStep.kMapName)
        if stabWep and stabWep.stabbing then
            stabWep:DoAttack()
        end
    end
end

function MetabolizeShadowStep:OnUpdateAnimationInput(modelMixin)

    PROFILE("MetabolizeShadowStep:OnUpdateAnimationInput")

    ShadowStep.OnUpdateAnimationInput(self, modelMixin)

    modelMixin:SetAnimationInput("ability", "vortex")

    local player = self:GetParent()
    local activityString = (self.primaryAttacking and "primary") or "none"
    if player and player:GetHasMetabolizeAnimationDelay() then
        activityString = "primary"
    end

    modelMixin:SetAnimationInput("activity", activityString)

end

Shared.LinkClassToMap("MetabolizeShadowStep", MetabolizeShadowStep.kMapName, networkVars)
