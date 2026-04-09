local SteamIDProvider = {}
SteamIDProvider.__index = SteamIDProvider
local Platform = require("src.infra.system.platform")
local ffi_ok, ffi = pcall(require, "ffi")

local BRIDGE_TIMEOUT_SECONDS = 3.0
local BRIDGE_POLL_INTERVAL_SECONDS = 0.01
local BRIDGE_SCRIPT_NAME = "guandan_steam_id_bridge.ps1"
local REAL_STEAM_ID_PREFIX = "7656119"
local REAL_STEAM_ID_LENGTH = 17
local DEBUG_LOG_NAME = "guandan_steam_id_debug.log"
local NATIVE_ERROR_BUFFER_SIZE = 1024

local steam_api_defs_loaded = false
local steam_api_lib = nil

local function normalizeStartupMode(value)
    local mode = tostring(value or ""):match("^%s*(.-)%s*$"):lower()
    if mode == "dev" then
        return "dev"
    end
    return "practical"
end

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

local function debugLogPath()
    return Platform.joinPath(resolveTempDir(), DEBUG_LOG_NAME)
end

local function appendDebugLog(message)
    local path = debugLogPath()
    local file = io.open(path, "ab")
    if not file then
        return
    end

    local line = string.format("[%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), tostring(message or ""))
    file:write(line)
    file:close()
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

local function parentPath(path)
    local value = normalizePath(path)
    if value == "" then
        return ""
    end

    local trimmed = value:gsub("[/\\]+$", "")
    local parent = trimmed:match("^(.*)[/\\][^/\\]+$")
    if not parent then
        return ""
    end

    if parent:match("^[A-Za-z]:$") then
        parent = parent .. Platform.pathSeparator()
    end

    return parent
end

local function addSearchVariants(roots, path)
    local root = normalizePath(path)
    if root == "" then
        return
    end

    addRoot(roots, root)
    addRoot(roots, Platform.joinPath(root, "steam_bridge"))
    addRoot(roots, Platform.joinPath(root, "src/infra/steam/bridge"))
    addRoot(roots, Platform.joinPath(root, "src/features/gameplay/card_themes/SteamIDGet"))
end

local function buildSearchRoots()
    local roots = {}
    local cwd = love and love.filesystem and love.filesystem.getWorkingDirectory and love.filesystem.getWorkingDirectory()
    local source = love and love.filesystem and love.filesystem.getSource and love.filesystem.getSource()
    local source_base = love and love.filesystem and love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory()
    local argv0 = type(arg) == "table" and arg[0] or nil

    addSearchVariants(roots, cwd)
    addSearchVariants(roots, parentPath(cwd))
    addSearchVariants(roots, source)
    addSearchVariants(roots, parentPath(source))
    addSearchVariants(roots, source_base)
    addSearchVariants(roots, parentPath(source_base))
    addSearchVariants(roots, argv0)
    addSearchVariants(roots, parentPath(argv0))

    appendDebugLog("buildSearchRoots cwd=" .. tostring(cwd))
    appendDebugLog("buildSearchRoots source=" .. tostring(source))
    appendDebugLog("buildSearchRoots source_base=" .. tostring(source_base))
    appendDebugLog("buildSearchRoots argv0=" .. tostring(argv0))
    for index, root in ipairs(roots) do
        appendDebugLog(string.format("search_root[%d]=%s", index, tostring(root)))
    end

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
        appendDebugLog("bridge_candidate=" .. tostring(candidate))
        if fileExists(candidate) then
            appendDebugLog("bridge_resolved=" .. tostring(candidate))
            return candidate
        end
    end

    appendDebugLog("bridge_resolved=nil")
    return nil
end

local function resolveSteamApiDllPath()
    local candidates = {}

    for _, root in ipairs(buildSearchRoots()) do
        candidates[#candidates + 1] = Platform.joinPath(root, "steam_api64.dll")
    end

    for _, candidate in ipairs(candidates) do
        appendDebugLog("steam_api_candidate=" .. tostring(candidate))
        if fileExists(candidate) then
            appendDebugLog("steam_api_resolved=" .. tostring(candidate))
            return candidate
        end
    end

    appendDebugLog("steam_api_resolved=nil")
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

local function randomDigitString(length)
    local target_length = math.max(0, math.floor(tonumber(length) or 0))
    if target_length <= 0 then
        return ""
    end

    local entropy_parts = {
        tostring(os.time()),
        tostring(math.floor((nowSeconds() % 1) * 1000000)),
        tostring(request_counter),
    }

    if love and love.math and love.math.random then
        entropy_parts[#entropy_parts + 1] = tostring(love.math.random(100000, 999999))
        entropy_parts[#entropy_parts + 1] = tostring(love.math.random(100000, 999999))
    else
        entropy_parts[#entropy_parts + 1] = tostring(math.random(100000, 999999))
        entropy_parts[#entropy_parts + 1] = tostring(math.random(100000, 999999))
    end

    local digits = table.concat(entropy_parts, ""):gsub("%D", "")
    while #digits < target_length do
        digits = digits .. digits
    end

    return digits:sub(1, target_length)
end

local function generateFakeSteamID64()
    local suffix_length = REAL_STEAM_ID_LENGTH - #REAL_STEAM_ID_PREFIX
    local fake_id = REAL_STEAM_ID_PREFIX .. randomDigitString(suffix_length)
    appendDebugLog("generateFakeSteamID64 value=" .. tostring(fake_id))
    return fake_id
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
        appendDebugLog("bridge_runner_script=existing " .. tostring(script_path))
        return script_path
    end

    if not writeTextFile(script_path, script_body) then
        appendDebugLog("bridge_runner_script_write_failed " .. tostring(script_path))
        return nil
    end

    appendDebugLog("bridge_runner_script=written " .. tostring(script_path))
    return script_path
end

local function runBridgeHiddenWindows(path)
    appendDebugLog("runBridgeHiddenWindows path=" .. tostring(path))
    local script_path = ensureBridgeRunnerScript()
    if not script_path then
        appendDebugLog("runBridgeHiddenWindows script_path=nil")
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
    appendDebugLog("runBridgeHiddenWindows started=" .. tostring(started))
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
    appendDebugLog("runBridgeHiddenWindows output=" .. tostring(output or "nil"))
    cleanupPaths({ output_path, done_path })
    return parseSteamIdFromOutput(output)
end

local function runBridgeDirect(path)
    if not path or path == "" then
        appendDebugLog("runBridgeDirect skipped empty path")
        return nil
    end

    local quoted_path = '"' .. tostring(path):gsub('"', '\\"') .. '"'
    local pipe = io.popen(quoted_path .. " 2>&1")
    if not pipe then
        appendDebugLog("runBridgeDirect pipe=nil")
        return nil
    end

    local output = pipe:read("*a") or ""
    pipe:close()
    appendDebugLog("runBridgeDirect output=" .. tostring(output))
    return parseSteamIdFromOutput(output)
end

local function runBridge(path)
    if not path or path == "" then
        appendDebugLog("runBridge skipped empty path")
        return nil
    end

    if Platform.isWindows() then
        local hidden_steam_id = runBridgeHiddenWindows(path)
        if hidden_steam_id and hidden_steam_id ~= "" then
            appendDebugLog("runBridge windows hidden success=" .. tostring(hidden_steam_id))
            return hidden_steam_id
        end

        appendDebugLog("runBridge windows hidden failed, fallback direct")
        local direct_steam_id = runBridgeDirect(path)
        if direct_steam_id and direct_steam_id ~= "" then
            appendDebugLog("runBridge windows direct success=" .. tostring(direct_steam_id))
            return direct_steam_id
        end

        appendDebugLog("runBridge windows direct failed")
        return nil
    end

    local quoted_path = '"' .. tostring(path):gsub('"', '\\"') .. '"'
    local pipe = io.popen(quoted_path .. " 2>&1")
    if not pipe then
        return nil
    end
    local output = pipe:read("*a") or ""
    pipe:close()
    appendDebugLog("runBridge output=" .. tostring(output))
    return parseSteamIdFromOutput(output)
end

local function tryRequire(name)
    local ok, mod = pcall(require, name)
    if ok then
        return mod
    end
    return nil
end

local function ensureSteamApiBindings()
    if not ffi_ok then
        return false, "ffi unavailable"
    end

    if not steam_api_defs_loaded then
        local ok, err = pcall(function()
            ffi.cdef([[
                typedef unsigned long long uint64_t;

                int SteamAPI_InitFlat(char* errorMessage);
                void SteamAPI_Shutdown(void);
                void* SteamAPI_SteamUser_v023(void);
                uint64_t SteamAPI_ISteamUser_GetSteamID(void* self);
            ]])
        end)
        if not ok then
            return false, tostring(err)
        end
        steam_api_defs_loaded = true
    end

    if not steam_api_lib then
        local dll_path = resolveSteamApiDllPath()
        if not dll_path then
            return false, "steam_api64.dll not found"
        end

        local ok, lib_or_err = pcall(ffi.load, dll_path)
        if not ok then
            appendDebugLog("ensureSteamApiBindings load_failed=" .. tostring(lib_or_err))
            return false, tostring(lib_or_err)
        end
        steam_api_lib = lib_or_err
    end

    return true
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

local function getSteamIDFromNativeSteamApi()
    local ok, err = ensureSteamApiBindings()
    if not ok then
        appendDebugLog("getSteamIDFromNativeSteamApi bindings_failed=" .. tostring(err))
        return nil
    end

    local error_buffer = ffi.new("char[?]", NATIVE_ERROR_BUFFER_SIZE)
    local init_result = steam_api_lib.SteamAPI_InitFlat(error_buffer)
    appendDebugLog("getSteamIDFromNativeSteamApi init_result=" .. tostring(tonumber(init_result or -1)))
    if tonumber(init_result or -1) ~= 0 then
        local init_error = ffi.string(error_buffer)
        appendDebugLog("getSteamIDFromNativeSteamApi init_error=" .. tostring(init_error))
        return nil
    end

    local ok_call, steam_id = pcall(function()
        local steam_user = steam_api_lib.SteamAPI_SteamUser_v023()
        appendDebugLog("getSteamIDFromNativeSteamApi steam_user=" .. tostring(steam_user))
        if steam_user == nil or steam_user == ffi.NULL then
            return nil
        end

        local raw_steam_id = steam_api_lib.SteamAPI_ISteamUser_GetSteamID(steam_user)
        return parseSteamIdFromOutput(tostring(tonumber(raw_steam_id)))
    end)

    steam_api_lib.SteamAPI_Shutdown()

    if not ok_call then
        appendDebugLog("getSteamIDFromNativeSteamApi call_failed=" .. tostring(steam_id))
        return nil
    end

    appendDebugLog("getSteamIDFromNativeSteamApi steam_id=" .. tostring(steam_id))
    return steam_id
end

local function getSteamIDFromSteamworks()
    local binding = tryRequire("steamworks") or tryRequire("luasteam") or tryRequire("steam_api")
    appendDebugLog("getSteamIDFromSteamworks binding=" .. tostring(binding))
    return getSteamIDFromBinding(binding) or getSteamIDFromNativeSteamApi()
end

local function getSteamIDFromBridge(path)
    local resolved_path = resolveBridgePath(path)
    if not resolved_path then
        appendDebugLog("getSteamIDFromBridge resolved_path=nil")
        return nil
    end

    appendDebugLog("getSteamIDFromBridge resolved_path=" .. tostring(resolved_path))
    return runBridge(resolved_path)
end

function SteamIDProvider.new(options)
    local self = setmetatable({}, SteamIDProvider)

    options = options or {}
    self.source = options.source or "auto"
    self.bridge_path = tostring(options.bridge_path or "")
    self.startup_mode = normalizeStartupMode(options.startup_mode)
    self.fake_steam_id = nil

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
    appendDebugLog("getSteamID source=" .. tostring(self.source))
    if self.startup_mode == "dev" then
        if not self.fake_steam_id then
            self.fake_steam_id = generateFakeSteamID64()
        end
        appendDebugLog("getSteamID dev_fake=" .. tostring(self.fake_steam_id))
        return self.fake_steam_id
    end

    local steam_id = self:tryResolveSteamID()
    if steam_id and steam_id ~= "" then
        appendDebugLog("getSteamID success=" .. tostring(steam_id))
        return steam_id
    end

    appendDebugLog("getSteamID result=nil log=" .. tostring(debugLogPath()))
    return nil
end

function SteamIDProvider.isRealSteamID(value)
    return parseSteamIdFromOutput(tostring(value or "")) ~= nil
end

return SteamIDProvider
