local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

local nft = require("cc.image.nft")

local url_image = "https://raw.githubusercontent.com/nissene99/nggyu-cc-tweaked/main/image/"
local url_sound = "https://raw.githubusercontent.com/nissene99/nggyu-cc-tweaked/main/audio/"

local function download(url)
    local request = http.get(url)
    if not request then
        error("Failed to download " .. url)
    end
    return request.readAll()
end

local function play(url)
    local samples_i, samples_n = 1, 48000 * 1.5
    local samples = {}
    for i = 1, samples_n do samples[i] = 0 end
    local data = download(url)
    -- save the file to disk
    local file = io.open("disk/temp.dfpwm", "wb")
    file:write(data)
    file:close()
    -- play the file
    for chunk in io.lines("disk/temp.dfpwm", 16*1024) do
        local buffer = decoder(chunk)

        for i = 1, #buffer do
            local original_value = buffer[i]

            -- Replace this sample with its current amplitude plus the amplitude from 1.5 seconds ago.
            -- We scale both to ensure the resulting value is still between -128 and 127.
            buffer[i] = original_value * 0.6 + samples[samples_i] * 0.4

            -- Now store the current sample, and move the "head" of our ring buffer forward one place.
            samples[samples_i] = original_value
            samples_i = samples_i + 1
            if samples_i > samples_n then samples_i = 1 end
        end

        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    -- delete the file
    fs.delete("disk/temp.dfpwm")
end



local function format_number(num)
    local str = tostring(num)
    while str:len() < 4 do
        str = "0" .. str
    end
    return str
end

local function play_audios(begin_index, end_index)
    for i = begin_index, end_index do
        local num = string.format("%03d", i)
        play(url_sound .. num .. ".dfpwm")
    end
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
            play_audios(0, 21)
        end
    )
end

video_player()