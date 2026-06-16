local networkVars =
{
    endPoint = "vector",
    isOneSided = "boolean",
}

AddMixinNetworkVars(TeamMixin, networkVars)

Shared.LinkClassToMap("MapConnector", MapConnector.kMapName, networkVars)

function MapConnector:GetIsConnectionOneSided()
    return self.isOneSided
end
