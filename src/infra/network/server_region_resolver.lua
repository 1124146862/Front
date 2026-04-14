do
    local AppConfig = require("src.core.config.app_config")

    local Resolver = {}

    function Resolver.resolveDefaultNetwork()
        return AppConfig.getDefaultNetwork()
    end

    return Resolver
end

local AppConfig = require("src.core.config.app_config")
local HttpClient = require("src.infra.network.http_client")

local Resolver = {}

local cached_network = nil

local DOMESTIC_NETWORK = {
    host = "114.55.113.236",
    port = 8123,
    use_tls = false,
}

local OVERSEAS_NETWORK = {
    host = "3.18.105.105",
    port = 8123,
    use_tls = false,
}

local GEOLOOKUP_BASE_URL = "https://ipapi.co"

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function hasExplicitNetworkOverride()
    local host = trim(os.getenv("GUANDAN_SERVER_HOST"))
    local port = trim(os.getenv("GUANDAN_SERVER_PORT"))
    local use_tls = trim(os.getenv("GUANDAN_SERVER_USE_TLS"))
    return host ~= "" or port ~= "" or use_tls ~= ""
end

local function copyNetwork(network)
    return {
        host = tostring(network and network.host or ""),
        port = tonumber(network and network.port) or DOMESTIC_NETWORK.port,
        use_tls = network and network.use_tls == true,
    }
end

local function isChinaCountryCode(value)
    local code = trim(value):upper()
    return code == "CN"
        or code == "CHN"
        or code == "CHINA"
        or code == "中华人民共和国"
end

local function shouldAutoDetect(default_network)
    if hasExplicitNetworkOverride() then
        return false
    end

    if not default_network then
        return true
    end

    local host = trim(default_network.host)
    local port = tonumber(default_network.port)
    local use_tls = default_network.use_tls == true

    return (host == "" or host == "127.0.0.1" or host == "localhost")
        and (port == nil or port == DOMESTIC_NETWORK.port)
        and not use_tls
end

local function pickNetworkFromCountry(country_code)
    if isChinaCountryCode(country_code) then
        return DOMESTIC_NETWORK, "cn"
    end

    if trim(country_code) ~= "" then
        return OVERSEAS_NETWORK, string.lower(trim(country_code))
    end

    return DOMESTIC_NETWORK, "fallback"
end

function Resolver.resolveDefaultNetwork()
    if cached_network then
        return copyNetwork(cached_network)
    end

    local default_network = AppConfig.getDefaultNetwork()
    if not shouldAutoDetect(default_network) then
        cached_network = copyNetwork(default_network)
        return copyNetwork(cached_network)
    end

    local selected_network = DOMESTIC_NETWORK
    local detection_source = "fallback"
    local country_code = nil

    local client = HttpClient.new({
        base_url = GEOLOOKUP_BASE_URL,
    })
    local result = client:get("/json/")

    if result and result.ok and type(result.data) == "table" then
        country_code = result.data.country_code
            or result.data.countryCode
            or result.data.country
        selected_network, detection_source = pickNetworkFromCountry(country_code)
    end

    cached_network = copyNetwork(selected_network)

    print(string.format(
        "[network] auto-selected host=%s port=%s use_tls=%s source=%s country=%s",
        tostring(cached_network.host),
        tostring(cached_network.port),
        tostring(cached_network.use_tls),
        tostring(detection_source),
        tostring(country_code or "")
    ))

    return copyNetwork(cached_network)
end

return Resolver
