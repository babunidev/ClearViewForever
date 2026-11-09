-- ClearViewForever: World of Warcraft Forever 1.60.1 / Interface 16001.
-- The game's native 3D overhead names are not addon-owned font strings.
local ADDON = ...
local frame = CreateFrame("Frame")
local defaults = { names = true, numbers = true, errors = true, xp = false, nameplates = false, combatNameplates = false, portraitDamage = false }

local function Say(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffClearViewForever:|r " .. message)
    end
end

local function ReadCVar(name)
    if C_CVar and type(C_CVar.GetCVar) == "function" then
        local ok, value = pcall(C_CVar.GetCVar, name)
        if ok then return value end
    end
    if type(GetCVar) == "function" then
        local ok, value = pcall(GetCVar, name)
        if ok then return value end
    end
    return nil
end

local function WriteCVar(name, value)
    if ReadCVar(name) == nil then return false end
    if C_CVar and type(C_CVar.SetCVar) == "function" then
        local ok = pcall(C_CVar.SetCVar, name, value)
        local result = ReadCVar(name)
        return ok and (result == value or (tonumber(result) and tonumber(value) and tonumber(result) == tonumber(value)))
    elseif type(SetCVar) == "function" then
        local ok = pcall(SetCVar, name, value)
        local result = ReadCVar(name)
        return ok and (result == value or (tonumber(result) and tonumber(value) and tonumber(result) == tonumber(value)))
    end
    return false
end

-- Native 3D target-name rendering can override these creature-name CVars.
local creatureNames = {
    "UnitNameNPC",
    "UnitNameHostleNPC", -- Historical spelling is "Hostle".
    "UnitNameNonCombatCreatureName",
}

local numberNames = {
    "floatingCombatTextCombatDamage_v2",
    "floatingCombatTextCombatHealing_v2",
    "floatingCombatTextCombatLogPeriodicSpells_v2",
    "floatingCombatTextPetMeleeDamage_v2",
    "floatingCombatTextPetSpellDamage_v2",
    "floatingCombatTextCombatDamage",
    "floatingCombatTextCombatHealing",
    "floatingCombatTextCombatLogPeriodic",
    "floatingCombatTextPetMeleeDamage",
    "floatingCombatTextPetSpellDamage",
    "enableFloatingCombatText",
}

-- Diagnostic only: this is for NAMEPLATES, not native 3D overhead names.
local diagnosticCVars = { "nameplateForceShowUnitName", "nameplateShowEnemies" }

-- Keep the nameplate system active while making selected visual UnitFrames transparent.
-- The two options share one alpha state per frame, so disabling one reason never
-- reveals a plate that is still hidden by the other option.
local nameplateAlphaStates = setmetatable({}, { __mode = "k" })
local activeNameplateFrames = {}
local nameplateCheckSerial = {}
local combatActive = false

local function SetNameplateHiddenReason(unitFrame, reason, hidden)
    if not unitFrame or type(unitFrame.GetAlpha) ~= "function" or type(unitFrame.SetAlpha) ~= "function" then
        return false
    end

    local state = nameplateAlphaStates[unitFrame]
    if not state then
        if not hidden then return true end
        local ok, alpha = pcall(unitFrame.GetAlpha, unitFrame)
        if not ok or type(alpha) ~= "number" then return false end
        state = {
            originalAlpha = alpha,
            appliedAlpha = alpha,
            general = false,
            combat = false,
        }
        nameplateAlphaStates[unitFrame] = state
    else
        local ok, currentAlpha = pcall(unitFrame.GetAlpha, unitFrame)
        if not ok or type(currentAlpha) ~= "number" then return false end
        -- Preserve an alpha change made by another addon while our transparency is active.
        if state.appliedAlpha ~= nil and currentAlpha ~= state.appliedAlpha then
            state.originalAlpha = currentAlpha
        end
    end

    local previousReason = state[reason]
    state[reason] = hidden and true or false

    if state.general or state.combat then
        local ok = pcall(unitFrame.SetAlpha, unitFrame, 0)
        if not ok then
            state[reason] = previousReason
            if not state.general and not state.combat then
                nameplateAlphaStates[unitFrame] = nil
            end
            return false
        end
        state.appliedAlpha = 0
        return true
    end

    local ok, currentAlpha = pcall(unitFrame.GetAlpha, unitFrame)
    if ok and currentAlpha == state.appliedAlpha then
        local restored = pcall(unitFrame.SetAlpha, unitFrame, state.originalAlpha)
        if not restored then
            state[reason] = previousReason
            return false
        end
    end
    nameplateAlphaStates[unitFrame] = nil
    return true
end

local function IsHostileNameplateUnit(unitToken)
    if type(unitToken) ~= "string" or type(UnitCanAttack) ~= "function" then
        return false
    end
    local ok, canAttack = pcall(UnitCanAttack, "player", unitToken)
    return ok and canAttack == true
end

local function GetNameplateUnitFrame(unitToken)
    if not C_NamePlate or type(C_NamePlate.GetNamePlateForUnit) ~= "function" then
        return nil
    end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unitToken)
    if not ok or not plate then return nil end
    return plate.UnitFrame, plate
end

local function ApplyNameplateUnit(unitToken)
    local unitFrame = GetNameplateUnitFrame(unitToken)
    if not unitFrame then return false end

    activeNameplateFrames[unitToken] = unitFrame

    local generalHidden = ClearViewForeverDB and ClearViewForeverDB.nameplates
    local generalOK = SetNameplateHiddenReason(unitFrame, "general", generalHidden)

    local combatHidden = ClearViewForeverDB and ClearViewForeverDB.combatNameplates
        and combatActive and IsHostileNameplateUnit(unitToken)
    local combatOK = SetNameplateHiddenReason(unitFrame, "combat", combatHidden)

    return generalOK and combatOK
end

local function ScheduleNameplateUnitRefresh(unitToken)
    if not C_Timer or type(C_Timer.After) ~= "function" then return end
    local serial = (nameplateCheckSerial[unitToken] or 0) + 1
    nameplateCheckSerial[unitToken] = serial
    -- Recheck once after the add event in case the unit token was not populated yet.
    C_Timer.After(0.1, function()
        if nameplateCheckSerial[unitToken] ~= serial then return end
        ApplyNameplateUnit(unitToken)
    end)
end

local function RefreshVisibleNameplates()
    if not C_NamePlate or type(C_NamePlate.GetNamePlates) ~= "function" then
        return false, "Forever nameplate APIs are unavailable."
    end
    local ok, plates = pcall(C_NamePlate.GetNamePlates)
    if not ok or type(plates) ~= "table" then
        return false, "Could not enumerate visible nameplates."
    end

    local generalHiddenCount, combatHiddenCount = 0, 0
    for _, plate in ipairs(plates) do
        local unitFrame = plate and plate.UnitFrame
        if unitFrame then
            local unitToken = plate.unitToken
            if not unitToken and type(plate.GetUnit) == "function" then
                local tokenOK, token = pcall(plate.GetUnit, plate)
                if tokenOK then unitToken = token end
            end
            if unitToken then
                activeNameplateFrames[unitToken] = unitFrame
            end

            local generalHidden = ClearViewForeverDB and ClearViewForeverDB.nameplates
            if generalHidden then
                if SetNameplateHiddenReason(unitFrame, "general", true) then
                    generalHiddenCount = generalHiddenCount + 1
                end
            else
                SetNameplateHiddenReason(unitFrame, "general", false)
            end

            local combatHidden = ClearViewForeverDB and ClearViewForeverDB.combatNameplates
                and combatActive and unitToken and IsHostileNameplateUnit(unitToken)
            if combatHidden then
                if SetNameplateHiddenReason(unitFrame, "combat", true) then
                    combatHiddenCount = combatHiddenCount + 1
                end
            else
                SetNameplateHiddenReason(unitFrame, "combat", false)
            end
        end
    end
    return true, generalHiddenCount, combatHiddenCount
end

local function SetNameplatesHidden(hide)
    if hide then
        local ok, generalCount = RefreshVisibleNameplates()
        if not ok then return false, generalCount end
        return true, string.format(
            "Made %d visible nameplate frame(s) transparent; nameplate system remains active.",
            generalCount
        )
    end

    local released = 0
    for unitFrame, state in pairs(nameplateAlphaStates) do
        if state.general and SetNameplateHiddenReason(unitFrame, "general", false) then
            released = released + 1
        end
    end
    return true, string.format(
        "Released general transparency on %d frame(s); combat transparency remains active where enabled.",
        released
    )
end

local function SetCombatNameplatesHidden(hide)
    if hide then
        local ok, generalCount, combatCount = RefreshVisibleNameplates()
        if not ok then return false, generalCount end
        return true, string.format(
            "Made %d hostile nameplate frame(s) transparent; nameplate system remains active.",
            combatCount
        )
    end

    local released = 0
    for unitFrame, state in pairs(nameplateAlphaStates) do
        if state.combat and SetNameplateHiddenReason(unitFrame, "combat", false) then
            released = released + 1
        end
    end
    return true, string.format(
        "Released combat transparency on %d hostile frame(s); general transparency remains active where enabled.",
        released
    )
end

local function InCombatLockdownActive()
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, active = pcall(InCombatLockdown)
    return ok and active or false
end

-- Older development builds changed nameplateShowEnemies. Restore a leftover
-- saved override once, then never use that CVar for either transparency option.
local function RestoreLegacyCombatNameplateCVar()
    local original = ClearViewForeverDB and ClearViewForeverDB.combatNameplatesOriginal
    if original == nil then return true end
    if InCombatLockdownActive() then return true end

    local current = ReadCVar("nameplateShowEnemies")
    if current == nil then
        return false, "Could not read the legacy nameplateShowEnemies setting."
    end
    if current == "0" and original ~= "0" then
        if not WriteCVar("nameplateShowEnemies", original) then
            return false, "Could not restore the legacy nameplateShowEnemies setting."
        end
    end
    ClearViewForeverDB.combatNameplatesOriginal = nil
    return true
end

local errorSuppressed = false
local function SetErrorsHidden(hide)
    if not UIErrorsFrame then return end
    if hide then
        if type(UIErrorsFrame.UnregisterEvent) == "function" then
            UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
        end
        if type(UIErrorsFrame.Clear) == "function" then
            UIErrorsFrame:Clear()
        end
        UIErrorsFrame:Hide()
        errorSuppressed = true
    elseif errorSuppressed then
        if type(UIErrorsFrame.RegisterEvent) == "function" then
            UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
        end
        UIErrorsFrame:Show()
        errorSuppressed = false
    end
end

-- Experimental: XP is native world text, not a regular floating combat number.
-- This documented workaround changes ALL world-text scaling, not just XP.
local worldScaleCVars = { "WorldTextScale_v2", "WorldTextScale" }
local function SetXPWorldTextHidden(hide)
    if hide then
        local currentName, currentValue
        for _, name in ipairs(worldScaleCVars) do
            local value = ReadCVar(name)
            if value and value ~= "" then
                currentName, currentValue = name, value
                break
            end
        end
        if not currentName then return false, "No supported world-text scale CVar found." end
        -- Save the untouched scale before the first change, also across reloads.
        if not ClearViewForeverDB.xpOriginalScale then
            ClearViewForeverDB.xpOriginalScale = currentValue
            ClearViewForeverDB.xpScaleCVar = currentName
        end
        if WriteCVar(currentName, "1000") then
            return true, "Experimental world-text scaling applied (affects all world text)."
        end
        if ReadCVar(currentName) == currentValue then
            ClearViewForeverDB.xpOriginalScale = nil
            ClearViewForeverDB.xpScaleCVar = nil
        end
        return false, "Client did not accept the experimental world-text scale."
    end
    local name, original = ClearViewForeverDB.xpScaleCVar, ClearViewForeverDB.xpOriginalScale
    if not name or not original then return true, "No XP scale change to restore." end
    local current = ReadCVar(name)
    if tonumber(current) ~= 1000 then
        return false, "World-text scale changed externally; original value preserved in SavedVariables."
    end
    if WriteCVar(name, original) then
        ClearViewForeverDB.xpScaleCVar = nil
        ClearViewForeverDB.xpOriginalScale = nil
        return true, "Previous world-text scale restored."
    end
    return false, "Could not restore world-text scale automatically."
end

local function Apply()
    for _, name in ipairs(creatureNames) do
        if ClearViewForeverDB.names then WriteCVar(name, "0") end
    end
    for _, name in ipairs(numberNames) do
        if ClearViewForeverDB.numbers then WriteCVar(name, "0") end
    end
    SetErrorsHidden(ClearViewForeverDB.errors)
    if ClearViewForeverDB.xp then SetXPWorldTextHidden(true) end

    if ClearViewForeverDB.nameplates or (ClearViewForeverDB.combatNameplates and combatActive) then
        local ok, explanation = RefreshVisibleNameplates()
        if not ok then
            if ClearViewForeverDB.nameplates then
                ClearViewForeverDB.nameplates = false
            end
            Say("Nameplate transparency unavailable: " .. explanation)
        end
    end

    local legacyOK, legacyExplanation = RestoreLegacyCombatNameplateCVar()
    if not legacyOK then
        Say("Legacy nameplate setting restore warning: " .. legacyExplanation)
    end
end

local function Status()
    Say("Creature names: " .. (ClearViewForeverDB.names and "hide (requested)" or "unmanaged") ..
        "; combat numbers: " .. (ClearViewForeverDB.numbers and "hide (requested)" or "unmanaged") ..
        "; red errors: " .. (ClearViewForeverDB.errors and "hidden" or "visible"))
    Say("XP world-text workaround: " .. (ClearViewForeverDB.xp and "ON (experimental; affects ALL world text)" or "OFF"))
    Say("Nameplate visuals: " .. (ClearViewForeverDB.nameplates and "invisible (system active)" or "visible"))
    Say("Combat enemy nameplates: " .. (ClearViewForeverDB.combatNameplates and "transparent during combat (system active)" or "unmanaged"))
    Say("Native targeted-name suppression is not confirmed by Forever's API.")
end

SLASH_CLEARVIEWFOREVER1 = "/cvf"
SlashCmdList.CLEARVIEWFOREVER = function(message)
    local command, setting = (message or ""):lower():match("^%s*(%S*)%s*(%S*)")
    if command == "status" or command == "" then
        Status()
    elseif command == "nameplates" then
        if setting ~= "on" and setting ~= "off" then
            Say("Usage: /cvf nameplates on|off (on = transparent, system stays active)")
            return
        end
        local wanted = setting == "on"
        ClearViewForeverDB.nameplates = wanted
        local ok, explanation = SetNameplatesHidden(wanted)
        if not ok and wanted then
            ClearViewForeverDB.nameplates = false
            Say("Nameplate warning: " .. explanation)
        else
            Say(explanation)
        end
        Say("Nameplate hiding " .. (ClearViewForeverDB.nameplates and "enabled" or "disabled") .. ".")
    elseif command == "combatplates" then
        if setting ~= "on" and setting ~= "off" then
            Say("Usage: /cvf combatplates on|off (on = transparent hostile nameplates only during combat)")
            return
        end
        local wanted = setting == "on"
        ClearViewForeverDB.combatNameplates = wanted
        if wanted then
            combatActive = combatActive or InCombatLockdownActive()
            if combatActive then
                local ok, explanation = SetCombatNameplatesHidden(true)
                if ok then
                    Say("Combat enemy nameplate transparency enabled. " .. explanation)
                else
                    Say("Combat nameplate warning: " .. explanation)
                end
            else
                Say("Combat enemy nameplate transparency enabled; hostile UnitFrames will become transparent when combat begins.")
            end
        else
            local ok, explanation = SetCombatNameplatesHidden(false)
            if not ok then
                Say("Combat nameplate warning: " .. explanation)
            else
                Say("Combat enemy nameplate transparency disabled. " .. explanation)
            end
        end
    elseif command == "names" or command == "numbers" or command == "errors" or command == "xp" then
        if setting ~= "on" and setting ~= "off" then
            Say("Usage: /cvf " .. command .. " on|off (on = hide)")
            return
        end
        local oldValue = ClearViewForeverDB[command]
        ClearViewForeverDB[command] = setting == "on"
        -- Off stops management; it does not guess original CVar values.
        if command == "errors" then
            SetErrorsHidden(ClearViewForeverDB.errors)
        elseif command == "xp" then
            local ok, explanation = SetXPWorldTextHidden(ClearViewForeverDB.xp)
            Say((ok and "XP: " or "XP warning: ") .. explanation)
            if not ok and ClearViewForeverDB.xp then ClearViewForeverDB.xp = false end
        elseif ClearViewForeverDB[command] then
            Apply()
        end
        Say(command .. " hiding " .. (ClearViewForeverDB[command] and "enabled" or "disabled") ..
            (oldValue and not ClearViewForeverDB[command] and command ~= "errors" and
            "; previous console settings are retained" or ""))
    elseif command == "apply" then
        Apply()
        Say("Settings applied.")
    elseif command == "diagnose" then
        local _, build, _, interface = GetBuildInfo()
        Say("Client build " .. tostring(build) .. "; interface " .. tostring(interface))
        for _, name in ipairs(creatureNames) do Say(name .. " = " .. tostring(ReadCVar(name))) end
        for _, name in ipairs(numberNames) do Say(name .. " = " .. tostring(ReadCVar(name))) end
        for _, name in ipairs(diagnosticCVars) do Say(name .. " = " .. tostring(ReadCVar(name)) .. " (nameplate only)") end
        for _, name in ipairs(worldScaleCVars) do Say(name .. " = " .. tostring(ReadCVar(name)) .. " (global world text)") end
        Say("A native target overhead name may remain regardless of these values.")
    else
        Say("Commands: /cvf status | apply | diagnose | names on|off | nameplates on|off | combatplates on|off | numbers on|off | errors on|off | xp on|off (experimental)")
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:SetScript("OnEvent", function(_, event, unitToken)
    if event == "ADDON_LOADED" and unitToken == ADDON then
        if type(ClearViewForeverDB) ~= "table" then ClearViewForeverDB = {} end
        for key, value in pairs(defaults) do
            if type(ClearViewForeverDB[key]) ~= "boolean" then
                ClearViewForeverDB[key] = value
            end
        end
        frame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        combatActive = InCombatLockdownActive()
        Apply()
        frame:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "PLAYER_REGEN_DISABLED" then
        combatActive = true
        if ClearViewForeverDB and ClearViewForeverDB.combatNameplates then
            local ok, explanation = SetCombatNameplatesHidden(true)
            if not ok then Say("Combat nameplate transparency unavailable: " .. explanation) end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        combatActive = false
        local ok, explanation = SetCombatNameplatesHidden(false)
        if not ok then Say("Combat nameplate transparency restore warning: " .. explanation) end
        local legacyOK, legacyExplanation = RestoreLegacyCombatNameplateCVar()
        if not legacyOK then Say("Legacy nameplate setting restore warning: " .. legacyExplanation) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if ClearViewForeverDB then
            combatActive = InCombatLockdownActive()
            if ClearViewForeverDB.nameplates or (ClearViewForeverDB.combatNameplates and combatActive) then
                local ok, explanation = RefreshVisibleNameplates()
                if not ok then
                    if ClearViewForeverDB.nameplates then ClearViewForeverDB.nameplates = false end
                    Say("Nameplate transparency unavailable: " .. explanation)
                end
            end
            local legacyOK, legacyExplanation = RestoreLegacyCombatNameplateCVar()
            if not legacyOK then Say("Legacy nameplate setting restore warning: " .. legacyExplanation) end
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if ClearViewForeverDB and (ClearViewForeverDB.nameplates or (ClearViewForeverDB.combatNameplates and combatActive)) then
            ApplyNameplateUnit(unitToken)
            ScheduleNameplateUnitRefresh(unitToken)
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        nameplateCheckSerial[unitToken] = (nameplateCheckSerial[unitToken] or 0) + 1
        local unitFrame = activeNameplateFrames[unitToken]
        activeNameplateFrames[unitToken] = nil
        if unitFrame then
            -- Release only the combat reason. General transparency remains active if enabled.
            SetNameplateHiddenReason(unitFrame, "combat", false)
        end
    end
end)
