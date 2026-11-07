-- Keyed by the setup string ExoWeaponHolder:SetWeapons builds, because the weapon
-- classes are not loaded yet when this post hook runs.
local kClawViewModels = {
    ["claw+minigun"] = {
        model = PrecacheAsset("models/marine/exosuit/exosuit_cm_view.model"),
        graph = PrecacheAsset("models/marine/exosuit/exosuit_cm_view.animation_graph"),
    },
    ["claw+railgun"] = {
        model = PrecacheAsset("models/marine/exosuit/exosuit_cr_view.model"),
        graph = PrecacheAsset("models/marine/exosuit/exosuit_cr_view.animation_graph"),
    },
}

if Server then

    local baseGetViewModelName = ExoWeaponHolder.GetViewModelName
    function ExoWeaponHolder:GetViewModelName()
        local clawViewModel = kClawViewModels[self.weaponSetupName]
        return clawViewModel and clawViewModel.model or baseGetViewModelName(self)
    end

    local baseGetAnimationGraphName = ExoWeaponHolder.GetAnimationGraphName
    function ExoWeaponHolder:GetAnimationGraphName()
        local clawViewModel = kClawViewModels[self.weaponSetupName]
        return clawViewModel and clawViewModel.graph or baseGetAnimationGraphName(self)
    end

end
