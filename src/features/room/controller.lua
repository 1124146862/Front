local Controller = {}
Controller.__index = Controller

local I18n = require("src.core.i18n.i18n")
local SERVER_ACTION_LOADING_DELAY = 0.04

local MAX_INPUT_LENGTH = 24
local ROOM_MODE_OPTIONS = {
    "classic",
    "level",
}

local function sameSteamID(left, right)
    local left_text = tostring(left or "")
    local right_text = tostring(right or "")
    return left_text ~= "" and left_text == right_text
end

local function isRequesterOwner(room, state)
    if (room or {}).requester_is_owner == true then
        return true
    end
    return sameSteamID((room or {}).owner_steam_id, (state or {}).steam_id)
end

local function findSelfPlayer(room, state)
    for _, player in ipairs((room and room.players) or {}) do
        if player.is_self == true or sameSteamID(player.steam_id, (state or {}).steam_id) then
            return player
        end
    end
    return nil
end

local function trim(text)
    return (text or ""):match("^%s*(.-)%s*$")
end

local function normalizeInputValue(value)
    if type(value) == "string" then
        return value
    end

    if type(value) == "number" then
        return tostring(value)
    end

    return ""
end

local function normalizeRoomMode(value)
    local normalized = trim(normalizeInputValue(value)):lower()
    for _, candidate in ipairs(ROOM_MODE_OPTIONS) do
        if normalized == candidate then
            return candidate
        end
    end
    return "classic"
end

local function roomText(key, fallback)
    local value = I18n:t(key)
    if value == key then
        return fallback
    end
    return value
end

local function isRoomMissingMessage(message)
    local text = tostring(message or ""):lower()
    return text:find("room not found", 1, true) ~= nil
        or text:find("not found", 1, true) ~= nil
end

local function isRoomMissingResult(result)
    if not result or result.ok then
        return false
    end
    if tonumber(result.status) == 404 then
        return true
    end
    if tostring(result.error_code or "") == "room_not_found" then
        return true
    end
    return isRoomMissingMessage(result.message)
end

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "RoomController requires state")
    self.service = assert(options and options.service, "RoomController requires service")
    self.on_back_to_lobby = assert(options and options.on_back_to_lobby, "RoomController requires on_back_to_lobby")
    self.on_game_started = assert(options and options.on_game_started, "RoomController requires on_game_started")
    self.auto_single_player_bootstrap = options and options.auto_single_player_bootstrap == true

    self.state.realtime_status = "connecting"
    self:beginServerLoading(function()
        self:refreshRoom()
    end, I18n:t("room.loading_room"))
    self.service:connectRoomChannel(self.state.room_id, self.state.steam_id)

    return self
end

function Controller:beginServerLoading(action_fn, message)
    if self.state.server_loading_visible then
        return false
    end
    self.state.server_loading_visible = true
    self.state.server_loading_message = message or I18n:t("common.loading")
    self.state.server_loading_elapsed = 0
    self.state.server_loading_request_started = false
    self.state.pending_server_action = action_fn
    self.state.hovered_control = nil
    return true
end

function Controller:finishServerLoading()
    self.state.server_loading_visible = false
    self.state.server_loading_message = nil
    self.state.server_loading_elapsed = 0
    self.state.server_loading_request_started = false
    self.state.pending_server_action = nil
end

function Controller:maybeBootstrapSinglePlayer()
    if not self.auto_single_player_bootstrap then
        return
    end

    if self.state.loading or self.state.saving or self.state.leaving then
        return
    end

    local room = self.state.room or {}
    if room.status == "in_game" then
        self.auto_single_player_bootstrap = false
        return
    end

    if not isRequesterOwner(room, self.state) then
        return
    end

    local players = room.players or {}
    local max_player_count = room.max_player_count or 4
    if #players < max_player_count then
        self.state.saving = true
        self.state.error_message = ""
        self.state.status_message = I18n:t("room.adding_bot")
        self:handleRoomResult(self.service:addBot(self.state.room_id, self.state.steam_id))
        return
    end

    local me_ready = (findSelfPlayer(room, self.state) or {}).is_ready == true

    if not me_ready then
        self.state.saving = true
        self.state.error_message = ""
        self.state.status_message = I18n:t("room.saving_ready")
        self:handleRoomResult(self.service:setReady(self.state.room_id, self.state.steam_id, true))
        return
    end

    self.auto_single_player_bootstrap = false
end

function Controller:syncConfigInputs()
    local room = self.state.room or {}
    self.state.config_title_input = normalizeInputValue(room.title)
    self.state.config_mode_input = normalizeRoomMode(room.game_mode ~= nil and room.game_mode or "classic")
    self.state.config_password_input = normalizeInputValue(room.password_value)
end

function Controller:openPasswordOverlay()
    self.state.overlay_visible = true
    self.state.overlay_step = "password"
    self.state.overlay_password_input = normalizeInputValue(self.state.config_password_input)
    self.state.overlay_error_message = ""
    self.state.overlay_hovered_key = nil
    self.state.error_message = ""
    self.state.focused_field = nil
end

function Controller:closePasswordOverlay()
    self.state.overlay_visible = false
    self.state.overlay_step = "password"
    self.state.overlay_room_id_input = ""
    self.state.overlay_password_input = ""
    self.state.overlay_error_message = ""
    self.state.overlay_hovered_key = nil
end

function Controller:handleOverlayAction(action)
    if not action then
        return
    end

    if action == "close" then
        self:closePasswordOverlay()
        return
    end

    local current = normalizeInputValue(self.state.overlay_password_input)

    if action == "delete" then
        current = current:sub(1, math.max(#current - 1, 0))
    elseif action == "ok" then
        self.state.config_password_input = current
        self:closePasswordOverlay()
        self:beginServerLoading(function()
            self:saveConfig()
        end, I18n:t("room.saving_config"))
        return
    elseif action:match("^%d$") then
        if #current < 8 then
            current = current .. action
        end
    end

    self.state.overlay_password_input = current
    self.state.overlay_error_message = ""
    self.state.error_message = ""
end

function Controller:cycleConfigMode()
    local current_mode = normalizeRoomMode(self.state.config_mode_input)
    local current_index = 1
    for index, candidate in ipairs(ROOM_MODE_OPTIONS) do
        if candidate == current_mode then
            current_index = index
            break
        end
    end

    local next_index = current_index + 1
    if next_index > #ROOM_MODE_OPTIONS then
        next_index = 1
    end

    self.state.config_mode_input = ROOM_MODE_OPTIONS[next_index]
    self.state.error_message = ""
    self.state.focused_field = nil
end

function Controller:handleRoomResult(result)
    self.state.loading = false
    self.state.saving = false
    self.state.leaving = false

    if not result.ok then
        self.state.room_missing = isRoomMissingResult(result)
        if self.state.room_missing then
            self.state.room = nil
        end
        self.state.error_message = result.message or I18n:t("room.load_failed")
        self.state.status_message = ""
        return
    end

    self.state.room = result.room or self.state.room
    self.state.room_missing = false
    self.state.error_message = ""
    self.state.status_message = result.message or I18n:t("room.room_refreshed")
    self:syncConfigInputs()

    if self.state.room and self.state.room.status == "in_game" then
        self.service:disconnectRoomChannel()
        self.on_game_started(self.state.room)
    end
end

function Controller:handleRealtimePacket(packet)
    if packet.type == "bridge_status" then
        local payload = packet.payload or {}
        if payload.status == "connected" then
            self.state.realtime_status = "connected"
            self.state.status_message = I18n:t("room.realtime_connected")
            self.state.error_message = ""
        elseif payload.status == "connecting" then
            self.state.realtime_status = "connecting"
            self.state.status_message = I18n:t("room.realtime_connecting")
            self.state.error_message = ""
        elseif payload.status == "error" then
            self.state.realtime_status = "error"
            self.state.error_message = payload.message or I18n:t("room.realtime_failed")
            self.state.status_message = I18n:t("room.realtime_failed")
            self.state.loading = false
            self.state.saving = false
            self.state.leaving = false
        end
        return
    end

    if packet.type == "room_snapshot" then
        self:handleRoomResult({
            ok = true,
            room = packet.payload or {},
            message = I18n:t("room.snapshot_synced"),
        })
        return
    end

    if packet.type == "left_room" then
        self.service:disconnectRoomChannel()
        self.on_back_to_lobby()
        return
    end

    if packet.type == "game_started" then
        if self.state.room then
            self.service:disconnectRoomChannel()
            self.on_game_started(self.state.room)
        end
        return
    end

    if packet.type == "error" then
        local payload = packet.payload or {}
        self.state.room_missing = isRoomMissingMessage(payload.message)
        if self.state.room_missing then
            self.state.room = nil
        end
        self.state.error_message = payload.message or I18n:t("room.load_failed")
        self.state.status_message = ""
        self.state.loading = false
        self.state.saving = false
        self.state.leaving = false
        return
    end

    local event_text = {
        player_ready_changed = I18n:t("room.event_ready"),
        player_seat_changed = roomText("room.event_seat", "座位已更新。"),
        room_config_updated = I18n:t("room.event_config"),
        player_left = I18n:t("room.event_left"),
        player_presence_changed = I18n:t("room.event_presence"),
        bot_added = I18n:t("room.event_bot_added"),
        bot_removed = roomText("room.event_bot_removed", "已移除测试 Bot。"),
    }

    if event_text[packet.type] then
        self.state.status_message = event_text[packet.type]
        self.state.error_message = ""
    end
end

function Controller:refreshRoom()
    self.state.loading = true
    self.state.error_message = ""
    self.state.status_message = I18n:t("room.loading_room")
    local result = self.service:fetchRoom(self.state.room_id, self.state.steam_id)
    self:handleRoomResult(result)
end

function Controller:toggleReady()
    local room = self.state.room or {}
    local me_ready = (findSelfPlayer(room, self.state) or {}).is_ready == true

    self.state.saving = true
    self.state.error_message = ""
    self.state.status_message = me_ready and I18n:t("room.saving_cancel_ready") or I18n:t("room.saving_ready")
    self:handleRoomResult(self.service:setReady(self.state.room_id, self.state.steam_id, not me_ready))
end

function Controller:saveConfig()
    local room = self.state.room or {}
    local title = trim(self.state.config_title_input)
    local mode = normalizeRoomMode(self.state.config_mode_input)
    if title == "" then
        title = trim(room.title)
    end
    if title == "" then
        title = roomText("room.default_title", "我的房间")
    end

    self.state.saving = true
    self.state.error_message = ""
    self.state.status_message = I18n:t("room.saving_config")
    self:handleRoomResult(self.service:updateConfig(
        self.state.room_id,
        self.state.steam_id,
        title,
        mode,
        trim(self.state.config_password_input)
    ))
end

function Controller:setConfigMode(mode)
    self.state.config_mode_input = normalizeRoomMode(mode)
    self.state.error_message = ""
    self.state.focused_field = nil
end

function Controller:saveConfigWithMode(mode)
    self:setConfigMode(mode)
    self:saveConfig()
end

function Controller:leaveRoom()
    if self.state.room_missing then
        self.state.leaving = false
        self.service:disconnectRoomChannel()
        self.on_back_to_lobby()
        return
    end

    self.state.leaving = true
    self.state.error_message = ""
    self.state.status_message = I18n:t("room.leaving")
    local result = self.service:leaveRoom(self.state.room_id, self.state.steam_id)
    self.state.leaving = false
    if not result.ok then
        if isRoomMissingResult(result) then
            self.state.room_missing = true
            self.service:disconnectRoomChannel()
            self.on_back_to_lobby()
            return
        end
        self.state.error_message = result.message or I18n:t("room.load_failed")
        self.state.status_message = ""
        return
    end
    self.state.room_missing = false
    self.service:disconnectRoomChannel()
    self.on_back_to_lobby()
end

function Controller:addBot()
    local room = self.state.room or {}
    if not isRequesterOwner(room, self.state) then
        self.state.error_message = I18n:t("room.only_owner_add_bot")
        self.state.status_message = ""
        return
    end

    self.state.saving = true
    self.state.error_message = ""
    self.state.status_message = I18n:t("room.adding_bot")
    self:handleRoomResult(self.service:addBot(self.state.room_id, self.state.steam_id))
end

function Controller:removeBot(bot_steam_id)
    local room = self.state.room or {}
    if not isRequesterOwner(room, self.state) then
        self.state.error_message = roomText("room.only_owner_remove_bot", "只有房主可以删除 Bot。")
        self.state.status_message = ""
        return
    end

    local target_bot_id = tonumber(bot_steam_id)
    if not target_bot_id or target_bot_id <= 0 then
        self.state.error_message = I18n:t("room.load_failed")
        self.state.status_message = ""
        return
    end

    self.state.saving = true
    self.state.error_message = ""
    self.state.status_message = roomText("room.removing_bot", "正在移除测试 Bot...")
    self:handleRoomResult(self.service:removeBot(self.state.room_id, self.state.steam_id, target_bot_id))
end

function Controller:changeSeat(seat_index)
    self.state.saving = true
    self.state.error_message = ""
    self.state.status_message = roomText("room.saving_seat", "正在切换座位...")
    self:handleRoomResult(self.service:changeSeat(self.state.room_id, self.state.steam_id, seat_index))
end

function Controller:setFocusedField(field_id)
    self.state.focused_field = field_id
end

function Controller:appendText(text)
    if self.state.overlay_visible then
        return
    end

    local field = self.state.focused_field
    if not field then
        return
    end

    local map = {
        config_title = "config_title_input",
        config_mode = "config_mode_input",
        config_password = "config_password_input",
    }

    local key = map[field]
    if not key then
        return
    end

    if field == "config_mode" then
        return
    end

    local current = normalizeInputValue(self.state[key])
    if #current >= MAX_INPUT_LENGTH then
        return
    end

    self.state[key] = current .. text
    self.state.error_message = ""
end

function Controller:backspace()
    local field = self.state.focused_field
    if not field then
        return
    end

    local map = {
        config_title = "config_title_input",
        config_mode = "config_mode_input",
        config_password = "config_password_input",
    }

    local key = map[field]
    if not key then
        return
    end

    if field == "config_mode" then
        return
    end

    local current = normalizeInputValue(self.state[key])
    self.state[key] = current:sub(1, math.max(#current - 1, 0))
end

function Controller:mousemoved(x, y, view)
    if self.state.server_loading_visible then
        self.state.hovered_control = nil
        self.state.overlay_hovered_key = nil
        return
    end

    if self.state.overlay_visible then
        self.state.overlay_hovered_key = view:getOverlayActionAt(x, y, self.state)
        self.state.hovered_control = nil
        return
    end

    self.state.hovered_control = view:getControlAt(x, y, self.state)
end

function Controller:mousepressed(x, y, button, view)
    if button ~= 1 then
        return false
    end

    if self.state.server_loading_visible then
        return false
    end

    if self.state.overlay_visible then
        local action = view:getOverlayActionAt(x, y, self.state)
        self:handleOverlayAction(action)
        return action ~= nil
    end

    local input = view:getInputAt(x, y, self.state)
    if input then
        if input == "config_password" then
            self:openPasswordOverlay()
            return true
        end
        self:setFocusedField(input)
        return false
    end

    self:setFocusedField(nil)

    local control = view:getControlAt(x, y, self.state)
    if not control then
        return false
    end

    if control == "toggle_ready" then
        self:beginServerLoading(function()
            self:toggleReady()
        end, I18n:t("room.saving_ready"))
        return true
    end

    if control == "leave_room" then
        self:beginServerLoading(function()
            self:leaveRoom()
        end, I18n:t("room.leaving"))
        return true
    end

    if control == "add_bot" then
        self:beginServerLoading(function()
            self:addBot()
        end, I18n:t("room.adding_bot"))
        return true
    end

    if control == "config_mode_classic" then
        self:beginServerLoading(function()
            self:saveConfigWithMode("classic")
        end, I18n:t("room.saving_config"))
        return true
    end

    if control == "config_mode_level" then
        self:beginServerLoading(function()
            self:saveConfigWithMode("level")
        end, I18n:t("room.saving_config"))
        return true
    end

    local bot_steam_id = tonumber(string.match(tostring(control), "^remove_bot_(%d+)$"))
    if bot_steam_id then
        self:beginServerLoading(function()
            self:removeBot(bot_steam_id)
        end, roomText("room.removing_bot", "正在移除测试 Bot..."))
        return true
    end

    local seat_index = tonumber(string.match(tostring(control), "^seat_row_(%d+)$"))
    if seat_index then
        self:beginServerLoading(function()
            self:changeSeat(seat_index)
        end, roomText("room.saving_seat", "正在切换座位..."))
        return true
    end
    return false
end

function Controller:keypressed(key)
    if self.state.overlay_visible then
        if key == "escape" then
            self:closePasswordOverlay()
        elseif key == "return" or key == "kpenter" then
            self:handleOverlayAction("ok")
        elseif key == "backspace" then
            self:handleOverlayAction("delete")
        elseif key:match("^%d$") then
            self:handleOverlayAction(key)
        end
        return
    end

    if key == "backspace" then
        self:backspace()
        return
    end

    if key == "escape" then
        self:beginServerLoading(function()
            self:leaveRoom()
        end, I18n:t("room.leaving"))
        return
    end

    if key == "return" or key == "kpenter" then
        if self.state.focused_field then
            self:beginServerLoading(function()
                self:saveConfig()
            end, I18n:t("room.saving_config"))
        else
            self:beginServerLoading(function()
                self:toggleReady()
            end, I18n:t("room.saving_ready"))
        end
    end
end

function Controller:update(dt)
    if self.state.server_loading_visible then
        self.state.server_loading_elapsed = (tonumber(self.state.server_loading_elapsed) or 0) + (tonumber(dt) or 0)
        if not self.state.server_loading_request_started
            and self.state.server_loading_elapsed >= SERVER_ACTION_LOADING_DELAY
        then
            self.state.server_loading_request_started = true
            local action_fn = self.state.pending_server_action
            if action_fn then
                action_fn()
            end
            self:finishServerLoading()
        end
    end

    local packets = self.service:pollRoomChannel()
    for _, packet in ipairs(packets) do
        self:handleRealtimePacket(packet)
    end

    self:maybeBootstrapSinglePlayer()
end

function Controller:shutdown()
    self.state.realtime_status = "disconnected"
    self.service:disconnectRoomChannel()
end

return Controller
