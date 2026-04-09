local SteamIDTest = {}
SteamIDTest.__index = SteamIDTest
local Platform = require("src.infra.system.platform")

local BRIDGE_TIMEOUT_SECONDS = 3.0
local BRIDGE_POLL_INTERVAL_SECONDS = 0.01

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

local function readTextFile(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
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

local function tempPath(stem, extension)
    local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "."
    local suffix = string.format("%d_%d", os.time(), math.floor((nowSeconds() % 1) * 100000))
    return Platform.joinPath(temp_dir, string.format("%s_%s%s", tostring(stem), suffix, tostring(extension or "")))
end

local function normalizePath(path)
    return (path or "."):gsub("\\", "/")
end

local function sanitizeText(value)
    local text = tostring(value or "")
    text = text:gsub("\r\n", "\n")
    text = text:gsub("[^\t\n\r -~]", "?")
    return text
end

local function buildSearchRoots()
    local roots = {}
    local cwd = love and love.filesystem and love.filesystem.getWorkingDirectory and love.filesystem.getWorkingDirectory()
    local source = love and love.filesystem and love.filesystem.getSource and love.filesystem.getSource()
    local source_base = love and love.filesystem and love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory()

    roots[#roots + 1] = normalizePath(cwd)
    roots[#roots + 1] = normalizePath(source)
    roots[#roots + 1] = normalizePath(source_base) .. "/card_themes"

    return roots
end

local function joinPath(base, child)
    return normalizePath(base) .. "/" .. child
end

local function fileExists(path)
    local info = love.filesystem.getInfo(path)
    if info then
        return true
    end
    local handle = io.open(path, "rb")
    if handle then
        handle:close()
        return true
    end
    return false
end

local function findBridgePath()
    for _, root in ipairs(buildSearchRoots()) do
        local candidate = joinPath(root, "SteamIDGet/steam_id_bridge.exe")
        if fileExists(candidate) then
            return candidate
        end
    end
    return nil
end

local function splitLines(text)
    local lines = {}
    text = sanitizeText(text)
    for line in text:gmatch("([^\n]+)") do
        lines[#lines + 1] = line
    end
    if #lines == 0 and text ~= "" then
        lines[1] = text
    end
    return lines
end

local function runBridge(bridge_path)
    local output = ""
    if Platform.isWindows() then
        local output_path = tempPath("guandan_steamid_test", ".txt")
        local command_script = string.format(
            "& %s 2>&1 | Out-File -LiteralPath %s -Encoding utf8",
            Platform.quotePowerShellLiteral(bridge_path),
            Platform.quotePowerShellLiteral(output_path)
        )
        local command_args = {
            "powershell.exe",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-WindowStyle",
            "Hidden",
            "-Command",
            command_script,
        }
        writeTextFile(output_path, "")
        local started = Platform.spawnDetached(command_args)
        if not started then
            return false, { "Failed to start steam_id_bridge.exe." }
        end
        local deadline = nowSeconds() + BRIDGE_TIMEOUT_SECONDS
        while nowSeconds() < deadline do
            local content = readTextFile(output_path)
            if content and content ~= "" then
                output = content
                break
            end
            sleepSeconds(BRIDGE_POLL_INTERVAL_SECONDS)
        end
        pcall(os.remove, output_path)
    else
        local quoted = '"' .. bridge_path:gsub('"', '\\"') .. '"'
        local pipe = io.popen(quoted .. " 2>&1")
        if not pipe then
            return false, { "Failed to start steam_id_bridge.exe." }
        end
        output = pipe:read("*a") or ""
        pipe:close()
    end

    local lines = splitLines(output)
    local steam_id = nil
    for _, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed:match("^%d+$") then
            steam_id = trimmed
            break
        end
    end

    return steam_id ~= nil, lines, steam_id
end

function SteamIDTest.new()
    return setmetatable({
        bridge_path = nil,
        steam_id = nil,
        ok = false,
        cached_lines = {},
        font_title = nil,
        font_body = nil,
        font_mono = nil,
    }, SteamIDTest)
end

function SteamIDTest:load()
    self.font_title = love.graphics.newFont(28)
    self.font_body = love.graphics.newFont(18)
    self.font_mono = love.graphics.newFont(14)
    self:refresh()
end

function SteamIDTest:refresh()
    self.bridge_path = findBridgePath()
    self.steam_id = nil
    self.ok = false

    if not self.bridge_path then
        self.cached_lines = {
            "steam_id_bridge test",
            "",
            "steam_id_bridge.exe not found.",
            "Expected it under ./SteamIDGet/steam_id_bridge.exe",
            "",
            "Press R to retry, F3 to return to preview, ESC to quit.",
        }
        return
    end

    local ok, lines, steam_id = runBridge(self.bridge_path)
    self.ok = ok
    self.steam_id = steam_id

    self.cached_lines = {
        "steam_id_bridge test",
        "",
        "Bridge path:",
        self.bridge_path,
        "",
        "Success: " .. tostring(ok),
        "SteamID: " .. tostring(steam_id or "nil"),
        "",
        "Bridge output:",
    }

    for _, line in ipairs(lines) do
        self.cached_lines[#self.cached_lines + 1] = line
    end

    self.cached_lines[#self.cached_lines + 1] = ""
    self.cached_lines[#self.cached_lines + 1] = "Press R to retry, F3 to return to card preview, ESC to quit."
end

function SteamIDTest:update(_dt)
end

function SteamIDTest:keypressed(key)
    if key == "r" then
        self:refresh()
    elseif key == "escape" then
        love.event.quit()
    end
end

function SteamIDTest:resize(_width, _height)
end

function SteamIDTest:draw()
    local w, h = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(0.06, 0.07, 0.09, 1)
    love.graphics.setColor(0.09, 0.11, 0.14, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(0.18, 0.22, 0.28, 0.95)
    love.graphics.rectangle("fill", 32, 30, w - 64, h - 60, 18, 18)
    love.graphics.setColor(0.32, 0.38, 0.46, 0.90)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 32, 30, w - 64, h - 60, 18, 18)

    love.graphics.setFont(self.font_title)
    love.graphics.setColor(0.98, 0.98, 0.95, 1)
    love.graphics.print("Steam Bridge Test", 54, 50)

    love.graphics.setFont(self.font_body)
    love.graphics.setColor(0.80, 0.84, 0.88, 1)
    love.graphics.print("Press R to rerun steam_id_bridge, F3 to return to card preview, ESC to quit.", 54, 92)

    local y = 140
    love.graphics.setFont(self.font_mono)
    for _, line in ipairs(self.cached_lines) do
        love.graphics.setColor(0.90, 0.92, 0.94, 1)
        love.graphics.print(sanitizeText(line), 56, y)
        y = y + 22
    end
end

return SteamIDTest
