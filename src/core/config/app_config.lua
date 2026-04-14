local AppConfig = {
    startup = {
        mode = "practical", -- "dev", "practical", or legacy "pratical"
        server = "domestic", -- "local", "domestic", or "overseas"; "local" is only allowed in "dev"
    },
    network = {
        servers = {
            ["local"] = {
                host = "127.0.0.1",
                port = 8123,
                use_tls = false,
            },
            domestic = {
                host = "114.55.113.236",
                port = 8123,
                use_tls = false,
            },
            overseas = {
                host = "3.18.105.105",
                port = 8123,
                use_tls = false,
            },
        },
    },
}

local startup_network_cache = nil
local startup_network_resolved = false
local startup_server_key_cache = nil
local SERVER_KEYS = {
    "local",
    "domestic",
    "overseas",
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function boolValue(value)
    return value == true
end

local function numberValue(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil then
        return fallback
    end
    numeric = math.floor(numeric)
    if numeric < 1 or numeric > 65535 then
        return fallback
    end
    return numeric
end

local function copyNetwork(network)
    local source = network or {}
    return {
        host = trim(source.host),
        port = numberValue(source.port, 8123),
        use_tls = boolValue(source.use_tls),
    }
end

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function normalizeServerKey(value)
    local server_key = trim(value):lower()
    if server_key == "local_test" then
        return "local"
    end
    if server_key == "local" or server_key == "domestic" or server_key == "overseas" then
        return server_key
    end
    return "domestic"
end

local function normalizeStartupMode(value)
    local mode = trim(value):lower()
    if mode == "dev" then
        return "dev"
    end
    if mode == "practical" or mode == "pratical" then
        return "practical"
    end
    return "dev"
end

local function isServerAllowedInMode(server_key, startup_mode)
    if normalizeServerKey(server_key) == "local" then
        return startup_mode == "dev"
    end
    return true
end

local function isLoopbackHost(value)
    local host = trim(value):lower()
    return host == "127.0.0.1" or host == "localhost"
end

local function getServerPresetsTable()
    return (((AppConfig or {}).network or {}).servers) or {}
end

local function getRawServerPreset(server_key)
    local presets = getServerPresetsTable()
    return presets[normalizeServerKey(server_key)]
end

local function resolveStartupServerKey()
    local startup_mode = AppConfig.getStartupMode()
    local requested_server_key = normalizeServerKey(((AppConfig or {}).startup or {}).server)
    if isServerAllowedInMode(requested_server_key, startup_mode) then
        return requested_server_key, "configured"
    end
    return "domestic", "startup_mode_fallback"
end

local function resolveStartupNetwork()
    if startup_network_resolved then
        return copyNetwork(startup_network_cache)
    end

    startup_network_resolved = true

    local startup_mode = AppConfig.getStartupMode()
    local server_key, selection_source = resolveStartupServerKey()
    local selected = getRawServerPreset(server_key)
    if not selected then
        server_key = "domestic"
        selection_source = "missing_server_fallback"
        selected = getRawServerPreset(server_key)
    end

    startup_network_cache = copyNetwork(selected)
    startup_server_key_cache = server_key

    print(string.format(
        "[network] startup_mode=%s server=%s source=%s host=%s port=%s use_tls=%s",
        tostring(startup_mode),
        tostring(server_key),
        tostring(selection_source),
        tostring(startup_network_cache.host),
        tostring(startup_network_cache.port),
        tostring(startup_network_cache.use_tls)
    ))

    return copyNetwork(startup_network_cache)
end

function AppConfig.getDefaultNetwork()
    return resolveStartupNetwork()
end

function AppConfig.getStartupMode()
    return normalizeStartupMode((AppConfig.startup or {}).mode)
end

function AppConfig.isDevMode()
    return AppConfig.getStartupMode() == "dev"
end

function AppConfig.isPracticalMode()
    return AppConfig.getStartupMode() == "practical"
end

function AppConfig.getStartupServerKey()
    if not startup_network_resolved then
        resolveStartupNetwork()
    end
    return startup_server_key_cache
end

function AppConfig.isServerSelectable(server_key)
    return isServerAllowedInMode(server_key, AppConfig.getStartupMode())
end

function AppConfig.getServerPreset(server_key)
    local preset = getRawServerPreset(server_key)
    if not preset then
        return nil
    end
    return copyNetwork(preset)
end

function AppConfig.getServerPresets()
    local presets = {}
    for _, server_key in ipairs(SERVER_KEYS) do
        presets[server_key] = AppConfig.getServerPreset(server_key)
    end
    return presets
end

function AppConfig.isLocalNetwork(network)
    if not network then
        return false
    end

    if isLoopbackHost(network.host) then
        return true
    end

    local local_preset = AppConfig.getServerPreset("local")
    return local_preset ~= nil
        and trim(network.host):lower() == trim(local_preset.host):lower()
        and numberValue(network.port, local_preset.port) == local_preset.port
        and boolValue(network.use_tls) == local_preset.use_tls
end

function AppConfig.sanitizeNetworkSettings(settings)
    local sanitized = shallowCopy(settings)
    if AppConfig.isDevMode() then
        return sanitized, false
    end

    local current_network = {
        host = sanitized.server_host,
        port = sanitized.server_port,
        use_tls = sanitized.server_use_tls,
    }
    if not AppConfig.isLocalNetwork(current_network) then
        return sanitized, false
    end

    local fallback_network = AppConfig.getDefaultNetwork()
    local fallback_urls = AppConfig.buildBaseUrls(fallback_network)
    sanitized.server_host = fallback_network.host
    sanitized.server_port = fallback_network.port
    sanitized.server_use_tls = fallback_network.use_tls
    sanitized.server_http_base_url = fallback_urls.http
    sanitized.server_ws_base_url = fallback_urls.ws

    print(string.format(
        "[network] startup_mode=%s rejected_local_override=true fallback_server=%s fallback_host=%s fallback_port=%s",
        tostring(AppConfig.getStartupMode()),
        tostring(AppConfig.getStartupServerKey()),
        tostring(fallback_network.host),
        tostring(fallback_network.port)
    ))

    return sanitized, true
end

function AppConfig.buildBaseUrls(options)
    local network = options or AppConfig.getDefaultNetwork()
    local host = trim(network.host)
    local port = numberValue(network.port, 8123)
    local use_tls = boolValue(network.use_tls)

    local http_scheme = use_tls and "https" or "http"
    local ws_scheme = use_tls and "wss" or "ws"
    local authority = string.format("%s:%d", host, port)

    return {
        http = string.format("%s://%s", http_scheme, authority),
        ws = string.format("%s://%s", ws_scheme, authority),
    }
end

return AppConfig
