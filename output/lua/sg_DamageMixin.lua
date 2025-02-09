--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--

-- Exclude these targets from protection (prevent exploits )
local function CanBeDamaged(target)
    return target == nil or target:isa("Babbler") or target:isa("Whip")
end

-- Truce mode untill front doors are closed
local ns2_DoDamage = DamageMixin.DoDamage
function DamageMixin:DoDamage(damage, target, point, direction, surface, altMode, showtracer)
    local front, siege, suddendeath = GetGameInfoEntity():GetSiegeTimes()
    if front > 0 and siege > 0 and not CanBeDamaged(target) then
        return false -- peacemaker
    end

    return ns2_DoDamage(self, damage, target, point, direction, surface, altMode, showtracer)
end
