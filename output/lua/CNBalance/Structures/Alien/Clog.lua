function Clog:GetExtraHealth(techLevel,extraPlayers,recentWins)
   return techLevel * kClogHealthPerBioMass + extraPlayers * 5
end