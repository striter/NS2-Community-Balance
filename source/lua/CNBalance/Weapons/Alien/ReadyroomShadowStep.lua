Script.Load("lua/CNBalance/Weapons/Alien/ShadowStep.lua")

class 'ReadyRoomShadowStep' (ShadowStep)
ReadyRoomShadowStep.kMapName = "ready_room_shadowstep"

local networkVars =
{
}

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

function ReadyRoomShadowStep:OnCreate()

    ShadowStep.OnCreate(self)
    
    self.primaryAttacking = false

end

function ReadyRoomShadowStep:GetAnimationGraphName()
    return kAnimationGraph
end

function ReadyRoomShadowStep:GetHUDSlot()
    return 1
end

function ReadyRoomShadowStep:GetSecondaryTechId()
    return kTechId.ShadowStep
end

function ReadyRoomShadowStep:GetShadowStepAllowed()
    return true
end

function ReadyRoomShadowStep:GetViewModelName()
    return ""
end

Shared.LinkClassToMap("ReadyRoomShadowStep", ReadyRoomShadowStep.kMapName, networkVars)