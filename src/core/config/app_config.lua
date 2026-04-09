local Platform = require("src.infra.system.platform")

local AppConfig = {
    network = {
        mode = "local", -- "local", "cloud_default", or "ip_based"
        local_server = {
            host = "127.0.0.1",
            port = 8123,
            use_tls = false,
        },
        cloud_default_server = {
                host = "3.18.105.105",
                port = 8123,
                use_tls = false,
        },
        ip_based_servers = {
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

local function normalizeMode(value)
    local mode = trim(value)
    if mode == "local" or mode == "cloud_default" or mode == "ip_based" then
        return mode
    end
    return "cloud_default"
end

local function isChinaCountryCode(value)
    local code = trim(value):upper()
    return code == "CN" or code == "CHN" or code == "CHINA"
end

local function detectCountryCode()
    local curl_command = Platform.isWindows() and "curl.exe" or "curl"
    local command = table.concat({
        curl_command,
        "--silent",
        "--show-error",
        "--max-time",
        "3",
        "https://ipapi.co/json/",
    }, " ")

    local pipe = io.popen(command, "r")
    if not pipe then
        return nil
    end

    local body = pipe:read("*a") or ""
    pipe:close()

    local country_code = body:match('"country_code"%s*:%s*"([^"]+)"')
        or body:match('"countryCode"%s*:%s*"([^"]+)"')
        or body:match('"country"%s*:%s*"([^"]+)"')

    return trim(country_code)
end

local function resolveStartupNetwork()
    if startup_network_resolved then
        return copyNetwork(startup_network_cache)
    end

    startup_network_resolved = true

    local mode = normalizeMode((AppConfig.network or {}).mode)
    local selected = nil
    local country_code = nil
    local selection_source = mode

    if mode == "local" then
        selected = AppConfig.network.local_server
    elseif mode == "cloud_default" then
        selected = AppConfig.network.cloud_default_server
    else
        country_code = detectCountryCode()
        if isChinaCountryCode(country_code) then
            selected = AppConfig.network.ip_based_servers.domestic
            selection_source = "ip_based_cn"
        elseif trim(country_code) ~= "" then
            selected = AppConfig.network.ip_based_servers.overseas
            selection_source = "ip_based_overseas"
        else
            selected = AppConfig.network.ip_based_servers.domestic
            selection_source = "ip_based_fallback"
        end
    end

    startup_network_cache = copyNetwork(selected)

    print(string.format(
        "[network] startup_mode=%s source=%s host=%s port=%s use_tls=%s country=%s",
        tostring(mode),
        tostring(selection_source),
        tostring(startup_network_cache.host),
        tostring(startup_network_cache.port),
        tostring(startup_network_cache.use_tls),
        tostring(country_code or "")
    ))

    return copyNetwork(startup_network_cache)
end

function AppConfig.getDefaultNetwork()
    return resolveStartupNetwork()
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
