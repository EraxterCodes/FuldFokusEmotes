local EMOTES = { "wolt","emilFører","OnlyFans","sniffLoot","StroxxTlf","darioSmil","magexdd","mortenSur","eddyPeak","dembSmile","dembRizz","dembDespair","dembd","osmanBruh","levMette","wwwww","Scaredge","LockIn","magiBrain","GigaNæb","kvidder","wikked","MONKA","kaj","iAsk","GAMBAADDICT","fflol","ffActually","catsittingverycomfortable","pause","magiBoksen","EraxterSus","FuldDonk","EmilVinder","flyvebjørn","næb","naeb","fugl","doraGlad","doraW","skodbutik","rema","BobHehe","EmilOk","MortenW","magitlf","FuldFokus","EddySug","EmilMagi","MortenKniv","MortenSug" }
local BASE = "Interface\\AddOns\\FuldFokusEmotes\\Emotes\\FuldFokus\\"
local SIZE = ":28:28"

local ANIMATED = {
    FuldDonk = { nFrames=2, frameWidth=64, frameHeight=64, imageWidth=64, imageHeight=128, framerate=8, pingpong=false },
}

local function add_to_autocomplete(ids)
    Emoticons_Settings = Emoticons_Settings or {}
    Emoticons_Settings["ENABLE_AUTOCOMPLETE"] = true
    if AllTwitchEmoteNames then
        local excluded = {}
        if TwitchEmotes_ExcludedSuggestions then
            for _, e in ipairs(TwitchEmotes_ExcludedSuggestions) do excluded[e]=true end
        end
        local present = {}
        for _, name in ipairs(AllTwitchEmoteNames) do present[name]=true end
        for _, id in ipairs(ids) do
            if not excluded[id] and not present[id] then
                table.insert(AllTwitchEmoteNames, id)
            end
        end
        table.sort(AllTwitchEmoteNames)
    else
        Emoticons_SetAutoComplete(true)
    end
end

local function integrate()
    TwitchEmotes_defaultpack = TwitchEmotes_defaultpack or {}
    TwitchEmotes_emoticons   = TwitchEmotes_emoticons   or {}
    TwitchEmotes_dropdown_options = TwitchEmotes_dropdown_options or {}
    TwitchEmotes_animation_metadata = TwitchEmotes_animation_metadata or {}
    Emoticons_Settings = Emoticons_Settings or {}

    for _, id in ipairs(EMOTES) do
        local path = BASE .. id .. ".tga" .. SIZE
        TwitchEmotes_defaultpack[id] = path
        TwitchEmotes_emoticons[id] = id
        TwitchEmotes_emoticons[":"..id..":"] = id
    end

    for id, meta in pairs(ANIMATED) do
        local fullpath = BASE .. id .. ".tga"
        TwitchEmotes_animation_metadata[fullpath] = {
            nFrames = meta.nFrames,
            frameWidth = meta.frameWidth,
            frameHeight = meta.frameHeight,
            imageWidth = meta.imageWidth,
            imageHeight = meta.imageHeight,
            framerate = meta.framerate,
            pingpong = meta.pingpong,
        }
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

    add_to_autocomplete(EMOTES)
end

local function escpattern(x)
    return (x:gsub("%%","%%%%")
             :gsub("%^","%%^")
             :gsub("%$","%%$")
             :gsub("%(","%%(")
             :gsub("%)","%%)")
             :gsub("%.","%%.")
             :gsub("%[","%%[")
             :gsub("%]","%%]")
             :gsub("%*","%%*")
             :gsub("%+","%%+")
             :gsub("%-","%%-")
             :gsub("%?","%%?"))
end

local function FF_Animator_UpdateEmoteInFontString(fontstring, widthOverride, heightOverride, fixedFrame)
    local txt = fontstring:GetText()
    if not txt then return end
    for emoteTextureString in txt:gmatch("(|TInterface\\AddOns\\FuldFokusEmotes\\Emotes.-|t)") do
        local imagepath = emoteTextureString:match("|T(Interface\\AddOns\\FuldFokusEmotes\\Emotes.-%.tga).-|t")
        local animdata = TwitchEmotes_animation_metadata[imagepath]
        if animdata then
            local framenum = fixedFrame ~= nil and fixedFrame or TwitchEmotes_GetCurrentFrameNum(animdata)
            local replacement
            if widthOverride or heightOverride then
                replacement = TwitchEmotes_BuildEmoteFrameStringWithDimensions(imagepath, animdata, framenum, widthOverride or animdata.frameWidth, heightOverride or animdata.frameHeight)
            else
                replacement = TwitchEmotes_BuildEmoteFrameString(imagepath, animdata, framenum)
            end
            local nTxt = txt:gsub(escpattern(emoteTextureString), replacement)
            if fontstring.messageInfo ~= nil then fontstring.messageInfo.message = nTxt end
            fontstring:SetText(nTxt)
            txt = nTxt
        end
    end
end

local FF_TimeSince = 0
local FF_Frame = CreateFrame("Frame")
FF_Frame:SetScript("OnUpdate", function(_, elapsed)
    FF_TimeSince = FF_TimeSince + elapsed
    if FF_TimeSince >= 0.033 then
        for _, frameName in pairs(CHAT_FRAMES) do
            for _, visibleLine in ipairs(_G[frameName].visibleLines) do
                if _G[frameName]:IsShown() and visibleLine.messageInfo ~= TwitchEmotes_HoverMessageInfo then
                    FF_Animator_UpdateEmoteInFontString(visibleLine, 28, 28, nil)
                end
            end
        end
        if EditBoxAutoCompleteBox and EditBoxAutoCompleteBox:IsShown() and EditBoxAutoCompleteBox.existingButtonCount then
            for i = 1, EditBoxAutoCompleteBox.existingButtonCount do
                local cBtn = EditBoxAutoComplete_GetAutoCompleteButton(i)
                if cBtn:IsVisible() then
                    FF_Animator_UpdateEmoteInFontString(cBtn, 16, 16, nil)
                else
                    break
                end
            end
        end
        FF_TimeSince = 0
    end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", integrate)
