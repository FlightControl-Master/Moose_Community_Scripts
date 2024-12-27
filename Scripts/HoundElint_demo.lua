do
   
    if MSRS ~= nil then
      -- mostly using defaults from our Moose MSRS config file
      HOUND.MSRS = MSRS:New("E:\\Program Files\\DCS-SimpleRadio-Standalone",251,radio.modulation.AM,MSRS.Backend.GRPC)
      HOUND.MSRS:SetVoiceGoogle(MSRS.Voices.Google.Standard.en_GB_Standard_N)
      HOUND.MSRS:SetTTSProviderGoogle()
      HOUND.MSRSQ = MSRSQUEUE:New("HOUND")
    end
    
    HOUND.USE_LEGACY_MARKS = false
    HOUND.TTS_ENGINE = {'MSRS'}

end

do
    Elint_blue = HoundElint:create(coalition.side.BLUE)

    Elint_blue:preBriefedContact('PB-test-1')
    Elint_blue:systemOn()

    -- Elint_blue:addPlatform("ELINT_C17")
    -- Elint_blue:addPlatform("ELINT_C130")
    Elint_blue:addPlatform("Kokotse_Elint")
    Elint_blue:addPlatform("Khvamli_Elint")
    Elint_blue:addPlatform("Migariya_Elint")
    -- Elint_blue:addPlatform("Cow")
    
    
    -- Radios need slightly different setup in Moose, not strings, but numbers
    tts_args = {
        freq = "251.000,127.500,35.000",
        modulation = "AM,AM,FM",
        mfreq = {251.000,127.500,35.000}, -- Moose config
        mmodulation = {radio.modulation.AM,radio.modulation.AM,radio.modulation.FM}, -- Moose config
        gender = "female",
        voice = "en-US-Standard-F", -- Google needs a voice set
        googleTTS = true
    }
    atis_args = {
        freq = 251.500,
        modulation = "AM",
        mfreq = 251.500,
        mmodulation = radio.modulation.AM,
        voice = "en-US-Standard-E", -- Google needs a voice set
        NATO = false,
    }

    notifier_args = {
        freq = "305.000,127.000",
        modulation = "AM,AM",
        mfreq = {305.000,127.000},
        mmodulation = {radio.modulation.AM,radio.modulation.AM},
        voice = "en-US-Standard-B", -- Google needs a voice set
        gender = "male"
    }
    Elint_blue:configureController(tts_args)
    Elint_blue:configureAtis(atis_args)
    Elint_blue:configureNotifier(notifier_args)

    Elint_blue:enableController()
    Elint_blue:enableText()
    Elint_blue:enableAtis()
    Elint_blue:enableNotifier()
    -- Elint_blue:disableBDA()
    Elint_blue:setMarkerType(HOUND.MARKER.POLYGON)
    -- Elint_blue:setMarkerType(HOUND.MARKER.SITE_ONLY)


    Elint_blue:addSector("Fake")
    Elint_blue:setZone("Fake")
    Elint_blue:setAlertOnLaunch(true)
    -- Elint_blue:onScreenDebug(true)
    Elint_blue:enablePlatformPosErrors()

    local callsignOverride = {
        Uzi = "Tulip",
        Chevy = "*"
    }

    Elint_blue:setCallsignOverride(callsignOverride)

    -- test death
    Elint_blue.onHoundEvent = function(self,event)
        if event.id == HOUND.EVENTS.RADAR_DESTROYED or event.id == HOUND.EVENTS.SITE_ASLEEP or event.id == HOUND.EVENTS.SITE_REMOVED then
            HOUND.Logger.debug("Event triggered! " .. HOUND.reverseLookup(HOUND.EVENTS,event.id) .. " for " .. event.initiator:getName())
        end
    end
end


