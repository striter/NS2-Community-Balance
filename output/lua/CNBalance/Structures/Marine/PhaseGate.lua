Script.Load("lua/BiomassHealthMixin.lua")

local kPhaseCooldownBase = 0.8
local kPhaseCooldownPerPlayerAboveLimit = 0.1
local kPhaseCooldownPerGateUpEnd = 0.5
local kBeaconInstantPhaseDuration = 15
local kBeaconInstantPhaseCooldown = 0.5

local baseOnCreate = PhaseGate.OnCreate
function PhaseGate:OnCreate()
    baseOnCreate(self)
    InitMixin(self, BiomassHealthMixin)
    if Server then
        self.cooldownNextPhase = 1
    end
end

function PhaseGate:GetExtraHealth(techLevel,extraPlayers,recentWins)
    return kPhaseGateHealthPerPlayerAdd * extraPlayers
end


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

local function GetDestinationGate(self)

    -- Find next phase gate to teleport to
    local phaseGates = {}
    for index, phaseGate in ipairs( GetEntitiesForTeam("PhaseGate", self:GetTeamNumber()) ) do
        if GetIsUnitActive(phaseGate) then
            table.insert(phaseGates, phaseGate)
        end
    end

    if table.icount(phaseGates) < 2 then
        return nil
    end

    -- Find our index and add 1
    local index = table.find(phaseGates, self)
    if (index ~= nil) then
        local nextIndex
        if directionBackwards then
            nextIndex = ConditionalValue(index == 1, table.icount(phaseGates), index - 1)
        else
            nextIndex = ConditionalValue(index == table.icount(phaseGates), 1, index + 1)
        end

        ASSERT(nextIndex >= 1)
        ASSERT(nextIndex <= table.icount(phaseGates))
        return phaseGates[nextIndex],#phaseGates

    end

    return nil

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

        
        user:SetOrigin(self.destinationEndpoint)

        --Mark PG to trigger Phase/teleport FX next update loop. This does incure a _slight_ delay in FX but it's worth it
        --to remove the need for the plyaer-centric 2D sound, and simplify effects definitions
        self.performedPhaseLastUpdate = true

        if Server then
            
            local phaseTime = kBeaconInstantPhaseCooldown
            local destinationPhaseGate,gateCount = GetDestinationGate(self)
            if destinationPhaseGate  then
                if destinationPhaseGate:GetIsCorroded() then
                    if user.DeductArmorWithAutoWeld then
                        user:DeductArmorWithAutoWeld(kMarinePhaseArmorDeduct)
                        user:SetCorroded()
                    end

                    if user.SetCorroded then
                        user:SetCorroded()
                    end
                end

                self:TransferParasite(user)
                user:TransferParasite(destinationPhaseGate)
            end
            
            local instantPhase = user.timeLastBeacon and Shared.GetTime() - user.timeLastBeacon <= kBeaconInstantPhaseDuration
            if not instantPhase then
                gateCount = gateCount or 2
                phaseTime = kPhaseCooldownBase
                        + math.max( 0,gateCount - 2) * kPhaseCooldownPerGateUpEnd
                        + playerAboveLimit * kPhaseCooldownPerPlayerAboveLimit
            end

            local playerAboveLimit = GetPlayersAboveLimit(self:GetTeamNumber())
            self.cooldownNextPhase = phaseTime
        end
        
        self.timeOfLastPhase = Shared.GetTime()

        return true

    end

    return false

end

if Server then
    
    local function ComputeDestinationLocationId(self, destGate)

        local destLocationId = Entity.invalidId
        if destGate then

            local location = GetLocationForPoint(destGate:GetOrigin())
            if location then
                destLocationId = location:GetId()
            end

        end

        return destLocationId

    end
    
    local function DestroyRelevancyPortal(self)
        if self.relevancyPortalIndex ~= -1 then
            Server.DestroyRelevancyPortal(self.relevancyPortalIndex)
            self.relevancyPortalIndex = -1
        end
    end

    
    function PhaseGate:Update()

        local destinationPhaseGate,gateCount = GetDestinationGate(self)

        if self.performedPhaseLastUpdate then
            self:TriggerEffects("phase_gate_player_teleport", { effecthostcoords = self:GetCoords() })

            if destinationPhaseGate ~= nil then
                --Force destination gate to trigger effect so the teleporting FX is not visible to enemy with sight on self
                local destinationCoords = Angles(0, self.targetYaw, 0):GetCoords()
                destinationCoords.origin = self.destinationEndpoint
                destinationPhaseGate:TriggerEffects("phase_gate_player_teleport", { effecthostcoords = destinationCoords })
            end

            self.performedPhaseLastUpdate = false
        end

        
        self.phase = (self.timeOfLastPhase ~= nil) and (Shared.GetTime() < (self.timeOfLastPhase + self.cooldownNextPhase))

        if destinationPhaseGate ~= nil and GetIsUnitActive(self) and self.deployed and destinationPhaseGate.deployed then

            self.destinationEndpoint = destinationPhaseGate:GetOrigin()
            self.linked = true
            self.targetYaw = destinationPhaseGate:GetAngles().yaw
            self.destLocationId = ComputeDestinationLocationId(self, destinationPhaseGate)

            if self.relevancyPortalIndex == -1 then
                -- Create a relevancy portal to the destination to smooth out entity propagation.
                local mask = 0
                local teamNumber = self:GetTeamNumber()
                if teamNumber == 1 then
                    mask = kRelevantToTeam1Unit
                elseif teamNumber == 2 then
                    mask = kRelevantToTeam2Unit
                end

                if mask ~= 0 then
                    self.relevancyPortalIndex = Server.CreateRelevancyPortal(self:GetOrigin(), self.destinationEndpoint, mask, self.kRelevancyPortalRadius)
                end
            end

        else
            self.linked = false
            self.targetYaw = 0
            self.destLocationId = Entity.invalidId

            DestroyRelevancyPortal(self)

        end

        return true

    end

end

if Client then

    function PhaseGate:OnUpdateRender()

        PROFILE("PhaseGate:OnUpdateRender")

        local linked = self.linked and not self.phase
        if self.clientLinked ~= linked then

            self.clientLinked = linked

            local effects = ConditionalValue(linked and self:GetIsVisible(), "phase_gate_linked", "phase_gate_unlinked")
            self:TriggerEffects(effects) --FIXME This is really wasteful

        end

    end

end
