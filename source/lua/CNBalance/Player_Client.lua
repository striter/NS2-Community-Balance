function Player:GetWeaponClipSize()
    local weapon = self:GetActiveWeapon()

    if weapon then
        if weapon:isa("ClipWeapon") then
            return weapon:GetClipSize()
        end
    end

    return 0
end