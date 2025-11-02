-------------------------------------------------------------------------------------------------
-- General Launchers
-------------------------------------------------------------------------------------------------
function AddRevetments()
    BASE:I(
        "------ADDING GENERAL LAUNCHERS ---------")

    local LauncherUnitSet = SET_UNIT:New()
        :FilterActive(false)
        :FilterPrefixes({ "SA-", "BLUE-SAM" })  --Put your SAM Prefixes here
        :FilterCategories("ground")
        :FilterOnce()

    LauncherUnitSet:ForEachUnit(function(unt)
        BASE:I(unt:GetName() .. " is a " .. unt:GetTypeName())

        local untCoalition = unt:GetCoalition()
        local heading      = unt:GetHeading()
        local typeName     = unt:GetTypeName() or ""
        local tl           = typeName:lower()

        local isVolhov     = tl:find("volhov", 1, true) ~= nil
        -- match "ln" as a standalone word (e.g., "Hawk ln"), or the word "launcher"
        local hasLnWord    = (tl:match("%fln%f[^%a]") ~= nil) or (tl:find("launcher", 1, true) ~= nil)

        local function placeRevetment(staticType, countryId, label)
            local ZoneUnt = ZONE_UNIT:New("ZoneUnit for " .. unt:GetName(), unt, 10,
                { rho = 0, theta = 0, relative_to_unit = true })
            local RevetmentObject = SPAWNSTATIC:NewFromType(staticType, "Fortifications", countryId)
            RevetmentObject:SpawnFromZone(ZoneUnt, heading, string.format("%s Revetment for: %s", label, unt:GetName()))
            BASE:I("------------ Adding Revetment to: " .. unt:GetName())
            if RedDebug and untCoalition == coalition.side.RED then
                trigger.action.outText("------------ Adding Revetment to: " .. unt:GetName(), 2)
            elseif BlueDebug and untCoalition == coalition.side.BLUE then
                trigger.action.outText("------------ Adding Revetment to: " .. unt:GetName(), 2)
            end
        end

        -- SA-2 (Volhov) → elevated OC2
        if isVolhov and unt:IsSAM() then
            if untCoalition == coalition.side.BLUE then
                BASE:I(unt:GetName() .. " is a BLUE Launcher")
                placeRevetment("ERO_Revetment_SAM_OC2_elevated", country.id.CJTF_BLUE, "BLUE")
            elseif untCoalition == coalition.side.RED then
                BASE:I(unt:GetName() .. " is a RED Launcher")
                placeRevetment("ERO_Revetment_SAM_OC2_elevated", country.id.CJTF_RED, "RED")
            end
        else
            -- NEW RULE: SAM + Ground, NOT Volhov, AND has "ln" (as word) OR "launcher" → elevated OC2
            if unt:IsSAM() and hasLnWord then
                if untCoalition == coalition.side.BLUE then
                    BASE:I(unt:GetName() .. " is a BLUE Launcher (LN/launcher match)")
                    placeRevetment("ERO_Revetment_SAM_OC2_elevated", country.id.CJTF_BLUE, "BLUE")
                elseif untCoalition == coalition.side.RED then
                    BASE:I(unt:GetName() .. " is a RED Launcher (LN/launcher match)")
                    placeRevetment("ERO_Revetment_SAM_OC2_elevated", country.id.CJTF_RED, "RED")
                end

                -- fallback: general → UC
            else
                if untCoalition == coalition.side.BLUE then
                    BASE:I(unt:GetName() .. " is a BLUE Launcher (general)")
                    placeRevetment("ERO_Revetment_SAM_UC", country.id.CJTF_BLUE, "BLUE")
                elseif untCoalition == coalition.side.RED then
                    BASE:I(unt:GetName() .. " is a RED Launcher (general)")
                    placeRevetment("ERO_Revetment_SAM_UC", country.id.CJTF_RED, "RED")
                end
            end
        end
    end) -- ForEachUnit
end

TIMER:New(AddRevetments):Start(10)

