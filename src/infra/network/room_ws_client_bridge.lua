local Json = require("src.infra.network.json")
local Platform = require("src.infra.system.platform")
local RuntimeConfig = require("src.infra.network.runtime_config")

local RoomWebSocketClient = {}
RoomWebSocketClient.__index = RoomWebSocketClient

local HEARTBEAT_INTERVAL_SECONDS = 1.0

local function nowSeconds()
    if love and love.timer and love.timer.getTime then
        return love.timer.getTime()
    end
    return os.clock()
end

local function clearFile(path)
    local handle = io.open(path, "w")
    if handle then
        handle:write("")
        handle:close()
    end
end

local function appendEvent(path, packet)
    local handle = io.open(path, "a")
    if not handle then
        return
    end
    handle:write(Json.encodeObject(packet) .. "\n")
    handle:close()
end

local function fileExists(path)
    local handle = io.open(path, "r")
    if handle then
        handle:close()
        return true
    end
    return false
end

local function readAll(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end

    local content = handle:read("*a")
    handle:close()
    return content
end

local function parentPath(path)
    local normalized = Platform.toSystemPath(tostring(path or "")):gsub("[/\\]+$", "")
    if normalized == "" then
        return ""
    end

    local parent = normalized:match("^(.*)[/\\][^/\\]+$")
    return parent or ""
end

local function resolveBridgeExecutablePath(explicit_path)
    local candidates = {}
    if explicit_path and explicit_path ~= "" then
        candidates[#candidates + 1] = explicit_path
    end

    local env_path = os.getenv("ROOM_WS_BRIDGE_EXE")
    if env_path and env_path ~= "" then
        candidates[#candidates + 1] = env_path
    end

    local source_base = love.filesystem and love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory() or nil
    if source_base and source_base ~= "" then
        local repo_root = parentPath(source_base)
        candidates[#candidates + 1] = Platform.joinPath(source_base, "room_ws_bridge", "room_ws_bridge.exe")
        candidates[#candidates + 1] = Platform.joinPath(source_base, "tools", "room_ws_bridge.exe")
        candidates[#candidates + 1] = Platform.joinPath(source_base, "Front", "tools", "room_ws_bridge.exe")
        if repo_root ~= "" then
            candidates[#candidates + 1] = Platform.joinPath(repo_root, "backend", "dist", "room_ws_bridge.exe")
            candidates[#candidates + 1] = Platform.joinPath(repo_root, "build", "room_ws_bridge", "room_ws_bridge.exe")
        end
    end

    candidates[#candidates + 1] = "room_ws_bridge/room_ws_bridge.exe"
    candidates[#candidates + 1] = "tools/room_ws_bridge.exe"
    candidates[#candidates + 1] = "Front/tools/room_ws_bridge.exe"
    candidates[#candidates + 1] = "backend/dist/room_ws_bridge.exe"

    for _, candidate in ipairs(candidates) do
        if fileExists(candidate) then
            return Platform.toSystemPath(candidate)
        end
    end

    return nil
end

local function resolveBridgeScriptPath(explicit_path)
    local candidates = {}
    if explicit_path and explicit_path ~= "" then
        candidates[#candidates + 1] = explicit_path
    end

    local source_base = love.filesystem and love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory() or nil
    if source_base and source_base ~= "" then
        candidates[#candidates + 1] = Platform.joinPath(source_base, "room_ws_bridge", "room_ws_bridge.py")
        candidates[#candidates + 1] = Platform.joinPath(source_base, "Front", "tools", "room_ws_bridge.py")
    end

    candidates[#candidates + 1] = "tools/room_ws_bridge.py"
    candidates[#candidates + 1] = "Front/tools/room_ws_bridge.py"

    for _, candidate in ipairs(candidates) do
        if fileExists(candidate) then
            return Platform.toSystemPath(candidate)
        end
    end

    return Platform.toSystemPath(explicit_path or "Front/tools/room_ws_bridge.py")
end

local function ensureLoveDirectory(path)
    local normalized = tostring(path or ""):gsub("\\", "/")
    local segments = {}
    for segment in normalized:gmatch("[^/]+") do
        segments[#segments + 1] = segment
    end

    local current = ""
    for _, segment in ipairs(segments) do
        current = current == "" and segment or (current .. "/" .. segment)
        love.filesystem.createDirectory(current)
    end
end

local function detectPythonCommand()
    local candidates = {}
    local source_base = love.filesystem and love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory() or nil

    local function pushCandidate(path)
        if path and path ~= "" then
            candidates[#candidates + 1] = { path }
        end
    end

    local explicit_python = os.getenv("ROOM_WS_PYTHON")
    if explicit_python and explicit_python ~= "" then
        pushCandidate(explicit_python)
    end

    local virtual_env = os.getenv("VIRTUAL_ENV")
    if virtual_env and virtual_env ~= "" then
        pushCandidate(Platform.joinPath(virtual_env, "Scripts", "python.exe"))
        pushCandidate(Platform.joinPath(virtual_env, "bin", "python"))
    end

    local conda_prefix = os.getenv("CONDA_PREFIX")
    if conda_prefix and conda_prefix ~= "" then
        pushCandidate(Platform.joinPath(conda_prefix, "python.exe"))
        pushCandidate(Platform.joinPath(conda_prefix, "bin", "python"))
    end

    if source_base and source_base ~= "" then
        pushCandidate(Platform.joinPath(source_base, "backend", "web", "Scripts", "python.exe"))
        pushCandidate(Platform.joinPath(source_base, "backend", ".venv", "Scripts", "python.exe"))
        pushCandidate(Platform.joinPath(source_base, "backend", "web", "bin", "python"))
        pushCandidate(Platform.joinPath(source_base, "backend", ".venv", "bin", "python"))
    end

    pushCandidate("backend/web/Scripts/python.exe")
    pushCandidate("backend/.venv/Scripts/python.exe")
    pushCandidate("backend/web/bin/python")
    pushCandidate("backend/.venv/bin/python")

    for _, candidate in ipairs(candidates) do
        if fileExists(candidate[1]) then
            candidate[1] = Platform.toSystemPath(candidate[1])
            return candidate
        end
    end

    if Platform.isWindows() then
        return { "python" }
    end

    return { "python3" }
end

function RoomWebSocketClient.new(options)
    local self = setmetatable({}, RoomWebSocketClient)

    self.ws_base_url = (options and options.ws_base_url) or RuntimeConfig.getWsBaseUrl()
    self.bridge_executable = resolveBridgeExecutablePath((options and options.bridge_executable) or nil)
    self.python_command = (options and options.python_command) or detectPythonCommand()
    self.bridge_script = resolveBridgeScriptPath((options and options.bridge_script) or nil)
    self.session_dir = nil
    self.session_rel_dir = nil
    self.events_path = nil
    self.commands_path = nil
    self.pid_path = nil
    self.stop_path = nil
    self.heartbeat_path = nil
    self.read_offset = 0
    self.connected = false
    self.last_heartbeat_at = 0

    return self
end

function RoomWebSocketClient:start(room_id, steam_id)
    self:stop()

    self.session_rel_dir = string.format("runtime/room_ws/%s_%s", tostring(room_id), tostring(steam_id))
    ensureLoveDirectory(self.session_rel_dir)
    self.session_dir = Platform.joinPath(love.filesystem.getSaveDirectory(), self.session_rel_dir)
    self.events_path = Platform.joinPath(self.session_dir, "events.ndjson")
    self.commands_path = Platform.joinPath(self.session_dir, "commands.ndjson")
    self.pid_path = Platform.joinPath(self.session_dir, "pid")
    self.stop_path = Platform.joinPath(self.session_dir, "stop")
    self.heartbeat_path = Platform.joinPath(self.session_dir, "heartbeat")
    self.read_offset = 0
    self.connected = false
    self.last_heartbeat_at = 0

    clearFile(self.events_path)
    clearFile(self.commands_path)
    clearFile(self.pid_path)
    clearFile(self.stop_path)
    clearFile(self.heartbeat_path)

    local bridge_mode = nil
    local command_args = {}
    if self.bridge_executable and fileExists(self.bridge_executable) then
        bridge_mode = "exe"
        command_args[#command_args + 1] = self.bridge_executable
    elseif self.bridge_script and fileExists(self.bridge_script) then
        bridge_mode = "python"
        for _, part in ipairs(self.python_command) do
            command_args[#command_args + 1] = part
        end
        command_args[#command_args + 1] = self.bridge_script
    else
        appendEvent(self.events_path, {
            type = "bridge_status",
            payload = {
                status = "error",
                message = "room_ws bridge executable/script not found",
            },
        })
        return
    end

    local ws_url = string.format("%s/room/ws/%s?steam_id=%s", self.ws_base_url, tostring(room_id), tostring(steam_id))
    command_args[#command_args + 1] = "--ws-url"
    command_args[#command_args + 1] = ws_url
    command_args[#command_args + 1] = "--session-dir"
    command_args[#command_args + 1] = self.session_dir

    print(string.format(
        "[room_ws_client] starting bridge mode=%s runner=%s ws_url=%s",
        tostring(bridge_mode),
        tostring(command_args[1]),
        tostring(ws_url)
    ))
    local ok, spawn_error = Platform.spawnDetached(command_args)
    if not ok then
        appendEvent(self.events_path, {
            type = "bridge_status",
            payload = {
                status = "error",
                message = tostring(spawn_error or "failed to launch room_ws bridge"),
            },
        })
    end
end

function RoomWebSocketClient:stop(fast)
    local events_path = self.events_path
    local commands_path = self.commands_path
    local pid_path = self.pid_path
    local stop_path = self.stop_path
    local heartbeat_path = self.heartbeat_path

    if stop_path then
        local stop_handle = io.open(stop_path, "w")
        if stop_handle then
            stop_handle:write("stop")
            stop_handle:close()
        end
    end

    if not fast and self.pid_path then
        local pid = readAll(self.pid_path)
        if pid and pid:match("^%d+$") then
            Platform.killProcess(pid:match("^%d+$"))
        end
    end

    if not fast and events_path then
        clearFile(events_path)
    end
    if not fast and commands_path then
        clearFile(commands_path)
    end
    if not fast and pid_path then
        clearFile(pid_path)
    end
    if not fast and heartbeat_path then
        clearFile(heartbeat_path)
    end

    self.session_dir = nil
    self.session_rel_dir = nil
    self.events_path = nil
    self.commands_path = nil
    self.pid_path = nil
    self.stop_path = nil
    self.heartbeat_path = nil
    self.read_offset = 0
    self.connected = false
    self.last_heartbeat_at = 0
end

function RoomWebSocketClient:send(packet)
    if not self.commands_path then
        return
    end

    local handle = io.open(self.commands_path, "a")
    if not handle then
        return
    end

    handle:write(Json.encodeObject(packet) .. "\n")
    handle:close()
end

function RoomWebSocketClient:poll()
    if not self.events_path then
        return {}
    end

    local now = nowSeconds()
    if self.heartbeat_path and (self.last_heartbeat_at == 0 or (now - self.last_heartbeat_at) >= HEARTBEAT_INTERVAL_SECONDS) then
        local heartbeat_handle = io.open(self.heartbeat_path, "w")
        if heartbeat_handle then
            heartbeat_handle:write(tostring(os.time()))
            heartbeat_handle:close()
            self.last_heartbeat_at = now
        end
    end

    local handle = io.open(self.events_path, "r")
    if not handle then
        return {}
    end

    handle:seek("set", self.read_offset)
    local lines = {}
    for line in handle:lines() do
        lines[#lines + 1] = line
    end
    self.read_offset = handle:seek()
    handle:close()

    local packets = {}
    for _, line in ipairs(lines) do
        if line ~= "" then
            local decoded, decode_error = Json.decode(line)
            if not decode_error and decoded then
                if decoded.type == "bridge_status" then
                    packets[#packets + 1] = decoded
                elseif decoded.type == "bridge_message" and decoded.payload then
                    local message, message_error = Json.decode(decoded.payload)
                    if not message_error and message then
                        packets[#packets + 1] = message
                    end
                end
            end
        end
    end

    return packets
end

return RoomWebSocketClient
