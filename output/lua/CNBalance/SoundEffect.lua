if Client then

    local function CustomBalanceVoice(self)
        if not self.balanceVoice then
            self.balanceVoice = nil
            return
        end
        if self.playing and self.soundEffectInstance then
            local volume = OptionsDialogUI_GetSoundVolume() / 100
            volume = volume * (gMuteCustomVoices and 0 or 1)
            if self.volume ~= volume then
                self.volume = volume
                self.soundEffectInstance:SetVolume(volume)
            end
        end
    end

    local baseOnInitialized = SoundEffect.OnInitialized
    function SoundEffect:OnInitialized()
        baseOnInitialized(self)
        local assetName = Shared.GetSoundName(self.assetIndex)
        self.balanceVoice = string.find(assetName, "ns2plus.fev") ~= nil
    end

    local baseOnUpdate = SoundEffect.OnUpdate
    function SoundEffect:OnUpdate(deltaTime)
        baseOnUpdate(self)
        CustomBalanceVoice(self)
    end
    --
    --local baseOnProcessMove = SoundEffect.OnProcessMove
    --function SoundEffect:OnProcessMove()
    --    baseOnProcessMove(self)
    --    CustomBalanceVoice(self)
    --end
    --
    --local baseOnProcessSpectate = SoundEffect.OnProcessSpectate
    --function SoundEffect:OnProcessSpectate()
    --    baseOnProcessSpectate(self)
    --    CustomBalanceVoice(self)
    --end

    -- Effects
    local function GetVolume(soundEffectName,volume)
        if string.find(soundEffectName, "ns2plus.fev") ~= nil then
            volume = volume or 1
            volume = volume * OptionsDialogUI_GetSoundVolume() / 100
        end
        return volume
    end

    local baseStartSoundEffectAtOrigin = StartSoundEffectAtOrigin
    function StartSoundEffectAtOrigin(soundEffectName, atOrigin, volume, predictor)
        baseStartSoundEffectAtOrigin(soundEffectName, atOrigin, GetVolume(soundEffectName,volume), predictor)
    end

    local baseStartSoundEffectOnEntity = StartSoundEffectOnEntity
    function StartSoundEffectOnEntity(soundEffectName, onEntity, volume, predictor)
        baseStartSoundEffectOnEntity(soundEffectName,onEntity,GetVolume(soundEffectName,volume),predictor)
    end

    local baseStartSoundEffect = StartSoundEffect
    function StartSoundEffect(soundEffectName, volume, pitch)
        baseStartSoundEffect(soundEffectName, GetVolume(soundEffectName,volume), pitch)
    end

    local baseStartSoundEffectForPlayer = StartSoundEffectForPlayer
    function StartSoundEffectForPlayer(soundEffectName, forPlayer, volume)
        baseStartSoundEffectForPlayer(soundEffectName, forPlayer, GetVolume(soundEffectName,volume))
    end



end
