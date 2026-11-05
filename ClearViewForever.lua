-- ClearViewForever: World of Warcraft Forever 1.60.1 / Interface 16001.
-- The game's native 3D overhead names are not addon-owned font strings.
local ADDON = ...
local frame = CreateFrame("Frame")
local defaults = { names = true, numbers = true, errors = true, xp = false, portraitDamage = false }

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
local diagnosticCVars = { "nameplateForceShowUnitName" }

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
end

local function Status()
    Say("Creature names: " .. (ClearViewForeverDB.names and "hide (requested)" or "unmanaged") ..
        "; combat numbers: " .. (ClearViewForeverDB.numbers and "hide (requested)" or "unmanaged") ..
        "; red errors: " .. (ClearViewForeverDB.errors and "hidden" or "visible"))
    Say("XP world-text workaround: " .. (ClearViewForeverDB.xp and "ON (experimental; affects ALL world text)" or "OFF"))
    Say("Native targeted-name suppression is not confirmed by Forever's API.")
end

SLASH_CLEARVIEWFOREVER1 = "/cvf"
SlashCmdList.CLEARVIEWFOREVER = function(message)
    local command, setting = (message or ""):lower():match("^%s*(%S*)%s*(%S*)")
    if command == "status" or command == "" then
        Status()
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
        Say("Commands: /cvf status | apply | diagnose | names on|off | numbers on|off | errors on|off | xp on|off (experimental)")
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
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
    end
end)
