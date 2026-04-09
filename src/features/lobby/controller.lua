local Controller = {}
Controller.__index = Controller

local I18n = require("src.core.i18n.i18n")
local SERVER_ACTION_LOADING_DELAY = 0.04

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "LobbyController requires state")
    self.service = assert(options and options.service, "LobbyController requires service")
    self.user_profile = assert(options and options.user_profile, "LobbyController requires user_profile")
    self.on_back = assert(options and options.on_back, "LobbyController requires on_back")
    self.on_enter_room = assert(options and options.on_enter_room, "LobbyController requires on_enter_room")

    self:beginServerLoading(function()
        self:loadPage(1)
    end, I18n:t("lobby.loading_rooms"))

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
    self.state.hovered_join_room_id = nil
    self.state.overlay_hovered_key = nil
    return true
end

function Controller:finishServerLoading()
    self.state.server_loading_visible = false
    self.state.server_loading_message = nil
    self.state.server_loading_elapsed = 0
    self.state.server_loading_request_started = false
    self.state.pending_server_action = nil
end

function Controller:loadPage(page)
    self.state.loading = true
    self.state.error_message = ""
    self.state.status_message = I18n:t("lobby.loading_rooms")

    local result = self.service:fetchRooms(page, self.state.page_size)

    self.state.loading = false
    if not result.ok then
        self.state.error_message = result.message or I18n:t("lobby.load_failed")
        self.state.status_message = ""
        self.state.rooms = {}
        self.state.total = 0
        self.state.has_prev = false
        self.state.has_next = false
        return
    end

    self.state.rooms = result.rooms or {}
    -- Show actual visible room count for the current list.
    self.state.total = #(self.state.rooms or {})
    self.state.page = result.page or page
    self.state.page_size = 5
    self.state.has_prev = result.has_prev == true
    self.state.has_next = result.has_next == true
    self.state.error_message = ""
    self.state.status_message = ""
end

function Controller:openJoinOverlay()
    self:openJoinOverlayForRoom(nil, false)
end

function Controller:openJoinOverlayForRoom(room_id, password_required)
    self.state.overlay_visible = true
    self.state.overlay_step = password_required and "password" or "room_id"
    self.state.overlay_room_id_input = room_id and tostring(room_id) or ""
    self.state.overlay_password_input = ""
    self.state.overlay_error_message = ""
    self.state.overlay_hovered_key = nil
    self.state.error_message = ""
    self.state.status_message = room_id and I18n:t("lobby.ready_join") or I18n:t("lobby.input_room")
end

function Controller:closeJoinOverlay()
    self.state.overlay_visible = false
    self.state.overlay_step = "room_id"
    self.state.overlay_room_id_input = ""
    self.state.overlay_password_input = ""
    self.state.overlay_error_message = ""
    self.state.overlay_hovered_key = nil
end

function Controller:showLobbyError(message, status_message)
    self.state.error_message = message or ""
    self.state.status_message = status_message or ""
    self.state.submitting = false
end

function Controller:handleJoinFailure(result)
    local code = result.error_code

    if code == "password_required" then
        self.state.overlay_visible = true
        self.state.overlay_step = "password"
        self.state.overlay_password_input = ""
        self.state.overlay_error_message = ""
        self.state.error_message = ""
        self.state.status_message = ""
        return
    end

    if code == "password_incorrect" then
        self.state.overlay_visible = true
        self.state.overlay_step = "password"
        self.state.overlay_error_message = I18n:t("lobby.password_incorrect")
        self.state.error_message = ""
        self.state.status_message = ""
        return
    end

    if code == "room_full" then
        self:showLobbyError(I18n:t("lobby.room_full"), "")
        return
    end

    if code == "room_in_game" then
        self:showLobbyError(I18n:t("lobby.room_in_game"), "")
        return
    end

    if code == "room_not_found" then
        self:showLobbyError(I18n:t("lobby.room_not_found"), "")
        return
    end

    self:showLobbyError(result.message or I18n:t("lobby.join_failed"), "")
end

function Controller:prepareJoinRoom(room_id)
    self.state.submitting = true
    self.state.error_message = ""
    self.state.status_message = I18n:t("lobby.fetching_detail")

    local detail = self.service:fetchRoomDetail(room_id)
    self.state.submitting = false

    if not detail.ok then
        self:handleJoinFailure(detail)
        return
    end

    local latest_room = detail.room or {}
    local is_member = false
    for _, player in ipairs(latest_room.players or {}) do
        if tonumber(player.steam_id) == tonumber(self.user_profile.steam_id) then
            is_member = true
            break
        end
    end

    if latest_room.status == "in_game" and not is_member then
        self:showLobbyError(I18n:t("lobby.room_in_game"), "")
        return
    end

    self.state.overlay_room_id_input = tostring(latest_room.room_id or room_id)
    self.state.overlay_password_input = ""

    if latest_room.has_password == true then
        self.state.overlay_visible = true
        self.state.overlay_step = "password"
        self.state.overlay_error_message = ""
        self.state.error_message = ""
        self.state.status_message = ""
        return
    end

    self:joinRoom()
end

function Controller:mousemoved(x, y, view)
    if self.state.server_loading_visible then
        self.state.hovered_control = nil
        self.state.hovered_join_room_id = nil
        self.state.overlay_hovered_key = nil
        return
    end

    if self.state.overlay_visible then
        self.state.overlay_hovered_key = view:getOverlayActionAt(x, y, self.state)
        self.state.hovered_control = nil
        self.state.hovered_join_room_id = nil
        return
    end

    self.state.hovered_control = view:getControlAt(x, y, self.state)
    local room = view:getRoomJoinActionAt(x, y, self.state)
    self.state.hovered_join_room_id = room and room.room_id or nil
end

function Controller:createRoom()
    self.state.submitting = true
    self.state.error_message = ""
    self.state.status_message = I18n:t("lobby.creating")

    local result = self.service:createRoom(self.user_profile.steam_id, nil, nil, nil)

    self.state.submitting = false
    if not result.ok then
        self.state.error_message = result.message or I18n:t("lobby.create_failed")
        self.state.status_message = ""
        return
    end

    self.on_enter_room(result.room_id)
end

function Controller:submitJoinRoomByRoomID()
    if #self.state.overlay_room_id_input ~= 5 then
        self.state.overlay_error_message = I18n:t("lobby.room_id_length")
        self.state.error_message = ""
        self.state.status_message = ""
        return
    end

    self:prepareJoinRoom(self.state.overlay_room_id_input)
end

function Controller:joinRoom()
    self.state.submitting = true
    self.state.error_message = ""
    self.state.overlay_error_message = ""
    self.state.status_message = I18n:t("lobby.joining")

    local result = self.service:joinRoom(
        self.state.overlay_room_id_input,
        self.user_profile.steam_id,
        self.state.overlay_password_input
    )

    self.state.submitting = false
    if not result.ok then
        self:handleJoinFailure(result)
        return
    end

    self:closeJoinOverlay()
    self.on_enter_room(result.room_id)
end

function Controller:handleOverlayAction(action)
    if not action then
        return
    end

    if action == "close" then
        self:closeJoinOverlay()
        return
    end

    local current = self.state.overlay_step == "password" and self.state.overlay_password_input or self.state.overlay_room_id_input

    if action == "delete" then
        current = current:sub(1, math.max(#current - 1, 0))
    elseif action == "ok" then
        if self.state.overlay_step == "room_id" then
            self:beginServerLoading(function()
                self:submitJoinRoomByRoomID()
            end, I18n:t("lobby.fetching_detail"))
        else
            self:beginServerLoading(function()
                self:joinRoom()
            end, I18n:t("lobby.joining"))
        end
        return
    elseif action:match("^%d$") then
        local max_length = self.state.overlay_step == "password" and 8 or 5
        if #current < max_length then
            current = current .. action
        end
    end

    if self.state.overlay_step == "password" then
        self.state.overlay_password_input = current
    else
        self.state.overlay_room_id_input = current
    end

    self.state.overlay_error_message = ""
    self.state.error_message = ""
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

    local control = view:getControlAt(x, y, self.state)
    if not control then
        local room = view:getRoomJoinActionAt(x, y, self.state)
        if room then
            self:beginServerLoading(function()
                self:prepareJoinRoom(room.room_id)
            end, I18n:t("lobby.fetching_detail"))
            return true
        end
        return false
    end

    if control == "back" then
        self:beginServerLoading(function()
            self.on_back()
        end, I18n:t("common.loading"))
        return true
    end

    if control == "refresh" then
        self:beginServerLoading(function()
            self:loadPage(self.state.page)
        end, I18n:t("lobby.loading_rooms"))
        return true
    end

    if control == "prev_page" then
        self:beginServerLoading(function()
            self:loadPage(self.state.page - 1)
        end, I18n:t("lobby.loading_rooms"))
        return true
    end

    if control == "next_page" then
        self:beginServerLoading(function()
            self:loadPage(self.state.page + 1)
        end, I18n:t("lobby.loading_rooms"))
        return true
    end

    if control == "create_room" then
        self:beginServerLoading(function()
            self:createRoom()
        end, I18n:t("lobby.creating"))
        return true
    end

    if control == "join_room" then
        self:openJoinOverlay()
        return true
    end
    return false
end

function Controller:keypressed(key)
    if self.state.overlay_visible then
        if key == "escape" then
            self:closeJoinOverlay()
        elseif key == "return" or key == "kpenter" then
            self:handleOverlayAction("ok")
        elseif key == "backspace" then
            self:handleOverlayAction("delete")
        elseif key:match("^%d$") then
            self:handleOverlayAction(key)
        end
        return
    end

    if key == "r" then
        self:beginServerLoading(function()
            self:loadPage(self.state.page)
        end, I18n:t("lobby.loading_rooms"))
        return
    end

    if key == "escape" then
        self:beginServerLoading(function()
            self.on_back()
        end, I18n:t("common.loading"))
    end
end

function Controller:update(dt)
    if not self.state.server_loading_visible then
        return
    end

    self.state.server_loading_elapsed = (tonumber(self.state.server_loading_elapsed) or 0) + (tonumber(dt) or 0)
    if self.state.server_loading_request_started then
        return
    end
    if self.state.server_loading_elapsed < SERVER_ACTION_LOADING_DELAY then
        return
    end

    self.state.server_loading_request_started = true
    local action_fn = self.state.pending_server_action
    if action_fn then
        action_fn()
    end
    self:finishServerLoading()
end

return Controller
