
local GetPickupTextureCoordinates = debug.getupvaluex(GUIPickups.Update, "GetPickupTextureCoordinates")
local kPickupTypes = debug.getupvaluex(GetPickupTextureCoordinates, "kPickupTypes")
table.insert(kPickupTypes, "Revolver")
table.insert(kPickupTypes, "SubMachineGun")
table.insert(kPickupTypes, "LightMachineGun")
table.insert(kPickupTypes, "Cannon")
table.insert(kPickupTypes, "CombatBuilder")
local kPickupTextureYOffsets = debug.getupvaluex(GetPickupTextureCoordinates, "kPickupTextureYOffsets")
kPickupTextureYOffsets["Revolver"] = 13
kPickupTextureYOffsets["SubMachineGun"] = 14
kPickupTextureYOffsets["Cannon"] = 15
kPickupTextureYOffsets["LightMachineGun"] = 16
kPickupTextureYOffsets["CombatBuilder"] = 17