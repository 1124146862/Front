local Platform = require("src.infra.system.platform")
local utf8lib = rawget(_G, "utf8")

if not utf8lib then
    local ok, loaded = pcall(require, "utf8")
    if ok and type(loaded) == "table" then
        utf8lib = loaded
    end
end

local EncodingRepair = {
    SCRIPT_NAME = "guandan_text_repair.ps1",
    cache = {},
    request_counter = 0,
}
local REPAIR_TIMEOUT_SECONDS = 3.0
local REPAIR_POLL_INTERVAL_SECONDS = 0.01

local function nowSeconds()
    if love and love.timer and love.timer.getTime then
        return love.timer.getTime()
    end
    return os.clock()
end

local function sleepSeconds(seconds)
    local delay = math.max(tonumber(seconds) or 0, 0)
    if delay <= 0 then
        return
    end
    if love and love.timer and love.timer.sleep then
        love.timer.sleep(delay)
    end
end

local function encodeCodepoint(codepoint)
    if type(codepoint) ~= "number" or codepoint < 0 then
        return ""
    end

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

    if codepoint <= 0x10FFFF then
        local byte1 = 0xF0 + math.floor(codepoint / 0x40000)
        local byte2 = 0x80 + (math.floor(codepoint / 0x1000) % 0x40)
        local byte3 = 0x80 + (math.floor(codepoint / 0x40) % 0x40)
        local byte4 = 0x80 + (codepoint % 0x40)
        return string.char(byte1, byte2, byte3, byte4)
    end

    return ""
end

local function decodeCodepoint(text, byte_index)
    local byte1 = string.byte(text, byte_index)
    if not byte1 then
        return nil, 0
    end

    if byte1 < 0x80 then
        return byte1, 1
    end

    local byte2 = string.byte(text, byte_index + 1)
    if byte1 < 0xE0 then
        if not byte2 then
            return nil, 0
        end

        return (byte1 - 0xC0) * 0x40 + (byte2 - 0x80), 2
    end

    local byte3 = string.byte(text, byte_index + 2)
    if byte1 < 0xF0 then
        if not byte2 or not byte3 then
            return nil, 0
        end

        return (byte1 - 0xE0) * 0x1000
            + (byte2 - 0x80) * 0x40
            + (byte3 - 0x80), 3
    end

    local byte4 = string.byte(text, byte_index + 3)
    if not byte2 or not byte3 or not byte4 then
        return nil, 0
    end

    return (byte1 - 0xF0) * 0x40000
        + (byte2 - 0x80) * 0x1000
        + (byte3 - 0x80) * 0x40
        + (byte4 - 0x80), 4
end

if not utf8lib then
    utf8lib = {}

    function utf8lib.char(codepoint)
        return encodeCodepoint(codepoint)
    end

    function utf8lib.codes(text)
        local value = tostring(text or "")
        return function(_, last_index)
            local next_index = (last_index or 0) + 1
            if next_index > #value then
                return nil
            end

            local codepoint, width = decodeCodepoint(value, next_index)
            if not codepoint or width <= 0 then
                return nil
            end

            return next_index, codepoint
        end, value, 0
    end
end

local function resolveTempDir()
    local temp_dir = os.getenv("TEMP") or os.getenv("TMP")
    if temp_dir and temp_dir ~= "" then
        return temp_dir
    end
    return "."
end

local function writeTextFile(path, content)
    local file = io.open(path, "wb")
    if not file then
        return false
    end
    file:write(content or "")
    file:close()
    return true
end

local function readTextFile(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function cleanupPaths(paths)
    for _, path_to_remove in ipairs(paths or {}) do
        if path_to_remove and path_to_remove ~= "" then
            pcall(os.remove, path_to_remove)
        end
    end
end

local function nextTempPath(stem, extension)
    EncodingRepair.request_counter = EncodingRepair.request_counter + 1
    local file_name = string.format(
        "%s_%d_%d%s",
        tostring(stem or "tmp"),
        os.time(),
        EncodingRepair.request_counter,
        tostring(extension or "")
    )
    return Platform.joinPath(resolveTempDir(), file_name)
end

local function getScriptPath()
    return Platform.joinPath(resolveTempDir(), EncodingRepair.SCRIPT_NAME)
end

local function ensureRepairScript()
    local script_path = getScriptPath()
    local script_body = [[
param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
)

$utf8 = [System.Text.UTF8Encoding]::new($false)
$gbk = [System.Text.Encoding]::GetEncoding(936)
$text = [System.IO.File]::ReadAllText($InputPath, $utf8)
$fixed = $text

try {
    $candidate = $utf8.GetString($gbk.GetBytes($text))
    if ($candidate -ne "") {
        $fixed = $candidate
    }
} catch {
    $fixed = $text
}

[System.IO.File]::WriteAllText($OutputPath, $fixed, $utf8)
]]

    local existing = io.open(script_path, "rb")
    if existing then
        local current = existing:read("*a")
        existing:close()
        if current == script_body then
            return script_path
        end
    end

    if not writeTextFile(script_path, script_body) then
        return nil
    end

    return script_path
end

local function hasNonAscii(value)
    return type(value) == "string" and value:find("[\128-\255]") ~= nil
end

local function hasReplacementCharacter(value)
    return type(value) == "string" and value:find(utf8lib.char(0xFFFD), 1, true) ~= nil
end

local function looksLikeNickname(value)
    if type(value) ~= "string" or value == "" or hasReplacementCharacter(value) then
        return false
    end

    local length = 0
    for _, codepoint in utf8lib.codes(value) do
        length = length + 1
        local char = utf8lib.char(codepoint)

        if not char:match("[%w_]") then
            local is_cjk = (codepoint >= 0x3400 and codepoint <= 0x4DBF)
                or (codepoint >= 0x4E00 and codepoint <= 0x9FFF)
            if not is_cjk then
                return false
            end
        end
    end

    return length >= 1 and length <= 12
end

function EncodingRepair.repairCommonMojibake(value)
    if not Platform.isWindows() or type(value) ~= "string" or value == "" or not hasNonAscii(value) then
        return value
    end

    local cached = EncodingRepair.cache[value]
    if cached ~= nil then
        return cached
    end

    local script_path = ensureRepairScript()
    if not script_path then
        EncodingRepair.cache[value] = value
        return value
    end

    local input_path = nextTempPath("guandan_text_in", ".txt")
    local output_path = nextTempPath("guandan_text_out", ".txt")
    if not writeTextFile(input_path, value) then
        cleanupPaths({ input_path, output_path })
        EncodingRepair.cache[value] = value
        return value
    end

    local command_args = {
        "powershell.exe",
        "-NoProfile",
        "-NonInteractive",
        "-ExecutionPolicy",
        "Bypass",
        "-WindowStyle",
        "Hidden",
        "-File",
        script_path,
        "-InputPath",
        input_path,
        "-OutputPath",
        output_path,
    }
    local started = Platform.spawnDetached(command_args)
    if started then
        local deadline = nowSeconds() + REPAIR_TIMEOUT_SECONDS
        while nowSeconds() < deadline do
            local content = readTextFile(output_path)
            if content ~= nil then
                break
            end
            sleepSeconds(REPAIR_POLL_INTERVAL_SECONDS)
        end
    end

    local candidate = readTextFile(output_path) or value
    cleanupPaths({ input_path, output_path })

    if looksLikeNickname(candidate) and candidate ~= value then
        EncodingRepair.cache[value] = candidate
        return candidate
    end

    EncodingRepair.cache[value] = value
    return value
end

return EncodingRepair
