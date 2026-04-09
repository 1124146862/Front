local Json = {}

local JSON_NULL = {}
local MAX_SAFE_INTEGER_TEXT = "9007199254740991"

local function shouldPreserveIntegerAsString(literal)
    local text = tostring(literal or "")
    if text == "" then
        return false
    end

    local negative = text:sub(1, 1) == "-"
    if negative then
        text = text:sub(2)
    end

    if text == "" or not text:match("^%d+$") then
        return false
    end

    text = text:gsub("^0+", "")
    if text == "" then
        text = "0"
    end

    if #text > #MAX_SAFE_INTEGER_TEXT then
        return true
    end

    if #text < #MAX_SAFE_INTEGER_TEXT then
        return false
    end

    return text > MAX_SAFE_INTEGER_TEXT
end

local function isArray(value)
    if type(value) ~= "table" then
        return false
    end

    local count = 0
    local max_index = 0

    for key, _ in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false
        end

        count = count + 1
        if key > max_index then
            max_index = key
        end
    end

    if count == 0 then
        return false
    end

    return max_index == count
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

    if value_type == "table" then
        if isArray(value) then
            local parts = {}
            for _, item in ipairs(value) do
                parts[#parts + 1] = encodeJsonValue(item)
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end

        local parts = {}
        for key, item in pairs(value) do
            parts[#parts + 1] = "\"" .. tostring(key) .. "\":" .. encodeJsonValue(item)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end

    if value == nil then
        return "null"
    end

    error("Unsupported JSON value type: " .. value_type)
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

function Json.encodeObject(payload)
    return encodeJsonValue(payload or {})
end

function Json.decode(raw)
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

        local literal = raw:sub(start_pos, position - 1)
        if not literal:find("[%.eE]") and shouldPreserveIntegerAsString(literal) then
            return literal
        end

        return tonumber(literal)
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

return Json
