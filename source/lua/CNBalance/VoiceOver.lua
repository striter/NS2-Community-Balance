local kAlienTauntSounds =
{
    [kTechId.Skulk] = "sound/NS2.fev/alien/voiceovers/chuckle",
    [kTechId.Gorge] = "sound/NS2.fev/alien/gorge/taunt",
    [kTechId.Lerk] = "sound/NS2.fev/alien/lerk/taunt",
    [kTechId.Fade] = "sound/NS2.fev/alien/fade/taunt",
    [kTechId.Onos] = "sound/NS2.fev/alien/onos/wound_serious",
    [kTechId.Embryo] = "sound/NS2.fev/alien/common/swarm",
    [kTechId.ReadyRoomEmbryo] = "sound/NS2.fev/alien/common/swarm",
    [kTechId.Prowler] = "sound/NS2.fev/alien/drifter/ordered",
    [kTechId.Vokex] = "sound/NS2.fev/alien/fade/taunt",
    
}


for _, tauntSound in pairs(kAlienTauntSounds) do
    PrecacheAsset(tauntSound)
end

local kSoundData = debug.getupvaluex(GetVoiceSoundData, "kSoundData")

local function GetLifeFormSound(player)

    if player and (player:isa("Alien") or player:isa("ReadyRoomEmbryo")) then    
        return kAlienTauntSounds[player:GetTechId()] or ""    
    end
    
    return ""

end

local addAlienSounds = true

function GetVoiceSoundData(voiceId)
    if addAlienSounds then

        kSoundData[kVoiceId.AlienTaunt].Function = GetLifeFormSound

        addAlienSounds = false
    end
    
    return kSoundData[voiceId]
end

local kRequestMenus = debug.getupvaluex(GetRequestMenu, "kRequestMenus")

local kAlienMenu =
{
    [LEFT_MENU] = { kVoiceId.AlienRequestHealing, kVoiceId.AlienRequestDrifter, kVoiceId.AlienRequestStructure, kVoiceId.Ping },
    [RIGHT_MENU] = { kVoiceId.AlienTaunt, kVoiceId.AlienChuckle }    
}

kRequestMenus["Prowler"] = kAlienMenu
kRequestMenus["Vokex"] = kAlienMenu
