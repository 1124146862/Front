local AudioCatalog = require("src.core.audio.audio_catalog")

local AudioManager = {}
AudioManager.__index = AudioManager

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function safeNewSource(path, source_type)
    local ok, source = pcall(love.audio.newSource, path, source_type)
    if not ok then
        return nil
    end
    return source
end

function AudioManager.new(options)
    local self = setmetatable({}, AudioManager)

    self.catalog = (options and options.catalog) or AudioCatalog
    self.settings = (options and options.settings) or {}

    self.master_volume = 1
    self.bgm_volume = 1
    self.sfx_volume = 1
    self.mute_master = false
    self.mute_bgm = false
    self.mute_sfx = false

    self.current_bgm_id = nil
    self.current_bgm_source = nil
    self.sfx_prototypes = {}
    self.active_sfx_sources = {}
    self.looped_sfx_sources = {}
    self.looped_sfx_settings = {}

    self:applySettings(self.settings)

    return self
end

function AudioManager:applySettings(settings)
    settings = settings or {}
    self.settings = settings
    self.master_volume = clamp(tonumber(settings.audio_master_volume) or 1, 0, 1)
    self.bgm_volume = clamp(tonumber(settings.audio_bgm_volume) or 1, 0, 1)
    self.sfx_volume = clamp(tonumber(settings.audio_sfx_volume) or 1, 0, 1)
    self.mute_master = settings.audio_mute_master == true
    self.mute_bgm = settings.audio_mute_bgm == true
    self.mute_sfx = settings.audio_mute_sfx == true
    self:refreshVolumes()
end

function AudioManager:getGain(channel)
    if self.mute_master then
        return 0
    end

    if channel == "bgm" then
        if self.mute_bgm then
            return 0
        end
        return clamp(self.master_volume * self.bgm_volume, 0, 1)
    end

    if self.mute_sfx then
        return 0
    end
    return clamp(self.master_volume * self.sfx_volume, 0, 1)
end

function AudioManager:refreshVolumes()
    if self.current_bgm_source then
        self.current_bgm_source:setVolume(self:getGain("bgm"))
    end
    for sfx_id, source in pairs(self.looped_sfx_sources) do
        local settings = self.looped_sfx_settings[sfx_id] or {}
        local gain = tonumber(settings.gain) or 1
        source:setVolume(self:getGain("sfx") * gain)
    end
end

function AudioManager:loadBgmSource(bgm_id)
    local path = ((self.catalog or {}).bgm or {})[bgm_id]
    if not path then
        return nil
    end

    local source = safeNewSource(path, "stream")
    if not source then
        return nil
    end

    source:setLooping(true)
    return source
end

function AudioManager:setBgm(bgm_id)
    if not bgm_id or bgm_id == "" then
        self:stopBgm()
        return false
    end

    if self.current_bgm_id == bgm_id and self.current_bgm_source then
        self.current_bgm_source:setVolume(self:getGain("bgm"))
        if not self.current_bgm_source:isPlaying() then
            self.current_bgm_source:play()
        end
        return true
    end

    self:stopBgm()

    local source = self:loadBgmSource(bgm_id)
    if not source then
        return false
    end

    source:setVolume(self:getGain("bgm"))
    source:play()
    self.current_bgm_id = bgm_id
    self.current_bgm_source = source
    return true
end

function AudioManager:stopBgm()
    if self.current_bgm_source then
        self.current_bgm_source:stop()
    end
    self.current_bgm_source = nil
    self.current_bgm_id = nil
end

function AudioManager:getSfxPrototype(sfx_id)
    local prototype = self.sfx_prototypes[sfx_id]
    if prototype then
        return prototype
    end

    local path = ((self.catalog or {}).sfx or {})[sfx_id]
    if not path then
        return nil
    end

    prototype = safeNewSource(path, "static")
    if not prototype then
        return nil
    end

    self.sfx_prototypes[sfx_id] = prototype
    return prototype
end

function AudioManager:playSfx(sfx_id)
    local prototype = self:getSfxPrototype(sfx_id)
    if not prototype then
        return false
    end

    local source = prototype:clone()
    source:setVolume(self:getGain("sfx"))
    source:play()
    self.active_sfx_sources[#self.active_sfx_sources + 1] = source
    return true
end

function AudioManager:getSfxDuration(sfx_id)
    local prototype = self:getSfxPrototype(sfx_id)
    if not prototype then
        return nil
    end

    local ok, duration = pcall(function()
        return prototype:getDuration()
    end)
    if not ok or type(duration) ~= "number" or duration <= 0 then
        return nil
    end
    return duration
end

function AudioManager:playLoopedSfx(sfx_id, options)
    options = options or {}
    local gain = tonumber(options.gain) or 1
    local existing = self.looped_sfx_sources[sfx_id]
    if existing then
        self.looped_sfx_settings[sfx_id] = {
            gain = gain,
        }
        existing:setVolume(self:getGain("sfx") * gain)
        existing:setPitch(tonumber(options.pitch) or 1)
        if not existing:isPlaying() then
            existing:play()
        end
        return true
    end

    local prototype = self:getSfxPrototype(sfx_id)
    if not prototype then
        return false
    end

    local source = prototype:clone()
    source:setLooping(true)
    source:setPitch(tonumber(options.pitch) or 1)
    source:setVolume(self:getGain("sfx") * gain)
    source:play()
    self.looped_sfx_sources[sfx_id] = source
    self.looped_sfx_settings[sfx_id] = {
        gain = gain,
    }
    return true
end

function AudioManager:stopLoopedSfx(sfx_id)
    local source = self.looped_sfx_sources[sfx_id]
    if not source then
        return false
    end
    source:stop()
    self.looped_sfx_sources[sfx_id] = nil
    self.looped_sfx_settings[sfx_id] = nil
    return true
end

function AudioManager:stopAllLoopedSfx()
    for sfx_id, source in pairs(self.looped_sfx_sources) do
        source:stop()
        self.looped_sfx_sources[sfx_id] = nil
        self.looped_sfx_settings[sfx_id] = nil
    end
end

function AudioManager:playClick()
    return self:playSfx("click_button")
end

function AudioManager:update()
    for index = #self.active_sfx_sources, 1, -1 do
        if not self.active_sfx_sources[index]:isPlaying() then
            table.remove(self.active_sfx_sources, index)
        end
    end
end

function AudioManager:shutdown()
    self:stopBgm()
    self:stopAllLoopedSfx()
    for _, source in ipairs(self.active_sfx_sources) do
        source:stop()
    end
    self.active_sfx_sources = {}
end

return AudioManager
