
local function CheckHasTech(techId)

    local techTree = GetTechTree()
    return techTree ~= nil and techTree:GetHasTech(techId)

end

local function SetShellIcon(icon)

    if CheckHasTech(kTechId.ThreeShells) then
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.ThreeShells)))
    elseif CheckHasTech(kTechId.TwoShells) then
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.TwoShells)))
    else
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.Shell)))
    end

end

local function SetVeilIcon(icon)

    if CheckHasTech(kTechId.ThreeVeils) then
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.ThreeVeils)))
    elseif CheckHasTech(kTechId.TwoVeils) then
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.TwoVeils)))
    else
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.Veil)))
    end

end

local function SetSpurIcon(icon)

    if CheckHasTech(kTechId.ThreeSpurs) then
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.ThreeSpurs)))
    elseif CheckHasTech(kTechId.TwoSpurs) then
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.TwoSpurs)))
    else
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.Spur)))
    end

end

local function GetBiomassPreservation(techId)
    local teamInfo = GetTeamInfoEntity(kAlienTeamType)
    if techId == kTechId.ShiftHive then
        return teamInfo.shiftHiveBiomassPreserve
    elseif techId == kTechId.ShadeHive then
        return teamInfo.shadeHiveBiomassPreserve
    elseif techId == kTechId.CragHive then
        return teamInfo.cragHiveBiomassPreserve
    end
    
end

local function ApplyBiomassPreservationToIcon(icon,level)

    if level == 3 then
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.RecoverBiomassTwo)))
    elseif level == 4 then
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.RecoverBiomassThree)))
    else
        icon:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.RecoverBiomassOne)))
    end
end

local function GetShiftHiveBiomassPreservation(icon)
    ApplyBiomassPreservationToIcon(icon,GetBiomassPreservation(kTechId.ShiftHive))
end
local function GetShadeHiveBiomassPreservation(icon)
    ApplyBiomassPreservationToIcon(icon,GetBiomassPreservation(kTechId.ShadeHive))
end
local function GetCragHiveBiomassPreservation(icon)
    ApplyBiomassPreservationToIcon(icon,GetBiomassPreservation(kTechId.CragHive))
end

kAlienTechMap =
{
                                         { kTechId.OriginForm , 7 , -1},    { kTechId.DropTeamStructureAbility , 9 , -1},
                                 
    { kTechId.Whip, 5.5, 0.5 }, { kTechId.Shift, 6.5, 0.5 }, { kTechId.Shade, 7.5, 0.5 }, { kTechId.Crag, 8.5, 0.5 },
    { kTechId.Harvester, 4, 1.5 }, { kTechId.Hive, 7, 1.5 }, { kTechId.Drifter, 10, 1.5 },
    { kTechId.ShiftHive, 4, 3 }, { kTechId.ShadeHive, 7, 3 }, { kTechId.CragHive, 10, 3 },
    
    --FIXME Update and correct all icon positions

    { kTechId.ShiftTunnel,3 , 4},{ kTechId.Spur, 4, 4, SetSpurIcon }, { kTechId.ShiftHiveBiomassPreserve,5 , 4,GetShiftHiveBiomassPreservation},
    { kTechId.ShadeTunnel,6 , 4},{ kTechId.Veil, 7, 4, SetVeilIcon }, { kTechId.ShadeHiveBiomassPreserve,8 , 4,GetShadeHiveBiomassPreservation},
    { kTechId.CragTunnel,9 , 4},{ kTechId.Shell, 10, 4, SetShellIcon }, { kTechId.CragHiveBiomassPreserve,11 , 4,GetCragHiveBiomassPreservation},
    
    { kTechId.CystCelerity, 3, 3 }, { kTechId.CystCamouflage, 6, 3 }, { kTechId.CystCarapace, 9, 3 },
    { kTechId.DrifterCelerity, 5, 3 },  { kTechId.DrifterCamouflage, 8, 3 }, { kTechId.DrifterRegeneration, 11, 3 },

    { kTechId.Silence, 2, 5 },
    { kTechId.Crush, 3, 5 },
    { kTechId.Celerity, 4, 5 },
    { kTechId.Adrenaline, 5, 5 },

    { kTechId.Focus, 6, 5 },
    { kTechId.Camouflage, 7, 5 },
    { kTechId.Aura, 8, 5 },

    { kTechId.Vampirism, 9, 5 },
    { kTechId.Carapace, 10, 5 },
    { kTechId.Regeneration, 11, 5 }, 
    { kTechId.Condense, 12, 5 },

                                        { kTechId.BioMassOne, 1.5, 8, nil, "1" }, {kTechId.ShadowStep, 1.5, 9},--{kTechId.Web, 1.5, 10},
    {kTechId.Rupture, 2.5, 7},          { kTechId.BioMassTwo, 2.5, 8, nil, "2" },  { kTechId.MetabolizeEnergy, 2.5, 9 }, {kTechId.BabblerEgg, 2.5, 10},
    {kTechId.BoneWall, 3.5, 7},         { kTechId.BioMassThree, 3.5, 8, nil, "3" }, { kTechId.BileBomb, 3.5, 9 },{ kTechId.Devour, 3.5, 10},
                                        { kTechId.BioMassFour, 4.5, 8, nil, "4" }, { kTechId.Leap, 4.5, 9}, {kTechId.Spores, 4.5, 10},
                                        { kTechId.BioMassFive, 5.5, 8, nil, "5" }, { kTechId.BoneShield, 5.5, 9}, { kTechId.MetabolizeHealth, 5.5, 10},{kTechId.AcidRocket, 5.5, 11},
                                        { kTechId.BioMassSix, 6.5, 8, nil, "6" },  { kTechId.Umbra, 6.5, 9},{kTechId.AcidSpray, 6.5, 10},
                                        { kTechId.BioMassSeven, 7.5, 8, nil, "7" }, { kTechId.Xenocide, 7.5, 9},{kTechId.Stab, 7.5, 10},
                                        { kTechId.BioMassEight, 8.5, 8, nil, "8" }, { kTechId.Stomp, 8.5, 9},{kTechId.VortexShadowStep, 8.5, 10 },
                                        { kTechId.BioMassNine, 9.5, 8, nil, "9" },
    {kTechId.Contamination, 10.5, 7},   { kTechId.BioMassTen, 10.5, 8, nil, "10" },  {kTechId.XenocideFuel, 10.5, 9},
                                        { kTechId.BioMassEleven, 11.5, 8, nil, "11" },
                                        { kTechId.BioMassTwelve, 12.5, 8, nil, "12" },
}

kAlienLines =
{
    GetLinePositionForTechMap(kAlienTechMap, kTechId.OriginForm, kTechId.Hive),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.OriginForm, kTechId.DropTeamStructureAbility),
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Crag),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Shift),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Shade),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Whip),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.Harvester, kTechId.Hive),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Hive, kTechId.Drifter),
    { 7, 1.5, 7, 2.5 },
    { 4, 2.5, 10, 2.5},
    { 4, 2.5, 4, 3},{ 7, 2.5, 7, 3},{ 10, 2.5, 10, 3},
    GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.Shell),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.Veil),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.Spur),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.CragTunnel),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.ShadeTunnel),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.ShiftTunnel),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.DrifterRegeneration),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.DrifterCamouflage),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.DrifterCelerity),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.CystCarapace),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.CystCamouflage),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.CystCelerity),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.CragHive, kTechId.CragHiveBiomassPreserve),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShadeHive, kTechId.ShadeHiveBiomassPreserve),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.ShiftHive, kTechId.ShiftHiveBiomassPreserve),
    
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Carapace, kTechId.Vampirism),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Shell, kTechId.Carapace),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Carapace, kTechId.Regeneration),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Regeneration, kTechId.Condense),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.Camouflage, kTechId.Focus),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Veil, kTechId.Camouflage),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Camouflage, kTechId.Aura),

    GetLinePositionForTechMap(kAlienTechMap, kTechId.Silence, kTechId.Crush),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Celerity, kTechId.Crush),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Spur, kTechId.Celerity),
    GetLinePositionForTechMap(kAlienTechMap, kTechId.Celerity, kTechId.Adrenaline),

}