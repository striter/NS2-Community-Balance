local baseCreateMarineComSense = CreateMarineComSenses
function CreateMarineComSenses()
    local s = baseCreateMarineComSense()
    s:Add("mainStandardStation", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local commandStationsInMainBase = GetEntitiesAliveForTeamByLocationWithTechId( "CommandStation", db.bot:GetTeamNumber(), startingLocationId ,kTechId.StandardStation)

        if #commandStationsInMainBase > 0 then
            return commandStationsInMainBase[1]
        end

    end)
    
    s:Add("mainJetpackLab", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocationWithTechId( "PrototypeLab", db.bot:GetTeamNumber(), startingLocationId, kTechId.JetpackPrototypeLab )
        if #units > 0 then
            return units[1]
        end
    end)

    s:Add("mainExosuitLab", function(db)
        local startingLocationId = Shared.GetStringIndex(db.bot.brain:GetStartingTechPoint() or "")
        local units = GetEntitiesAliveForTeamByLocationWithTechId( "PrototypeLab", db.bot:GetTeamNumber(), startingLocationId, kTechId.ExosuitPrototypeLab )
        if #units > 0 then
            return units[1]
        end
    end)
    
    return s
end
