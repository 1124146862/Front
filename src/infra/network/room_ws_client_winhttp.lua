local Json = require("src.infra.network.json")
local RuntimeConfig = require("src.infra.network.runtime_config")

local RoomWebSocketClient = {}
RoomWebSocketClient.__index = RoomWebSocketClient

local RECEIVE_WORKER_PATH = "src/infra/network/room_ws_worker_winhttp.lua"
local SEND_WORKER_PATH = "src/infra/network/room_ws_sender_winhttp.lua"
local STOP_WAIT_SECONDS = 0.25

local worker_counter = 0
local receive_worker_filedata = nil
local send_worker_filedata = nil

local function nowSeconds()
    if love and love.timer and love.timer.getTime then
        return love.timer.getTime()
    end
    return os.clock()
end

local function sleepSeconds(seconds)
    if love and love.timer and love.timer.sleep then
        love.timer.sleep(seconds)
    end
end

local function clearChannel(channel)
    if not channel then
        return
    end
    while channel:pop() ~= nil do
    end
end

local function nextWorkerToken()
    worker_counter = worker_counter + 1
    return string.format("%d_%d", os.time(), worker_counter)
end

local function loadThreadFileData(path, cache_key)
    if cache_key == "receive" and receive_worker_filedata then
        return receive_worker_filedata
    end
    if cache_key == "send" and send_worker_filedata then
        return send_worker_filedata
    end
    if not (love and love.filesystem and love.filesystem.read and love.filesystem.newFileData) then
        return nil, "love.thread worker loading is unavailable"
    end

    local content, size_or_error = love.filesystem.read(path)
    if not content then
        return nil, tostring(size_or_error or ("failed to read " .. path))
    end

    local filedata = love.filesystem.newFileData(content, path:match("([^/\\]+)$") or "room_ws_thread.lua")
    if cache_key == "receive" then
        receive_worker_filedata = filedata
    elseif cache_key == "send" then
        send_worker_filedata = filedata
    end
    return filedata
end

function RoomWebSocketClient.new(options)
    local self = setmetatable({}, RoomWebSocketClient)
    self.ws_base_url = (options and options.ws_base_url) or RuntimeConfig.getWsBaseUrl()
    self.thread = nil
    self.command_channel = nil
    self.sender_thread = nil
    self.sender_command_channel = nil
    self.event_channel = nil
    self.synthetic_events = {}
    self.last_thread_error = nil
    self.last_sender_thread_error = nil
    self.worker_token = nil
    self.room_id = nil
    self.steam_id = nil
    self.ws_url = nil
    self.event_channel_name = nil
    return self
end

function RoomWebSocketClient:pushSyntheticEvent(packet)
    self.synthetic_events[#self.synthetic_events + 1] = packet
end

function RoomWebSocketClient:start(room_id, steam_id)
    local resolved_room_id = tostring(room_id)
    local resolved_steam_id = tostring(steam_id)
    if self.thread
        and self.sender_thread
        and self.room_id == resolved_room_id
        and self.steam_id == resolved_steam_id
    then
        return
    end

    self:stop(true)

    if not (love and love.thread and love.thread.newThread and love.thread.getChannel) then
        self:pushSyntheticEvent({
            type = "bridge_status",
            payload = {
                status = "error",
                message = "love.thread is unavailable",
            },
        })
        return
    end

    local worker_data, worker_error = loadThreadFileData(RECEIVE_WORKER_PATH, "receive")
    if not worker_data then
        self:pushSyntheticEvent({
            type = "bridge_status",
            payload = {
                status = "error",
                message = tostring(worker_error),
            },
        })
        return
    end

    self.worker_token = nextWorkerToken()
    local command_name = "room_ws_winhttp_command_" .. self.worker_token
    local event_name = "room_ws_winhttp_event_" .. self.worker_token
    self.command_channel = love.thread.getChannel(command_name)
    self.event_channel = love.thread.getChannel(event_name)
    self.event_channel_name = event_name
    clearChannel(self.command_channel)
    clearChannel(self.event_channel)
    self.sender_command_channel = love.thread.getChannel(command_name .. "_sender")
    clearChannel(self.sender_command_channel)

    local ws_url = string.format("%s/room/ws/%s?steam_id=%s", self.ws_base_url, resolved_room_id, resolved_steam_id)
    self.room_id = resolved_room_id
    self.steam_id = resolved_steam_id
    self.ws_url = ws_url
    self.thread = love.thread.newThread(worker_data)
    self.last_thread_error = nil

    local started, start_error = pcall(self.thread.start, self.thread, ws_url, command_name, event_name)
    if not started then
        self:pushSyntheticEvent({
            type = "bridge_status",
            payload = {
                status = "error",
                message = tostring(start_error),
            },
        })
        self.thread = nil
        return
    end

    local sender_data, sender_error = loadThreadFileData(SEND_WORKER_PATH, "send")
    if not sender_data then
        self:pushSyntheticEvent({
            type = "bridge_status",
            payload = {
                status = "error",
                message = tostring(sender_error),
            },
        })
        return
    end

    self.sender_thread = love.thread.newThread(sender_data)
    self.last_sender_thread_error = nil
    local sender_started, sender_start_error = pcall(
        self.sender_thread.start,
        self.sender_thread,
        ws_url .. "&sender_only=1",
        command_name .. "_sender",
        event_name
    )
    if not sender_started then
        self:pushSyntheticEvent({
            type = "bridge_status",
            payload = {
                status = "error",
                message = tostring(sender_start_error),
            },
        })
        self.sender_thread = nil
    end
end

function RoomWebSocketClient:stop(fast)
    if self.command_channel then
        self.command_channel:push(Json.encodeObject({ type = "stop" }))
    end
    if self.sender_command_channel then
        self.sender_command_channel:push(Json.encodeObject({ type = "stop" }))
    end

    if not fast and self.thread then
        local deadline = nowSeconds() + STOP_WAIT_SECONDS
        while self.thread:isRunning() and nowSeconds() < deadline do
            sleepSeconds(0.01)
        end
    end
    if not fast and self.sender_thread then
        local deadline = nowSeconds() + STOP_WAIT_SECONDS
        while self.sender_thread:isRunning() and nowSeconds() < deadline do
            sleepSeconds(0.01)
        end
    end

    if self.event_channel then
        clearChannel(self.event_channel)
    end

    self.thread = nil
    self.command_channel = nil
    self.sender_thread = nil
    self.sender_command_channel = nil
    self.event_channel = nil
    self.synthetic_events = {}
    self.last_thread_error = nil
    self.last_sender_thread_error = nil
    self.worker_token = nil
    self.room_id = nil
    self.steam_id = nil
    self.ws_url = nil
    self.event_channel_name = nil
end

function RoomWebSocketClient:send(packet)
    if not self.sender_command_channel then
        return
    end
    self.sender_command_channel:push(Json.encodeObject({
        type = "send",
        payload = Json.encodeObject(packet),
    }))
end

function RoomWebSocketClient:poll()
    local packets = {}

    while #self.synthetic_events > 0 do
        packets[#packets + 1] = table.remove(self.synthetic_events, 1)
    end

    if self.thread and not self.thread:isRunning() then
        local thread_error = self.thread:getError()
        if thread_error and thread_error ~= "" and thread_error ~= self.last_thread_error then
            self.last_thread_error = thread_error
            packets[#packets + 1] = {
                type = "bridge_status",
                payload = {
                    status = "error",
                    message = tostring(thread_error),
                },
            }
        end
    end

    if self.sender_thread and not self.sender_thread:isRunning() then
        local thread_error = self.sender_thread:getError()
        if thread_error and thread_error ~= "" and thread_error ~= self.last_sender_thread_error then
            self.last_sender_thread_error = thread_error
            packets[#packets + 1] = {
                type = "bridge_status",
                payload = {
                    status = "error",
                    message = tostring(thread_error),
                },
            }
        end
    end

    while self.event_channel do
        local raw_packet = self.event_channel:pop()
        if raw_packet == nil then
            break
        end

        local decoded, decode_error = Json.decode(tostring(raw_packet))
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

    return packets
end

return RoomWebSocketClient
