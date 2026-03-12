Script.Load("lua/TechTreeConstants.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

---Contains helpful values that are used in multiple files.
Bishop.lib.constants = {}

---@class Alert
---@field entityId integer
---@field techId integer

---@class kTechId
---@field AdvancedWeaponry integer
---@field AmmoPack integer
---@field Armory integer
---@field Cyst integer
---@field DualMinigunExosuit integer
---@field DualRailgunExosuit integer
---@field ExosuitTech integer
---@field Fade integer
---@field Flamethrower integer
---@field Gorge integer
---@field GrenadeLauncher integer
---@field HeavyMachineGun integer
---@field Jetpack integer
---@field JetpackTech integer
---@field Lerk integer
---@field MarineAlertNeedAmmo integer
---@field MarineAlertNeedMedpack integer
---@field MedPack integer
---@field None integer
---@field Onos integer
---@field PhaseGate integer
---@field Rifle integer
---@field Sentry integer
---@field SentryBattery integer
---@field Shotgun integer
---@field ShotgunTech integer
---@field Skulk integer

---Map of player class names to their associated kTechId enum entries.
---@type table<string, integer>
Bishop.lib.constants.kClassNameToTechId = {
  ["Fade"] = kTechId.Fade,
  ["Gorge"] = kTechId.Gorge,
  ["Lerk"] = kTechId.Lerk,
  ["Onos"] = kTechId.Onos,
  ["Skulk"] = kTechId.Skulk
}

---@class Action
---@field name string
---@field perform function
---@field weight number
---@field validate function?
---@field fastUpdate boolean?
---@field memory TeamBrain.Memory?

---@class ActionBuy : Action
---@field building ScriptActor
---@field techId integer
---@field usePosition Vector?

---@class ActionEntPos : Action
---@field entId integer
---@field position Vector

---A generic zero weight action that performs nothing.
---@type Action
Bishop.lib.constants.kNilAction = {
  name = "nil",
  perform = function() end,
  weight = 0.0
}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
