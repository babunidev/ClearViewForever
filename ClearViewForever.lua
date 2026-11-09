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

-- Keep the nameplate system active while making Blizzard's visual UnitFrame transparent.
-- Alpha is saved per frame so the user's previous value can be restored when disabled.
local savedNameplateAlphas = setmetatable({}, { __mode = "k" })

local function SetNameplateFrameHidden(plate)
    local unitFrame = plate and plate.UnitFrame
    if not unitFrame or type(unitFrame.GetAlpha) ~= "function" or type(unitFrame.SetAlpha) ~= "function" then
        return false
    end
    if savedNameplateAlphas[unitFrame] == nil then
        local ok, alpha = pcall(unitFrame.GetAlpha, unitFrame)
        if not ok or type(alpha) ~= "number" then return false end
        savedNameplateAlphas[unitFrame] = alpha
    end
    local ok = pcall(unitFrame.SetAlpha, unitFrame, 0)
    if not ok then savedNameplateAlphas[unitFrame] = nil end
    return ok
end

local function SetNameplatesHidden(hide)
    if not hide then
        local restored = 0
        for unitFrame, originalAlpha in pairs(savedNameplateAlphas) do
            local ok, currentAlpha = pcall(unitFrame.GetAlpha, unitFrame)
            -- Do not overwrite an alpha value changed by another addon while this option was active.
            if ok and currentAlpha == 0 then
                local restoredOK = pcall(unitFrame.SetAlpha, unitFrame, originalAlpha)
                if restoredOK then restored = restored + 1 end
            end
            savedNameplateAlphas[unitFrame] = nil
        end
        return true, string.format("Restored %d nameplate visual frame(s); nameplate system remains active.", restored)
    end

    if not C_NamePlate or type(C_NamePlate.GetNamePlates) ~= "function" then
        return false, "Forever nameplate APIs are unavailable."
    end
    local ok, plates = pcall(C_NamePlate.GetNamePlates)
    if not ok or type(plates) ~= "table" then
        return false, "Could not enumerate visible nameplates."
    end

    local hidden = 0
    for _, plate in ipairs(plates) do
        if SetNameplateFrameHidden(plate) then hidden = hidden + 1 end
    end
    return true, string.format("Made %d visible nameplate frame(s) transparent; nameplate system remains active.", hidden)
end

-- Hide hostile enemy plates only while the player is in combat. Forever's
-- combat-start event fires before combat lockdown, allowing this CVar change.
-- The previous value is saved and restored after combat, unless another
-- system has changed the CVar in the meantime.
local ENEMY_NAMEPLATE_CVAR = "nameplateShowEnemies"

local function InCombatLockdownActive()
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, active = pcall(InCombatLockdown)
    return ok and active or false
end

local function HideCombatEnemyNameplates()
    local current = ReadCVar(ENEMY_NAMEPLATE_CVAR)
    if current == nil then
        return false, "The nameplateShowEnemies CVar is unavailable."
    end

    if ClearViewForeverDB.combatNameplatesOriginal == nil then
        ClearViewForeverDB.combatNameplatesOriginal = current
    end

    if current == "0" then
        return true, "Enemy nameplates are already disabled."
    end
    if WriteCVar(ENEMY_NAMEPLATE_CVAR, "0") then
        return true, "Enemy nameplates hidden for combat."
    end
    return false, "The client did not accept nameplateShowEnemies = 0."
end

local function RestoreCombatEnemyNameplates()
    local original = ClearViewForeverDB and ClearViewForeverDB.combatNameplatesOriginal
    if original == nil then return true, "No saved enemy nameplate setting to restore." end
    if InCombatLockdownActive() then
        return true, "The previous enemy nameplate setting will be restored after combat."
    end

    local current = ReadCVar(ENEMY_NAMEPLATE_CVAR)
    if current == nil then
        return false, "Could not read nameplateShowEnemies."
    end
    if current ~= "0" then
        ClearViewForeverDB.combatNameplatesOriginal = nil
        return true, "Enemy nameplate setting changed externally; left it unchanged."
    end
    if WriteCVar(ENEMY_NAMEPLATE_CVAR, original) then
        ClearViewForeverDB.combatNameplatesOriginal = nil
        return true, "Previous enemy nameplate setting restored."
    end
    return false, "Could not restore the previous enemy nameplate setting."
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
    if ClearViewForeverDB.nameplates then
        local ok, explanation = SetNameplatesHidden(true)
        if not ok then
            ClearViewForeverDB.nameplates = false
            Say("Nameplate hiding unavailable: " .. explanation)
        end
    end
    -- A stale saved value can remain if the client was closed during combat.
    if ClearViewForeverDB.combatNameplatesOriginal ~= nil and not InCombatLockdownActive() then
        local ok, explanation = RestoreCombatEnemyNameplates()
        if not ok then Say("Combat nameplate restore warning: " .. explanation) end
    end
end

local function Status()
    Say("Creature names: " .. (ClearViewForeverDB.names and "hide (requested)" or "unmanaged") ..
        "; combat numbers: " .. (ClearViewForeverDB.numbers and "hide (requested)" or "unmanaged") ..
        "; red errors: " .. (ClearViewForeverDB.errors and "hidden" or "visible"))
    Say("XP world-text workaround: " .. (ClearViewForeverDB.xp and "ON (experimental; affects ALL world text)" or "OFF"))
    Say("Nameplate visuals: " .. (ClearViewForeverDB.nameplates and "invisible (system active)" or "visible"))
    Say("Combat enemy nameplates: " .. (ClearViewForeverDB.combatNameplates and "hidden during combat" or "unmanaged"))
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
            Say("Usage: /cvf combatplates on|off (on = hide hostile nameplates only during combat)")
            return
        end
        local wanted = setting == "on"
        ClearViewForeverDB.combatNameplates = wanted
        if wanted then
            if ClearViewForeverDB.combatNameplatesOriginal ~= nil and ReadCVar(ENEMY_NAMEPLATE_CVAR) == "0" then
                Say("Combat enemy nameplate hiding is already active.")
            elseif InCombatLockdownActive() then
                Say("Combat enemy nameplate hiding enabled; it will apply on your next combat.")
            else
                Say("Combat enemy nameplate hiding enabled; hostile plates will be suppressed when combat begins.")
            end
        else
            local ok, explanation = RestoreCombatEnemyNameplates()
            if not ok then
                Say("Combat nameplate warning: " .. explanation)
            else
                Say("Combat enemy nameplate hiding disabled. " .. explanation)
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
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == ADDON then
        if type(ClearViewForeverDB) ~= "table" then ClearViewForeverDB = {} end
        for key, value in pairs(defaults) do
            if type(ClearViewForeverDB[key]) ~= "boolean" then
                ClearViewForeverDB[key] = value
            end
        end
        frame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        Apply()
        frame:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- This event fires just before combat lockdown on Forever.
        if ClearViewForeverDB and ClearViewForeverDB.combatNameplates then
            local ok, explanation = HideCombatEnemyNameplates()
            if not ok then
                ClearViewForeverDB.combatNameplates = false
                RestoreCombatEnemyNameplates()
                Say("Combat nameplate hiding unavailable: " .. explanation)
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ClearViewForeverDB then
            local ok, explanation = RestoreCombatEnemyNameplates()
            if not ok then Say("Combat nameplate restore warning: " .. explanation) end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if ClearViewForeverDB then
            if ClearViewForeverDB.nameplates then
                local ok, explanation = SetNameplatesHidden(true)
                if not ok then
                    ClearViewForeverDB.nameplates = false
                    Say("Nameplate hiding unavailable: " .. explanation)
                end
            end
            if not InCombatLockdownActive() then
                local ok, explanation = RestoreCombatEnemyNameplates()
                if not ok then Say("Combat nameplate restore warning: " .. explanation) end
            end
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if ClearViewForeverDB and ClearViewForeverDB.nameplates then
            local plate
            if C_NamePlate and type(C_NamePlate.GetNamePlateForUnit) == "function" then
                local ok, result = pcall(C_NamePlate.GetNamePlateForUnit, name)
                if ok then plate = result end
            end
            if not SetNameplateFrameHidden(plate) then
                local ok, explanation = SetNameplatesHidden(true)
                if not ok then
                    ClearViewForeverDB.nameplates = false
                    Say("Nameplate hiding unavailable: " .. explanation)
                end
            end
        end
    end
end)
