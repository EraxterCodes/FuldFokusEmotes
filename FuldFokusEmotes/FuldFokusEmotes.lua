local function integrate()
    local path = "Interface\\AddOns\\FuldFokusEmotes\\Emotes\\FuldFokus\\EmilOk.tga:28:28"

    TwitchEmotes_defaultpack = TwitchEmotes_defaultpack or {}
    TwitchEmotes_emoticons   = TwitchEmotes_emoticons   or {}
    TwitchEmotes_dropdown_options = TwitchEmotes_dropdown_options or {}
    Emoticons_Settings = Emoticons_Settings or {}


    TwitchEmotes_defaultpack["EmilOk"] = path
    TwitchEmotes_emoticons["EmilOk"]   = "EmilOk"
    TwitchEmotes_emoticons[":EmilOk:"] = "EmilOk"
    local catIndex = nil
    for i, cat in ipairs(TwitchEmotes_dropdown_options) do
        if type(cat) == "table" and cat[1] == "FuldFokus" then
            catIndex = i
            local found = false
            for j = 2, #cat do
                if cat[j] == "EmilOk" then found = true break end
            end
            if not found then table.insert(cat, "EmilOk") end
            break
        end
    end

    if not catIndex then
        table.insert(TwitchEmotes_dropdown_options, { "FuldFokus", "EmilOk" })
        catIndex = #TwitchEmotes_dropdown_options
    end

    Emoticons_Settings["FAVEMOTES"] = Emoticons_Settings["FAVEMOTES"] or {}
    for i = #Emoticons_Settings["FAVEMOTES"] + 1, catIndex do
        Emoticons_Settings["FAVEMOTES"][i] = true
    end

    print("|cff00ff00FuldFokusEmotes integrated!|r :EmilOk: in category 'FuldFokus'")
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", integrate)
