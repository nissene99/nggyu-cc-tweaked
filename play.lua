local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

local nft = require("cc.image.nft")

local url_image = "https://raw.githubusercontent.com/nissene99/nggyu-cc-tweaked/main/image/"
local url_sound = "https://raw.githubusercontent.com/nissene99/nggyu-cc-tweaked/main/audio/small.dfpwm"

local function download(url)
    local request = http.get(url)
    if not request then
        error("Failed to download " .. url)
    end
    return request.readAll()
end

local function play(url)
    local data = download(url)
    -- save the file to disk
    local file = io.open("temp.dfpwm", "w")
    file:write(data)
    file:close()
    -- play the file
    for chunk in io.lines("temp.dfpwm", 16*1024) do
        local buf = decoder(chunk)

        while not speaker.playAudio(buf) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    -- delete the file
    fs.delete("temp.dfpwm")
end

local function format_number(num)
    local str = tostring(num)
    while str:len() < 4 do
        str = "0" .. str
    end
    return str
end

local function show_image(url, duration)
    local data = download(url)
    local file = io.open("temp.nfp", "w")
    file:write(data)
    file:close()
    local image = assert(
        nft.load("temp.nfp")
    )
    nft.draw(image, term.getCursorPos())
    os.sleep(duration)
    fs.delete("temp.nfp")
end

local function show_images(begin_index, end_index, duration)
    for i = begin_index, end_index do
        show_image(url_image .. format_number(i) .. ".nfp", duration)
    end
end

local function video_player()
    local begin_index = 1
    local end_index = 212
    local duration = 1
    parallel.waitForAll(
        function()
            show_images(begin_index, end_index, duration)
        end,
        function()
            play(url_sound)
        end
    )
end

video_player()