local EMOTES = { "EmilOk", "MortenW", "magitlf" } -- Emotes
local BASE = "Interface\\AddOns\\FuldFokusEmotes\\Emotes\\FuldFokus\\"
local SIZE = ":28:28"

local function integrate()
    TwitchEmotes_defaultpack = TwitchEmotes_defaultpack or {}
    TwitchEmotes_emoticons   = TwitchEmotes_emoticons   or {}
    TwitchEmotes_dropdown_options = TwitchEmotes_dropdown_options or {}
    Emoticons_Settings = Emoticons_Settings or {}

    for _, id in ipairs(EMOTES) do
        local path = BASE .. id .. ".tga" .. SIZE
        TwitchEmotes_defaultpack[id] = path
        TwitchEmotes_emoticons[id] = id
        TwitchEmotes_emoticons[":"..id..":"] = id
    end

    local catIndex
    for i, cat in ipairs(TwitchEmotes_dropdown_options) do
        if type(cat) == "table" and cat[1] == "FuldFokus" then catIndex = i break end
    end
    if not catIndex then
        table.insert(TwitchEmotes_dropdown_options, { "FuldFokus" })
        catIndex = #TwitchEmotes_dropdown_options
    end

    local cat = TwitchEmotes_dropdown_options[catIndex]
    local present = {}
    for i = 2, #cat do present[cat[i]] = true end
    for _, id in ipairs(EMOTES) do
        if not present[id] then table.insert(cat, id) end
    end

    Emoticons_Settings["FAVEMOTES"] = Emoticons_Settings["FAVEMOTES"] or {}
    for i = #Emoticons_Settings["FAVEMOTES"] + 1, catIndex do
        Emoticons_Settings["FAVEMOTES"][i] = true
    end

    print("|cff00ff00FuldFokusEmotes integrated!|r Added: " .. table.concat(EMOTES, ", "))
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and (name == "FoldFokusEmotes" or name == "TwitchEm  otes") then
        integrate()
    elseif event == "PLAYER_LOGIN" then
        integrate()
    end
end)
