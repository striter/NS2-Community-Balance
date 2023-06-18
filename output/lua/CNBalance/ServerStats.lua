-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/ServerStats.lua
--
-- Ported by: Darrell Gentry (darrell@naturalselection2.com)
--
-- Port of the NS2+ stats tracker.
-- Originally Created By: Juanjo Alfaro "Mendasp"
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- Todo: Optimize so that stats are processed faster and use less network bandwidth
-- Todo: Remodel stats data model (big mess at the moment and not easy to parse)

local STATS_ClientStats = {}
local STATS_CommStats = {}
local STATS_TeamStats = {}
local STATS_RTGraph = {}
local STATS_HiveSkillGraph = {}
local STATS_KillGraph = {}
local STATS_ResearchTree = {}
local STATS_BuildingSummary = {}
local STATS_StartingTechPoints = {}
local STATS_ExportResearch = {}
local STATS_ExportBuilding = {}

local STATS_remoteEndpoint = LoadConfigFile("RemoteStats.json")

local serverStatsPath = "NS2Plus\\Stats\\"
local locationsTable = {}
local locationsLookup = {}
local minimapExtents = {}

local STATS_MarineCommanderSteamID

StatsUI_kLifecycle = enum( {'Placed', 'Built', 'Destroyed', 'Recycled', 'Teleported'} )

function StatsUI_SetMarineCommmaderSteamID(steamId)
	STATS_MarineCommanderSteamID = steamId or 0
end

function StatsUI_GetMarineCommmaderSteamID()
	return STATS_MarineCommanderSteamID or 0
end

local function OnMapLoadEntity(className, _, values)

	if className == "minimap_extents" then

		minimapExtents.scale = tostring(values.scale)
		minimapExtents.origin = tostring(values.origin)

	elseif className == "location" and values.name and values.name ~= "" then

		if not locationsLookup[values.name] then

			locationsLookup[values.name] = #locationsTable+1
			table.insert(locationsTable, values.name)

		end
	end
end
Event.Hook("MapLoadEntity", OnMapLoadEntity)

local function GetGameTime(inMinutes)
	local gamerules = GetGamerules()
	local gameTime
	if gamerules then
		gameTime = gamerules:GetGameTimeChanged()
	end

	if gameTime and inMinutes then
		gameTime = gameTime/60
	end

	return gameTime
end

function StatsUI_AddExportBuilding(teamNumber, techId, entityId, location, lifecycle, isBuilt, extraInfo)

	table.insert(STATS_ExportBuilding,
			{
				teamNumber = teamNumber,
				techId = EnumToString(kTechId, techId),
				entityId = entityId,
				gameTime = GetGameTime(),
				built = isBuilt,
				destroyed = lifecycle == StatsUI_kLifecycle.Destroyed or lifecycle == StatsUI_kLifecycle.Recycled,
				recycled = lifecycle == StatsUI_kLifecycle.Recycled,
				event = EnumToString(StatsUI_kLifecycle, lifecycle),
				location = tostring(location)
			})


	if extraInfo then
		STATS_ExportBuilding[#STATS_ExportBuilding][extraInfo.name] = extraInfo.value
	end
end

function StatsUI_AddRTStat(teamNumber, built, destroyed)

	if teamNumber == 1 or teamNumber == 2 then

		local rtsTable = STATS_TeamStats[teamNumber].rts
		local finishedBuilding = built and not destroyed

		if built then
			table.insert(STATS_RTGraph, {teamNumber = teamNumber, destroyed = destroyed, gameMinute = GetGameTime(true)})
		end

		-- The unfinished nodes will be computed on the overall built/lost data
		rtsTable.lost = rtsTable.lost + ConditionalValue(destroyed, 1, 0)
		rtsTable.built = rtsTable.built + ConditionalValue(finishedBuilding, 1, 0)
	end
end

function StatsUI_AddTechStat(teamNumber, techId, built, destroyed, recycled)

	if (teamNumber == 1 or teamNumber == 2) and techId then

		local teamInfoEnt = GetTeamInfoEntity(teamNumber)

		-- Advanced armory displays both "Upgrade to advanced armory" and "Advanced weaponry", filter one
		if techId ~= kTechId.AdvancedWeaponry then

			table.insert(STATS_ResearchTree,
					{
						teamNumber = teamNumber,
						techId = techId,
						finishedMinute = GetGameTime(true),
						activeRTs = teamInfoEnt:GetNumResourceTowers(),
						teamRes = teamInfoEnt:GetTeamResources(),
						destroyed = destroyed,
						built = built,
						recycled = recycled
					})
		end
	end
end

function StatsUI_AddBuildingStat(teamNumber, techId, lost)

	if (teamNumber == 1 or teamNumber == 2) and techId then

		if techId == kTechId.DrifterEgg then
			techId = kTechId.Drifter
		elseif techId == kTechId.ARCRoboticsFactory then
			techId = kTechId.RoboticsFactory
		elseif techId == kTechId.AdvancedArmory then
			techId = kTechId.Armory
		elseif techId == kTechId.CragHive then
			techId = kTechId.Hive
		elseif techId == kTechId.ShiftHive then
			techId = kTechId.Hive
		elseif techId == kTechId.ShadeHive then
			techId = kTechId.Hive
		elseif techId == kTechId.StandardStation then
			techId = kTechId.CommandStation
		elseif techId == kTechId.ArmorStation then
			techId = kTechId.CommandStation
		elseif techId == kTechId.ExplosiveStation then
			techId = kTechId.CommandStation
		elseif techId == kTechId.ElectronicStation then
			techId = kTechId.CommandStation
		end

		local stat = STATS_BuildingSummary[teamNumber][techId]
		if not stat then
			STATS_BuildingSummary[teamNumber][techId] = {}
			STATS_BuildingSummary[teamNumber][techId].built = 0
			STATS_BuildingSummary[teamNumber][techId].lost = 0
			stat = STATS_BuildingSummary[teamNumber][techId]
		end

		if lost then
			stat.lost = stat.lost + 1
		else
			stat.built = stat.built + 1
		end
	end
end

local notLoggedBuildings = set {
	"PowerPoint",
	"Hydra",
	"Clog",
	"Web",
	"Babbler",
	"BabblerEgg",
	"Egg",
	"BoneWall",
	"Hallucination",
	"Mine",
	"SporeMine",
	"MAC",
}

function StatsUI_GetBuildingBlockedFromLog(structureName)
	return notLoggedBuildings[structureName]
end

local techLoggedAsBuilding = set {
	kTechId.ARC,
	kTechId.MAC,
	kTechId.Drifter
}

function StatsUI_GetTechLoggedAsBuilding(techId)
	return techLoggedAsBuilding[techId]
end

local techLogBuildings = set {
	"ArmsLab",
	"PrototypeLab",
	"Observatory",
	"InfantryPortal",
	"CommandStation",
	"Veil",
	"Shell",
	"Spur",
	"Hive"
}

function StatsUI_GetBuildingLogged(structureName)
	return techLogBuildings[structureName]
end

function StatsUI_AddExportResearch(teamNumber, researchIdString)

	table.insert(STATS_ExportResearch, {
		teamNumber = teamNumber,
		researchId = researchIdString,
		gameTime = GetGameTime() })
end

function StatsUI_AddHiveSkillEntry(player, teamNumber, joined)

	local gamerules = GetGamerules()
	local steamId = player:GetSteamId()
	local isOnPlayingTeam = teamNumber == kTeam1Index or teamNumber == kTeam2Index -- don't track spectators

	if gamerules and isOnPlayingTeam and steamId > 0 then -- don't track bots

		STATS_TeamStats[1].maxPlayers = math.max(STATS_TeamStats[1].maxPlayers, gamerules.team1:GetNumPlayers())
		STATS_TeamStats[2].maxPlayers = math.max(STATS_TeamStats[2].maxPlayers, gamerules.team2:GetNumPlayers())

		local gameTime = GetGameTime(true)
		table.insert(STATS_HiveSkillGraph, { gameMinute = gameTime, joined = joined, teamNumber = teamNumber, steamId = steamId } )
	end
end

function StatsUI_ResetLastLifeStats(steamId)

	if steamId > 0 and STATS_ClientStats[steamId] then

		STATS_ClientStats[steamId]["last"] = {}
		STATS_ClientStats[steamId]["last"].pdmg = 0
		STATS_ClientStats[steamId]["last"].sdmg = 0
		STATS_ClientStats[steamId]["last"].hits = 0
		STATS_ClientStats[steamId]["last"].onosHits = 0
		STATS_ClientStats[steamId]["last"].misses = 0
		STATS_ClientStats[steamId]["last"].kills = 0
	end
end

-- Function name 2 stronk
function StatsUI_MaybeInitClientStats(steamId, wTechId, teamNumber)

	if steamId > 0 and (teamNumber == 1 or teamNumber == 2) then

		if not STATS_ClientStats[steamId] then
			STATS_ClientStats[steamId] = {}
			STATS_ClientStats[steamId][1] = {}
			STATS_ClientStats[steamId][2] = {}
			for _, entry in ipairs(STATS_ClientStats[steamId]) do
				entry.kills = 0
				entry.assists = 0
				entry.deaths = 0
				entry.score = 0
				entry.pdmg = 0
				entry.sdmg = 0
				entry.hits = 0
				entry.onosHits = 0
				entry.misses = 0
				entry.killstreak = 0
				entry.timeBuilding = 0
				entry.timePlayed = 0
				entry.commanderTime = 0
			end

			-- These are team independent
			STATS_ClientStats[steamId].playerName = "NSPlayer"
			STATS_ClientStats[steamId].hiveSkill = -1
			STATS_ClientStats[steamId].playerSkillOffset = -1
			STATS_ClientStats[steamId].commanderSkill = -1
			STATS_ClientStats[steamId].commanderSkillOffset = -1
			STATS_ClientStats[steamId].adagrad = -1
			STATS_ClientStats[steamId].isRookie = false
			STATS_ClientStats[steamId].lastTeam = teamNumber

			-- Initialize the last life stats
			StatsUI_ResetLastLifeStats(steamId)

			STATS_ClientStats[steamId]["weapons"] = {}
			STATS_ClientStats[steamId]["status"] = {}
		elseif (teamNumber ~= nil and STATS_ClientStats[steamId].lastTeam ~= teamNumber) then
			STATS_ClientStats[steamId].lastTeam = teamNumber

			-- Clear the last life stats if the player switches teams
			StatsUI_ResetLastLifeStats(steamId)
		end

		if wTechId and not STATS_ClientStats[steamId]["weapons"][wTechId] and (teamNumber == 1 or teamNumber == 2) then
			STATS_ClientStats[steamId]["weapons"][wTechId] = {}
			STATS_ClientStats[steamId]["weapons"][wTechId].hits = 0
			STATS_ClientStats[steamId]["weapons"][wTechId].onosHits = 0
			STATS_ClientStats[steamId]["weapons"][wTechId].misses = 0
			STATS_ClientStats[steamId]["weapons"][wTechId].kills = 0
			STATS_ClientStats[steamId]["weapons"][wTechId].pdmg = 0
			STATS_ClientStats[steamId]["weapons"][wTechId].sdmg = 0
			STATS_ClientStats[steamId]["weapons"][wTechId].teamNumber = teamNumber
		end
	end
end

function StatsUI_AddAccuracyStat(steamId, wTechId, wasHit, isOnos, teamNumber)

	if GetGamerules():GetGameStarted() and steamId > 0 and (teamNumber == 1 or teamNumber == 2) then

		StatsUI_MaybeInitClientStats(steamId, wTechId, teamNumber)

		if STATS_ClientStats[steamId] then
			local overallStat = STATS_ClientStats[steamId][teamNumber]
			local stat = STATS_ClientStats[steamId]["weapons"][wTechId]
			local lastStat = STATS_ClientStats[steamId]["last"]

			if wasHit then
				overallStat.hits = overallStat.hits + 1
				stat.hits = stat.hits + 1
				lastStat.hits = lastStat.hits + 1

				if teamNumber == 1 or teamNumber == 2 then
					STATS_TeamStats[teamNumber].hits = STATS_TeamStats[teamNumber].hits + 1
				end

				if isOnos then
					overallStat.onosHits = overallStat.onosHits + 1
					stat.onosHits = stat.onosHits + 1
					lastStat.onosHits = lastStat.onosHits + 1

					if teamNumber == 1 then
						STATS_TeamStats[1].onosHits = STATS_TeamStats[1].onosHits + 1
					end
				end
			else
				overallStat.misses = overallStat.misses + 1
				stat.misses = stat.misses + 1
				lastStat.misses = lastStat.misses + 1

				if teamNumber == 1 or teamNumber == 2 then
					STATS_TeamStats[teamNumber].misses = STATS_TeamStats[teamNumber].misses + 1
				end
			end
		end
	end
end

function StatsUI_AddDamageStat(steamId, damage, isPlayer, wTechId, teamNumber)

	if GetGamerules():GetGameStarted() and steamId > 0 and (teamNumber == 1 or teamNumber == 2) then

		StatsUI_MaybeInitClientStats(steamId, wTechId, teamNumber)

		if STATS_ClientStats[steamId] then

			local stat = STATS_ClientStats[steamId][teamNumber]
			local weaponStat = STATS_ClientStats[steamId]["weapons"][wTechId]
			local lastStat = STATS_ClientStats[steamId]["last"]

			if isPlayer then
				stat.pdmg = stat.pdmg + damage
				weaponStat.pdmg = weaponStat.pdmg + damage
				lastStat.pdmg = lastStat.pdmg + damage
			else
				stat.sdmg = stat.sdmg + damage
				weaponStat.sdmg = weaponStat.sdmg + damage
				lastStat.sdmg = lastStat.sdmg + damage
			end
		end
	end
end

function StatsUI_AddWeaponKill(steamId, wTechId, teamNumber)

	if GetGamerules():GetGameStarted() and steamId > 0 and (teamNumber == 1 or teamNumber == 2) then

		StatsUI_MaybeInitClientStats(steamId, wTechId, teamNumber)

		if STATS_ClientStats[steamId] then
			local rootStat = STATS_ClientStats[steamId][teamNumber]
			local weaponStat = STATS_ClientStats[steamId]["weapons"][wTechId]
			local lastStat = STATS_ClientStats[steamId]["last"]

			weaponStat.kills = weaponStat.kills + 1
			lastStat.kills = lastStat.kills + 1

			if lastStat.kills > rootStat.killstreak then
				rootStat.killstreak = lastStat.kills
			end
		end
	end
end

function StatsUI_AddTeamGraphKill(teamNumber, killer, victim, weapon, doer)

	if teamNumber == 1 or teamNumber == 2 then

		local killerLocation = killer and killer:isa("Player") and locationsLookup[killer:GetLocationName()] or nil
		local killerPosition = killer and killer:isa("Player") and tostring(killer:GetOrigin()) or nil
		local killerClass = killer and killer:isa("Player") and EnumToString(kPlayerStatus, killer:GetPlayerStatusDesc()) or nil

		if not killerClass and doer and doer.GetClassName then
			killerClass = doer:GetClassName()
		end

		local doerLocation, doerPosition

		if doer and doer:isa("WhipBomb") and doer.shooter then
			doer = doer.shooter
		end

		-- Don't log doerLocation/Position for weapons that have parents (rifle, bite, etc)
		-- These are meant for things like mines, grenades, etc
		if doer and doer.GetParent and doer:GetParent() == nil then

			local origin = doer.GetOrigin and doer:GetOrigin()

			if origin then
				local location = GetLocationForPoint(origin)
				doerLocation = locationsLookup[location and location:GetName()]
				doerPosition = tostring(origin)
			end
		end

		local killerSteamID = killer and killer:isa("Player") and killer:GetSteamId() or nil
		local victimLocation = victim and victim:isa("Player") and locationsLookup[victim:GetLocationName()] or nil
		local victimPosition = victim and victim:isa("Player") and tostring(victim:GetOrigin()) or nil
		local victimClass = victim and victim:isa("Player") and EnumToString(kPlayerStatus, victim:GetPlayerStatusDesc()) or nil
		local victimSteamID = victim and victim:isa("Player") and victim:GetSteamId() or nil
		weapon = EnumToString(kTechId, weapon) or nil

		table.insert(STATS_KillGraph,
				{
					gameTime = GetGameTime(),
					gameMinute = GetGameTime(true),
					killerTeamNumber = teamNumber,
					killerWeapon = weapon,
					killerPosition = killerPosition,
					killerLocation = killerLocation,
					killerClass = killerClass,
					killerSteamID = killerSteamID,
					victimPosition = victimPosition,
					victimLocation = victimLocation,
					victimClass = victimClass,
					victimSteamID = victimSteamID,
					doerLocation = doerLocation,
					doerPosition = doerPosition
				})
	end
end

function StatsUI_AddBuildTime(steamId, buildTime, teamNumber)

	if GetGamerules():GetGameStarted() and steamId > 0 and (teamNumber == 1 or teamNumber == 2) then

		StatsUI_MaybeInitClientStats(steamId, nil, teamNumber)

		if STATS_ClientStats[steamId] then
			local stat = STATS_ClientStats[steamId][teamNumber]
			stat.timeBuilding = stat.timeBuilding + buildTime
		end
	end
end

local classNameToTechId = {}
classNameToTechId["SporeCloud"] = kTechId.Spores
classNameToTechId["NerveGasCloud"] = kTechId.GasGrenade
classNameToTechId["WhipBomb"] = kTechId.WhipBomb
classNameToTechId["DotMarker"] = kTechId.BileBomb
classNameToTechId["Shockwave"] = kTechId.Stomp

function StatsUI_GetAttackerWeapon(attacker, doer)

	local attackerTeam = attacker and attacker:isa("Player") and attacker:GetTeamNumber() or nil
	local attackerSteamId = attacker and attacker:isa("Player") and attacker:GetSteamId() or nil
	local attackerWeapon = doer and doer:isa("Weapon") and doer:GetTechId() or kTechId.None

	if attacker and doer then
		if doer.GetClassName and classNameToTechId[doer:GetClassName()] then

			attackerWeapon = classNameToTechId[doer:GetClassName()]

		elseif doer:GetParent() and doer:GetParent():isa("Player") then

			if attacker:isa("Alien") and ((attacker:isa("Gorge") and doer.secondaryAttacking) or doer.shootingSpikes) then
				attackerWeapon = attacker:GetActiveWeapon():GetSecondaryTechId()
			else
				attackerWeapon = doer:GetTechId()
			end

		elseif HasMixin(doer, "Owner") then

			if doer.GetWeaponTechId then

				attackerWeapon = doer:GetWeaponTechId()

			elseif doer.techId then

				attackerWeapon = doer.techId
				local deathIcon = doer.GetDeathIconIndex and doer:GetDeathIconIndex() or nil

				-- Translate the deathicon into a techid we can use for the end-game stats
				if deathIcon == kDeathMessageIcon.Mine then
					attackerWeapon = kTechId.LayMines
				elseif deathIcon == kDeathMessageIcon.PulseGrenade then
					attackerWeapon = kTechId.PulseGrenade
				elseif deathIcon == kDeathMessageIcon.ClusterGrenade then
					attackerWeapon = kTechId.ClusterGrenade
				elseif deathIcon == kDeathMessageIcon.Flamethrower then
					attackerWeapon = kTechId.Flamethrower
				elseif deathIcon == kDeathMessageIcon.EMPBlast then
					attackerWeapon = kTechId.PowerSurge
				end
			end
		end
	end

	return attackerSteamId, attackerWeapon, attackerTeam
end

function StatsUI_GetStatForClient(steamId)
	return STATS_ClientStats[steamId]
end

function StatsUI_GetStatForCommander(commanderSteamId)
	return STATS_CommStats[commanderSteamId]
end

function StatsUI_SetBaseClientStatsInfo(steamId, playerName, playerSkill, playerSkillOffset, commanderSkill, commanderSkillOffset, adagrad, commAdagrad, isRookie)

	local stat = StatsUI_GetStatForClient(steamId)

	if stat then
		stat.playerName = playerName
		stat.hiveSkill = playerSkill
		stat.playerSkillOffset = playerSkillOffset
		stat.commanderSkill = commanderSkill
		stat.commanderSkillOffset = commanderSkillOffset
		stat.adagrad = adagrad
		stat.commAdagrad = commAdagrad
		stat.isRookie = isRookie
	end
end

local statusGrouping = {}
statusGrouping[kPlayerStatus.SkulkEgg] = kPlayerStatus.Embryo
statusGrouping[kPlayerStatus.GorgeEgg] = kPlayerStatus.Embryo
statusGrouping[kPlayerStatus.LerkEgg] = kPlayerStatus.Embryo
statusGrouping[kPlayerStatus.FadeEgg] = kPlayerStatus.Embryo
statusGrouping[kPlayerStatus.OnosEgg] = kPlayerStatus.Embryo
statusGrouping[kPlayerStatus.Evolving] = kPlayerStatus.Embryo
statusGrouping[kPlayerStatus.ProwlerEgg] = kPlayerStatus.Embryo
statusGrouping[kPlayerStatus.VokexEgg] = kPlayerStatus.Embryo

function StatsUI_GetStatusGrouping(playerStatus)
	return statusGrouping[playerStatus]
end

local kBioMassTechIds = enum({ kTechId.BioMassOne, kTechId.BioMassTwo, kTechId.BioMassThree,
							   kTechId.BioMassFour, kTechId.BioMassFive, kTechId.BioMassSix,
							   kTechId.BioMassSeven, kTechId.BioMassEight, kTechId.BioMassNine })

function StatsUI_GetBiomassTechIdFromLevel(biomassLevel)
	return kBioMassTechIds[biomassLevel]
end

function StatsUI_ResetCommStats(commSteamId)

	if not STATS_CommStats[commSteamId] then

		STATS_CommStats[commSteamId] = { }
		STATS_CommStats[commSteamId]["medpack"] = { }
		STATS_CommStats[commSteamId]["ammopack"] = { }
		STATS_CommStats[commSteamId]["catpack"] = { }

		for index, _ in pairs(STATS_CommStats[commSteamId]) do

			STATS_CommStats[commSteamId][index].picks = 0
			STATS_CommStats[commSteamId][index].misses = 0

			if index ~= "catpack" then
				STATS_CommStats[commSteamId][index].refilled = 0
			end

			if index == "medpack" then
				STATS_CommStats[commSteamId][index].hitsAcc = 0
			end
		end
	end
end

function StatsUI_ResetStats()

	STATS_CommStats = {}
	STATS_ClientStats = {}

	STATS_RTGraph = {}
	STATS_KillGraph = {}

	STATS_TeamStats[1] = {}
	STATS_TeamStats[1].hits = 0
	STATS_TeamStats[1].onosHits = 0
	STATS_TeamStats[1].misses = 0
	STATS_TeamStats[1].rts = {lost = 0, built = 0}
	STATS_TeamStats[1].maxPlayers = 0
	-- Easier to read for servers parsing the jsons
	STATS_TeamStats[1].teamNumber = 1

	STATS_TeamStats[2] = {}
	STATS_TeamStats[2].hits = 0
	STATS_TeamStats[2].misses = 0
	STATS_TeamStats[2].rts = {lost = 0, built = 0}
	STATS_TeamStats[2].maxPlayers = 0
	-- Easier to read for servers parsing the jsons
	STATS_TeamStats[2].teamNumber = 2

	STATS_ResearchTree = {}

	STATS_BuildingSummary = {}
	STATS_BuildingSummary[1] = {}
	STATS_BuildingSummary[2] = {}

	STATS_ExportResearch = {}
	STATS_ExportBuilding = {}

	-- Do this so we can spawn items without a commander with cheats on
	StatsUI_SetMarineCommmaderSteamID(0)
	StatsUI_ResetCommStats(StatsUI_GetMarineCommmaderSteamID())

	STATS_HiveSkillGraph = {}

	for _, playerInfo in ientitylist(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) do

		local teamNumber = playerInfo.teamNumber
		local steamId = playerInfo.steamId

		if playerInfo.isCommander then

			if teamNumber == kTeam1Index then
				StatsUI_SetMarineCommmaderSteamID(steamId)
				StatsUI_ResetCommStats(steamId)
			end

			-- Init the commander player stats so they show up at the end-game stats
			StatsUI_MaybeInitClientStats(steamId, nil, teamNumber)
		end
	end
end

function StatsUI_InitializeTeamStatsAndTechPoints(self)

	-- Add the team player counts on game reset
	STATS_TeamStats[1].maxPlayers = math.max(0, self.team1:GetNumPlayers())
	STATS_TeamStats[2].maxPlayers = math.max(0, self.team2:GetNumPlayers())

	-- Starting tech points
	STATS_StartingTechPoints["1"] = locationsLookup[self.startingLocationNameTeam1]
	STATS_StartingTechPoints["2"] = locationsLookup[self.startingLocationNameTeam2]
end

local function CHUDGetAccuracy(hits, misses, onosHits)
	local accuracy = 0
	local accuracyOnos = ConditionalValue(onosHits == 0, -1, 0)

	if hits > 0 or misses > 0 then
		accuracy = hits/(hits+misses)*100
		if onosHits and onosHits > 0 and hits ~= onosHits then
			accuracyOnos = (hits-onosHits)/((hits-onosHits)+misses)*100
		end
	end

	return accuracy, accuracyOnos
end

local lastRoundStats = {}
function CHUDGetLastRoundStats()
	return lastRoundStats
end

function StatsUI_FormatRoundStats()

	local finalStats = {}
	finalStats[1] = {}
	finalStats[2] = {}

	-- reformat stats for export
	for steamId, stats in pairs(STATS_ClientStats) do

		-- Easier format for easy parsing server-side
		local newWeaponsTable = {}
		for wTechId, wStats in pairs(stats["weapons"]) do

			-- Use more consistent naming for exporting stats
			wStats.playerDamage = wStats.pdmg
			wStats.structureDamage = wStats.sdmg

			wStats.pdmg = nil
			wStats.sdmg = nil

			newWeaponsTable[EnumToString(kTechId, wTechId)] = wStats
		end
		stats["weapons"] = newWeaponsTable

		-- Easier format for easy parsing server-side
		local newStatusTable = {}
		for statusId, classTime in pairs(stats["status"]) do
			table.insert(newStatusTable, {statusId = EnumToString(kPlayerStatus, statusId), classTime = classTime})
		end
		stats["status"] = newStatusTable

		for teamNumber = 1, 2 do

			local entry = stats[teamNumber]
			if entry.timePlayed and entry.timePlayed > 0 then

				local statEntry = {}

				local accuracy, accuracyOnos = CHUDGetAccuracy(entry.hits, entry.misses, entry.onosHits)

				statEntry.isMarine = teamNumber == 1
				statEntry.playerName = stats.playerName
				statEntry.hiveSkill = stats.hiveSkill
				statEntry.kills = entry.kills
				statEntry.killstreak = entry.killstreak
				statEntry.assists = entry.assists
				statEntry.deaths = entry.deaths
				statEntry.score = entry.score
				statEntry.accuracy = accuracy
				statEntry.accuracyOnos = accuracyOnos
				statEntry.pdmg = entry.pdmg
				statEntry.sdmg = entry.sdmg
				statEntry.minutesBuilding = entry.timeBuilding/60
				statEntry.minutesPlaying = entry.timePlayed/60
				statEntry.minutesComm = entry.commanderTime/60
				statEntry.isRookie = entry.isRookie
				statEntry.steamId = steamId

				if teamNumber == 1 then
					table.insert(finalStats[1], statEntry)
				else
					table.insert(finalStats[2], statEntry)
				end
			end

			-- Use more consistent naming for exporting stats
			entry.playerDamage = entry.pdmg
			entry.structureDamage = entry.sdmg

			entry.pdmg = nil
			entry.sdmg = nil
		end

		-- Remove last life stats and last update time from exported data
		stats.last = nil
		stats.lastUpdate = nil
	end

	local newBuildingSummaryTable = {}
	for teamNumber, team in pairs(STATS_BuildingSummary) do

		for techId, entry in pairs(team) do

			entry.teamNumber = teamNumber
			entry.techId = EnumToString(kTechId, techId)
			table.insert(newBuildingSummaryTable, entry)
		end
	end

	STATS_BuildingSummary = newBuildingSummaryTable

	return finalStats
end

local function SendClientCommanderStats(client, steamId)

	if not STATS_CommStats[steamId] then return end

	local msg = {
		medpackAccuracy = 0,
		medpackResUsed = 0,
		medpackResExpired = 0,
		medpackEfficiency = 0,
		medpackRefill = 0,
		ammopackResUsed = 0,
		ammopackResExpired = 0,
		ammopackEfficiency = 0,
		ammopackRefill = 0,
		catpackResUsed = 0,
		catpackResExpired = 0,
		catpackEfficiency = 0
	}

	for index, commStats in pairs(STATS_CommStats[steamId]) do

		if commStats.picks and commStats.picks > 0 or commStats.misses and commStats.misses > 0 then

			if index == "medpack" then
				-- Add medpacks that were picked up later to the misses count for accuracy
				msg.medpackAccuracy = CHUDGetAccuracy(commStats.hitsAcc, (commStats.picks- commStats.hitsAcc)+ commStats.misses)
				msg.medpackResUsed = commStats.picks * kMedPackCost
				msg.medpackResExpired = commStats.misses * kMedPackCost
				msg.medpackEfficiency = CHUDGetAccuracy(commStats.picks, commStats.misses)
				msg.medpackRefill = commStats.refilled
			elseif index == "ammopack" then
				msg.ammopackResUsed = commStats.picks * kAmmoPackCost
				msg.ammopackResExpired = commStats.misses * kAmmoPackCost
				msg.ammopackEfficiency = CHUDGetAccuracy(commStats.picks, commStats.misses)
				msg.ammopackRefill = commStats.refilled
			elseif index == "catpack" then
				msg.catpackResUsed = commStats.picks * kCatPackCost
				msg.catpackResExpired = commStats.misses * kCatPackCost
				msg.catpackEfficiency = CHUDGetAccuracy(commStats.picks, commStats.misses)
			end
		end
	end

	Server.SendNetworkMessage(client, "MarineCommStats", msg, true)
end

function StatsUI_SendPlayerStats(player)

	local client = player:GetClient()
	if not client then return end

	local steamId = player:GetSteamId()
	if not steamId or steamId < 1 then return end

	local stats = STATS_ClientStats[steamId]
	if not stats then return end

	-- Commander stats
	SendClientCommanderStats(client, steamId)

	for wTechName, wStats in pairs(stats["weapons"]) do
		local accuracy, accuracyOnos = CHUDGetAccuracy(wStats.hits, wStats.misses, wStats.onosHits)

		local msg = {}
		msg.wTechId = kTechId[wTechName]
		msg.accuracy = accuracy
		msg.accuracyOnos = accuracyOnos
		msg.kills = wStats.kills
		msg.pdmg = wStats.playerDamage
		msg.sdmg = wStats.structureDamage
		msg.teamNumber = wStats.teamNumber
		--Log("NS2+ %s : %s -> %s", wTechId, wStats, msg )
		Server.SendNetworkMessage(client, "EndStatsWeapon", msg, true)
	end

	for i = 1, #stats.status do
		local entry = stats.status[i]
		local msg = {}

		msg.statusId = kPlayerStatus[entry.statusId]
		msg.timeMinutes = entry.classTime / 60
		Server.SendNetworkMessage(client, "EndStatsStatus", msg, true)
	end
end

function StatsUI_SendTeamStats()

	local team1Accuracy, team1OnosAccuracy = CHUDGetAccuracy(STATS_TeamStats[1].hits, STATS_TeamStats[1].misses, STATS_TeamStats[1].onosHits)
	local team2Accuracy = CHUDGetAccuracy(STATS_TeamStats[2].hits, STATS_TeamStats[2].misses)

	local msg = {}
	msg.marineAcc = team1Accuracy
	msg.marineOnosAcc = team1OnosAccuracy
	msg.marineRTsBuilt = STATS_TeamStats[1]["rts"].built
	msg.marineRTsLost = STATS_TeamStats[1]["rts"].lost
	msg.alienAcc = team2Accuracy
	msg.alienRTsBuilt = STATS_TeamStats[2]["rts"].built
	msg.alienRTsLost = STATS_TeamStats[2]["rts"].lost
	msg.gameLengthMinutes = GetGameTime(true)

	Server.SendNetworkMessage("GameData", msg, true)

	for _, entry in ipairs(STATS_ResearchTree) do

		-- Exclude the initial buildings (finishedMinute is 0 and teamRes is 0)
		if entry.finishedMinute > 0 or entry.teamRes > 0 then
			Server.SendNetworkMessage("TechLog", entry, true)
		end
	end

	for _, entry in ipairs(STATS_HiveSkillGraph) do
		Server.SendNetworkMessage("HiveSkillGraph", entry, true)
	end

	for _, entry in ipairs(STATS_RTGraph) do
		Server.SendNetworkMessage("RTGraph", entry, true)
	end

	for _, entry in ipairs(STATS_KillGraph) do

		Server.SendNetworkMessage("KillGraph", entry, true)
		-- Remove the game minute so it doesn't get exported
		entry.gameMinute = nil
	end

	for _, entry in pairs(STATS_BuildingSummary) do

		local buildMsg = {}
		buildMsg.teamNumber = entry.teamNumber
		buildMsg.techId = kTechId[entry.techId]
		buildMsg.built = entry.built
		buildMsg.lost = entry.lost
		Server.SendNetworkMessage("BuildingSummary", buildMsg, true)
	end
end

local function GetServerMods()
	local mods = {}

	-- Can't get the mod title correctly unless we do this
	-- GetModTitle can't get it from the active mod list index, it uses the normal one
	local activeModIds = {}
	for modNum = 1, Server.GetNumActiveMods() do
		activeModIds[Server.GetActiveModId(modNum)] = true
	end

	for modNum = 1, Server.GetNumMods() do
		local modId = Server.GetModId(modNum)
		if activeModIds[modId] then
			table.insert(mods, {modId = modId, name = Server.GetModTitle(modNum)})
		end
	end

	return mods
end

function StatsUI_UploadRoundStats(endpoint)
	Log("Uploading stats to remote endpoint %s", endpoint.url)

	Shared.SendHTTPRequest(endpoint.url, "POST", { authToken=endpoint.authToken, stats=json.encode(lastRoundStats) },
			function(result, error, code)
				Log("Round stats upload to endpoint %s complete, result code: %s", endpoint.url, code)
			end
	)
end

function StatsUI_SaveRoundStats(winningTeam)

	if AdvancedServerOptions["savestats"].currentValue == false then
		return
	end

	lastRoundStats = {}
	lastRoundStats.MarineCommStats = STATS_CommStats
	lastRoundStats.PlayerStats = STATS_ClientStats
	lastRoundStats.KillFeed = STATS_KillGraph

	lastRoundStats.ServerInfo =
	{
		ip = Server.GetIpAddress(),
		port = Server.GetPort(),
		name = Server.GetName(),
		slots = Server.GetMaxPlayers(),
		buildNumber = Shared.GetBuildNumber(),
		rookieOnly = Server.GetHasTag("rookie_only"),
		mods = GetServerMods()
	}

	lastRoundStats.RoundInfo =
	{
		mapName = Shared.GetMapName(),
		minimapExtents = minimapExtents,
		roundDate = Shared.GetSystemTime(),
		roundLength = GetGameTime(),
		startingLocations = STATS_StartingTechPoints,
		winningTeam = winningTeam and winningTeam.GetTeamType and winningTeam:GetTeamType() or kNeutralTeamType,
		tournamentMode = Shared.GetThunderdomeEnabled(),
		maxPlayers1 = STATS_TeamStats[1].maxPlayers,
		maxPlayers2 = STATS_TeamStats[2].maxPlayers,
		gameMode = GetGamemode and GetGamemode() or "ns2"
	}

	lastRoundStats.Locations = locationsTable
	lastRoundStats.Buildings = STATS_ExportBuilding
	lastRoundStats.Research = STATS_ExportResearch

	if type(STATS_remoteEndpoint) == "table" then
		Log("Beginning remote stats upload...")

		if type(STATS_remoteEndpoint.endpoint) == "table" then
			StatsUI_UploadRoundStats(STATS_remoteEndpoint.endpoint)
		end

		if type(STATS_remoteEndpoint.altEndpoint) == "table" then
			StatsUI_UploadRoundStats(STATS_remoteEndpoint.altEndpoint)
		end
	end

	local savedServerFile = io.open(string.format("config://%s%s.json", serverStatsPath, Shared.GetSystemTime()), "w+")
	if savedServerFile then
		savedServerFile:write(json.encode(lastRoundStats, { indent = true }))
		io.close(savedServerFile)
	end

end

function StatsUI_SendGlobalCommanderStats()	--TODO Roll this data into "core" stats (at least for disk-write)
	local medpackHitsAcc = 0
	local medpackMisses = 0
	local medpackPicks = 0
	local medpackRefill = 0
	local ammopackPicks = 0
	local ammopackMisses = 0
	local ammopackRefill = 0
	local catpackPicks = 0
	local catpackMisses = 0
	local sendCommStats = false

	for _, playerStats in pairs(STATS_CommStats) do
		for index, stats in pairs(playerStats) do
			if stats.picks and stats.picks > 0 or stats.misses and stats.misses > 0 then
				sendCommStats = true
				if index == "medpack" then
					medpackHitsAcc = medpackHitsAcc + stats.hitsAcc
					medpackPicks = medpackPicks + stats.picks
					medpackMisses = medpackMisses + stats.misses
					medpackRefill = medpackRefill + stats.refilled
				elseif index == "ammopack" then
					ammopackPicks = ammopackPicks + stats.picks
					ammopackMisses = ammopackMisses + stats.misses
					ammopackRefill = ammopackRefill + stats.refilled
				elseif index == "catpack" then
					catpackPicks = catpackPicks + stats.picks
					catpackMisses = catpackMisses + stats.misses
				end
			end
		end
	end

	if sendCommStats then
		local comMsg = {
			medpackAccuracy = CHUDGetAccuracy(medpackHitsAcc, (medpackPicks-medpackHitsAcc)+medpackMisses),
			medpackResUsed = medpackPicks,
			medpackResExpired = medpackMisses,
			medpackEfficiency = CHUDGetAccuracy(medpackPicks, medpackMisses),
			medpackRefill = medpackRefill,
			ammopackResUsed = ammopackPicks,
			ammopackResExpired = ammopackMisses,
			ammopackEfficiency = CHUDGetAccuracy(ammopackPicks, ammopackMisses),
			ammopackRefill = ammopackRefill,
			catpackResUsed = catpackPicks,
			catpackResExpired = catpackMisses,
			catpackEfficiency = CHUDGetAccuracy(catpackPicks, catpackMisses)
		}

		Server.SendNetworkMessage("GlobalCommStats", comMsg, true)
	end
end

function StatsUI_HandlePreOnKill(self, killer, doer, point, direction)

	-- Send stats to the player on death
	if GetGamerules():GetGameStarted() then

		local steamId = self:GetSteamId()
		if steamId and steamId > 0 then

			local teamNumber = self:GetTeamNumber()
			StatsUI_MaybeInitClientStats(steamId, nil, teamNumber)

			if STATS_ClientStats[steamId] then

				local lastStat = STATS_ClientStats[steamId]["last"]
				local totalStats = STATS_ClientStats[steamId]["weapons"]
				local msg = {}
				local lastAcc = 0
				local lastAccOnos = 0
				local currentAcc = 0
				local currentAccOnos = 0
				local hitssum = 0
				local missessum = 0
				local onossum = 0

				for _, wStats in pairs(totalStats) do
					-- Display current accuracy for the current team's weapons
					if wStats.teamNumber == teamNumber then
						hitssum = hitssum + wStats.hits
						onossum = onossum + wStats.onosHits
						missessum = missessum + wStats.misses
					end
				end

				if lastStat.hits > 0 or lastStat.misses > 0 then
					lastAcc, lastAccOnos = CHUDGetAccuracy(lastStat.hits, lastStat.misses, lastStat.onosHits)
				end

				if hitssum > 0 or missessum > 0 then
					currentAcc, currentAccOnos = CHUDGetAccuracy(hitssum, missessum, onossum)
				end

				if lastStat.hits > 0 or lastStat.misses > 0 or lastStat.pdmg > 0 or lastStat.sdmg > 0 then
					msg.lastAcc = lastAcc
					msg.lastAccOnos = lastAccOnos
					msg.currentAcc = currentAcc
					msg.currentAccOnos = currentAccOnos
					msg.pdmg = lastStat.pdmg
					msg.sdmg = lastStat.sdmg
					msg.kills = lastStat.kills

					Server.SendNetworkMessage(Server.GetOwner(self), "DeathStats", msg, true)
				end
			end

			StatsUI_ResetLastLifeStats(steamId)
		end

		local targetTeam = self.GetTeamNumber and self:GetTeamNumber() or 0

		-- Now save the attacker weapon
		local killerSteamId, killerWeapon, killerTeam = StatsUI_GetAttackerWeapon(killer, doer)

		if not self.isHallucination then
			if killerSteamId and killerTeam ~= targetTeam then
				StatsUI_AddWeaponKill(killerSteamId, killerWeapon, killerTeam)
			end
			-- If there's a teamkill or a death by natural causes, award the kill to the other team
			if killerTeam == targetTeam or killerTeam == nil then
				if targetTeam == 1 then
					killerTeam = 2
				else
					killerTeam = 1
				end
			end

			StatsUI_AddTeamGraphKill(killerTeam, killer, self, killerWeapon, doer)
		end
	end

end

-- Initialize the arrays
StatsUI_ResetStats()
