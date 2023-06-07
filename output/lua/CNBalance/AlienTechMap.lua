
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

kAlienTechMap =
{
    { kTechId.Whip, 5.5, 0.5 }, { kTechId.Shift, 6.5, 0.5 }, { kTechId.Shade, 7.5, 0.5 }, { kTechId.Crag, 8.5, 0.5 },
    { kTechId.Harvester, 4, 1.5 }, { kTechId.Hive, 7, 1.5 }, { kTechId.Drifter, 10, 1.5 },
    { kTechId.ShiftHive, 4, 3 }, { kTechId.ShadeHive, 7, 3 }, { kTechId.CragHive, 10, 3 },

    { kTechId.DrifterCelerity, 5, 3 },  { kTechId.DrifterCamouflage, 8, 3 }, { kTechId.DrifterRegeneration, 11, 3 },

    { kTechId.CystCelerity, 3, 3 }, { kTechId.CystCamouflage, 6, 3 }, { kTechId.CystCarapace, 9, 3 },

    --FIXME Update and correct all icon positions
    { kTechId.ShiftTunnel,3.5 , 4},{ kTechId.Spur, 4.5, 4, SetSpurIcon },
    { kTechId.ShadeTunnel,6.5 , 4},{ kTechId.Veil, 7.5, 4, SetVeilIcon },
    { kTechId.CragTunnel,9.5 , 4},{ kTechId.Shell, 10.5, 4, SetShellIcon },

    { kTechId.Crush, 3, 5 },
    { kTechId.Celerity, 4, 5 },
    { kTechId.Adrenaline, 5, 5 },

    { kTechId.Focus, 6, 5 },
    { kTechId.Camouflage, 7, 5 },
    { kTechId.Aura, 8, 5 },

    { kTechId.Vampirism, 9, 5 },
    { kTechId.Carapace, 10, 5 },
    { kTechId.Regeneration, 11, 5 },

                                        { kTechId.BioMassOne, 1.5, 8, nil, "1" }, {kTechId.ShadowStep, 1.5, 9},
    {kTechId.Rupture, 2.5, 7},          { kTechId.BioMassTwo, 2.5, 8, nil, "2" }, { kTechId.Devour, 2.5, 9 },{kTechId.Web, 2.5, 10},
    {kTechId.BoneWall, 3.5, 7},         { kTechId.BioMassThree, 3.5, 8, nil, "3" },  { kTechId.MetabolizeEnergy, 3.5, 9 }, {kTechId.BileBomb, 3.5, 10},
                                        { kTechId.BioMassFour, 4.5, 8, nil, "4" }, {kTechId.Leap, 4.5, 9},{kTechId.Spores, 4.5, 10},{kTechId.BabblerEgg, 4.5, 11}, 
                                        { kTechId.BioMassFive, 5.5, 8, nil, "5" }, {kTechId.MetabolizeHealth, 5.5, 9},{kTechId.AcidRocket, 5.5, 10},
                                        { kTechId.BioMassSix, 6.5, 8, nil, "6" },  {kTechId.AcidSpray, 6.5, 9},{kTechId.Umbra, 6.5, 10}, {kTechId.BoneShield, 6.5, 11},
                                        { kTechId.BioMassSeven, 7.5, 8, nil, "7" }, {kTechId.Xenocide, 7.5, 9},{kTechId.Stab, 7.5, 10},
                                        { kTechId.BioMassEight, 8.5, 8, nil, "8" }, {kTechId.Stomp, 8.5, 9},
                                        { kTechId.BioMassNine, 9.5, 8, nil, "9" },
    {kTechId.Contamination, 10.5, 7},   { kTechId.BioMassTen, 10.5, 8, nil, "10" },  {kTechId.XenocideFuel, 10.5, 9},
                                        { kTechId.BioMassEleven, 11.5, 8, nil, "11" },
                                        { kTechId.BioMassTwelve, 12.5, 8, nil, "12" },
}
