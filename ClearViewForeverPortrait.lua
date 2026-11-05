-- Target-portrait damage feedback for World of Warcraft Forever.
-- UNIT_COMBAT reports damage received by a unit, not who caused it.
-- In groups, numbers may include damage from other players.
local handler = CreateFrame("Frame")
local overlay
local labels = {}
local slots = 4
local duration = 0.85
local active = false

local function EnsureOverlay()
    if overlay then return overlay end
    if not TargetFrame then return nil end
    overlay = CreateFrame("Frame", nil, TargetFrame)
    overlay:SetSize(70, 48)
    -- Fallback for Forever's default target layout, not a claim of exact portrait coordinates.
    local portrait = TargetFrame.portrait or TargetFrame.Portrait
    if portrait and portrait.GetObjectType then
        overlay:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    else
        overlay:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 38, -28)
    end
    overlay:SetFrameLevel(TargetFrame:GetFrameLevel() + 5)
    for i = 1, slots do
        local label = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
        -- Blizzard's large numeric font is also used for portrait combat feedback.
        -- Keep the same baseline typeface; emphasize critical hits separately.
        local font, normalSize, flags = label:GetFont()
        if not font or not normalSize then
            label:SetFontObject(GameFontNormalLarge)
            font, normalSize, flags = label:GetFont()
        end
        label:SetPoint("CENTER", overlay, "CENTER", 0, 2)
        label:SetTextColor(1, 0.88, 0.3, 1)
        label:SetShadowOffset(1, -1)
        label:Hide()
        labels[i] = {
            text = label, untilTime = 0, offset = (i - 1) * 10,
            font = font, normalSize = normalSize, fontFlags = flags,
        }
    end
    overlay:Hide()
    overlay:SetScript("OnUpdate", function(self)
        local now = GetTime()
        local any = false
        for _, slot in ipairs(labels) do
            if slot.text:IsShown() then
                if now >= slot.untilTime then
                    slot.text:Hide()
                else
                    local remaining = slot.untilTime - now
                    slot.text:SetAlpha(math.min(1, remaining / 0.3))
                    any = true
                end
            end
        end
        if not any then self:Hide() end
    end)
    return overlay
end

local function Clear()
    for _, slot in ipairs(labels) do
        slot.text:Hide()
        slot.untilTime = 0
    end
    if overlay then overlay:Hide() end
end

local function Enable(enabled)
    active = enabled and true or false
    if active then
        if not EnsureOverlay() then return false end
        handler:RegisterUnitEvent("UNIT_COMBAT", "target")
        handler:RegisterEvent("PLAYER_TARGET_CHANGED")
    else
        handler:UnregisterEvent("UNIT_COMBAT")
        handler:UnregisterEvent("PLAYER_TARGET_CHANGED")
        Clear()
    end
    return true
end

handler:SetScript("OnEvent", function(_, event, unit, action, flag, amount)
    if event == "PLAYER_TARGET_CHANGED" then
        Clear()
        return
    end
    if not active or unit ~= "target" or action ~= "WOUND" then return end
    if not EnsureOverlay() then return end
    -- UNIT_COMBAT is unit-scoped and does not identify the attacker.
    -- Do not infer that a hit came from the player.
    local now = GetTime()
    local chosen
    for _, slot in ipairs(labels) do
        if not slot.text:IsShown() then chosen = slot; break end
    end
    if not chosen then
        chosen = labels[1]
        for i = 2, slots do
            if labels[i].untilTime < chosen.untilTime then chosen = labels[i] end
        end
    end
    -- Amount is reported as plain in observed Forever 1.60.1 open-world tests;
    -- guard conversion in case future combat restrictions protect it.
    local ok, value = pcall(tostring, amount)
    if not ok then return end
    -- UNIT_COMBAT's flagText identifies critical damage.
    if chosen.font and chosen.normalSize then
        local size = (flag == "CRITICAL") and (chosen.normalSize * 1.3) or chosen.normalSize
        chosen.text:SetFont(chosen.font, size, chosen.fontFlags)
    end
    chosen.text:SetText(value)
    chosen.text:ClearAllPoints()
    chosen.text:SetPoint("CENTER", overlay, "CENTER", 0, 2 + chosen.offset)
    chosen.text:SetAlpha(1)
    chosen.untilTime = now + duration
    chosen.text:Show()
    overlay:Show()
end)

local load = CreateFrame("Frame")
load:RegisterEvent("PLAYER_LOGIN")
load:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    Enable(ClearViewForeverDB and ClearViewForeverDB.portraitDamage)
end)

local previous = SlashCmdList.CLEARVIEWFOREVER
SlashCmdList.CLEARVIEWFOREVER = function(message, ...)
    local command, value = (message or ""):lower():match("^%s*(%S*)%s*(%S*)")
    if command == "portrait" then
        if value ~= "on" and value ~= "off" then
            if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("ClearViewForever: /cvf portrait on|off") end
            return
        end
        local wanted = value == "on"
        local supported = Enable(wanted)
        ClearViewForeverDB.portraitDamage = wanted and supported
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("ClearViewForever: Target portrait damage " ..
                (ClearViewForeverDB.portraitDamage and "enabled" or "disabled") ..
                ". UNIT_COMBAT includes damage from other attackers.")
        end
        return
    end
    previous(message, ...)
end
