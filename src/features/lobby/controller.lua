local Controller = {}
Controller.__index = Controller

local MAX_INPUT_LENGTH = 24

local function trim(text)
    return (text or ""):match("^%s*(.-)%s*$")
end

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "LobbyController requires state")
    self.service = assert(options and options.service, "LobbyController requires service")
    self.user_profile = assert(options and options.user_profile, "LobbyController requires user_profile")
    self.on_back = assert(options and options.on_back, "LobbyController requires on_back")
    self.on_enter_room = assert(options and options.on_enter_room, "LobbyController requires on_enter_room")

    self:loadPage(1)

    return self
end

function Controller:loadPage(page)
    self.state.loading = true
    self.state.error_message = ""
    self.state.status_message = "正在加载房间列表..."

    local result = self.service:fetchRooms(page, self.state.page_size)

    self.state.loading = false
    if not result.ok then
        self.state.error_message = result.message or "房间列表加载失败。"
        self.state.status_message = ""
        self.state.rooms = {}
        self.state.total = 0
        self.state.has_prev = false
        self.state.has_next = false
        return
    end

    self.state.rooms = result.rooms or {}
    self.state.total = result.total or 0
    self.state.page = result.page or page
    self.state.page_size = result.page_size or self.state.page_size
    self.state.has_prev = result.has_prev == true
    self.state.has_next = result.has_next == true
    self.state.error_message = ""
    self.state.status_message = result.message or "大厅列表已刷新。"
end

function Controller:mousemoved(x, y, view)
    self.state.hovered_control = view:getControlAt(x, y, self.state)
end

function Controller:setFocusedField(field_id)
    self.state.focused_field = field_id
end

function Controller:appendText(text)
    local field = self.state.focused_field
    if not field then
        return
    end

    if #text == 0 then
        return
    end

    local map = {
        create_title = "create_title_input",
        create_mode = "create_mode_input",
        create_password = "create_password_input",
        join_room_id = "join_room_id_input",
        join_password = "join_password_input",
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
        create_title = "create_title_input",
        create_mode = "create_mode_input",
        create_password = "create_password_input",
        join_room_id = "join_room_id_input",
        join_password = "join_password_input",
    }

    local key = map[field]
    if not key then
        return
    end

    local current = self.state[key] or ""
    self.state[key] = current:sub(1, math.max(#current - 1, 0))
end

function Controller:createRoom()
    local title = trim(self.state.create_title_input)
    local mode = trim(self.state.create_mode_input)

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

    self.state.submitting = true
    self.state.error_message = ""
    self.state.status_message = "正在创建房间..."

    local result = self.service:createRoom(
        self.user_profile.steam_id,
        title,
        mode,
        trim(self.state.create_password_input)
    )

    self.state.submitting = false
    if not result.ok then
        self.state.error_message = result.message or "创建房间失败。"
        self.state.status_message = ""
        return
    end

    self.on_enter_room(result.room_id)
end

function Controller:joinRoom()
    local room_id = trim(self.state.join_room_id_input)
    if room_id == "" then
        self.state.error_message = "房间号不能为空。"
        self.state.status_message = ""
        return
    end

    self.state.submitting = true
    self.state.error_message = ""
    self.state.status_message = "正在加入房间..."

    local result = self.service:joinRoom(room_id, self.user_profile.steam_id, trim(self.state.join_password_input))

    self.state.submitting = false
    if not result.ok then
        self.state.error_message = result.message or "加入房间失败。"
        self.state.status_message = ""
        return
    end

    self.on_enter_room(result.room_id)
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

    if control == "back" then
        self.on_back()
        return
    end

    if control == "refresh" then
        self:loadPage(self.state.page)
        return
    end

    if control == "prev_page" then
        self:loadPage(self.state.page - 1)
        return
    end

    if control == "next_page" then
        self:loadPage(self.state.page + 1)
        return
    end

    if control == "create_room" then
        self:createRoom()
        return
    end

    if control == "join_room" then
        self:joinRoom()
    end
end

function Controller:keypressed(key)
    if key == "backspace" then
        self:backspace()
        return
    end

    if key == "r" then
        self:loadPage(self.state.page)
        return
    end

    if key == "escape" then
        self:setFocusedField(nil)
        self.on_back()
        return
    end

    if key == "return" or key == "kpenter" then
        if self.state.focused_field == "join_room_id" or self.state.focused_field == "join_password" then
            self:joinRoom()
        else
            self:createRoom()
        end
    end
end

return Controller
