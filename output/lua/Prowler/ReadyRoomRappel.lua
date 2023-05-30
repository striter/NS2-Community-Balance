-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\ReadyRoomRappel.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- Swipe/blink - Left-click to attack, right click to show ghost. When ghost is showing,
-- right click again to go there. Left-click to cancel. Attacking many times in a row will create
-- a cool visual "chain" of attacks, showing the more flavorful animations in sequence.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Prowler/RappelMixin.lua")

class 'ReadyRoomRappel' (Ability)
ReadyRoomRappel.kMapName = "ready_room_rappel"

local networkVars =
{
}

function ReadyRoomRappel:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, RappelMixin)
    
    self.primaryAttacking = false
    self.secondaryAttacking = false

end

function ReadyRoomRappel:GetAnimationGraphName()
    return kAnimationGraph
end

function ReadyRoomRappel:GetHUDSlot()
    return 1
end

function ReadyRoomRappel:GetSecondaryTechId()
    return kTechId.Rappel
end

function ReadyRoomRappel:GetViewModelName()
    return ""
end

Shared.LinkClassToMap("ReadyRoomRappel", ReadyRoomRappel.kMapName, networkVars)