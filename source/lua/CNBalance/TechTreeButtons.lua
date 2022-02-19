-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\TechTreeButtons.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- Hard-coded data which maps tech tree constants to indices into a texture. Used to display
-- icons in the commander build menu and alien buy menu.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- These are the icons that appear next to alerts or as hotkey icons.
-- Icon size should be 20x20. Also used for the alien buy menu.
function CommanderUI_Icons()

    local player = Client.GetLocalPlayer()
    if(player and (player:isa("Alien") or player:isa("AlienCommander"))) then
        return "alien_upgradeicons"
    end
    
    return "marine_upgradeicons"

end

function CommanderUI_MenuImageSize()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return 640, 1040
    end
    
    return 960, 960
    
end

-- Init icon offsets.
local kTechIdToMaterialOffset = {}

kTechIdToMaterialOffset[kTechId.BioMassOne] = 112 
kTechIdToMaterialOffset[kTechId.BioMassTwo] = 112 
kTechIdToMaterialOffset[kTechId.BioMassThree] = 112 
kTechIdToMaterialOffset[kTechId.BioMassFour] = 112 
kTechIdToMaterialOffset[kTechId.BioMassFive] = 112 
kTechIdToMaterialOffset[kTechId.BioMassSix] = 112 
kTechIdToMaterialOffset[kTechId.BioMassSeven] = 112
kTechIdToMaterialOffset[kTechId.BioMassEight] = 112
kTechIdToMaterialOffset[kTechId.BioMassNine] = 112
kTechIdToMaterialOffset[kTechId.BioMassTen] = 112
kTechIdToMaterialOffset[kTechId.BioMassEleven] = 112
kTechIdToMaterialOffset[kTechId.BioMassTwelve] = 112

kTechIdToMaterialOffset[kTechId.CollectResources] = 143
kTechIdToMaterialOffset[kTechId.TransformResources] = 120

kTechIdToMaterialOffset[kTechId.PingLocation] = 162
kTechIdToMaterialOffset[kTechId.Research] = 163

kTechIdToMaterialOffset[kTechId.CommandStation] = 0
kTechIdToMaterialOffset[kTechId.TwoCommandStations] = 0
kTechIdToMaterialOffset[kTechId.Armory] = 1
kTechIdToMaterialOffset[kTechId.AdvancedArmory] = 99
kTechIdToMaterialOffset[kTechId.Hive] = 2
kTechIdToMaterialOffset[kTechId.Extractor] = 3
kTechIdToMaterialOffset[kTechId.ExtractorArmor] = 14
kTechIdToMaterialOffset[kTechId.InfantryPortal] = 4
kTechIdToMaterialOffset[kTechId.Sentry] = 5
kTechIdToMaterialOffset[kTechId.RoboticsFactory] = 6
kTechIdToMaterialOffset[kTechId.ARCRoboticsFactory] = 6
kTechIdToMaterialOffset[kTechId.Observatory] = 7
kTechIdToMaterialOffset[kTechId.SelectObservatory] = 74
kTechIdToMaterialOffset[kTechId.MinesTech] = 8
kTechIdToMaterialOffset[kTechId.Mine] = 8
kTechIdToMaterialOffset[kTechId.DropMines] = 8
kTechIdToMaterialOffset[kTechId.SentryBattery] = 9
kTechIdToMaterialOffset[kTechId.ArmsLab] = 10
kTechIdToMaterialOffset[kTechId.Spur] = 11
kTechIdToMaterialOffset[kTechId.TwoSpurs] = 144
kTechIdToMaterialOffset[kTechId.SecondSpur] = 144
kTechIdToMaterialOffset[kTechId.ThreeSpurs] = 145
kTechIdToMaterialOffset[kTechId.ThirdSpur] = 145
kTechIdToMaterialOffset[kTechId.FullSpur] = 153

kTechIdToMaterialOffset[kTechId.Door] = 12
kTechIdToMaterialOffset[kTechId.ResourcePoint] = 13
kTechIdToMaterialOffset[kTechId.TechPoint] = 14
kTechIdToMaterialOffset[kTechId.PrototypeLab] = 15
kTechIdToMaterialOffset[kTechId.Harvester] = 16
kTechIdToMaterialOffset[kTechId.PhaseGate] = 17
kTechIdToMaterialOffset[kTechId.ReversePhaseGate] = 120
kTechIdToMaterialOffset[kTechId.Crag] = 18
kTechIdToMaterialOffset[kTechId.Whip] = 19
kTechIdToMaterialOffset[kTechId.Shift] = 20
kTechIdToMaterialOffset[kTechId.SelectShift] = 59
kTechIdToMaterialOffset[kTechId.Shade] = 21
kTechIdToMaterialOffset[kTechId.Shell] = 22
kTechIdToMaterialOffset[kTechId.TwoShells] = 148
kTechIdToMaterialOffset[kTechId.SecondShell] = 148
kTechIdToMaterialOffset[kTechId.ThreeShells] = 149
kTechIdToMaterialOffset[kTechId.ThirdShell] = 149
kTechIdToMaterialOffset[kTechId.FullShell] = 151

kTechIdToMaterialOffset[kTechId.Veil] = 23
kTechIdToMaterialOffset[kTechId.TwoVeils] = 146
kTechIdToMaterialOffset[kTechId.SecondVeil] = 146
kTechIdToMaterialOffset[kTechId.ThreeVeils] = 147
kTechIdToMaterialOffset[kTechId.ThirdVeil] = 147
kTechIdToMaterialOffset[kTechId.FullVeil] = 152

kTechIdToMaterialOffset[kTechId.Marine] = 24
kTechIdToMaterialOffset[kTechId.ExosuitTech] = 25
kTechIdToMaterialOffset[kTechId.Exo] = 25
kTechIdToMaterialOffset[kTechId.DropExosuit] = 25
kTechIdToMaterialOffset[kTechId.JetpackMarine] = 26    
kTechIdToMaterialOffset[kTechId.JetpackFuelTech] = 26    
kTechIdToMaterialOffset[kTechId.Skulk] = 27
kTechIdToMaterialOffset[kTechId.UpgradeSkulk] = 27
kTechIdToMaterialOffset[kTechId.SkulkMenu] = 27
kTechIdToMaterialOffset[kTechId.Gorge] = 28
kTechIdToMaterialOffset[kTechId.UpgradeGorge] = 28
kTechIdToMaterialOffset[kTechId.GorgeMenu] = 28
kTechIdToMaterialOffset[kTechId.GorgeEgg] = 28
kTechIdToMaterialOffset[kTechId.Lerk] = 29
kTechIdToMaterialOffset[kTechId.UpgradeLerk] = 29
kTechIdToMaterialOffset[kTechId.LerkMenu] = 29
kTechIdToMaterialOffset[kTechId.LerkEgg] = 29
kTechIdToMaterialOffset[kTechId.Fade] = 30
kTechIdToMaterialOffset[kTechId.UpgradeFade] = 30
kTechIdToMaterialOffset[kTechId.FadeMenu] = 30
kTechIdToMaterialOffset[kTechId.FadeEgg] = 30
kTechIdToMaterialOffset[kTechId.Onos] = 31  
kTechIdToMaterialOffset[kTechId.UpgradeOnos] = 31  
kTechIdToMaterialOffset[kTechId.OnosMenu] = 31  
kTechIdToMaterialOffset[kTechId.OnosEgg] = 31
kTechIdToMaterialOffset[kTechId.ARC] = 32
kTechIdToMaterialOffset[kTechId.ARCUndeploy] = 32
kTechIdToMaterialOffset[kTechId.ARCDeploy] = 33
kTechIdToMaterialOffset[kTechId.Egg] = 34
kTechIdToMaterialOffset[kTechId.Embryo] = 34
kTechIdToMaterialOffset[kTechId.Cyst] = 35

kTechIdToMaterialOffset[kTechId.CystCamouflage] = 180
kTechIdToMaterialOffset[kTechId.CystCelerity] = 182
kTechIdToMaterialOffset[kTechId.CystCarapace] = 181

kTechIdToMaterialOffset[kTechId.MAC] = 36
kTechIdToMaterialOffset[kTechId.Drifter] = 37
kTechIdToMaterialOffset[kTechId.DrifterEgg] = 37
kTechIdToMaterialOffset[kTechId.SelectDrifter] = 98
kTechIdToMaterialOffset[kTechId.WhipUnroot] = 38
kTechIdToMaterialOffset[kTechId.WhipRoot] = 39
kTechIdToMaterialOffset[kTechId.ShiftEcho] = 40
kTechIdToMaterialOffset[kTechId.WhipBombard] = 41
kTechIdToMaterialOffset[kTechId.EnzymeCloud] = 42
kTechIdToMaterialOffset[kTechId.MACEMPTech] = 43
kTechIdToMaterialOffset[kTechId.MACEMP] = 43
kTechIdToMaterialOffset[kTechId.Rupture] = 44
kTechIdToMaterialOffset[kTechId.RuptureTech] = 44
kTechIdToMaterialOffset[kTechId.ShadeInk] = 45
kTechIdToMaterialOffset[kTechId.ShiftHatch] = 46
kTechIdToMaterialOffset[kTechId.ShiftEnergize] = 47

kTechIdToMaterialOffset[kTechId.Hallucinate] = 126
kTechIdToMaterialOffset[kTechId.SelectHallucinations] = 118
kTechIdToMaterialOffset[kTechId.DestroyHallucination] = 139
kTechIdToMaterialOffset[kTechId.DrifterCelerity] = 185
kTechIdToMaterialOffset[kTechId.DrifterRegeneration] = 183

kTechIdToMaterialOffset[kTechId.HealWave] = 48
kTechIdToMaterialOffset[kTechId.Infestation] = 49
kTechIdToMaterialOffset[kTechId.Contamination] = 168
kTechIdToMaterialOffset[kTechId.ContaminationTech] = 168
kTechIdToMaterialOffset[kTechId.Slap] = 50
kTechIdToMaterialOffset[kTechId.HiveHeal] = 51
kTechIdToMaterialOffset[kTechId.CragHeal] = 51
kTechIdToMaterialOffset[kTechId.DistressBeacon] = 52
kTechIdToMaterialOffset[kTechId.BoneWall] = 53
kTechIdToMaterialOffset[kTechId.BoneWallTech] = 53
kTechIdToMaterialOffset[kTechId.Scan] = 54
kTechIdToMaterialOffset[kTechId.NanoShieldSupport] = 55
kTechIdToMaterialOffset[kTechId.NanoShield] = 55
kTechIdToMaterialOffset[kTechId.NutrientMist] = 56
kTechIdToMaterialOffset[kTechId.Welding] = 57
kTechIdToMaterialOffset[kTechId.NanoArmor] = 202
kTechIdToMaterialOffset[kTechId.EvolveHallucinations] = 58
kTechIdToMaterialOffset[kTechId.EvolveEcho] = 59

kTechIdToMaterialOffset[kTechId.AdvancedMarineSupport] = 188
kTechIdToMaterialOffset[kTechId.PowerSurgeSupport] = 119
kTechIdToMaterialOffset[kTechId.PowerSurge] = 119

kTechIdToMaterialOffset[kTechId.EvolveBombard] = 60

----Crag-Hive
kTechIdToMaterialOffset[kTechId.Vampirism] = 173
kTechIdToMaterialOffset[kTechId.Carapace] = 61
kTechIdToMaterialOffset[kTechId.Regeneration] = 62

----Shift-Hive
kTechIdToMaterialOffset[kTechId.Adrenaline] = 63
kTechIdToMaterialOffset[kTechId.Celerity] = 64
kTechIdToMaterialOffset[kTechId.Crush] = 172

kTechIdToMaterialOffset[kTechId.Sneak] = 65

----Shade-Hive
kTechIdToMaterialOffset[kTechId.Camouflage] = 66
kTechIdToMaterialOffset[kTechId.Focus] = 174
kTechIdToMaterialOffset[kTechId.Aura] = 66


kTechIdToMaterialOffset[kTechId.HeavyRifleTech] = 73
kTechIdToMaterialOffset[kTechId.HeavyMachineGun] = 171
kTechIdToMaterialOffset[kTechId.HeavyMachineGunTech] = 171
kTechIdToMaterialOffset[kTechId.DropHeavyMachineGun] = 171
kTechIdToMaterialOffset[kTechId.Aura] = 113
kTechIdToMaterialOffset[kTechId.Leap] = 67
kTechIdToMaterialOffset[kTechId.BileBomb] = 68

-- Todo: Add new icons for new tunnel tech ids
kTechIdToMaterialOffset[kTechId.Tunnel] = 179
kTechIdToMaterialOffset[kTechId.BuildTunnelMenu] = 178
kTechIdToMaterialOffset[kTechId.BuildTunnelEntryOne] = 187
kTechIdToMaterialOffset[kTechId.BuildTunnelEntryTwo] = 187
kTechIdToMaterialOffset[kTechId.BuildTunnelEntryThree] = 187
kTechIdToMaterialOffset[kTechId.BuildTunnelEntryFour] = 187
kTechIdToMaterialOffset[kTechId.SelectTunnelEntryOne] = 177
kTechIdToMaterialOffset[kTechId.SelectTunnelEntryTwo] = 177
kTechIdToMaterialOffset[kTechId.SelectTunnelEntryThree] = 177
kTechIdToMaterialOffset[kTechId.SelectTunnelEntryFour] = 177
kTechIdToMaterialOffset[kTechId.UpgradeToInfestedTunnel] = 189
kTechIdToMaterialOffset[kTechId.InfestedTunnel] = 189
kTechIdToMaterialOffset[kTechId.TunnelExit] = 179
kTechIdToMaterialOffset[kTechId.BuildTunnelExitOne] = 186
kTechIdToMaterialOffset[kTechId.BuildTunnelExitTwo] = 186
kTechIdToMaterialOffset[kTechId.BuildTunnelExitThree] = 186
kTechIdToMaterialOffset[kTechId.BuildTunnelExitFour] = 186
kTechIdToMaterialOffset[kTechId.SelectTunnelExitOne] = 176
kTechIdToMaterialOffset[kTechId.SelectTunnelExitTwo] = 176
kTechIdToMaterialOffset[kTechId.SelectTunnelExitThree] = 176
kTechIdToMaterialOffset[kTechId.SelectTunnelExitFour] = 176
kTechIdToMaterialOffset[kTechId.TunnelRelocate] = 190
kTechIdToMaterialOffset[kTechId.TunnelCollapse] = 191

kTechIdToMaterialOffset[kTechId.Stab] = 105
kTechIdToMaterialOffset[kTechId.ShadowStep] = 160
kTechIdToMaterialOffset[kTechId.MetabolizeEnergy] = 169
kTechIdToMaterialOffset[kTechId.MetabolizeHealth] = 170
kTechIdToMaterialOffset[kTechId.Return] = 133
kTechIdToMaterialOffset[kTechId.EvolutionChamber] = 136
kTechIdToMaterialOffset[kTechId.MucousMembrane] = 110
kTechIdToMaterialOffset[kTechId.BabblerTech] = 115
kTechIdToMaterialOffset[kTechId.Babbler] = 115
kTechIdToMaterialOffset[kTechId.BabblerAbility] = 115
kTechIdToMaterialOffset[kTechId.BabblerEgg] = 114
kTechIdToMaterialOffset[kTechId.WebTech] = 102
kTechIdToMaterialOffset[kTechId.Web] = 102
kTechIdToMaterialOffset[kTechId.Spores] = 69
kTechIdToMaterialOffset[kTechId.Vortex] = 70
kTechIdToMaterialOffset[kTechId.Blink] = 71
kTechIdToMaterialOffset[kTechId.Charge] = 111
kTechIdToMaterialOffset[kTechId.Parasite] = 155

kTechIdToMaterialOffset[kTechId.FollowAlien] = 121
kTechIdToMaterialOffset[kTechId.Follow] = 121

kTechIdToMaterialOffset[kTechId.AlienBrain] = 154
kTechIdToMaterialOffset[kTechId.AlienMuscles] = 114
kTechIdToMaterialOffset[kTechId.DefensivePosture] = 167
kTechIdToMaterialOffset[kTechId.OffensivePosture] = 42

--MOD
kTechIdToMaterialOffset[kTechId.RifleUpgrade] = 192

kTechIdToMaterialOffset[kTechId.GrenadeLauncherSupply] = 197
kTechIdToMaterialOffset[kTechId.GrenadeLauncherAllyBlast] = 203
kTechIdToMaterialOffset[kTechId.GrenadeLauncherUpgrade] = 193
kTechIdToMaterialOffset[kTechId.GrenadeLauncherImpactShot] = 194
kTechIdToMaterialOffset[kTechId.GrenadeLauncherDetectionShot] = 204

kTechIdToMaterialOffset[kTechId.HeavyMachineGunSupply] = 195
kTechIdToMaterialOffset[kTechId.FlamethrowerSupply] = 196
kTechIdToMaterialOffset[kTechId.ShotgunSupply] = 198
kTechIdToMaterialOffset[kTechId.MinesSupply] = 199
kTechIdToMaterialOffset[kTechId.ExosuitSupply] = 200
kTechIdToMaterialOffset[kTechId.JetpackSupply] = 201


kTechIdToMaterialOffset[kTechId.Stomp] = 72
kTechIdToMaterialOffset[kTechId.BoneShield] = 156
kTechIdToMaterialOffset[kTechId.MACSpeedTech] = 73
kTechIdToMaterialOffset[kTechId.Detector] = 74  
kTechIdToMaterialOffset[kTechId.Umbra] = 75
kTechIdToMaterialOffset[kTechId.ShadeCloak] = 76
kTechIdToMaterialOffset[kTechId.Armor1] = 77
kTechIdToMaterialOffset[kTechId.Armor2] = 78
kTechIdToMaterialOffset[kTechId.Armor3] = 79
kTechIdToMaterialOffset[kTechId.WeaponsMenu] = 85
kTechIdToMaterialOffset[kTechId.ProtosMenu] = 89
kTechIdToMaterialOffset[kTechId.Weapons1] = 80
kTechIdToMaterialOffset[kTechId.Weapons2] = 81
kTechIdToMaterialOffset[kTechId.Weapons3] = 82
kTechIdToMaterialOffset[kTechId.UpgradeRoboticsFactory] = 83
kTechIdToMaterialOffset[kTechId.DualMinigunTech] = 84
kTechIdToMaterialOffset[kTechId.ClawRailgunTech] = 116
kTechIdToMaterialOffset[kTechId.DualRailgunTech] = 116
kTechIdToMaterialOffset[kTechId.ShotgunTech] = 85
kTechIdToMaterialOffset[kTechId.Shotgun] = 85
kTechIdToMaterialOffset[kTechId.DropShotgun] = 85
kTechIdToMaterialOffset[kTechId.Flamethrower] = 86
kTechIdToMaterialOffset[kTechId.FlamethrowerTech] = 86
kTechIdToMaterialOffset[kTechId.DropFlamethrower] = 86
kTechIdToMaterialOffset[kTechId.GrenadeTech] = 161
kTechIdToMaterialOffset[kTechId.ClusterGrenade] = 161
kTechIdToMaterialOffset[kTechId.GasGrenade] = 161
kTechIdToMaterialOffset[kTechId.PulseGrenade] = 161
kTechIdToMaterialOffset[kTechId.AdvancedWeaponry] = 140
kTechIdToMaterialOffset[kTechId.GrenadeLauncher] = 87
kTechIdToMaterialOffset[kTechId.GrenadeLauncherTech] = 87
kTechIdToMaterialOffset[kTechId.DropGrenadeLauncher] = 87
kTechIdToMaterialOffset[kTechId.WelderTech] = 88
kTechIdToMaterialOffset[kTechId.Welder] = 88   
kTechIdToMaterialOffset[kTechId.DropWelder] = 88
kTechIdToMaterialOffset[kTechId.JetpackTech] = 89
kTechIdToMaterialOffset[kTechId.Jetpack] = 89
kTechIdToMaterialOffset[kTechId.DropJetpack] = 89
kTechIdToMaterialOffset[kTechId.PhaseTech] = 90
kTechIdToMaterialOffset[kTechId.AmmoPack] = 91
kTechIdToMaterialOffset[kTechId.MedPack] = 92
kTechIdToMaterialOffset[kTechId.CatPackSupport] = 164
kTechIdToMaterialOffset[kTechId.CatPack] = 164
kTechIdToMaterialOffset[kTechId.PowerPoint] = 93
kTechIdToMaterialOffset[kTechId.SocketPowerNode] = 94
kTechIdToMaterialOffset[kTechId.Xenocide] = 95

kTechIdToMaterialOffset[kTechId.SpawnMarine] = 96
kTechIdToMaterialOffset[kTechId.SpawnAlien] = 97
kTechIdToMaterialOffset[kTechId.DrifterCamouflage] = 184
kTechIdToMaterialOffset[kTechId.AdvancedArmoryUpgrade] = 99    

kTechIdToMaterialOffset[kTechId.Spikes] = 106
kTechIdToMaterialOffset[kTechId.Recycle] = 108
kTechIdToMaterialOffset[kTechId.Consume] = 191
kTechIdToMaterialOffset[kTechId.Storm] = 113
kTechIdToMaterialOffset[kTechId.Patrol] = 120
kTechIdToMaterialOffset[kTechId.Move] = 117
kTechIdToMaterialOffset[kTechId.Stop] = 122
kTechIdToMaterialOffset[kTechId.Attack] = 123
kTechIdToMaterialOffset[kTechId.Cancel] = 124
kTechIdToMaterialOffset[kTechId.ShadePhantomMenu] = 125
kTechIdToMaterialOffset[kTechId.Hallucination] = 125
kTechIdToMaterialOffset[kTechId.ShadePhantomStructuresMenu] = 126
kTechIdToMaterialOffset[kTechId.BuildMenu] = 128
kTechIdToMaterialOffset[kTechId.AdvancedMenu] = 129 
kTechIdToMaterialOffset[kTechId.AssistMenu] = 130
kTechIdToMaterialOffset[kTechId.Construct] = 131
kTechIdToMaterialOffset[kTechId.AutoConstruct] = 131

kTechIdToMaterialOffset[kTechId.NeedHealingMarker] = 132
kTechIdToMaterialOffset[kTechId.RootMenu] = 133  
kTechIdToMaterialOffset[kTechId.HoldPosition] = 134
kTechIdToMaterialOffset[kTechId.LifeFormMenu] = 136    
kTechIdToMaterialOffset[kTechId.Biomass] = 112   
kTechIdToMaterialOffset[kTechId.ResearchBioMassOne] = 150   
kTechIdToMaterialOffset[kTechId.ResearchBioMassTwo] = 112 
kTechIdToMaterialOffset[kTechId.ResearchBioMassThree] = 175
kTechIdToMaterialOffset[kTechId.ResearchBioMassFour] = 112
kTechIdToMaterialOffset[kTechId.SetRally] = 137
kTechIdToMaterialOffset[kTechId.ThreatMarker] = 138
kTechIdToMaterialOffset[kTechId.ExpandingMarker] = 141
kTechIdToMaterialOffset[kTechId.Grow] = 141
kTechIdToMaterialOffset[kTechId.Defend] = 142

kTechIdToMaterialOffset[kTechId.Weld] = 127
kTechIdToMaterialOffset[kTechId.AutoWeld] = 127
kTechIdToMaterialOffset[kTechId.FollowAndWeld] = 142



kTechIdToMaterialOffset[kTechId.UpgradeToCragHive] = 157
kTechIdToMaterialOffset[kTechId.UpgradeToShadeHive] = 158
kTechIdToMaterialOffset[kTechId.UpgradeToShiftHive] = 159
kTechIdToMaterialOffset[kTechId.CragHive] = 157
kTechIdToMaterialOffset[kTechId.ShadeHive] = 158
kTechIdToMaterialOffset[kTechId.ShiftHive] = 159

kTechIdToMaterialOffset[kTechId.BellySlide] = 165
kTechIdToMaterialOffset[kTechId.Cling] = 166

kTechIdToMaterialOffset[kTechId.TeleportWhip] = 19
kTechIdToMaterialOffset[kTechId.TeleportTunnel] = 103
kTechIdToMaterialOffset[kTechId.TeleportCrag] = 18
kTechIdToMaterialOffset[kTechId.TeleportShade] = 21
kTechIdToMaterialOffset[kTechId.TeleportShift] = 20
kTechIdToMaterialOffset[kTechId.TeleportVeil] = 23
kTechIdToMaterialOffset[kTechId.TeleportSpur] = 11
kTechIdToMaterialOffset[kTechId.TeleportShell] = 22
kTechIdToMaterialOffset[kTechId.TeleportHive] = 2
kTechIdToMaterialOffset[kTechId.TeleportEgg] = 34
kTechIdToMaterialOffset[kTechId.TeleportHarvester] = 16

kTechIdToMaterialOffset[kTechId.HallucinateDrifter] = 37
kTechIdToMaterialOffset[kTechId.HallucinateSkulk] = 27
kTechIdToMaterialOffset[kTechId.HallucinateGorge] = 28
kTechIdToMaterialOffset[kTechId.HallucinateLerk] = 29
kTechIdToMaterialOffset[kTechId.HallucinateFade] = 30
kTechIdToMaterialOffset[kTechId.HallucinateOnos] = 31

kTechIdToMaterialOffset[kTechId.HallucinateHive] = 2
kTechIdToMaterialOffset[kTechId.HallucinateWhip] = 19
kTechIdToMaterialOffset[kTechId.HallucinateShade] = 21
kTechIdToMaterialOffset[kTechId.HallucinateCrag] = 18
kTechIdToMaterialOffset[kTechId.HallucinateShift] = 20
kTechIdToMaterialOffset[kTechId.HallucinateHarvester] = 16

kTechIdToMaterialOffset[kTechId.Hydra] = 100
kTechIdToMaterialOffset[kTechId.HydraTech] = 100
kTechIdToMaterialOffset[kTechId.Clog] = 114

kTechIdToMaterialOffset[kTechId.MarineAlertSentryUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertSoldierUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertStructureUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertExtractorUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertCommandStationUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertInfantryPortalUnderAttack] = 123

kTechIdToMaterialOffset[kTechId.MarineAlertCommandStationComplete] = 0
kTechIdToMaterialOffset[kTechId.MarineAlertConstructionComplete] = 131
kTechIdToMaterialOffset[kTechId.MarineAlertSentryFiring] = 5
kTechIdToMaterialOffset[kTechId.MarineAlertSoldierLost] = 96
kTechIdToMaterialOffset[kTechId.MarineAlertNeedAmmo] = 91
kTechIdToMaterialOffset[kTechId.MarineAlertNeedMedpack] = 92
kTechIdToMaterialOffset[kTechId.MarineAlertNeedOrder] = 24
kTechIdToMaterialOffset[kTechId.MarineAlertNeedStructure] = 24
kTechIdToMaterialOffset[kTechId.MarineAlertUpgradeComplete] = 101
kTechIdToMaterialOffset[kTechId.MarineAlertResearchComplete] = 101
kTechIdToMaterialOffset[kTechId.MarineAlertManufactureComplete] = 131

kTechIdToMaterialOffset[kTechId.AlienAlertNeedMist] = 56
kTechIdToMaterialOffset[kTechId.AlienAlertNeedDrifter] = 37
kTechIdToMaterialOffset[kTechId.AlienAlertHiveUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertStructureUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertHarvesterUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertLifeformUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertHiveDying] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertHiveComplete] = 2

kTechIdToMaterialOffset[kTechId.AlienAlertUpgradeComplete] = 101
kTechIdToMaterialOffset[kTechId.AlienAlertResearchComplete] = 101
kTechIdToMaterialOffset[kTechId.AlienAlertManufactureComplete] = 131

function GetMaterialXYOffset(techId)

    local index
    
    local columns = 12
    index = kTechIdToMaterialOffset[techId]
    
    if not index then
        DebugPrint("Warning: %s did not define kTechIdToMaterialOffset ", EnumToString(kTechId, techId) )
    else
    
        local x = index % columns
        local y = math.floor(index / columns)
        return x, y
        
    end
    
    return nil, nil
    
end

function GetPixelCoordsForIcon(ent, forMarine)
    
    if ent and HasMixin(ent, "Tech") then
    
        local techId = ent:GetTechId()        
        if techId ~= kTechId.None then
            
            local xOffset, yOffset = GetMaterialXYOffset(techId, forMarine)
            return {xOffset, yOffset}
            
        end
                    
    end
    
    return nil
    
end
