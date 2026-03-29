local HttpClient = {}
HttpClient.__index = HttpClient

local JSON_NULL = {}

local function shellQuote(value)
    return "'" .. tostring(value):gsub("'", "'\"'\"'") .. "'"
end

local function urlEncode(value)
    return tostring(value)
        :gsub("\n", "\r\n")
        :gsub("([^%w%-_%.~])", function(char)
            return string.format("%%%02X", string.byte(char))
        end)
end

local function buildQuery(params)
    if not params then
        return ""
    end

    local parts = {}
    for key, value in pairs(params) do
        parts[#parts + 1] = urlEncode(key) .. "=" .. urlEncode(value)
    end

    return table.concat(parts, "&")
end

local function encodeJsonValue(value)
    local value_type = type(value)

    if value_type == "string" then
        local escaped = value
            :gsub("\\", "\\\\")
            :gsub("\"", "\\\"")
            :gsub("\n", "\\n")
            :gsub("\r", "\\r")
        return "\"" .. escaped .. "\""
    end

    if value_type == "number" or value_type == "boolean" then
        return tostring(value)
    end

    if value == nil then
        return "null"
    end

    error("Unsupported JSON value type: " .. value_type)
end

local function encodeJsonObject(payload)
    local parts = {}

    for key, value in pairs(payload or {}) do
        parts[#parts + 1] = "\"" .. tostring(key) .. "\":" .. encodeJsonValue(value)
    end

    return "{" .. table.concat(parts, ",") .. "}"
end

local function utf8EncodeCodepoint(codepoint)
    if codepoint <= 0x7F then
        return string.char(codepoint)
    end

    if codepoint <= 0x7FF then
        local byte1 = 0xC0 + math.floor(codepoint / 0x40)
        local byte2 = 0x80 + (codepoint % 0x40)
        return string.char(byte1, byte2)
    end

    if codepoint <= 0xFFFF then
        local byte1 = 0xE0 + math.floor(codepoint / 0x1000)
        local byte2 = 0x80 + (math.floor(codepoint / 0x40) % 0x40)
        local byte3 = 0x80 + (codepoint % 0x40)
        return string.char(byte1, byte2, byte3)
    end

    local byte1 = 0xF0 + math.floor(codepoint / 0x40000)
    local byte2 = 0x80 + (math.floor(codepoint / 0x1000) % 0x40)
    local byte3 = 0x80 + (math.floor(codepoint / 0x40) % 0x40)
    local byte4 = 0x80 + (codepoint % 0x40)
    return string.char(byte1, byte2, byte3, byte4)
end

local function decodeJson(raw)
    local position = 1

    local function skipWhitespace()
        while true do
            local char = raw:sub(position, position)
            if char == "" or not char:match("%s") then
                return
            end
            position = position + 1
        end
    end

    local parseValue

    local function parseString()
        position = position + 1
        local parts = {}

        while position <= #raw do
            local char = raw:sub(position, position)
            if char == "\"" then
                position = position + 1
                return table.concat(parts)
            end

            if char == "\\" then
                local escaped = raw:sub(position + 1, position + 1)
                if escaped == "\"" or escaped == "\\" or escaped == "/" then
                    parts[#parts + 1] = escaped
                    position = position + 2
                elseif escaped == "b" then
                    parts[#parts + 1] = "\b"
                    position = position + 2
                elseif escaped == "f" then
                    parts[#parts + 1] = "\f"
                    position = position + 2
                elseif escaped == "n" then
                    parts[#parts + 1] = "\n"
                    position = position + 2
                elseif escaped == "r" then
                    parts[#parts + 1] = "\r"
                    position = position + 2
                elseif escaped == "t" then
                    parts[#parts + 1] = "\t"
                    position = position + 2
                elseif escaped == "u" then
                    local hex = raw:sub(position + 2, position + 5)
                    if #hex < 4 or not hex:match("^%x%x%x%x$") then
                        error("Invalid unicode escape in JSON string")
                    end
                    parts[#parts + 1] = utf8EncodeCodepoint(tonumber(hex, 16))
                    position = position + 6
                else
                    error("Invalid escape sequence in JSON string")
                end
            else
                parts[#parts + 1] = char
                position = position + 1
            end
        end

        error("Unterminated JSON string")
    end

    local function parseNumber()
        local start_pos = position
        local char = raw:sub(position, position)

        if char == "-" then
            position = position + 1
        end

        while raw:sub(position, position):match("%d") do
            position = position + 1
        end

        if raw:sub(position, position) == "." then
            position = position + 1
            while raw:sub(position, position):match("%d") do
                position = position + 1
            end
        end

        local exponent = raw:sub(position, position)
        if exponent == "e" or exponent == "E" then
            position = position + 1
            local sign = raw:sub(position, position)
            if sign == "+" or sign == "-" then
                position = position + 1
            end
            while raw:sub(position, position):match("%d") do
                position = position + 1
            end
        end

        return tonumber(raw:sub(start_pos, position - 1))
    end

    local function parseArray()
        position = position + 1
        local result = {}
        skipWhitespace()

        if raw:sub(position, position) == "]" then
            position = position + 1
            return result
        end

        while true do
            result[#result + 1] = parseValue()
            skipWhitespace()

            local char = raw:sub(position, position)
            if char == "]" then
                position = position + 1
                return result
            end

            if char ~= "," then
                error("Invalid JSON array separator")
            end

            position = position + 1
            skipWhitespace()
        end
    end

    local function parseObject()
        position = position + 1
        local result = {}
        skipWhitespace()

        if raw:sub(position, position) == "}" then
            position = position + 1
            return result
        end

        while true do
            if raw:sub(position, position) ~= "\"" then
                error("Invalid JSON object key")
            end

            local key = parseString()
            skipWhitespace()

            if raw:sub(position, position) ~= ":" then
                error("Invalid JSON object separator")
            end

            position = position + 1
            skipWhitespace()
            local value = parseValue()
            result[key] = value == JSON_NULL and nil or value
            skipWhitespace()

            local char = raw:sub(position, position)
            if char == "}" then
                position = position + 1
                return result
            end

            if char ~= "," then
                error("Invalid JSON object separator")
            end

            position = position + 1
            skipWhitespace()
        end
    end

    function parseValue()
        skipWhitespace()
        local char = raw:sub(position, position)

        if char == "\"" then
            return parseString()
        end

        if char == "{" then
            return parseObject()
        end

        if char == "[" then
            return parseArray()
        end

        if char == "-" or char:match("%d") then
            return parseNumber()
        end

        if raw:sub(position, position + 3) == "true" then
            position = position + 4
            return true
        end

        if raw:sub(position, position + 4) == "false" then
            position = position + 5
            return false
        end

        if raw:sub(position, position + 3) == "null" then
            position = position + 4
            return JSON_NULL
        end

        error("Unexpected JSON token at position " .. tostring(position))
    end

    local ok, result = pcall(parseValue)
    if not ok then
        return nil, result
    end

    return result, nil
end

function HttpClient.new(options)
    local self = setmetatable({}, HttpClient)

    self.base_url = (options and options.base_url) or "http://127.0.0.1:8000"
    self.mode = (options and options.mode) or "curl"

    return self
end

function HttpClient:request(method, path, payload)
    local url = self.base_url .. path
    local curl_parts = {
        "curl",
        "--silent",
        "--show-error",
        "--write-out",
        shellQuote("\n__STATUS__:%{http_code}"),
        "-X",
        shellQuote(method),
        "-H",
        shellQuote("Accept: application/json"),
    }

    if method == "GET" and payload and next(payload) then
        url = url .. "?" .. buildQuery(payload)
    elseif method == "POST" or method == "PATCH" then
        local request_body = encodeJsonObject(payload or {})
        curl_parts[#curl_parts + 1] = "-H"
        curl_parts[#curl_parts + 1] = shellQuote("Content-Type: application/json")
        curl_parts[#curl_parts + 1] = "--data"
        curl_parts[#curl_parts + 1] = shellQuote(request_body)
    end

    curl_parts[#curl_parts + 1] = shellQuote(url)

    local command = table.concat(curl_parts, " ")
    local pipe = io.popen(command, "r")
    if not pipe then
        return {
            ok = false,
            status = 0,
            error = "无法执行 curl，请确认系统已安装 curl。",
        }
    end

    local raw_result = pipe:read("*a")
    pipe:close()

    local raw_body, raw_status = raw_result:match("^(.*)\n__STATUS__:(%d%d%d)$")
    if not raw_status then
        return {
            ok = false,
            status = 0,
            error = "HTTP 请求失败，未能获取状态码。",
            raw_body = raw_result,
        }
    end

    local response_data = nil
    if raw_body ~= "" then
        local decoded, decode_error = decodeJson(raw_body)
        if decode_error then
            return {
                ok = false,
                status = tonumber(raw_status) or 0,
                error = "后端返回了无法解析的 JSON。",
                raw_body = raw_body,
            }
        end

        response_data = decoded
    end

    local numeric_status = tonumber(raw_status) or 0
    local ok = numeric_status >= 200 and numeric_status < 300

    return {
        ok = ok,
        status = numeric_status,
        data = response_data,
        error = ok and nil or ((response_data and response_data.detail) or ("HTTP request failed: " .. tostring(numeric_status))),
    }
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
