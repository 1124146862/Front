local SteamIDProvider = {}
SteamIDProvider.__index = SteamIDProvider
local Platform = require("src.infra.system.platform")

local BRIDGE_TIMEOUT_SECONDS = 3.0
local BRIDGE_POLL_INTERVAL_SECONDS = 0.01
local BRIDGE_SCRIPT_NAME = "guandan_steam_id_bridge.ps1"
local REAL_STEAM_ID_PREFIX = "7656119"
local REAL_STEAM_ID_LENGTH = 17

local function fileExists(path)
    if not path or path == "" then
        return false
    end

    if love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(path) then
        return true
    end

    local file = io.open(path, "rb")
    if file then
        file:close()
        return true
    end

    return false
end

local function normalizePath(path)
    return Platform.toSystemPath(tostring(path or ""))
end

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

local function resolveTempDir()
    local temp_dir = os.getenv("TEMP") or os.getenv("TMP")
    if temp_dir and temp_dir ~= "" then
        return temp_dir
    end
    return "."
end

local request_counter = 0

local function nextTempPath(stem, extension)
    request_counter = request_counter + 1
    local file_name = string.format(
        "%s_%d_%d%s",
        tostring(stem or "tmp"),
        os.time(),
        request_counter,
        tostring(extension or "")
    )
    return Platform.joinPath(resolveTempDir(), file_name)
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

local function addRoot(roots, path)
    local value = normalizePath(path)
    if value ~= "" then
        roots[#roots + 1] = value
    end
end

local function buildSearchRoots()
    local roots = {}
    local cwd = love and love.filesystem and love.filesystem.getWorkingDirectory and love.filesystem.getWorkingDirectory()
    local source = love and love.filesystem and love.filesystem.getSource and love.filesystem.getSource()
    local source_base = love and love.filesystem and love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory()

    addRoot(roots, cwd)
    addRoot(roots, source)
    addRoot(roots, source_base)
    addRoot(roots, Platform.joinPath(source_base or "", "steam_bridge"))
    addRoot(roots, Platform.joinPath(source_base or "", "src/infra/steam/bridge"))
    addRoot(roots, Platform.joinPath(source_base or "", "src/features/gameplay/card_themes/SteamIDGet"))

    return roots
end

local function resolveBridgePath(preferred_path)
    local candidates = {}
    if preferred_path and preferred_path ~= "" then
        candidates[#candidates + 1] = preferred_path
    end

    for _, root in ipairs(buildSearchRoots()) do
        candidates[#candidates + 1] = Platform.joinPath(root, "steam_id_bridge.exe")
    end

    for _, candidate in ipairs(candidates) do
        if fileExists(candidate) then
            return candidate
        end
    end

    return nil
end

local function parseSteamIdFromOutput(output)
    local normalized_output = tostring(output or ""):gsub("^\239\187\191", "")
    for line in normalized_output:gmatch("([^\r\n]+)") do
        line = line:gsub("^\239\187\191", "")
        local steam_id = line:match("^%s*(%d+)%s*$")
        if steam_id and #steam_id == REAL_STEAM_ID_LENGTH and steam_id:sub(1, #REAL_STEAM_ID_PREFIX) == REAL_STEAM_ID_PREFIX then
            return steam_id
        end
    end
    return nil
end

local function ensureBridgeRunnerScript()
    local script_path = Platform.joinPath(resolveTempDir(), BRIDGE_SCRIPT_NAME)
    local script_body = [[
param(
    [Parameter(Mandatory = $true)][string]$BridgePath,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][string]$DonePath
)

$utf8 = [System.Text.UTF8Encoding]::new($false)
$outputLines = New-Object System.Collections.Generic.List[string]

try {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $BridgePath
    $startInfo.WorkingDirectory = [System.IO.Path]::GetDirectoryName($BridgePath)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::Start($startInfo)
    if ($null -eq $process) {
        throw "Failed to start steam_id_bridge.exe"
    }

    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($stdout) { $outputLines.Add($stdout) }
    if ($stderr) { $outputLines.Add($stderr) }
    $outputLines.Add("__EXITCODE__:$($process.ExitCode)")
}
catch {
    $outputLines.Add($_.Exception.GetType().FullName + ": " + $_.Exception.Message)
}
finally {
    [System.IO.File]::WriteAllText($OutputPath, [string]::Join([Environment]::NewLine, $outputLines), $utf8)
    [System.IO.File]::WriteAllText($DonePath, "done", $utf8)
}
]]

    local existing = readTextFile(script_path)
    if existing == script_body then
        return script_path
    end

    if not writeTextFile(script_path, script_body) then
        return nil
    end

    return script_path
end

local function runBridgeHiddenWindows(path)
    local script_path = ensureBridgeRunnerScript()
    if not script_path then
        return nil
    end

    local output_path = nextTempPath("guandan_steam_id_bridge_out", ".txt")
    local done_path = nextTempPath("guandan_steam_id_bridge_done", ".txt")
    cleanupPaths({ output_path, done_path })

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
        "-BridgePath",
        path,
        "-OutputPath",
        output_path,
        "-DonePath",
        done_path,
    }

    local started = Platform.spawnDetached(command_args)
    if not started then
        cleanupPaths({ output_path, done_path })
        return nil
    end

    local deadline = nowSeconds() + BRIDGE_TIMEOUT_SECONDS
    while nowSeconds() < deadline do
        if readTextFile(done_path) ~= nil then
            break
        end
        sleepSeconds(BRIDGE_POLL_INTERVAL_SECONDS)
    end

    local output = readTextFile(output_path)
    cleanupPaths({ output_path, done_path })
    return parseSteamIdFromOutput(output)
end

local function runBridge(path)
    if not path or path == "" then
        return nil
    end

    if Platform.isWindows() then
        return runBridgeHiddenWindows(path)
    end

    local quoted_path = '"' .. tostring(path):gsub('"', '\\"') .. '"'
    local pipe = io.popen(quoted_path .. " 2>&1")
    if not pipe then
        return nil
    end
    local output = pipe:read("*a") or ""
    pipe:close()
    return parseSteamIdFromOutput(output)
end

local function tryRequire(name)
    local ok, mod = pcall(require, name)
    if ok then
        return mod
    end
    return nil
end

local function getSteamIDFromBinding(binding)
    if not binding then
        return nil
    end

    if type(binding) == "table" then
        local steam = binding.Steam and binding.Steam()
        if steam and type(steam.GetSteamID) == "function" then
            local ok, steam_id = pcall(steam.GetSteamID, steam)
            if ok and steam_id ~= nil then
                return parseSteamIdFromOutput(tostring(steam_id))
            end
        end

        if type(binding.SteamAPI_Init) == "function" and type(binding.SteamUser) == "function" then
            local ok_init = pcall(binding.SteamAPI_Init)
            if ok_init then
                local user = binding.SteamUser()
                if user and type(user.GetSteamID) == "function" then
                    local ok, steam_id = pcall(user.GetSteamID, user)
                    if ok and steam_id ~= nil then
                        return parseSteamIdFromOutput(tostring(steam_id))
                    end
                end
            end
        end
    end

    return nil
end

local function getSteamIDFromSteamworks()
    local binding = tryRequire("steamworks") or tryRequire("luasteam") or tryRequire("steam_api")
    return getSteamIDFromBinding(binding)
end

local function getSteamIDFromBridge(path)
    local resolved_path = resolveBridgePath(path)
    if not resolved_path then
        return nil
    end

    return runBridge(resolved_path)
end

function SteamIDProvider.new(options)
    local self = setmetatable({}, SteamIDProvider)

    options = options or {}
    self.source = options.source or "auto"
    self.bridge_path = tostring(options.bridge_path or "")

    return self
end

function SteamIDProvider:tryResolveSteamID()
    if self.source == "steamworks" then
        return getSteamIDFromSteamworks()
    end

    if self.source == "bridge" then
        return getSteamIDFromBridge(self.bridge_path)
    end

    if self.source == "auto" then
        return getSteamIDFromSteamworks() or getSteamIDFromBridge(self.bridge_path)
    end

    return nil
end

function SteamIDProvider:getSteamID()
    local steam_id = self:tryResolveSteamID()
    if steam_id and steam_id ~= "" then
        return steam_id
    end

    return nil
end

function SteamIDProvider.isRealSteamID(value)
    return parseSteamIdFromOutput(tostring(value or "")) ~= nil
end

return SteamIDProvider
