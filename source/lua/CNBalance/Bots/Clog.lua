--Prevent gorge bots from heal crags (gorge shouldnt heal clogs too)
function Clog:GetIsHealableOverride()
    return false
end
