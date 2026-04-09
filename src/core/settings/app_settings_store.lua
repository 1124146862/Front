local default_config = require("src.core.settings.app_settings_config")

local AppSettingsStore = {}
AppSettingsStore.__index = AppSettingsStore

local SETTINGS_FILE = "user_settings.lua"
local PERSISTED_KEYS = {
    language = true,
    server_host = true,
    server_port = true,
    server_use_tls = true,
    server_http_base_url = true,
    server_ws_base_url = true,
    window_width = true,
    window_height = true,
    target_fps = true,
    audio_master_volume = true,
    audio_bgm_volume = true,
    audio_sfx_volume = true,
    preferred_game_bgm_id = true,
    preferred_gameplay_background_theme = true,
    cards_high_contrast = true,
}

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function mergeSettings(persisted)
    local merged = shallowCopy(default_config)
    for key, value in pairs(persisted or {}) do
        if PERSISTED_KEYS[key] then
            merged[key] = value
        end
    end
    return merged
end

local function serializeValue(value, indent)
    indent = indent or ""

    if type(value) == "table" then
        local next_indent = indent .. "    "
        local lines = { "{\n" }
        for key, entry in pairs(value) do
            lines[#lines + 1] = next_indent .. key .. " = " .. serializeValue(entry, next_indent) .. ",\n"
        end
        lines[#lines + 1] = indent .. "}"
        return table.concat(lines)
    end

    if type(value) == "string" then
        return string.format("%q", value)
    end

    if type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    end

    return "nil"
end

function AppSettingsStore.new()
    return setmetatable({}, AppSettingsStore)
end

function AppSettingsStore:load()
    if not love.filesystem.getInfo(SETTINGS_FILE) then
        return mergeSettings()
    end

    local chunk, load_error = love.filesystem.load(SETTINGS_FILE)
    if not chunk then
        return mergeSettings()
    end

    local ok, persisted = pcall(chunk)
    if not ok or type(persisted) ~= "table" then
        return mergeSettings()
    end

    return mergeSettings(persisted)
end

function AppSettingsStore:save(settings)
    local merged = mergeSettings(settings)
    local persisted = {}
    for key, enabled in pairs(PERSISTED_KEYS) do
        if enabled then
            persisted[key] = merged[key]
        end
    end
    local payload = "return " .. serializeValue(persisted) .. "\n"
    love.filesystem.write(SETTINGS_FILE, payload)
    return merged
end

function AppSettingsStore:update(patch)
    local current = self:load()
    for key, value in pairs(patch or {}) do
        if PERSISTED_KEYS[key] then
            current[key] = value
        end
    end
    return self:save(current)
end

return AppSettingsStore
