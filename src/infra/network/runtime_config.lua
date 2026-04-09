local AppConfig = require("src.core.config.app_config")
local default_config = require("src.core.settings.app_settings_config")

local RuntimeConfig = {
    http_base_url = nil,
    ws_base_url = nil,
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function stripTrailingSlash(value)
    return trim(value):gsub("/+$", "")
end

local function normalizeHost(value)
    return trim(value)
end

local function normalizePort(value, fallback)
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

local function normalizeTls(value, fallback)
    if value == nil then
        return fallback
    end
    return value == true
end

local function normalizeHttpBaseUrl(value)
    local normalized = stripTrailingSlash(value)
    if normalized == "" then
        normalized = stripTrailingSlash(default_config.server_http_base_url)
    end
    return normalized
end

local function deriveWsBaseUrl(http_base_url)
    local normalized_http = normalizeHttpBaseUrl(http_base_url)
    if normalized_http:match("^https://") then
        return (normalized_http:gsub("^https://", "wss://", 1))
    end
    if normalized_http:match("^http://") then
        return (normalized_http:gsub("^http://", "ws://", 1))
    end
    return stripTrailingSlash(default_config.server_ws_base_url)
end

local function normalizeWsBaseUrl(value, http_base_url)
    local normalized = stripTrailingSlash(value)
    if normalized == "" then
        normalized = deriveWsBaseUrl(http_base_url)
    end
    return normalized
end

local function buildBaseUrlsFromSettings(settings)
    local default_network = AppConfig.getDefaultNetwork()
    local host = normalizeHost((settings or {}).server_host)
    if host == "" then
        host = default_network.host
    end
    local port = normalizePort((settings or {}).server_port, default_network.port)
    local use_tls = normalizeTls((settings or {}).server_use_tls, default_network.use_tls)
    return AppConfig.buildBaseUrls({
        host = host,
        port = port,
        use_tls = use_tls,
    })
end

local function hasStructuredNetworkSettings(settings)
    return settings ~= nil and (
        settings.server_host ~= nil
        or settings.server_port ~= nil
        or settings.server_use_tls ~= nil
    )
end

function RuntimeConfig.applySettings(settings)
    local derived_urls = buildBaseUrlsFromSettings(settings)
    local http_source = hasStructuredNetworkSettings(settings) and derived_urls.http or ((settings or {}).server_http_base_url or derived_urls.http)
    local ws_source = hasStructuredNetworkSettings(settings) and derived_urls.ws or ((settings or {}).server_ws_base_url or derived_urls.ws)
    local next_http = normalizeHttpBaseUrl(http_source)
    RuntimeConfig.http_base_url = next_http
    RuntimeConfig.ws_base_url = normalizeWsBaseUrl(ws_source, next_http)
end

function RuntimeConfig.getHttpBaseUrl()
    if not RuntimeConfig.http_base_url then
        RuntimeConfig.applySettings(default_config)
    end
    return RuntimeConfig.http_base_url
end

function RuntimeConfig.getWsBaseUrl()
    if not RuntimeConfig.ws_base_url then
        RuntimeConfig.applySettings(default_config)
    end
    return RuntimeConfig.ws_base_url
end

return RuntimeConfig
