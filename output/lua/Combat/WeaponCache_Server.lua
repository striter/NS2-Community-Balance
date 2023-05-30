local function OnDeploy(self)

    self.deployed = true
    return false
    
end

local kDeployTime = 3

function WeaponCache:OnConstructionComplete()
    self:AddTimedCallback(OnDeploy, kDeployTime)
end

-- west/east = x/-x
-- north/south = -z/z

local indexToUseOrigin =
{
    -- West
    Vector(WeaponCache.kResupplyUseRange, 0, 0), 
    -- North
    Vector(0, 0, -WeaponCache.kResupplyUseRange),
    -- South
    Vector(0, 0, WeaponCache.kResupplyUseRange),
    -- East
    Vector(-WeaponCache.kResupplyUseRange, 0, 0)
}

function WeaponCache:GetTimeToResupplyPlayer(player)

    assert(player ~= nil)
    
    local timeResupplied = self.resuppliedPlayers[player:GetId()]
    
    if timeResupplied ~= nil then
    
        -- Make sure we haven't done this recently    
        if Shared.GetTime() < (timeResupplied + WeaponCache.kResupplyInterval) then
            return false
        end
        
    end
    
    return true
    
end

function WeaponCache:GetShouldResupplyPlayer(player)

    if not player:GetIsAlive() then
        return false
    end
    
    local stunned = HasMixin(player, "Stun") and player:GetIsStunned()
    
    if stunned then
        return false
    end
    
    local inNeed = false
    
    -- Don't resupply when already full
    if (player:GetHealth() < player:GetMaxHealth()) then
        inNeed = true
    else

        -- Do any weapons need ammo?
        for i = 1, player:GetNumChildren() do
            local child = player:GetChildAtIndex(i - 1)
            if child:isa("ClipWeapon") and child:GetNeedsAmmo(false) then
                inNeed = true
                break
            end
        end
        
    end
    
    if inNeed then
    
        -- Check player facing so players can't fight while getting benefits of armory
        local viewVec = player:GetViewAngles():GetCoords().zAxis

        local toArmoryVec = self:GetOrigin() - player:GetOrigin()
        
        if(GetNormalizedVector(viewVec):DotProduct(GetNormalizedVector(toArmoryVec)) > .75) then
        
            if self:GetTimeToResupplyPlayer(player) then
        
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

function WeaponCache:ResupplyPlayer(player)
    
    local resuppliedPlayer = false
    
    -- Heal player first
    if (player:GetHealth() < player:GetMaxHealth()) then

        -- third param true = ignore armor
        player:AddHealth(WeaponCache.kHealAmount, false, true)

        self:TriggerEffects("armory_health", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        resuppliedPlayer = true
        --[[
        if HasMixin(player, "ParasiteAble") and player:GetIsParasited() then
        
            player:RemoveParasite()
            
        end
        --]]
        
        if player:isa("Marine") and player.poisoned then
        
            player.poisoned = false
            
        end
        
    end

    -- Give ammo to all their weapons, one clip at a time, starting from primary
    local weapons = player:GetHUDOrderedWeaponList()
    
    for _, weapon in ipairs(weapons) do
    
        if weapon:isa("ClipWeapon") then
        
            if weapon:GiveAmmo(WeaponCache.kRefillAmount, false) then
            
                self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
                
                resuppliedPlayer = true
                
                break
                
            end 
                   
        end
        
    end
        
    if resuppliedPlayer then
    
        -- Insert/update entry in table
        self.resuppliedPlayers[player:GetId()] = Shared.GetTime()
        
        -- Play effect
        --self:PlayArmoryScan(player:GetId())

    end

end
function WeaponCache:ResupplyPlayers()

    local playersInRange = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), WeaponCache.kResupplyUseRange)
    for index, player in ipairs(playersInRange) do
    
        if self:GetShouldResupplyPlayer(player) then
            self:ResupplyPlayer(player)
        end
            
    end

end

function WeaponCache:UpdateResearch()


    -- local researchId = self:GetResearchingId()

    -- if researchId == kTechId.AdvancedArmoryUpgrade then
    
    --     local techTree = self:GetTeam():GetTechTree()    
    --     local researchNode = techTree:GetTechNode(kTechId.AdvancedArmory)    
    --     researchNode:SetResearchProgress(self.researchProgress)
    --     techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress)) 
        
    -- end


end

local function AddChildModel(self)

    scriptActor:SetParent(self)
    scriptActor:SetAttachPoint(WeaponCache.kAttachPoint)
    
    return scriptActor
    
end

function WeaponCache:OnResearch(researchId)

    if researchId == kTechId.AdvancedArmoryUpgrade then

        -- Create visual add-on
        local advancedArmoryModule = AddChildModel(self)
        
    end
    
end

function WeaponCache:OnResearchCancel(researchId)

    if researchId == kTechId.AdvancedArmoryUpgrade then
    
        local team = self:GetTeam()
        
        if team then
        
            local techTree = team:GetTechTree()
            local researchNode = techTree:GetTechNode(kTechId.AdvancedArmory)
            if researchNode then
            
                researchNode:ClearResearching()
                techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", 0))   
         
            end
            
            for i = 0, self:GetNumChildren() - 1 do
            
                local child = self:GetChildAtIndex(i)
                if child:isa("ArmoryAddon") then
                    DestroyEntity(child)
                    break
                end
                
            end  

        end  
    
    end

end

-- Called when research or upgrade complete
function WeaponCache:OnResearchComplete(researchId)

    if researchId == kTechId.AdvancedArmoryUpgrade then
    
        self:SetTechId(kTechId.AdvancedArmory)
        
        local techTree = self:GetTeam():GetTechTree()
        local researchNode = techTree:GetTechNode(kTechId.AdvancedWeaponry)
        
        if researchNode then     
   
            researchNode:SetResearchProgress(1.0)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress))
            researchNode:SetResearched(true)
            techTree:QueueOnResearchComplete(kTechId.AdvancedWeaponry, self)
            
        end
        
    end
    
end

function WeaponCache:UpdateLoggedIn()

    local players = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 2 * WeaponCache.kResupplyUseRange)
    local armoryCoords = self:GetAngles():GetCoords()
    
    for i = 1, 4 do
    
        local newState = false
        
       -- if GetIsUnitActive(self) then <- UnitActive checks for power. We want armory to work without power!
        if GetIsUnitActive(self) then
            local worldUseOrigin = self:GetModelOrigin() + armoryCoords:TransformVector(indexToUseOrigin[i])
        
            for playerIndex, player in ipairs(players) do
            
                -- See if valid player is nearby
                local isPlayerVortexed = HasMixin(player, "VortexAble") and player:GetIsVortexed()
                local isPlayerDevoured = player:isa("DevouredPlayer")

                if not isPlayerVortexed and not isPlayerDevoured and player:GetIsAlive() and (player:GetModelOrigin() - worldUseOrigin):GetLength() < WeaponCache.kResupplyUseRange then
                
                    newState = true
                    break
                    
                end
                
            end
            
        end
        
        if newState ~= self.loggedInArray[i] then
        
            if newState then
                self:TriggerEffects("armory_open")
            else
                self:TriggerEffects("armory_close")
            end
            
            self.loggedInArray[i] = newState
            
        end
        
    end
    
    -- Copy data to network variables (arrays not supported)    
    self.loggedInWest = self.loggedInArray[1]
    self.loggedInNorth = self.loggedInArray[2]
    self.loggedInSouth = self.loggedInArray[3]
    self.loggedInEast = self.loggedInArray[4]

end

