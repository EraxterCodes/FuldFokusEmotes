-- FFE_Options.lua - Minimal options panel for FuldFokusEmotes
-- UI: enable/disable, size slider, emote selection (editbox + EasyMenu dropdown), preview, sync, clear.
-- Also exposes FFE.OpenOptions() so /ffe options can open the panel.

local ADDON_NAME = ...
FFE = FFE or {}

-- Pretty print
local function ok(msg) print("|cffe5a472FFE|r " .. tostring(msg)) end

-- --------------------------------------------------------------------
-- Emote discovery helpers (non-invasive; no filesystem scan necessary)
-- --------------------------------------------------------------------
local function BuildKnownKeys()
  local keys, seen = {}, {}

  -- (1) Optional: dev-provided list you can set from anywhere:
  --   FFE.PredefinedKeys = {"FuldFokus", "AnotherEmote"}
  if FFE.PredefinedKeys then
    for _, k in ipairs(FFE.PredefinedKeys) do
      if k and k ~= "" and not seen[k] then
        seen[k] = true; table.insert(keys, k)
      end
    end
  end

  -- (2) From TwitchEmotes metadata under our BASE_DIR (animated sheets)
  local meta = _G.TwitchEmotes_animation_metadata
  if meta and FFE.BASE_DIR then
    local base = FFE.BASE_DIR:lower()
    for path,_ in pairs(meta) do
      local p = tostring(path):lower()
      if p:sub(1, #base) == base then
        local fname = tostring(path):match("([^\\/:]+)%.[TtPpBb][GgNnLl][AaPp]$")
        if fname and not seen[fname] then
          seen[fname] = true; table.insert(keys, fname)
        end
      end
    end
  end

  -- (3) Ensure the current selection is present
  if FFE_DB and FFE_DB.selected and FFE_DB.selected ~= "" and not seen[FFE_DB.selected] then
    table.insert(keys, 1, FFE_DB.selected)
  end

  table.sort(keys)
  return keys
end

-- -----------------------
-- EasyMenu dropdown bits
-- -----------------------
local dropdownMenuFrame = CreateFrame("Frame", "FFE_EmoteDropdownMenu", UIParent, "UIDropDownMenuTemplate")

local function OpenEmoteDropdown(anchorButton, onPick)
  local keys = BuildKnownKeys()
  local menu = {}

  if #keys == 0 then
    table.insert(menu, { text = "No known emotes (type a key)", notCheckable = true, isTitle = true })
  else
    for _, k in ipairs(keys) do
      table.insert(menu, {
        text = k,
        checked = (FFE_DB and FFE_DB.selected == k) or false,
        func = function() if onPick then onPick(k) end end,
      })
    end
  end

  table.insert(menu, { text = "Clear (none)", notCheckable = true, func = function() onPick("none") end })
  EasyMenu(menu, dropdownMenuFrame, anchorButton, 0 , 0, "MENU", 2)
end

-- ---------------
-- Panel + widgets
-- ---------------
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

-- Animate (NEW)
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

-- Size slider
local size = CreateFrame("Slider", "FFE_SizeSlider", panel, "OptionsSliderTemplate")
size:SetPoint("TOPLEFT", animate, "BOTTOMLEFT", 0, -24)
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

-- Set button
local setBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
setBtn:SetPoint("LEFT", keyEdit, "RIGHT", 8, 0)
setBtn:SetSize(80, 22)
setBtn:SetText("Set")
setBtn:SetScript("OnClick", function()
  local k = keyEdit:GetText() or ""
  if FFE.SetSelectedEmote then FFE.SetSelectedEmote(k) end
  if _G.FFE_Preview then
    _G.FFE_Preview:SetText((FFE.TextureStringForKey and FFE.TextureStringForKey(FFE_DB.selected, FFE_DB.iconSize)) or "")
  end
end)

-- Dropdown button (EasyMenu)
local ddBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
ddBtn:SetPoint("LEFT", setBtn, "RIGHT", 6, 0)
ddBtn:SetSize(100, 22)
ddBtn:SetText("Select…")
ddBtn:SetScript("OnClick", function(self)
  OpenEmoteDropdown(self, function(k)
    if FFE.SetSelectedEmote then FFE.SetSelectedEmote(k) end
    keyEdit:SetText(k == "none" and "" or k)
    if _G.FFE_Preview then
      _G.FFE_Preview:SetText((FFE.TextureStringForKey and FFE.TextureStringForKey(FFE_DB.selected, FFE_DB.iconSize)) or "")
    end
  end)
end)

-- Preview
local previewLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
previewLabel:SetPoint("TOPLEFT", keyEdit, "BOTTOMLEFT", 0, -16)
previewLabel:SetText("Preview:")

local preview = panel:CreateFontString("FFE_Preview", "ARTWORK", "GameFontHighlightLarge")
preview:SetPoint("LEFT", previewLabel, "RIGHT", 8, 0)
preview:SetText("")

-- Buttons row: Sync / Clear
local syncBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
syncBtn:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -18)
syncBtn:SetSize(100, 22)
syncBtn:SetText("Sync now")
syncBtn:SetScript("OnClick", function()
  if FFE.SendState then
    local chan = FFE.SendState(true)
    ok("Sync " .. (chan and ("sent to " .. chan) or "attempted"))
  end
end)

local clearBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
clearBtn:SetPoint("LEFT", syncBtn, "RIGHT", 8, 0)
clearBtn:SetSize(100, 22)
clearBtn:SetText("Clear")
clearBtn:SetScript("OnClick", function()
  if FFE.Clear then FFE.Clear() end
  keyEdit:SetText("")
  if _G.FFE_Preview then
    _G.FFE_Preview:SetText((FFE.TextureStringForKey and FFE.TextureStringForKey(FFE_DB.selected, FFE_DB.iconSize)) or "")
  end
end)

-- Populate widgets from DB
local function RefreshPanel()
  if not FFE_DB then return end
  if FFE_DB.enabled == nil then FFE_DB.enabled = true end
  if FFE_DB.animate == nil then FFE_DB.animate = true end  -- NEW DEFAULT
  enable:SetChecked(FFE_DB.enabled ~= false)
  animate:SetChecked(FFE_DB.animate ~= false)              -- NEW
  size:SetValue(FFE_DB.iconSize or 16)
  keyEdit:SetText(FFE_DB.selected or "")
  preview:SetText((FFE.TextureStringForKey and FFE.TextureStringForKey(FFE_DB.selected, FFE_DB.iconSize)) or "")
end

panel.refresh = RefreshPanel
panel:SetScript("OnShow", RefreshPanel)

-- -------------------------------
-- Register panel with the client
-- -------------------------------
local category -- keep in outer scope so we can store a reference

if Settings and Settings.RegisterCanvasLayoutCategory then
  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
else
  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

-- Keep references so commands can open this panel
FFE._optionsPanel = panel
FFE._settingsCategory = category or nil

-- Public opener used by /ffe options
function FFE.OpenOptions()
  if Settings and Settings.OpenToCategory and FFE._settingsCategory then
    -- Dragonflight+ Settings UI
    local id = FFE._settingsCategory.ID or FFE._settingsCategory
    Settings.OpenToCategory(id)
  elseif InterfaceOptionsFrame_OpenToCategory and FFE._optionsPanel then
    -- Older Interface Options (call twice due to Blizzard bug)
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
