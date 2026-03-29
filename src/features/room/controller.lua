local Controller = {}
Controller.__index = Controller

local MAX_INPUT_LENGTH = 24

local function trim(text)
    return (text or ""):match("^%s*(.-)%s*$")
end

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "RoomController requires state")
    self.service = assert(options and options.service, "RoomController requires service")
    self.on_back_to_lobby = assert(options and options.on_back_to_lobby, "RoomController requires on_back_to_lobby")
    self.on_game_started = assert(options and options.on_game_started, "RoomController requires on_game_started")

    self:refreshRoom()

    return self
end

function Controller:syncConfigInputs()
    local room = self.state.room or {}
    self.state.config_title_input = room.title or ""
    self.state.config_mode_input = room.game_mode or "classic"
    self.state.config_password_input = room.password_value or ""
end

function Controller:handleRoomResult(result)
    self.state.loading = false
    self.state.saving = false

    if not result.ok then
        self.state.error_message = result.message or "房间请求失败。"
        self.state.status_message = ""
        return
    end

    self.state.room = result.room or self.state.room
    self.state.error_message = ""
    self.state.status_message = result.message or "房间信息已刷新。"
    self:syncConfigInputs()

    if self.state.room and self.state.room.status == "in_game" then
        self.on_game_started(self.state.room)
    end
end

function Controller:refreshRoom()
    self.state.loading = true
    self.state.error_message = ""
    self.state.status_message = "正在加载房间信息..."
    local result = self.service:fetchRoom(self.state.room_id, self.state.steam_id)
    self:handleRoomResult(result)
end

function Controller:toggleReady()
    local room = self.state.room or {}
    local me_ready = false
    for _, player in ipairs(room.players or {}) do
        if player.steam_id == self.state.steam_id then
            me_ready = player.is_ready == true
            break
        end
    end

    self.state.saving = true
    self.state.error_message = ""
    self.state.status_message = me_ready and "正在取消准备..." or "正在设置准备..."
    local result = self.service:setReady(self.state.room_id, self.state.steam_id, not me_ready)
    self:handleRoomResult(result)
end

function Controller:saveConfig()
    local title = trim(self.state.config_title_input)
    local mode = trim(self.state.config_mode_input)
    if title == "" then
        self.state.error_message = "房间标题不能为空。"
        self.state.status_message = ""
        return
    end
    if mode == "" then
        self.state.error_message = "游戏模式不能为空。"
        self.state.status_message = ""
        return
    end

    self.state.saving = true
    self.state.error_message = ""
    self.state.status_message = "正在保存房间配置..."
    local result = self.service:updateConfig(
        self.state.room_id,
        self.state.steam_id,
        title,
        mode,
        trim(self.state.config_password_input)
    )
    self:handleRoomResult(result)
end

function Controller:leaveRoom()
    self.state.leaving = true
    self.state.error_message = ""
    self.state.status_message = "正在离开房间..."

    local result = self.service:leaveRoom(self.state.room_id, self.state.steam_id)
    self.state.leaving = false

    if not result.ok then
        self.state.error_message = result.message or "离开房间失败。"
        self.state.status_message = ""
        return
    end

    self.on_back_to_lobby()
end

function Controller:setFocusedField(field_id)
    self.state.focused_field = field_id
end

function Controller:appendText(text)
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

    local current = self.state[key] or ""
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

    local current = self.state[key] or ""
    self.state[key] = current:sub(1, math.max(#current - 1, 0))
end

function Controller:mousemoved(x, y, view)
    self.state.hovered_control = view:getControlAt(x, y, self.state)
end

function Controller:mousepressed(x, y, button, view)
    if button ~= 1 then
        return
    end

    local input = view:getInputAt(x, y, self.state)
    if input then
        self:setFocusedField(input)
        return
    end

    self:setFocusedField(nil)

    local control = view:getControlAt(x, y, self.state)
    if not control then
        return
    end

    if control == "refresh_room" then
        self:refreshRoom()
        return
    end

    if control == "toggle_ready" then
        self:toggleReady()
        return
    end

    if control == "leave_room" then
        self:leaveRoom()
        return
    end

    if control == "save_config" then
        self:saveConfig()
    end
end

function Controller:keypressed(key)
    if key == "backspace" then
        self:backspace()
        return
    end

    if key == "r" then
        self:refreshRoom()
        return
    end

    if key == "escape" then
        self:leaveRoom()
        return
    end

    if key == "return" or key == "kpenter" then
        if self.state.focused_field then
            self:saveConfig()
        else
            self:toggleReady()
        end
    end
end

return Controller
