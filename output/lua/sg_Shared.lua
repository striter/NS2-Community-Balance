--
--	ns2siege+ Custom Game Mode
--	ZycaR (c) 2016
--
Script.Load("lua/sg_FuncDoor.lua")
Script.Load("lua/sg_FuncMaid.lua")
Script.Load("lua/sg_SiegeDoor.lua")
Script.Load("lua/sg_FrontDoor.lua")
Script.Load("lua/sg_SideDoor.lua")
Script.Load("lua/sg_BreakableDoor.lua")
Script.Load("lua/sg_NetworkMessages.lua")

kSignalFuncMaid = "func_maid_signal"

kFrontDoorType = 0
kSiegeDoorType = 1

kDoorTypeToSiegeMessage = {}
kDoorTypeToSiegeMessage[kFrontDoorType] = kSiegeMessageTypes.FrontDoorOpened
kDoorTypeToSiegeMessage[kSiegeDoorType] = kSiegeMessageTypes.SiegeDoorOpened
