-- FFE_Commands.lua - slash commands
FFE = FFE or {}

SLASH_FFE1 = "/ffe"
SlashCmdList["FFE"] = function(msg)
  local cmd, rest = (msg or ""):match("^(%S+)%s*(.*)$")
  cmd = (cmd or ""):lower()

  local function help()
    print("|cffe5a472FFE|r commands:")
    print("/ffe help - show this help")
    print("/ffe status - show current selection, size, and resolved path")
    print("/ffe test - print a sample icon in chat to verify rendering")
    print("/ffe list - where emotes live / how to pick a key")
    print("/ffe set <key|none> - set your Details icon (filename without extension)")
    print("/ffe size <n> - icon size (8..64)")
  end

  if cmd == "" or cmd == "help" then
    help()

  elseif cmd == "status" then
    local sel = FFE_DB and FFE_DB.selected or ""
    local path = (FFE.ResolveKey and FFE.ResolveKey(sel)) or "(none)"
    print("|cffe5a472FFE|r Status:")
    print(" - Selected: " .. (sel == "" and "none" or sel))
    print(" - Resolved: " .. (path or "(none)"))
    print(" - Size: " .. tostring(FFE_DB and FFE_DB.iconSize or "n/a"))

  elseif cmd == "test" then
    local sel = FFE_DB and FFE_DB.selected or ""
    if sel == "" then
      print("|cffe5a472FFE|r No emote selected. Try: /ffe set FuldFokus")
    else
      local tex = (FFE.TextureStringForKey and FFE.TextureStringForKey(sel, FFE_DB.iconSize)) or ""
      print("|cffe5a472FFE|r Test: " .. tex .. " (key='" .. sel .. "', size=" .. tostring(FFE_DB.iconSize) .. ")")
    end

  elseif cmd == "list" then
    print("|cffe5a472FFE|r Emotes folder:")
    print(" Interface\\AddOns\\FuldFokusEmotes\\Emotes\\FuldFokus")
    print("Use the filename (without extension). Example: /ffe set FuldFokus")

  elseif cmd == "set" then
    if not FFE.SetSelectedEmote then
      print("|cffe5a472FFE|r Core not loaded yet.")
      return
    end
    local k = rest
    if not k or k == "" then
      print("|cffe5a472FFE|r Usage: /ffe set <key|none>")
      return
    end
    FFE.SetSelectedEmote(k)

  elseif cmd == "size" then
    if not FFE.SetIconSize then
      print("|cffe5a472FFE|r Core not loaded yet.")
      return
    end
    local n = tonumber(rest)
    if not n then
      print("|cffe5a472FFE|r Usage: /ffe size <8..64>")
      return
    end
    FFE.SetIconSize(n)

  else
    print("|cffe5a472FFE|r Unknown command: " .. (cmd or ""))
    help()
  end
end
