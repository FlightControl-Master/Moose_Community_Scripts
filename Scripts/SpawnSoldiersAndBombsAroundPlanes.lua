------------------------------------------------------------------------------------------------
---SET_CLIENT
-------------------------------------------------------------------------------------------------
-- Create a set of all blue coalition clients
ClientSet = SET_CLIENT:New()
ClientSet:HandleEvent(EVENTS.PlayerEnterAircraft)

function ClientSet:OnEventPlayerEnterAircraft(EventData)
    local PlayerGroup = EventData.IniGroup
    local PlayerUnit = EventData.IniUnit
    local PlayerUnitName = EventData.IniPlayerName
    local PlayerCoord = PlayerUnit:GetCoordinate()

    -- Log the Player Group and Unit names
    if PlayerGroup then
        env.info("DEBUG: Player Group Name: " .. PlayerGroup:GetName())
    else
        env.info("DEBUG: Player Group is nil.")
    end

    if PlayerUnit then
        env.info("DEBUG: Player Unit Name: " .. PlayerUnit:GetName())
    else
        env.info("DEBUG: Player Unit is nil.")
    end

    local spawnBASE = PlayerCoord:GetClosestAirbase()
    local messageText = "Welcome " .. PlayerUnitName .. " to " .. spawnBASE:GetName() ..
        "\n\nTraining: \n -A2A, A2G, and A2S Training Available via the Radio Menu (F10: Other) \n\nA2G Range:\n -JTAC Lasing message will appear automatically when you enter the A2G Coastal Range (if you've activated the drone) \n\nWAYPOINTS:\n -WPT: 1 Jets on Ramp (A2G Range)\n -WPT: 2 Stationary Tanks (A2G Range - Lasing)\n -WPT: 3 Mobile Tanks (A2G Range)\n -WPT: 4 Mobile Trucks (A2G Range)\n -WPT: 5 Strafing Pit Jets (A2G Range, Approach from 135, Fire At >2,000 Ft)\n -WPT: 6 Strafe Pit (A2G Range, Approach from 135, Fire At >2,000 Ft)\n -WPT: 7 A2A Training Zone (West)\n -WPT: 8 SAM Training Zone\n -WPT: 9 A2A Training Zone (East)\n\nATIS: \n -Tune to 261.00 for Kobuleti Runway, TACAN, ILS, and Weather Information. \n -Tune to 134.000 for Mineralnye Vody Runway, TACAN, ILS, and Weather Information.\n- Fog will burn off in 5 minutes, you can use the menu to adjust to your liking.\n\nTANKERS\nTraining Tankers\n-Arco (1-1) South of Kobuleti on 259.000, 59Y.\n-Bloodhound (S3) South of Kobuleti on 258.000, 58Y at 8,000 Ft.\nOther Tankers\n-Texaco (1-1) North of Sukhumi on 251.000, 51Y.\n-Texaco (2-1) West of Sukhumi on 252.000, 52Y.\n-Shell (1-1, Boom) on 127.000, 27Y North of Sukhumi."

    -- Check if the airbase name contains "Kobuleti"
    if string.find(spawnBASE:GetName(), "Kobuleti") then
        messageText = messageText ..
            "\n\nKOBULETI INFO:\nBe advised the Active Runway is 25 and there will be some initial traffic as Tankers, AWACS, and their Escorts depart."
    end

    -- Check if the airbase name contains "Kobuleti"
    if string.find(spawnBASE:GetName(), "Vody") then
        messageText = messageText .. "\n\nMINERALNYE VODY INFO:\nActive Runway is 12."
    end

    if string.find(spawnBASE:GetName(), "Roosevelt") then
        messageText = messageText ..
            "\n\nUSS ROOSEVELT INFO:\n-Ship's BRC: 087\n-Final Bearing: 078\n-TACAN: 71X\n-ILS: 11\n-Tower Frequency: 127.500"
    end

    -- Send the message
    --MESSAGE:New(messageText, 15):ToGroup(PlayerGroup):ToLog()
    -- MESSAGE:New(messageText, 15):ToAll():ToLog()

    ----------------------------------------------------------------------------------------------------------
    -- CREW CHIEF
    ----------------------------------------------------------------------------------------------------------
    local GroundCrew = nil
    local unitClient = PlayerUnit
    local UnitName = PlayerUnit:Name()
    local rampcoordinate = PlayerUnit:GetCoordinate()
    local heading = PlayerUnit:GetHeading() + math.random(328, 331)
    local GCfacingAC = math.fmod(PlayerUnit:GetHeading() + math.random(90, 95), 360)
    local newposition = rampcoordinate:Translate(18, heading)

    local nearestairfield = rampcoordinate:GetClosestAirbase()
    local airfieldtype = nearestairfield:GetAirbaseCategory()
    local OpenTerminalTypes = { 104, 72, 176 }
    local isParkingValid = false -- Flag to check if any parking spot is within 2 meters

    for _, TermnalTypeID in ipairs(OpenTerminalTypes) do
        local _, _, distanceToClosestSpot = rampcoordinate:GetClosestParkingSpot(nearestairfield, TermnalTypeID)

        -- Ensure the value is not nil before logging
        if distanceToClosestSpot then
            if BlueDebug then
                env.info(string.format("-----SPOT IS %.2f meters to a %d spot", distanceToClosestSpot, TermnalTypeID))
            end
            -- Check if it's within 2 meters of any valid spot
            if distanceToClosestSpot < 2 then
                isParkingValid = true
            end
        else
            if BlueDebug then
                env.info(
                    string.format("-----No valid parking spot found for %d at the nearest airfield.", TermnalTypeID))
            end
        end
    end

    -- Proceed only if airfield type and altitude conditions are met OR if a parking spot is valid
    if airfieldtype == 0 and (unitClient:GetAltitude() < 9000 and isParkingValid) then
        if BlueDebug then
            env.info("-----Conditions met: Proceeding with operation.")
        end
        -- Define all variables outside the condition to maintain their scope
        local spawnInstanceSoldier1, spawnInstanceSoldier2
        local spawnInstanceOne, spawnInstanceTwo, spawnInstanceThree, spawnInstanceFour

        -- Soldier One
        spawnInstanceSoldier1 = SPAWNSTATIC:NewFromType("Soldier M4", "Infantry", country.id.USA)
        spawnInstanceSoldier1 = spawnInstanceSoldier1:SpawnFromCoordinate(newposition, GCfacingAC, UTILS.UniqueName(
            "Static M4 Soldier " .. UnitName))

        -- Soldier Two
        spawnInstanceSoldier2 = SPAWNSTATIC:NewFromType("Soldier M249", "Infantry", country.id.USA)
        spawnInstanceSoldier2 = spawnInstanceSoldier2:SpawnFromCoordinate(newposition:Translate(-1),
            GCfacingAC + math.random(30, 60), UTILS.UniqueName("Static M249 Soldier " .. UnitName))

        -- Only spawn the cargo if the parking spot is outdoors like Nellis

        if rampcoordinate:IsNight(Clock) then
            -- SPAWN LIGHT LEFT
            local equipmentPositionOne = rampcoordinate:Translate(12, heading - 30)
            spawnInstanceOne = SPAWNSTATIC:NewFromType("NF-2_LightOn", "Fortifications", country.id.USA)
            spawnInstanceOne = spawnInstanceOne:SpawnFromCoordinate(equipmentPositionOne, heading - 150,
                UTILS.UniqueName("Static LightOn " .. UnitName))
        else
            -- SPAWN AIM-120s LEFT
            local equipmentPositionOne = rampcoordinate:Translate(12, heading - 30)
            spawnInstanceOne = SPAWNSTATIC:NewFromType("ERO_MHU-141-AIM-120", "Fortifications", country.id.USA)
            spawnInstanceOne = spawnInstanceOne:SpawnFromCoordinate(equipmentPositionOne, heading - 150,
                UTILS.UniqueName("Static AIM 120s " .. UnitName))
        end

        -- SPAWN Bombs LEFT
        local equipmentPositionTwo = rampcoordinate:Translate(10, heading - 70)
        spawnInstanceTwo = SPAWNSTATIC:NewFromType("ERO_Mk83", "Fortifications", country.id.USA)
        spawnInstanceTwo = spawnInstanceTwo:SpawnFromCoordinate(equipmentPositionTwo, heading - 150,
            UTILS.UniqueName("Static Mk83s " .. UnitName))

        -- More AIM-120s RIGHT
        local equipmentPositionThree = rampcoordinate:Translate(-12, heading - 50)
        spawnInstanceThree = SPAWNSTATIC:NewFromType("ERO_MHU-141-AIM-9", "Fortifications", country.id.USA)
        spawnInstanceThree = spawnInstanceThree:SpawnFromCoordinate(equipmentPositionThree, heading - 150,
            UTILS.UniqueName("Static AIM 120s " .. UnitName))

        -- SPAWN Bombs RIGHT
        local equipmentPositionFour = rampcoordinate:Translate(-10, heading - 70)
        spawnInstanceFour = SPAWNSTATIC:NewFromType("ERO_Mk83", "Fortifications", country.id.USA)
        spawnInstanceFour = spawnInstanceFour:SpawnFromCoordinate(equipmentPositionFour, heading - 150,
            UTILS.UniqueName("Static Mk83s " .. UnitName))

        -- Function to destroy crew and equipment after 15 minutes
        local function DelayedDestroy()
            if BlueDebug then env.info("-----DESTROYING CREW CHIEF AND EQUIPMENT AFTER 15 MINUTES------") end
            if spawnInstanceSoldier1 then
                spawnInstanceSoldier1:Destroy(nil, 0)
            end
            if spawnInstanceSoldier2 then
                spawnInstanceSoldier2:Destroy(nil, 0)
            end
            if spawnInstanceOne then
                spawnInstanceOne:Destroy(nil, 0)
            end
            if spawnInstanceTwo then
                spawnInstanceTwo:Destroy(nil, 0)
            end
            if spawnInstanceThree then
                spawnInstanceThree:Destroy(nil, 0)
            end
            if spawnInstanceFour then
                spawnInstanceFour:Destroy(nil, 0)
            end
        end

        local CleanupTimer = TIMER:New(DelayedDestroy)
        CleanupTimer:Start(900)
    else
        env.info("-------CREW CHIEF NOT AVAILABLE------")
    end
end
