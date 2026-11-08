-- Small standalone options window. Loaded after ClearViewForever.lua.
local panel = CreateFrame("Frame", "ClearViewForeverOptions", UIParent)
panel:SetSize(370, 335)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG")
panel:EnableMouse(true)
panel:SetMovable(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

local bg = panel:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(panel)
bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
local border = CreateFrame("Frame", nil, panel)
border:SetAllPoints(panel)
-- Avoid dependency on modern backdrop or Settings APIs.
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", panel, "TOP", 0, -16)
title:SetText("ClearViewForever")

local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
close:SetScript("OnClick", function() panel:Hide() end)

local options = {
    { key = "xp", label = "Hide XP popups" },
    { key = "errors", label = "Hide red error messages" },
    { key = "numbers", label = "Hide combat numbers" },
    { key = "names", label = "Hide creature names (target name may remain)" },
    { key = "nameplates", label = "Hide nameplates (keep system active)" },
    { key = "portraitDamage", label = "Show target damage on portrait" },
}

local checkboxes = {}
for index, option in ipairs(options) do
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -48 - (index - 1) * 39)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    label:SetText(option.label)
    check:SetScript("OnClick", function(self)
        local hide = self:GetChecked() and "on" or "off"
        if option.key == "portraitDamage" then
            SlashCmdList.CLEARVIEWFOREVER("portrait " .. hide)
            self:SetChecked(ClearViewForeverDB and ClearViewForeverDB.portraitDamage)
            return
        end
        -- Reuse the existing command handler so the UI and slash commands behave alike.
        SlashCmdList.CLEARVIEWFOREVER(option.key .. " " .. hide)
        self:SetChecked(ClearViewForeverDB and ClearViewForeverDB[option.key])
    end)
    checkboxes[option.key] = check
end

local note = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
note:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 24, 23)
note:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -24, 23)
note:SetJustifyH("LEFT")
note:SetText("XP hiding changes all world text. Hidden nameplates remain active.")

local function Refresh()
    for key, check in pairs(checkboxes) do
        check:SetChecked(ClearViewForeverDB and ClearViewForeverDB[key] or false)
    end
end
panel:SetScript("OnShow", Refresh)
panel:Hide()

if type(UISpecialFrames) == "table" then
    table.insert(UISpecialFrames, "ClearViewForeverOptions")
end

local originalCommand = SlashCmdList.CLEARVIEWFOREVER
SlashCmdList.CLEARVIEWFOREVER = function(message, ...)
    local trimmed = (message or ""):match("^%s*(.-)%s*$")
    if trimmed == "" or trimmed == "menu" then
        if panel:IsShown() then panel:Hide() else panel:Show() end
        return
    end
    originalCommand(message, ...)
    if panel:IsShown() then Refresh() end
end
