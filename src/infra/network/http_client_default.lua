local Platform = require("src.infra.system.platform")
local RuntimeConfig = require("src.infra.network.runtime_config")
local Support = require("src.infra.network.http_client_support")
local I18n = require("src.core.i18n.i18n")

local HttpClient = {}
HttpClient.__index = HttpClient

local request_counter = 0

local function nextTempPath(stem, extension)
    request_counter = request_counter + 1
    return Support.nextTempPath(stem, extension, request_counter)
end

function HttpClient.new(options)
    local self = setmetatable({}, HttpClient)
    self.base_url = (options and options.base_url) or RuntimeConfig.getHttpBaseUrl()
    self.mode = "default_curl"
    return self
end

function HttpClient:request(method, path, payload)
    local url = self.base_url .. path
    if method == "GET" and payload and next(payload) then
        url = url .. "?" .. Support.buildQuery(payload)
    end

    local response_path = nextTempPath("guandan_http_response", ".json")
    local curl_command = Platform.isWindows() and "curl.exe" or "curl"
    local curl_parts = {
        curl_command,
        "--silent",
        "--show-error",
        "--location",
        "--no-buffer",
        "--compressed",
        "--connect-timeout",
        "3",
        "--max-time",
        "10",
        "--output",
        Platform.quoteArg(response_path),
        "--write-out",
        Platform.quoteArg(Platform.formatCurlWriteOut("__STATUS__:%{response_code}")),
        "-X",
        Platform.quoteArg(method),
        "-H",
        Platform.quoteArg("Accept: application/json"),
    }

    if method == "POST" or method == "PATCH" then
        local request_body = require("src.infra.network.json").encodeObject(payload or {})
        curl_parts[#curl_parts + 1] = "-H"
        curl_parts[#curl_parts + 1] = Platform.quoteArg("Content-Type: application/json")
        curl_parts[#curl_parts + 1] = "--data"
        curl_parts[#curl_parts + 1] = Platform.quoteArg(request_body)
    end

    curl_parts[#curl_parts + 1] = Platform.quoteArg(url)
    local command = table.concat(curl_parts, " ") .. " 2>&1"

    Support.appendDebugLog({
        string.rep("=", 80),
        os.date("[%Y-%m-%d %H:%M:%S]") .. " REQUEST",
        "client_mode: " .. tostring(self.mode),
        "method: " .. tostring(method),
        "url: " .. tostring(url),
        "command: " .. tostring(command),
    })

    local pipe = io.popen(command, "r")
    if not pipe then
        Support.cleanupPaths({ response_path })
        return {
            ok = false,
            status = 0,
            error = I18n:t("network.curl_missing"),
        }
    end

    local raw_result = pipe:read("*a")
    pipe:close()
    local raw_body = Support.readTextFile(response_path) or ""
    Support.cleanupPaths({ response_path })

    local parsed = Support.parseResponse(raw_result, raw_body, nil)
    Support.appendDebugLog({
        "raw_result:",
        tostring(raw_result or ""),
        "raw_body:",
        tostring(raw_body or ""),
        "parsed_status: " .. tostring(parsed.status),
        "ok: " .. tostring(parsed.ok),
        "error_code: " .. tostring(parsed.error_code),
        "error: " .. tostring(parsed.error),
        "",
    })

    return parsed
end

function HttpClient:get(path, params)
    return self:request("GET", path, params)
end

function HttpClient:post(path, body)
    return self:request("POST", path, body)
end

function HttpClient:patch(path, body)
    return self:request("PATCH", path, body)
end

return HttpClient
