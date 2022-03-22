
local GetPickupTextureCoordinates = debug.getupvaluex(GUIPickups.Update, "GetPickupTextureCoordinates")
local kPickupTypes = debug.getupvaluex(GetPickupTextureCoordinates, "kPickupTypes")
table.insert(kPickupTypes, "Revolver")
table.insert(kPickupTypes, "Submachinegun")
table.insert(kPickupTypes, "Cannon")
local kPickupTextureYOffsets = debug.getupvaluex(GetPickupTextureCoordinates, "kPickupTextureYOffsets")
kPickupTextureYOffsets["Revolver"] = 13
kPickupTextureYOffsets["Submachinegun"] = 14
kPickupTextureYOffsets["Cannon"] = 15