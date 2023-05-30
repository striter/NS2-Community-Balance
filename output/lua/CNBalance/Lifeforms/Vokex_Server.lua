-- // ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
-- //
-- // lua\Fade_Server.lua
-- //
-- //    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
-- //                  Max McGuire (max@unknownworlds.com)
-- //
-- // ========= For more information, visit us at http://www.unknownworlds.com =====================

function Vokex:InitWeapons()

    Alien.InitWeapons(self)
    
    self:GiveItem(SwipeShadowStep.kMapName)
    self:SetActiveWeapon(SwipeShadowStep.kMapName)
    
end

function Vokex:InitWeaponsForReadyRoom()
    
    Alien.InitWeaponsForReadyRoom(self)
    
    self:GiveItem(ReadyRoomShadowStep.kMapName)
    self:SetActiveWeapon(ReadyRoomShadowStep.kMapName)
    
end

function Vokex:GetTierOneTechId()
    return kTechId.MetabolizeShadowStep
end

function Vokex:GetTierTwoTechId()
    return kTechId.MetabolizeHealth
end

function Vokex:GetTierThreeTechId()
    return kTechId.AcidRocket
end