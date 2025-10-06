local addonName = ...

FFE_DB = FFE_DB or { iconSize = 16, selected = "", rules = {} }
FFE = FFE or {}
FFE.debug = false

local function ok(msg) print("|cffe5a472FFE|r " .. tostring(msg)) end
local function dprint(msg) if FFE.debug then ok(msg) end end

FFE.BASE_DIR = "Interface\\AddOns\\FuldFokusEmotes\\Emotes\\FuldFokus\\"

local PREFIX = "FFE"
local _pName, _pRealm = UnitFullName("player")
local playerFullName = (_pRealm and _pRealm ~= "" and (_pName .. "-" .. _pRealm)) or _pName
local playerName = _pName  -- realm-less
local peersFull = {}  -- ["Name-Realm"] = { sel="key", sz=16, at=time }
local peersBase = {}  -- ["Name"]       = { sel="key", sz=16, at=time }  -- last-writer-wins for duplicates
local detailsHooked = false
local ticker
local DETAILS_ATTRIBUTE_DAMAGE = _G.DETAILS_ATTRIBUTE_DAMAGE or 1
local lastSend = 0

-- ---------- Public helpers ----------

function FFE.ResolveKey(key)
  if not key or key == "" then return nil end
  if key:find("\\") or key:find("^%d+$") then return key end
  local candidates = {
    FFE.BASE_DIR .. key .. ".tga",
    FFE.BASE_DIR .. key .. ".png",
    FFE.BASE_DIR .. key .. ".blp",
  }
  local hasAPI = C_Texture and C_Texture.GetFileIDFromPath
  for _, p in ipairs(candidates) do
    if hasAPI then
      if C_Texture.GetFileIDFromPath(p) then return p end
    else
      return p
    end
  end
  return nil
end

function FFE.TextureStringForKey(key, size)
  local path = FFE.ResolveKey(key)
  if not path then return "" end
  size = size or (FFE_DB and FFE_DB.iconSize) or 16

  local metaMap = _G.TwitchEmotes_animation_metadata
  if metaMap then
    local meta = metaMap[path]
    if meta then
      -- Preferred: use TwitchEmotes helpers, then force size
      if type(_G.TwitchEmotes_GetCurrentFrameNum) == "function"
         and type(_G.TwitchEmotes_BuildEmoteFrameString) == "function" then
        local frame = _G.TwitchEmotes_GetCurrentFrameNum(meta)
        local s = _G.TwitchEmotes_BuildEmoteFrameString(path, meta, frame, size, size)
        -- Some builds return a |T...|t with their own width/height. Force ours:
        if s and s:sub(1,2) == "|T" then
          s = s:gsub("^|T([^:]+):%d+:%d+(:?.*)|t$", function(tex, rest)
            return ("|T%s:%d:%d%s|t"):format(tex, size, size, rest or "")
          end)
        end
        if s and s ~= "" then return s end
      end

      -- Fallback: build our own cropped frame (supports vertical or grid sheets)
      local frames = tonumber(meta.nFrames) or tonumber(meta.frames) or 0
      local cols   = tonumber(meta.columns) or tonumber(meta.cols) or 1
      local rows   = tonumber(meta.rows) or 0
      local fps    = tonumber(meta.framerate) or tonumber(meta.fps) or 0
      local texW   = tonumber(meta.imageWidth) or tonumber(meta.texW)
      local texH   = tonumber(meta.imageHeight) or tonumber(meta.texH)

      if frames and frames > 1 and fps and fps > 0 and texW and texH then
        local now  = GetTime()
        local idx  = math.floor((now * fps) % frames)

        if (not rows or rows == 0) and cols and cols > 1 then
          rows = math.ceil(frames / cols)
        elseif (not cols or cols == 0) and rows and rows > 1 then
          cols = math.ceil(frames / rows)
        end
        cols = cols or 1
        rows = rows or frames

        local frameW = math.floor(texW / cols + 0.5)
        local frameH = math.floor(texH / rows + 0.5)
        local col    = idx % cols
        local row    = math.floor(idx / cols)

        local left   = col * frameW
        local right  = left + frameW
        local top    = row * frameH
        local bottom = top + frameH

        return ("|T%s:%d:%d:0:0:%d:%d:%d:%d:%d:%d|t")
          :format(path, size, size, texW, texH, left, right, top, bottom)
      end
    end
  end

  -- Static
  return ("|T%s:%d:%d|t"):format(path, size, size)
end

local function getEmoteForPlayer(name)
  if not name or name == "" then return "" end

  -- explicit per-player overrides (you can store with or without realm)
  if FFE_DB.rules and FFE_DB.rules[name] then
    local k = FFE_DB.rules[name]
    if FFE.ResolveKey(k) then return k end
  end

  -- me
  if name == playerName or name == playerFullName then
    return FFE_DB.selected or ""
  end

  -- exact full-name hit
  local st = peersFull[name]
  if st and st.sel and FFE.ResolveKey(st.sel) then
    return st.sel
  end

  -- try realm-less match
  local base = name:gsub("%-.*", "")
  st = peersBase[base]
  if st and st.sel and FFE.ResolveKey(st.sel) then
    return st.sel
  end

  return ""
end

local function anyAnimatedInUse()
  local function fpsForKey(k)
    if not k or k == "" then return 0 end
    local path = FFE.ResolveKey(k)
    if not path then return 0 end
    local meta = _G.TwitchEmotes_animation_metadata and _G.TwitchEmotes_animation_metadata[path]
    local frames = meta and (tonumber(meta.nFrames) or tonumber(meta.frames)) or 0
    local fps = meta and (tonumber(meta.framerate) or tonumber(meta.fps)) or 0
    if frames and frames > 1 and fps and fps > 0 then return fps end
    return 0
  end
  local fastest = 0
  fastest = math.max(fastest, fpsForKey(FFE_DB.selected))
  if FFE_DB.rules then for _, k in pairs(FFE_DB.rules) do fastest = math.max(fastest, fpsForKey(k)) end end
  for _, st in pairs(peersFull) do fastest = math.max(fastest, fpsForKey(st.sel)) end
  return fastest > 0, fastest
end

function FFE.RefreshDetails()
  local Details = _G._detalhes or _G.Details
  if Details and Details.RefreshMainWindow then
    Details:RefreshMainWindow(-1, true)
  end
end

-- actively reapply nicknames (so icons show even if Details caches display names)
function FFE.RefreshAllDisplayNames()
  local Details = _G._detalhes or _G.Details
  if not Details or not Details.GetCurrentCombat then return end
  local currentCombat = Details:GetCurrentCombat()
  if not currentCombat or not currentCombat.GetContainer then return end
  local actorContainer = currentCombat:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
  if not actorContainer or not actorContainer.ListActors then return end

  for _, actorObject in actorContainer:ListActors() do
    if actorObject and actorObject.Name and actorObject.SetDisplayName then
      local nick = Details:GetNickname(actorObject:Name(), false, true)
      if nick and nick ~= "" then actorObject:SetDisplayName(nick) end
    end
  end
end

function FFE.UpdateTicker()
  if ticker then ticker:Cancel(); ticker = nil end
  if FFE_DB.enabled == false then return end
  local has, fps = anyAnimatedInUse()
  if has then
    local interval = 1 / math.min(fps, 30)
    ticker = C_Timer.NewTicker(interval, function()
      FFE.RefreshAllDisplayNames()
      FFE.RefreshDetails()
    end)
  end
end

function FFE.SendState(force)
  local now = GetTime and GetTime() or 0
  if not force and (now - (lastSend or 0) < 1.5) then
    return
  end
  lastSend = now

  local chan = (IsInGroup(2) and "INSTANCE_CHAT") or (IsInRaid() and "RAID") or (IsInGroup() and "PARTY") or "GUILD"
  if C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered and C_ChatInfo.IsAddonMessagePrefixRegistered("FFE") then
    C_ChatInfo.SendAddonMessage("FFE", (FFE_DB.selected or "").."|"..tostring(FFE_DB.iconSize or 16), chan)
    if FFE.debug then print("|cffe5a472FFE|r Sent state to " .. chan .. " (" .. (FFE_DB.selected or "none") .. ", " .. tostring(FFE_DB.iconSize) .. ")") end
  end
end

function FFE.Clear()
  local oldSel  = FFE_DB.selected or ""
  local oldSize = FFE_DB.iconSize or 16

  FFE_DB.selected = ""
  FFE_DB.iconSize = 16

  ok(("Cleared. Emote='none', size=%d (was '%s' @ %d)"):format(
    FFE_DB.iconSize, (oldSel ~= "" and oldSel or "none"), oldSize))

  C_Timer.After(0,   function() FFE.RefreshAllDisplayNames(); FFE.RefreshDetails() end)
  C_Timer.After(0.2, function() FFE.SendState(true); FFE.UpdateTicker() end)
  C_Timer.After(0.6, function() FFE.RefreshAllDisplayNames(); FFE.RefreshDetails() end)
end

function FFE.SetSelectedEmote(k)
  if k == "none" or k == "" or not k then
    FFE_DB.selected = ""
    ok("Cleared emote selection.")
  else
    FFE_DB.selected = k
    local tex = (FFE.TextureStringForKey and FFE.TextureStringForKey(k, FFE_DB.iconSize)) or ""
    if tex ~= "" then
      ok(("Emote set: %s  (key='%s', size=%d)"):format(tex, k, FFE_DB.iconSize))
    else
      ok(("Emote set: '%s' (texture not resolved yet—may appear after reload)"):format(k))
    end
  end

  C_Timer.After(0, function() FFE.RefreshAllDisplayNames(); FFE.RefreshDetails() end)
  C_Timer.After(0.2, function() FFE.SendState(true); FFE.UpdateTicker() end)
  C_Timer.After(0.6, function() FFE.RefreshAllDisplayNames(); FFE.RefreshDetails() end)
end

function FFE.SetIconSize(n)
  n = tonumber(n)
  if not n then ok("Size must be a number between 8 and 64."); return end
  local old = FFE_DB.iconSize
  FFE_DB.iconSize = math.max(8, math.min(64, math.floor(n)))
  FFE.RefreshAllDisplayNames()
  FFE.RefreshDetails()
end

-- ---------- Details integration ----------

local function installDetailsHook()
  if detailsHooked then return end
  local detalhes = _G._detalhes or _G.Details
  if not detalhes then return end

  detalhes.ignore_nicktag = true
  local original = detalhes.GetNickname
  detailsHooked = true
  ok("Details hook installed.")

  -- Always prefix (some Details builds pass default=nil/true inconsistently)
  detalhes.GetNickname = function(self, name, default, silent)
  -- Helper: pass through to original and ensure realm removal on fallback
  local function passThrough()
    local result = original and original(self, name, default, silent)
    if type(result) == "string" and result ~= "" then
      return result
    end
    local shown = name or ""
    if detalhes.remove_realm_from_name and shown ~= "" then
      shown = shown:gsub("%-.*", "")
    end
    return shown
  end

  -- If disabled, behave like stock Details (no prefix), but still respect realm removal
  if FFE_DB.enabled == false then
    return passThrough()
  end

  -- Enabled: build prefix and prepend to whatever Details would show
  local key = getEmoteForPlayer(name)
  local prefix = (key and key ~= "") and (FFE.TextureStringForKey(key, FFE_DB.iconSize) .. " ") or ""
  return prefix .. passThrough()
end
end

-- ---------- Events ----------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
  C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
end

f:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local name = ...
    if name == addonName then
      FFE_DB.iconSize = FFE_DB.iconSize or 16
      FFE_DB.selected = FFE_DB.selected or ""
      FFE_DB.rules    = FFE_DB.rules or {}
      if FFE_DB.enabled == nil then FFE_DB.enabled = true end
      dprint("Addon loaded. Current: selected='" .. (FFE_DB.selected or "none") .. "', size=" .. tostring(FFE_DB.iconSize))
    end

  elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
  -- slight delay so the client knows which chat channel we're in
  C_Timer.After(0.5, function() FFE.SendState(true) end)
  FFE.RefreshAllDisplayNames()
  FFE.RefreshDetails()
  FFE.UpdateTicker()

  elseif event == "PLAYER_LOGIN" then
    installDetailsHook()

    -- Hook Details.RefreshMainWindow to reapply display names right before drawing
    local Details = _G._detalhes or _G.Details
    if Details and not FFE._refreshHooked and type(Details.RefreshMainWindow) == "function" then
      FFE._refreshHooked = true
      local original = Details.RefreshMainWindow
      Details.RefreshMainWindow = function(self, instanceOrForce, bForceRefresh)
        FFE.RefreshAllDisplayNames()
        return original(self, instanceOrForce, bForceRefresh)
      end
      dprint("RefreshMainWindow hook installed.")
    end

    FFE.UpdateTicker()
    ok("Ready. Selected='" .. (FFE_DB.selected == "" and "none" or FFE_DB.selected) .. "', size=" .. tostring(FFE_DB.iconSize) .. ". Try |cffffff00/ffe test|r.")
    C_Timer.After(1.0, FFE.SendState)

  elseif event == "CHAT_MSG_ADDON" then
  local prefix, msg, _, sender = ...
  if prefix == PREFIX then
    -- Ignore own broadcasts (compare using full name)
    if sender == playerFullName then return end

    local sel, sz = strsplit("|", msg or "")
    local st = { sel = sel or "", sz = tonumber(sz) or 16, at = GetTime() }

    -- Store by full and base name
    peersFull[sender] = st
    local base = sender:gsub("%-.*", "")
    peersBase[base] = st

    if FFE.debug then
      print("|cffe5a472FFE|r Received state from " .. (sender or "?") .. ": " .. (sel or "none") .. "@" .. (sz or 16))
    end

    FFE.RefreshAllDisplayNames()
    FFE.RefreshDetails()
    FFE.UpdateTicker()
  end

  else
    -- Helpful nudges during combat/roster changes
    FFE.RefreshAllDisplayNames()
    FFE.RefreshDetails()
    FFE.UpdateTicker()
  end
end)
