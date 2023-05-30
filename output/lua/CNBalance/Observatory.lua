function Observatory:GetTechButtons(techId)

    if techId == kTechId.RootMenu then
        return  { kTechId.Scan, kTechId.DistressBeacon, kTechId.None, kTechId.Detector,
        kTechId.PhaseTech, kTechId.None, kTechId.None, kTechId.None }
    end

    return nil

end