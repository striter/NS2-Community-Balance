
local GetPickupTextureCoordinates = debug.getupvaluex(GUIPickups.Update, "GetPickupTextureCoordinates")
local kPickupTypes = debug.getupvaluex(GetPickupTextureCoordinates, "kPickupTypes")
table.insert(kPickupTypes, "Revolver")
local kPickupTextureYOffsets = debug.getupvaluex(GetPickupTextureCoordinates, "kPickupTextureYOffsets")
kPickupTextureYOffsets["Revolver"] = 13