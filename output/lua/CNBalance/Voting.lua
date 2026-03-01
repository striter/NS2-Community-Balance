--Server Switch
RegisterVoteType("VoteDisease", {})

if Client then

    local function SetupAdditionalVotes(voteMenu)
        if Shine then
            voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_RANDOM_SCALE"),nil, function( msg )
                AttemptToStartVote("VoteRandomScale", { })
            end)
            
            AddVoteStartListener("VoteRandomScale", function(msg)
                return Locale.ResolveString("VOTE_RANDOM_SCALE_QUERY")
            end)
        end
    end
    AddVoteSetupCallback(SetupAdditionalVotes)

end

if Server then
    SetVoteSuccessfulCallback("VoteRandomScale", 1, function( msg )
        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            if player.SetPlayerScale then
                local random = 0.25 + math.random() * 1.5
                player:SetPlayerScale(random)
            end
        end
    end)
end