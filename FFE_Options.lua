-- FFE_Options.lua - Options panel for FuldFokusEmotes
-- This version:
--  - Keeps Set/Clear (Clear next to Set), no Select or Sync
--  - Adds "Enable Easter eggs" (default ON)
--  - Enter in the edit box applies (same as Set)

local ADDON_NAME = ...
FFE = FFE or {}

-- Pretty print
local function ok(msg) print("|cffe5a472FFE|r " .. tostring(msg)) end

-- Apply the typed key (used by Set button and Enter in the edit box)
local function ApplyEditBoxSelection(keyEdit, previewFS)
  local k = keyEdit:GetText() or ""
  if FFE.SetSelectedEmote then FFE.SetSelectedEmote(k) end
  if previewFS then
    previewFS:SetText((FFE.TextureStringForKey and FFE.TextureStringForKey(FFE_DB.selected, FFE_DB.iconSize)) or "")
  end
end

-- --------------------------------------------------------------------
-- Panel + widgets
-- --------------------------------------------------------------------
local panel = CreateFrame("Frame")
panel.name = "FuldFokus Emotes"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("FuldFokus Emotes")

local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
sub:SetText("Configure Details icons for FuldFokusEmotes.")

-- Enable
local enable = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
enable:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)
enable.Text:SetText("Enable icons in Details")
enable:SetScript("OnClick", function(self)
  FFE_DB.enabled = self:GetChecked() and true or false
  ok("Icons " .. (FFE_DB.enabled and "enabled" or "disabled") .. ".")
  if FFE.RefreshAllDisplayNames then FFE.RefreshAllDisplayNames() end
  if FFE.RefreshDetails then FFE.RefreshDetails() end
  if FFE.UpdateTicker then FFE.UpdateTicker() end
end)

-- Animate
local animate = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
animate:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 0, -12)
animate.Text:SetText("Animate emotes in Details")
animate:SetScript("OnClick", function(self)
  FFE_DB.animate = self:GetChecked() and true or false
  ok("Details emote animation " .. (FFE_DB.animate and "enabled" or "disabled") .. ".")
  if FFE.RefreshAllDisplayNames then FFE.RefreshAllDisplayNames() end
  if FFE.RefreshDetails then FFE.RefreshDetails() end
  if FFE.UpdateTicker then FFE.UpdateTicker() end
end)

-- Easter eggs (NEW)
local easter = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
easter:SetPoint("TOPLEFT", animate, "BOTTOMLEFT", 0, -12)
easter.Text:SetText("Enable Easter eggs")
easter:SetScript("OnClick", function(self)
  FFE_DB.easter = self:GetChecked() and true or false
  ok("Easter eggs " .. (FFE_DB.easter and "enabled" or "disabled") .. ".")
  if FFE.RefreshAllDisplayNames then FFE.RefreshAllDisplayNames() end
  if FFE.RefreshDetails then FFE.RefreshDetails() end
  if FFE.UpdateTicker then FFE.UpdateTicker() end
end)

-- Size slider
local size = CreateFrame("Slider", "FFE_SizeSlider", panel, "OptionsSliderTemplate")
size:SetPoint("TOPLEFT", easter, "BOTTOMLEFT", 0, -24)  -- moved under Easter eggs
size:SetMinMaxValues(8, 64)
size:SetValueStep(1)
size:SetObeyStepOnDrag(true)
size:SetWidth(240)
FFE_SizeSliderLow:SetText("8")
FFE_SizeSliderHigh:SetText("64")
FFE_SizeSliderText:SetText("Icon Size")

size:SetScript("OnValueChanged", function(self, v)
  if FFE.SetIconSize then FFE.SetIconSize(v) end
  if _G.FFE_Preview then
    _G.FFE_Preview:SetText((FFE.TextureStringForKey and FFE.TextureStringForKey(FFE_DB.selected, FFE_DB.iconSize)) or "")
  end
end)

-- Emote key label + editbox
local keyLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
keyLabel:SetPoint("TOPLEFT", size, "BOTTOMLEFT", 0, -18)
keyLabel:SetText("Emote key (filename without extension):")

local keyEdit = CreateFrame("EditBox", "FFE_KeyEditBox", panel, "InputBoxTemplate")
keyEdit:SetPoint("TOPLEFT", keyLabel, "BOTTOMLEFT", 0, -6)
keyEdit:SetSize(220, 24)
keyEdit:SetAutoFocus(false)

-- Pressing Enter applies (same as Set)
keyEdit:SetScript("OnEnterPressed", function(self)
  ApplyEditBoxSelection(self, _G.FFE_Preview)
  self:ClearFocus()
end)

-- Set button (applies current edit box value)
local setBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
setBtn:SetPoint("LEFT", keyEdit, "RIGHT", 8, 0)
setBtn:SetSize(80, 22)
setBtn:SetText("Set")
setBtn:SetScript("OnClick", function()
  ApplyEditBoxSelection(keyEdit, _G.FFE_Preview)
end)

-- Clear button (next to Set)
local clearBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
clearBtn:SetPoint("LEFT", setBtn, "RIGHT", 8, 0)
clearBtn:SetSize(100, 22)
clearBtn:SetText("Clear")
clearBtn:SetScript("OnClick", function()
  if FFE.Clear then FFE.Clear() end
  keyEdit:SetText("")
  if _G.FFE_Preview then
    _G.FFE_Preview:SetText((FFE.TextureStringForKey and FFE.TextureStringForKey(FFE_DB.selected, FFE_DB.iconSize)) or "")
  end
end)

-- Preview
local previewLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
previewLabel:SetPoint("TOPLEFT", keyEdit, "BOTTOMLEFT", 0, -16)
previewLabel:SetText("Preview:")

local preview = panel:CreateFontString("FFE_Preview", "ARTWORK", "GameFontHighlightLarge")
preview:SetPoint("LEFT", previewLabel, "RIGHT", 8, 0)
preview:SetText("")

-- Populate widgets from DB
local function RefreshPanel()
  if not FFE_DB then return end
  if FFE_DB.enabled == nil then FFE_DB.enabled = true end
  if FFE_DB.animate == nil then FFE_DB.animate = true end
  if FFE_DB.easter  == nil then FFE_DB.easter  = true end  -- default ON
  enable:SetChecked(FFE_DB.enabled ~= false)
  animate:SetChecked(FFE_DB.animate ~= false)
  easter:SetChecked(FFE_DB.easter  ~= false)
  size:SetValue(FFE_DB.iconSize or 16)
  keyEdit:SetText(FFE_DB.selected or "")
  preview:SetText((FFE.TextureStringForKey and FFE.TextureStringForKey(FFE_DB.selected, FFE_DB.iconSize)) or "")
end

panel.refresh = RefreshPanel
panel:SetScript("OnShow", RefreshPanel)

-- Register panel
local category
if Settings and Settings.RegisterCanvasLayoutCategory then
  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
else
  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

FFE._optionsPanel = panel
FFE._settingsCategory = category or nil

function FFE.OpenOptions()
  if Settings and Settings.OpenToCategory and FFE._settingsCategory then
    local id = FFE._settingsCategory.ID or FFE._settingsCategory
    Settings.OpenToCategory(id)
  elseif InterfaceOptionsFrame_OpenToCategory and FFE._optionsPanel then
    InterfaceOptionsFrame_OpenToCategory(FFE._optionsPanel)
    InterfaceOptionsFrame_OpenToCategory(FFE._optionsPanel)
  else
    ok("Open via Game Menu → Options → AddOns → " .. (panel.name or "FuldFokus Emotes"))
  end
end

-- Initialize on load
local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent", function(_, ev, name)
  if name == ADDON_NAME then
    C_Timer.After(0.1, RefreshPanel)
  end
end)
