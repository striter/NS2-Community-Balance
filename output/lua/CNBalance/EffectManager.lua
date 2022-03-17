-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\EffectManager.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--                  Trevor Harris (trevor@naturalselection2.com)
--
-- Play sounds, cinematics or animations through a simple trigger. Decouples script from
-- artist, sound designer, etc.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/EffectsGlobals.lua")
Script.Load("lua/SharedDecal.lua")

class 'EffectManager'

---------------------
-- LOCAL FUNCTIONS --
---------------------

local function PrecacheEffectComponent(component)
    
    local assets
    if component.assetVariants then
        assets = component.assetVariants
    else
        assets = {component.asset}
    end
    
    for i=1, #assets do
        if assets[i] and assets[i] ~= "" then
            if component.assetType == kDecalType then
                Shared.RegisterDecalMaterial(assets[i])
            end
            
            PrecacheAsset(assets[i])
        end
    end
    
end

-- traverse the existing cache, following/creating table entries for filters until we've run through all our
-- provided table params, then add the list of effect component indices to the array part of the table.
local function CacheResultsOfEffect(indices, cache, effectName, tableParams)
    
    local cacheTable = cache
    cacheTable[effectName] = cacheTable[effectName] or {}
    cacheTable = cacheTable[effectName]
    
    for filterIndex = 1, #kEffectFilters do
        
        local filter = kEffectFilters[filterIndex]
        if tableParams[filter] then
            
            cacheTable[tableParams[filter]] = cacheTable[tableParams[filter]] or {}
            cacheTable = cacheTable[tableParams[filter]]
            
        end
        
    end
    
    cacheTable.cachedIndices = indices
    
end

-- "Caching" an effect simply means we store the indices of the effect components that are triggered whenever
-- the effect is triggered with these exact parameters.  We find these cached indices by traversing a tree
-- created based on the table parameters supplied.
local function GetCachedComponentIndices(tableParams, cache)
    
    if not cache then
        return nil
    end
    
    if not tableParams then
        return nil
    end
    
    -- To cache effects with their various filter settings
    local cacheTable = cache
    
    -- loop through each parameter filter type, checking to see if that type of parameter is present, rather than the
    -- more direct, but MUCH less efficient (non-jit-able) pairs() function to directly get each supplied parameter.
    for filterIndex = 1, #kEffectFilters do
        
        local filter = kEffectFilters[filterIndex]
        
        if tableParams[filter] then
            
            -- we progressively refine our search by jumping to the next available cached parameter supplied by the
            -- tableParams
            cacheTable = cacheTable[tableParams[filter]]
            
            if not cacheTable then
                -- since this cache level doesn't exist, we know this effect has never been triggered with these
                -- specific parameters before.
                return nil
            end
            
        end
        
    end
    
    return cacheTable.cachedIndices
    
end

-- Assumes triggering entity is either a player, or a weapon who's owner is a player
local function GetPlayerFromTriggeringEntity(triggeringEntity)

    if triggeringEntity then
        
        if triggeringEntity:isa("Player") then
            return triggeringEntity
        else
            local parent = triggeringEntity:GetParent()
            if parent then
                return parent
            end
        end
        
    end

    return nil
    
end

local function Trigger_Cinematic(component, asset, tableParams, triggeringEntity)
    
    local coords = tableParams[kEffectHostCoords]
    local effectEntity = Shared.CreateEffect(nil, asset, nil, coords)
    CopyRelevancyMask(triggeringEntity, effectEntity)
    
end

local function Trigger_WeaponCinematic(component, asset, tableParams, triggeringEntity)
    
    if Server then
        
        local player = GetPlayerFromTriggeringEntity(triggeringEntity)
        local inWorldSpace = component[kEffectParamWorldSpace]
        local attachPoint = component[kEffectParamAttachPoint]
        if attachPoint and player then
            local effectEntity = Shared.CreateAttachedEffect(player, asset, triggeringEntity, Coords.GetIdentity(), attachPoint, false, inWorldSpace == true)
            CopyRelevancyMask(triggeringEntity, effectEntity)
        end
        
    end
    
end

local function Trigger_ViewModelCinematic(component, asset, tableParams, triggeringEntity)
    
    if Client then
        
        local player = GetPlayerFromTriggeringEntity(triggeringEntity)
        local inWorldSpace = component[kEffectParamWorldSpace]
        local attachPoint = component[kEffectParamAttachPoint]
        
        if player then
            
            local viewModel = player:GetViewModelEntity()
            if viewModel and not player:GetIsThirdPerson() then
                
                local effectEntity = Shared.CreateAttachedEffect(player, asset, viewModel, Coords.GetIdentity(), attachPoint or "", true, inWorldSpace == true)
                CopyRelevancyMask(triggeringEntity, effectEntity)
                
            end
            
        end
        
    end
    
end

local function Trigger_PlayerCinematic(component, asset, tableParams, triggeringEntity)
    
    local coords = tableParams[kEffectHostCoords]
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    local effectEntity = Shared.CreateEffect(player, asset, nil, coords)
    CopyRelevancyMask(triggeringEntity, effectEntity)
    
end

local function Trigger_ParentedCinematic(component, asset, tableParams, triggeringEntity)
    
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    local inWorldSpace = component[kEffectParamWorldSpace]
    local attachPoint = component[kEffectParamAttachPoint]
    local effectEntity
    if attachPoint then
        effectEntity = Shared.CreateAttachedEffect(player, asset, triggeringEntity, Coords.GetIdentity(), attachPoint, false, inWorldSpace == true)
    else
        effectEntity = Shared.CreateEffect(player, asset, triggeringEntity, Coords.GetIdentity())
    end
    CopyRelevancyMask(triggeringEntity, effectEntity)
    
end

local function Trigger_LoopingCinematic(component, asset, tableParams, triggeringEntity)
    
    if triggeringEntity and triggeringEntity.AttachEffect then
        
        local coords = tableParams[kEffectHostCoords]
        triggeringEntity:AttachEffect(asset, coords, Cinematic.Repeat_Endless)            
        
    end
    
end

local function Trigger_StopCinematic(component, asset, tableParams, triggeringEntity)
    
    if triggeringEntity and triggeringEntity.RemoveEffect then
        triggeringEntity:RemoveEffect(FilterCinematicName(asset))
    end
    
end

local function Trigger_StopViewModelCinematic(component, asset, tableParams, triggeringEntity)
    
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    if player then
        
        local viewModel = player:GetViewModelEntity()
        if viewModel and viewModel.RemoveEffect then
            viewModel:RemoveEffect(asset)
        end
        
    end
    
end

local function Trigger_Sound(component, asset, tableParams, triggeringEntity)
    
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    local inWorldSpace = component[kEffectParamWorldSpace]
    local volume = ConditionalValue(tableParams[kEffectParamVolume], tableParams[kEffectParamVolume], 1.0)
    local coords = tableParams[kEffectHostCoords]  
    
    local soundEffectEntity
    if player and inWorldSpace ~= true then
        soundEffectEntity = StartSoundEffectOnEntity(asset, player, volume)
    else
        soundEffectEntity = StartSoundEffectAtOrigin(asset, coords.origin, volume)
    end
    CopyRelevancyMask(triggeringEntity, soundEffectEntity)
    
end

local function Trigger_ParentedSound(component, asset, tableParams, triggeringEntity)
    
    local volume = ConditionalValue(tableParams[kEffectParamVolume], tableParams[kEffectParamVolume], 1.0)
    local soundEffectEntity = StartSoundEffectOnEntity(asset, triggeringEntity, volume, nil)
    CopyRelevancyMask(triggeringEntity, soundEffectEntity)
    
end

local function Trigger_PrivateSound(component, asset, tableParams, triggeringEntity)
    
    local volume = ConditionalValue(tableParams[kEffectParamVolume], tableParams[kEffectParamVolume], 1.0)
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    local soundEffectEntity = StartSoundEffectForPlayer(asset, player, volume)
    CopyRelevancyMask(triggeringEntity, soundEffectEntity)
    
end

local function Trigger_StopSound(component, asset, tableParams, triggeringEntity)
    
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    
    Shared.StopSound(player, asset, triggeringEntity)
    Shared.StopSound(player, asset)
    
    if triggeringEntity then
        
        for i= triggeringEntity:GetNumChildren() - 1, 0, -1 do
            local child = triggeringEntity:GetChildAtIndex(i)
            if child:isa("SoundEffect") and child:GetParent() == triggeringEntity and child:GetSoundName() == asset then
                child:Stop()
            end
        end
        
    end
    
end

local function Trigger_PlayerSound(component, asset, tableParams, triggeringEntity)
    
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    local volume = ConditionalValue(tableParams[kEffectParamVolume], tableParams[kEffectParamVolume], 1.0)
    local soundEffectEntity = StartSoundEffectOnEntity(asset, player, volume, player)
    CopyRelevancyMask(triggeringEntity, soundEffectEntity)
    
end

local function Trigger_StopEffects(component, asset, tableParams, triggeringEntity)
    
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    Shared.StopSound(player, "", triggeringEntity)
    
end

local function Trigger_Decal(component, asset, tableParams, triggeringEntity)
    
    local scale = component[kEffectParamScale]
    if type(scale) ~= "number" then
        scale = 1.0
    end
    
    Shared.CreateTimeLimitedDecal(asset, tableParams[kEffectHostCoords], scale)
    
end

local kTriggerFunctions = 
{
    -- Cinematics
    [kCinematicType]                = Trigger_Cinematic,
    [kWeaponCinematicType]          = Trigger_WeaponCinematic,
    [kViewModelCinematicType]       = Trigger_ViewModelCinematic,
    [kPlayerCinematicType]          = Trigger_PlayerCinematic,
    [kParentedCinematicType]        = Trigger_ParentedCinematic,
    [kLoopingCinematicType]         = Trigger_LoopingCinematic,
    [kStopCinematicType]            = Trigger_StopCinematic,
    [kStopViewModelCinematicType]   = Trigger_StopViewModelCinematic,
    
    -- Sounds
    [kSoundType]                    = Trigger_Sound,
    [kParentedSoundType]            = Trigger_ParentedSound,
    [kPrivateSoundType]             = Trigger_PrivateSound,
    [kStopSoundType]                = Trigger_StopSound,
    [kPlayerSoundType]              = Trigger_PlayerSound,
    
    -- Misc
    [kStopEffectsType]              = Trigger_StopEffects,
    [kDecalType]                    = Trigger_Decal,
}

local kTriggerFunctionsEmptyInputAllowed = 
{
    [kStopSoundType]                = true,
    [kStopEffectsType]              = true,
}

local function ChooseAsset(component)
    
    if not component.assetVariants then
        return component.asset
    end
    
    if #component.assetVariants == 1 then
        return component.assetVariants[1]
    end
    
    local r = math.random()
    for i=1, #component.weights do
        if r <= component.weights[i] then
            return component.assetVariants[i]
        end
    end
    
    assert(false)
    
end

-- Trigger effect component immediately (filters have already been validated)
local function TriggerEffectComponent(component, tableParams, triggeringEntity)
    
    local asset = ChooseAsset(component)
    if not asset or (asset == "" and not kTriggerFunctionsEmptyInputAllowed[component.assetType]) then
        return
    end
    
    local effectTriggerFunction = kTriggerFunctions[component.assetType]
    effectTriggerFunction(component, asset, tableParams, triggeringEntity)
    
end

local function ComponentFilter_Doer(tableParams, filterValue, triggeringEntity)
    
    local triggerFilterValue = tableParams[kEffectFilterDoerName]
    if triggerFilterValue == nil or not classisa(triggerFilterValue, filterValue) then
        return false
    end
    
    return true
    
end

local function ComponentFilter_ClassName(tableParams, filterValue, triggeringEntity)
    
    if not triggeringEntity then
        return false
    end
    
    local triggerClassName = tableParams[kEffectFilterClassName] or triggeringEntity:GetClassName()
    if classisa(triggerClassName, filterValue) then
        return true
    end
    
    if triggeringEntity:isa("ViewModel") then
        local weapon = triggeringEntity:GetWeapon()
        if weapon and weapon:isa(filterValue) then 
            return true
        end
    end
    
    return false
    
end

local kFilterFunctions = 
{
    [kEffectFilterDoerName] = ComponentFilter_Doer,
    [kEffectFilterClassName] = ComponentFilter_ClassName,
}
-- returns two parameters: result and done.  Result is true if the the effect is applicable to the
-- provided parameters/entity, false if not.  "done" is only applicable if "result" is true.  Done
-- signals we should stop processing effects.
local function GetIsEffectComponentApplicable(component, tableParams, triggeringEntity)
    
    if not tableParams then
        return false, nil
    end
    
    for filterIndex=1, #kEffectFilters do
        
        local filter = kEffectFilters[filterIndex]
        local filterValue = component[filter]
        if filterValue ~= nil then
            local filterFunction = kFilterFunctions[filter]
            if filterFunction then
                if not filterFunction(tableParams, filterValue, triggeringEntity) then
                    return false, nil
                end
            else
                if filterValue ~= tableParams[filter] then
                    return false, nil
                end
            end
            
        end
        
    end
    
    return true, (component.done == true)
    
end

-- Called when we have a cached version of the effect.
local function TriggerCachedEffects(effect, cachedIndices, tableParams, triggeringEntity)
    
    for i=1, #cachedIndices do -- for each cached effects block...
        for j=1, #cachedIndices[i] do -- for each cached effect component within the block...
            TriggerEffectComponent(effect[i][cachedIndices[i][j]], tableParams, triggeringEntity)
        end
    end
    
end

-- Called when we do not have a cached version of the effect.
local function TriggerEffectsInternal(data, effectName, tableParams, triggeringEntity, cache)
    
    -- Cache the effect
    local effect = data[effectName]
    
    local cachedBlockIndices = {}
    for i=1, #effect do -- for each block of the effect...
        cachedBlockIndices[i] = {}
        local cachedIndices = cachedBlockIndices[i]
        for j=1, #effect[i] do -- for each component of the block...
            local result, done = GetIsEffectComponentApplicable(effect[i][j], tableParams, triggeringEntity)
            if result then
                cachedIndices[#cachedIndices+1] = j
            end
            
            if done or j == #effect[i] then
                break
            end
        end
    end
    
    CacheResultsOfEffect(cachedBlockIndices, cache, effectName, tableParams)
    
    -- Trigger it like it was cached... it is now! :)
    TriggerCachedEffects(effect, cachedBlockIndices, tableParams, triggeringEntity)
    
end

local function BakeAssetType(component)
    
    local assetType
    for i=1, #kEffectTypes do
        if component[kEffectTypes[i]] then
            assetType = kEffectTypes[i]
            break
        end
    end
    
    if assetType then
        component.assetType = assetType
        component.asset = component[assetType]
        component[assetType] = nil
    else
        Log("ERROR!  Invalid/no effect type specified for effect!")
        Log("%s", component)
    end
    
end

local function PrecalculateWeightSums(component)
    
    local asset = component.asset
    if type(asset) == "table" then
        local sum = 0.0
        local weights = {}
        local assetVariants = {}
        for i=1, #asset do
            sum = sum + asset[i][1]
            weights[i] = sum
            assetVariants[i] = asset[i][2]
        end
        for i=1, #weights do
            weights[i] = weights[i] / sum
        end
        component.weights = weights
        component.assetVariants = assetVariants
    end
    
end

local function GetUsesTemplateName(component)
    
    if component.assetVariants then
        for i=1, #component.assetVariants do
            if string.find(component.assetVariants[i], "%%") then
                return true
            end
        end
    else
        if string.find(component.asset, "%%") then
            return true
        end
    end
    
    return false
    
end

local function GetAssetIfExists(asset)
    
    if StringStartsWith(asset, "sound") or GetFileExists(asset) then
        return asset
    end
    
    return ""
    
end

local function FillTemplate(component, surface)
    
    if component.assetVariants then
        for i=1, #component.assetVariants do
            component.assetVariants[i] = GetAssetIfExists(string.format(component.assetVariants[i], surface))
        end
    else
        component.asset = GetAssetIfExists(string.format(component.asset, surface))
    end
    
    component[kEffectSurface] = surface
    
end

local function CreateComponentFromTemplate(component)
    
    -- if the artist specified a surface, then we only have one value to fill in for the template.
    if component[kEffectSurface] then
        FillTemplate(component, component[kEffectSurface])
        return { component }
    end
    
    -- if the asset's don't use templates at all, just return what we were given, as a 1 element table.
    if not GetUsesTemplateName(component) then
        return {component}
    end
    
    -- create copies of the component for each possible surface that could be hit.
    local componentVariants = {}
    for i=1, #kHitEffectSurface do
        local surface = kHitEffectSurface[i]
        local newComponent = table.copyDict(component)
        FillTemplate(newComponent, surface)
        componentVariants[#componentVariants+1] = newComponent
    end
    
    return componentVariants
    
end

-- Add the component to the effect data if and only if it has at least one asset that exists.
-- No use adding the effect component if there's nothing for it to do!
-- There is one exception, however.  If the asset is blank, BUT "done" is set to true, then
-- the intent here is to stop it from executing anything afterwards.
local function AddComponentToTableIfExists(tbl, component)
    
    if component.assetVariants then
        local allBlank = true
        for i=1, #component.assetVariants do
            if component.assetVariants[i] ~= "" or component.done == true then
                allBlank = false
                break
            end
        end
        if not allBlank then
            tbl[#tbl + 1] = component
        end
    else
        if component.asset ~= "" or component.done == true then
            tbl[#tbl + 1] = component
        end
    end
    
end

----------------------
-- PUBLIC FUNCTIONS --
----------------------
function GetEffectManager()
    
    if not gEffectManager then
        gEffectManager = EffectManager()
        gEffectManager:Initialize()
    end
    
    return gEffectManager
    
end

function EffectManager:Initialize()
    
    self.data = {}
    self.effectCache = {}
    
end

function EffectManager:AddEffectData(name, data)
    
    for effectName, effect in pairs(data) do
        
        self.data[effectName] = self.data[effectName] or {}
        
        for _, effectGrouping in pairs(effect) do
            
            local effectBlockTable = self.data[effectName]
            effectBlockTable[#effectBlockTable + 1] = {}
            local tbl = effectBlockTable[#effectBlockTable]
            
            for i=1, #effectGrouping do
                
                local component = effectGrouping[i]
                
                -- precalculate stuff that would otherwise be a bit expensive/tedious to figure out on the fly.
                
                -- figure out what type of asset this is.  Move it to a field called "asset" and provide a field
                -- "asset type".  More programmer friendly this way.  Also nils out the original.
                BakeAssetType(component)
                
                -- if the asset is a random variant, precalculate the weight sums.  Creates two fields, "weights",
                -- and "assetVariants".  Weights is not actually weights, but the sum of the weight and the weights
                -- before it, so when looking for a random variant, we calculate one random number between 0 and 1,
                -- and loop through weights until we find one that is > the amount generated.
                PrecalculateWeightSums(component)
                
                -- if the component uses the surface-type template (%s) in any of the assets, we create components
                -- for all types of surfaces, that way we avoid doing any string operations later (comparisons are
                -- fine because lua hashes strings).
                local newComponents = CreateComponentFromTemplate(component)
                
                for i=1, #newComponents do
                    AddComponentToTableIfExists(tbl, newComponents[i])
                end
                
            end
            
        end
        
    end
    
end

function EffectManager:PrecacheEffects()
    
    for _, effect in pairs(self.data) do
        
        for i=1, #effect do -- for each effect block do...
            for j=1, #effect[i] do -- for each component of the effect block...
                PrecacheEffectComponent(effect[i][j])
            end
        end
        
    end
    
end

local updateThrottle = 0.0
function EffectManager:OnUpdate(delta)
    
    updateThrottle = updateThrottle - delta
    if updateThrottle <= 0 then
        updateThrottle = 10.0
        Log("WARNING:  EffectManager:OnUpdate() is deprecated! (throttling this message every 10 seconds).")
        Log("%s", debug.traceback())
    end
    
end

local kBlockedWaypointEffects = set
{
    "complete_order",
    "complete_autoorder"
}

function EffectManager:TriggerEffects(effectName, tableParams, triggeringEntity)
    
    if Shared.GetIsRunningPrediction() then
        return
    end

    if Client then

    if (Client.kWayPointsEnabled == false and kBlockedWaypointEffects[effectName]) or
       (Client.kHintsEnabled == false and effectName == "complete_autoorder") then
            return
        end
    end
    
    -- Ensure the effect exists.  If it doesn't, return without a fuss.  Many effects triggerings are called for
    -- without knowing if there's actually an effect there to play (eg. every weapon calls [name]_attack_end when
    -- destroyed, but not every weapon has an effect associated with that name).
    if not self.data[effectName] then
        return
    end
    
    local cachedComponentIndices = GetCachedComponentIndices(tableParams, self.effectCache[effectName])
    if cachedComponentIndices then
        TriggerCachedEffects(self.data[effectName], cachedComponentIndices, tableParams, triggeringEntity)
        return
    end
    
    TriggerEffectsInternal(self.data, effectName, tableParams, triggeringEntity, self.effectCache)
    
end


