Script.Load("lua/Combat/SentryAbility.lua")
Script.Load("lua/Combat/ArmoryAbility.lua")
Script.Load("lua/Combat/MarineStructureMixin.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/LiveMixin.lua")

class 'CombatBuilder' (Weapon)

local kDropCooldown = 1

local kAnimationGraph = PrecacheAsset("models/marine/welder/welder_view.animation_graph")
CombatBuilder.kViewModel = GenerateMarineViewModelPaths("welder")

CombatBuilder.kMapName = "combatbuilder"
CombatBuilder.kModelName = PrecacheAsset("models/marine/welder/builder_sandstorm.model")

local kCreateFailSound = PrecacheAsset("sound/NS2.fev/alien/gorge/create_fail")

CombatBuilder.kSupportedStructures = { SentryAbility, ArmoryAbility}--, PhaseGateAbility, ObservatoryAbility }

local networkVars =
{
    numSentriesLeft = "private integer (0 to 16)",
    numMiniArmoriesLeft = "private integer (0 to 16)",
	-- numPhaseGatesLeft = string.format("private integer (0 to %d)", kMaxStructures[kTechId.PhaseGate]),
	-- numObservatoriesLeft = string.format("private integer (0 to %d)", kMaxStructures[kTechId.Observatory]),
}
AddMixinNetworkVars(LiveMixin, networkVars)

function CombatBuilder:GetAnimationGraphName()
    return kAnimationGraph
end

function CombatBuilder:GetActiveStructure()

    if self.activeStructure == nil then
        return nil
    else
        return CombatBuilder.kSupportedStructures[self.activeStructure]
    end

end

function CombatBuilder:OnCreate()

    Weapon.OnCreate(self)
    
    self.dropping = false
    self.mouseDown = false
    self.activeStructure = nil
    
    InitMixin(self, PickupableWeaponMixin)
    InitMixin(self, LiveMixin)
    
    if Server then
        self.lastCreatedId = Entity.invalidId
    end
        
    self.numSentriesLeft = 0
    self.numMiniArmoriesLeft = 0
	-- self.numPhaseGatesLeft = 0
    -- self.numObservatoriesLeft = 0
    self.lastClickedPosition = nil
    
end

function CombatBuilder:OnInitialized()

    local worldModel = LookupTechData(self:GetTechId(), kTechDataModel)
    if worldModel ~= nil then
        self:SetModel(worldModel)
    end
    
    Weapon.OnInitialized(self)
    
end

function CombatBuilder:GetIsValidRecipient(recipient)

    if self:GetParent() == nil and recipient and not GetIsVortexed(recipient) and recipient:isa("Marine") then
        local welder = recipient:GetWeapon(CombatBuilder.kMapName)
        return welder == nil
    end
    
    return false
    
end

function CombatBuilder:GetViewModelName(sex, variant)
    return CombatBuilder.kViewModel[sex][variant]
end

function CombatBuilder:GetAnimationGraphName()
    return kAnimationGraph
end

function CombatBuilder:GetDeathIconIndex()
    return kDeathMessageIcon.CombatBuilder
end

function CombatBuilder:SetActiveStructure(structureNum)

    self.activeStructure = structureNum
    
end

function CombatBuilder:GetHasDropCooldown()
    return self.timeLastDrop ~= nil and self.timeLastDrop + kDropCooldown > Shared.GetTime()
end

function CombatBuilder:GetSecondaryTechId()
    return kTechId.None
end

function CombatBuilder:GetNumStructuresBuilt(techId)

    if techId == kTechId.Sentry then
        return self.numSentriesLeft
    end
	
	if techId == kTechId.WeaponCache then
        return self.numMiniArmoriesLeft
    end
	
	-- if techId == kTechId.PhaseGate then
    --     return self.numPhaseGatesLeft
    -- end

    -- if techId == kTechId.Observatory then
    --     return self.numObservatoriesLeft
    -- end

    return -1
end

function CombatBuilder:OnPrimaryAttack(player)

    if Client then

        if self.activeStructure ~= nil
        and not self.dropping
        and not self.mouseDown then
        
            self.mouseDown = true
        
			if self:PerformPrimaryAttack(player) then
				self.dropping = true
            else
                player:TriggerInvalidSound()
            end

        end
    
    end

end

function CombatBuilder:OnPrimaryAttackEnd(player)

    if not Shared.GetIsRunningPrediction() then
    
        if Client and self.dropping then
            self:OnSetActive()
        end

        self.dropping = false
        self.mouseDown = false
        
    end
    
end

function CombatBuilder:GetIsDropping()
    return self.dropping
end

function CombatBuilder:GetHUDSlot()
    return 4
end


function CombatBuilder:GetIsDroppable()
    return true
end

function CombatBuilder:Dropped(prevOwner)

    Weapon.Dropped(self, prevOwner)
    -- prevOwner:GetTeam():ClearMarineStructure(prevOwner)

    self.dropping = false
    self.mouseDown = false
    self.activeStructure = nil
    if Server then
        self.lastCreatedId = Entity.invalidId
    end
        
    self.numSentriesLeft = 0
    self.numMiniArmoriesLeft = 0
	-- self.numPhaseGatesLeft = 0
    -- self.numObservatoriesLeft = 0
    self.lastClickedPosition = nil
end


function CombatBuilder:GetHasSecondary(player)
    return true
end

function CombatBuilder:OnSecondaryAttack(player)

    if player then
        local weapon = player:GetWeaponInHUDSlot(1)
        if weapon then
            player:SetActiveWeapon(weapon:GetMapName())
        end
    end
end

function CombatBuilder:PerformPrimaryAttack(player)

    if self.activeStructure == nil then
        return false
    end 

    local success = false

    -- Ensure the current location is valid for placement.
    local coords, valid = self:GetPositionForStructure(player:GetEyePos(), player:GetViewCoords().zAxis, self:GetActiveStructure(), self.lastClickedPosition)
    local secondClick = true
    
    if LookupTechData(self:GetActiveStructure().GetDropStructureId(), kTechDataSpecifyOrientation, false) then
        secondClick = self.lastClickedPosition ~= nil
    end
    
    if secondClick then
    
        if valid then

            -- Ensure they have enough resources.
            -- local cost = GetCostForTech(self:GetActiveStructure().GetDropStructureId())
            -- if player:GetResources() >= cost then --and not self:GetHasDropCooldown() then
            local message = BuildMarineDropStructureMessage(player:GetEyePos(), player:GetViewCoords().zAxis, self.activeStructure, self.lastClickedPosition)
            Client.SendNetworkMessage("MarineBuildStructure", message, true)
            self.timeLastDrop = Shared.GetTime()
            success = true

            -- end
        
        end

        self.lastClickedPosition = nil

    else
        self.lastClickedPosition = Vector(coords.origin)
    end
    
    if not valid then
        player:TriggerInvalidSound()
    end
        
    return success
    
end

local function DropStructure(self, player, origin, direction, structureAbility, lastClickedPosition)

    -- If we have enough resources
    if Server then
    
        local coords, valid, onEntity = self:GetPositionForStructure(origin, direction, structureAbility, lastClickedPosition)
        local techId = structureAbility:GetDropStructureId()
        
        local maxStructures = -1
        
        if not LookupTechData(techId, kTechDataAllowConsumeDrop, false) then
            maxStructures = LookupTechData(techId, kTechDataMaxAmount, 0) 
        end
        
        -- local cost = LookupTechData(structureAbility:GetDropStructureId(), kTechDataCostKey, 0)
        -- local enoughRes = player:GetResources() >= cost
        
        if valid and structureAbility:IsAllowed(player) and not self:GetHasDropCooldown() then
        
            -- Create structure
            local structure = self:CreateStructure(coords, player, structureAbility)
            if structure then
            
                structure:SetOwner(player)
                InitMixin(structure, MarineStructureMixin)
				player:GetTeam():AddMarineStructure(player, structure)
                
                -- Check for space
                if structure:SpaceClearForEntity(coords.origin) then
                
                    local angles = Angles()                    
                    angles:BuildFromCoords(coords)
                    structure:SetAngles(angles)
                    
                    -- player:AddResources(-cost)
                    
                    if structureAbility:GetStoreBuildId() then
                        self.lastCreatedId = structure:GetId()
                    end
                    
                    -- self:TriggerEffects("spawn", {effecthostcoords = Coords.GetLookIn(origin, direction)} )
                    
                    if structureAbility.OnStructureCreated then
                        structureAbility:OnStructureCreated(structure, lastClickedPosition)
                    end
                    
                    self.timeLastDrop = Shared.GetTime()
                    
                    return true
                    
                else
                
                    player:TriggerInvalidSound()
                    DestroyEntity(structure)
                    
                end
                
            else
                player:TriggerInvalidSound()
            end
            
        else
        
            if not valid then
                player:TriggerInvalidSound()
            elseif not enoughRes then
                player:TriggerInvalidSound()
            end
            
        end
        
    end
    
    return true
    
end

function CombatBuilder:OnDropStructure(origin, direction, structureIndex, lastClickedPosition)

    local player = self:GetParent()
        
    if player then
    
        local structureAbility = CombatBuilder.kSupportedStructures[structureIndex]        
        if structureAbility then        
             DropStructure(self, player, origin, direction, structureAbility, lastClickedPosition)
        end
        
    end
    
end

function CombatBuilder:CreateStructure(coords, player, structureAbility, lastClickedPosition)
    local created_structure = structureAbility:CreateStructure(coords, player, lastClickedPosition)
    if created_structure then 
        return created_structure
    else
        return CreateEntity(structureAbility:GetDropMapName(), coords.origin, player:GetTeamNumber())
    end
end

local function FilterBabblersAndTwo(ent1, ent2)
    return function (test) return test == ent1 or test == ent2 or test:isa("Babbler") end
end

-- Given a gorge player's position and view angles, return a position and orientation
-- for structure. Used to preview placement via a ghost structure and then to create it.
-- Also returns bool if it's a valid position or not.
function CombatBuilder:GetPositionForStructure(startPosition, direction, structureAbility, lastClickedPosition)

    PROFILE("CombatBuilder:GetPositionForStructure")

    local validPosition = false
    local range = structureAbility.GetDropRange()
    local origin = startPosition + direction * range
    local player = self:GetParent()

    -- Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, FilterBabblersAndTwo(player, self))
    
    local displayOrigin = trace.endPoint
    
    -- If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = startPosition + direction * range
        trace = Shared.TraceRay(origin, origin - Vector(0, range, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
    end
    
    -- If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then
    
        if trace.entity == nil then
            validPosition = true
		end
        
        displayOrigin = trace.endPoint
        
    end
    
    -- Can only be built on infestation
    -- local requiresInfestation = LookupTechData(structureAbility.GetDropStructureId(), kTechDataRequiresInfestation)
    -- if requiresInfestation and not GetIsPointOnInfestation(displayOrigin) then
    
    --     if self:GetActiveStructure().OverrideInfestationCheck then
    --         validPosition = self:GetActiveStructure():OverrideInfestationCheck(trace)
    --     else
    --         validPosition = false
    --     end
        
    -- end
    
    if not structureAbility.AllowBackfacing() and trace.normal:DotProduct(GetNormalizedVector(startPosition - trace.endPoint)) < 0 then
        validPosition = false
    end    
    
    -- Don't allow dropped structures to go too close to techpoints and resource nozzles
    if GetPointBlocksAttachEntities(displayOrigin) then
        validPosition = false
    end
    
    if not structureAbility:GetIsPositionValid(displayOrigin, player, trace.normal, lastClickedPosition, trace.entity) then
        validPosition = false
    end    
    
    -- Don't allow placing above or below us and don't draw either
    local structureFacing = Vector(direction)
    
    if math.abs(Math.DotProduct(trace.normal, structureFacing)) > 0.9 then
        structureFacing = trace.normal:GetPerpendicular()
    end
    
    -- Coords.GetLookIn will prioritize the direction when constructing the coords,
    -- so make sure the facing direction is perpendicular to the normal so we get
    -- the correct y-axis.
    local perp = Math.CrossProduct( trace.normal, structureFacing )
    structureFacing = Math.CrossProduct( perp, trace.normal )
    
    local coords = Coords.GetLookIn( displayOrigin, structureFacing, trace.normal )
    
    if structureAbility.ModifyCoords then
        structureAbility:ModifyCoords(coords, lastClickedPosition)
    end
    
    -- Shared.Message(tostring(validPosition))
    return coords, validPosition, trace.entity

end

function CombatBuilder:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
	
	-- Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)

    self.previousWeaponMapName = previousWeaponMapName
    self.dropping = false
    self.activeStructure = nil

end


function CombatBuilder:OnUpdateAnimationInput(modelMixin)

    PROFILE("CombatBuilder:OnUpdateAnimationInput")
	
	local parent = self:GetParent()
    local sprinting = parent ~= nil and HasMixin(parent, "Sprint") and parent:GetIsSprinting()
    local activity = (self:GetActiveStructure() ~= nil and not sprinting) and "primary" or "none"
    
    modelMixin:SetAnimationInput("activity", activity)
    modelMixin:SetAnimationInput("welder", false)
    
end

function CombatBuilder:UpdateViewModelPoseParameters(viewModel)
    viewModel:SetPoseParam("welder", 0)    
end

function CombatBuilder:OnUpdatePoseParameters(viewModel)

    PROFILE("Welder:OnUpdatePoseParameters")
    self:SetPoseParam("welder", 0)
    
end

-- for marine third person model pose, "builder" fits perfectly for this.
function CombatBuilder:OverrideWeaponName()
    return "builder"
end

function CombatBuilder:ProcessMoveOnWeapon(input)

    -- Show ghost if we're able to create structure, and if menu is not visible
    local player = self:GetParent()
    if player then
    
        if Server then

            -- This is where you limit the number of entities that are alive
			local team = player:GetTeam()
            local numAllowedSentries = LookupTechData(kTechId.Sentry, kTechDataMaxAmount, -1) 
            local numAllowedMiniArmories = LookupTechData(kTechId.WeaponCache, kTechDataMaxAmount, -1) 
            -- local numAllowedPhaseGates = LookupTechData(kTechId.PhaseGate, kTechDataMaxAmount, -1) 
            -- local numAllowedObservatories = LookupTechData(kTechId.Observatory, kTechDataMaxAmount, -1) 

            if numAllowedSentries >= 0 then     
                self.numSentriesLeft = team:GetNumDroppedMarineStructures(player, kTechId.Sentry)           
            end
   
            if numAllowedMiniArmories >= 0 then     
                self.numMiniArmoriesLeft = team:GetNumDroppedMarineStructures(player, kTechId.WeaponCache)           
            end
            
            -- if numAllowedPhaseGates >= 0 then     
            --     self.numPhaseGatesLeft = team:GetNumDroppedMarineStructures(player, kTechId.PhaseGate)           
            -- end
            
            -- if numAllowedObservatories >= 0 then     
            --     self.numObservatoriesLeft = team:GetNumDroppedMarineStructures(player, kTechId.Observatory)           
            -- end
            
        end
        
    end    
    
end

function CombatBuilder:GetShowGhostModel()
    return self.activeStructure ~= nil and not self:GetHasDropCooldown()
end

function CombatBuilder:GetGhostModelCoords()
    return self.ghostCoords
end   

function CombatBuilder:GetIsPlacementValid()
    return self.placementValid
end

function CombatBuilder:GetGhostModelTechId()

    if self.activeStructure == nil then
        return nil
    else
        return self:GetActiveStructure():GetDropStructureId()
    end

end

if Client then

    function CombatBuilder:GetUIDisplaySettings()
        return { xSize = 512, ySize = 512, script = "lua/GUIWelderDisplay.lua", textureNameOverride = "welder" }
    end

    function CombatBuilder:OnProcessIntermediate(input)

        local player = self:GetParent()
        local viewDirection = player:GetViewCoords().zAxis

        if player and self.activeStructure then

            self.ghostCoords, self.placementValid = self:GetPositionForStructure(player:GetEyePos(), viewDirection, self:GetActiveStructure(), self.lastClickedPosition)
            
            -- if player:GetResources() < LookupTechData(self:GetActiveStructure():GetDropStructureId(), kTechDataCostKey) then
                -- self.placementValid = false
            -- end
        
        end
        
    end
    
    function CombatBuilder:CreateBuildMenu()
    
        if not self.buildMenu then        
            self.buildMenu = GetGUIManager():CreateGUIScript("Combat/GUIMarineBuildMenu")            
        end
        
    end
    
    function CombatBuilder:DestroyBuildMenu()

        if self.buildMenu ~= nil then
        
            GetGUIManager():DestroyGUIScript(self.buildMenu)
            self.buildMenu = nil
        
        end
    
    end

    function CombatBuilder:OnDestroy()
    
        self:DestroyBuildMenu()        
        Weapon.OnDestroy(self)
        
    end
    
    function CombatBuilder:OnKillClient()
        self.menuActive = false
    end
    
    function CombatBuilder:OnDrawClient()
    
        Weapon.OnDrawClient(self)
        
        -- We need this here in case we switch to it via Prev/NextWeapon keys
        
        -- Do not show menu for other players or local spectators.
        local player = self:GetParent()
        if player and player:GetIsLocalPlayer() and self:GetActiveStructure() == nil and Client.GetIsControllingPlayer() then
            self.menuActive = true
        end
        
    end
    
    local function UpdateGUI(self, player)

        local localPlayer = Client.GetLocalPlayer()
        if localPlayer == player then
            self:CreateBuildMenu()
        end
 
        if self.buildMenu then
            self.buildMenu:SetIsVisible(player and localPlayer == player and player:isa("Marine") and self.menuActive)
        end
    
    end

    function CombatBuilder:OnHolsterClient()
    
        self.menuActive = false
        Weapon.OnHolsterClient(self)
        
    end
    
    function CombatBuilder:OnSetActive()
    end
    
    function CombatBuilder:OverrideInput(input)
    
        if self.buildMenu then

            -- Build menu is up, let it handle input
            if self.buildMenu:GetIsVisible() then
            
                local selected = false
                input, selected = self.buildMenu:OverrideInput(input)
                self.menuActive = not selected
                
            else

                -- If player wants to switch to this, open build menu immediately
                local weaponSwitchCommands = { Move.Weapon1, Move.Weapon2, Move.Weapon3, Move.Weapon4, Move.Weapon5 }
                local thisCommand = weaponSwitchCommands[ self:GetHUDSlot() ]

                if bit.band( input.commands, thisCommand ) ~= 0 then
                    self.menuActive = true
                end

            end
            
        end    
        
        return input
        
    end
    
    function CombatBuilder:OnUpdateRender()
        UpdateGUI(self, self:GetParent())    
    end
    
end

Shared.LinkClassToMap("CombatBuilder", CombatBuilder.kMapName, networkVars)
