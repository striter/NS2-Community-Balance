local function TransformPlayerCoordsForPhaseGate(player, srcCoords, dstCoords)

    local viewCoords = player:GetViewCoords()

    -- If we're going through the backside of the phase gate, orient us
    -- so we go out of the front side of the other gate.
    if Math.DotProduct(viewCoords.zAxis, srcCoords.zAxis) < 0 then

        srcCoords.zAxis = -srcCoords.zAxis
        srcCoords.xAxis = -srcCoords.xAxis

    end

    -- Redirect player velocity relative to gates
    local invSrcCoords = srcCoords:GetInverse()
    local invVel = invSrcCoords:TransformVector(player:GetVelocity())
    local newVelocity = dstCoords:TransformVector(invVel)
    player:SetVelocity(newVelocity)

    local viewCoords = dstCoords * (invSrcCoords * viewCoords)
    local viewAngles = Angles()
    viewAngles:BuildFromCoords(viewCoords)

    player:SetBaseViewAngles(Angles(0,0,0))
    player:SetViewAngles(viewAngles)

end

function PhaseGate:Phase(user)

    if self.phase then
        return false
    end

    if HasMixin(user, "PhaseGateUser") and self.linked then

        local destinationCoords = Angles(0, self.targetYaw, 0):GetCoords()
        destinationCoords.origin = self.destinationEndpoint

        user:OnPhaseGateEntry(self.destinationEndpoint) --McG: Obsolete for PGs themselves, but required for Achievements

        TransformPlayerCoordsForPhaseGate(user, self:GetCoords(), destinationCoords)

        if user.DeductArmorWithAutoWeld then
            user:DeductArmorWithAutoWeld(kMarinePhaseArmorDeduct)
        end
        
        user:SetOrigin(self.destinationEndpoint)

        --Mark PG to trigger Phase/teleport FX next update loop. This does incure a _slight_ delay in FX but it's worth it
        --to remove the need for the plyaer-centric 2D sound, and simplify effects definitions
        self.performedPhaseLastUpdate = true

        self.timeOfLastPhase = Shared.GetTime()

        return true

    end

    return false

end