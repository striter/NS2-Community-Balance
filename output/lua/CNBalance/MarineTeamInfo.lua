-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. ========
--
-- lua/MarineTeamInfo.lua
--
-- MarineTeamInfo is used to sync information about a team to clients.
-- Only marine team players (and spectators) will receive the information about number of infantry
-- portals.
--
-- Created by Trevor Harris (trevor@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/TeamInfo.lua")

class "MarineTeamInfo" (TeamInfo)

MarineTeamInfo.kMapName = "MarineTeamInfo"

-- waaaaay more than can be reasonably expected in a normal game.
kMarineTeamInfoMaxInfantryPortalCount = 10

local userTrackerNetVarDef = string.format("integer (0 to %d)", kMaxPlayers - 1)
local networkVars =
{
    numInfantryPortals = string.format("integer (0 to %d)", kMarineTeamInfoMaxInfantryPortalCount),
}

local kTrackedMarineGadgets =
{
    Pistol.kMapName,
    Rifle.kMapName,
    Axe.kMapName,
    Welder.kMapName,
    Shotgun.kMapName,
    GrenadeLauncher.kMapName,
    Flamethrower.kMapName,
    HeavyMachineGun.kMapName,
    GasGrenadeThrower.kMapName,
    ClusterGrenadeThrower.kMapName,
    PulseGrenadeThrower.kMapName,
    LayMines.kMapName,
    Jetpack.kMapName,
    
-----------
    Knife.kMapName,
    Revolver.kMapName,
    SubMachineGun.kMapName,
    LightMachineGun.kMapName,
    Cannon.kMapName,
    CombatBuilder.kMapName,
---------
}

local kTrackedExoLayouts = IterableDict()
kTrackedExoLayouts[string.format("%s+%s", Minigun.kMapName, Minigun.kMapName)] = 1
kTrackedExoLayouts[string.format("%s+%s", Railgun.kMapName, Railgun.kMapName)] = 1

-- Add network variables for the user tracking stuff. (Marine weapons, exo layouts, etc)

do
    for i = 1, #kTrackedMarineGadgets do
        networkVars[TeamInfo_GetUserTrackerNetvarName(kTrackedMarineGadgets[i])] = userTrackerNetVarDef
    end

    for k, _ in pairs(kTrackedExoLayouts) do

        local netvarName = TeamInfo_GetUserTrackerNetvarName(k)
        networkVars[netvarName] = userTrackerNetVarDef
    end
end

function MarineTeamInfo:OnCreate()
    
    TeamInfo.OnCreate(self)
    
    self.numInfantryPortals = 0
    
end

if Client then
    
    function MarineTeamInfo:OnInitialized()
        
        TeamInfo.OnInitialized(self)
        
        -- Notify GUI system when the marine team's infantry portal count changes.
        self:AddFieldWatcher("numInfantryPortals",
            function(self2)
                GetGlobalEventDispatcher():FireEvent("OnInfantryPortalCountChanged", self2.numInfantryPortals)
                return true
            end)
        
    end
    
end

if Server then

    local function AddWeaponCountForMarine(trackedWeapons, marine, resultTable)

        for _, weaponMapName in ipairs(trackedWeapons) do
            if marine:GetWeapon(weaponMapName) then

                if not resultTable[weaponMapName] then
                    resultTable[weaponMapName] = 0
                end

                resultTable[weaponMapName] = resultTable[weaponMapName] + 1

            end
        end

    end

    local function AddWeaponCountForExo(self, exo)

        local weaponHolder = exo:GetWeapon(ExoWeaponHolder.kMapName)
        if weaponHolder and kTrackedExoLayouts[weaponHolder.weaponSetupName] then

            local netVarName = TeamInfo_GetUserTrackerNetvarName(weaponHolder.weaponSetupName)
            local netVarExists = self[netVarName] ~= nil
            assert(netVarExists)
            self[netVarName] = self[netVarName] + 1

        end

    end

    function MarineTeamInfo:UpdateUserTrackers()

        -- Update Marine weapons.
        local resultCounts = {}
        local marines = GetEntitiesAliveForTeam("Marine", kTeam1Index)
        for _, marine in ipairs(marines) do
            AddWeaponCountForMarine(kTrackedMarineGadgets, marine, resultCounts)
        end

        for _, mapName in ipairs(kTrackedMarineGadgets) do

            local netVarName = TeamInfo_GetUserTrackerNetvarName(mapName)
            local count = resultCounts[mapName]
            if self[netVarName] then

                if count then
                    self[netVarName] = count
                else
                    self[netVarName] = 0
                end

            end

        end

        -- Update number of jetpack marines.
        local jetpackMarines = GetEntitiesAliveForTeam("JetpackMarine", kTeam1Index)
        local netVarName = TeamInfo_GetUserTrackerNetvarName(Jetpack.kMapName)
        local count = #jetpackMarines
        if self[netVarName] then

            if count then
                self[netVarName] = count
            else
                self[netVarName] = 0
            end

        end

        -- Clear exo netvars.
        for k, _ in pairs(kTrackedExoLayouts) do
            self[TeamInfo_GetUserTrackerNetvarName(k)] = 0
        end

        -- Update the exo weapons.
        local exos = GetEntitiesAliveForTeam("Exo", kTeam1Index)
        for _, exo in ipairs(exos) do

            AddWeaponCountForExo(self, exo)

        end

    end

    function MarineTeamInfo:Reset()
        
        TeamInfo.Reset(self)
        
        self.numInfantryPortals = 0
        
    end
    
    function MarineTeamInfo:OnUpdate(deltaTime)
    
        TeamInfo.OnUpdate(self, deltaTime)
        
        local team = self:GetTeam()
        if team then
        
            self.numInfantryPortals = math.min(team:GetNumActiveInfantryPortals(), kMarineTeamInfoMaxInfantryPortalCount)
        
        end
    
    end

end

Shared.LinkClassToMap("MarineTeamInfo", MarineTeamInfo.kMapName, networkVars)
