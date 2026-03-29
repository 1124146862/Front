local Controller = {}
Controller.__index = Controller

local MIN_NICKNAME_LENGTH = 2
local MAX_NICKNAME_LENGTH = 12
local QUERY_DELAY = 0.45
local SUBMIT_DELAY = 0.55

local function utf8Length(text)
    local _, count = string.gsub(text or "", "[^\128-\193]", "")
    return count
end

local function trim(text)
    return text:match("^%s*(.-)%s*$")
end

local function utf8Codepoint(char)
    local byte1 = string.byte(char, 1)
    if not byte1 then
        return nil
    end

    if byte1 < 0x80 then
        return byte1
    end

    local byte2 = string.byte(char, 2)
    if byte1 < 0xE0 then
        if not byte2 then
            return nil
        end

        return (byte1 - 0xC0) * 0x40 + (byte2 - 0x80)
    end

    local byte3 = string.byte(char, 3)
    if byte1 < 0xF0 then
        if not byte2 or not byte3 then
            return nil
        end

        return (byte1 - 0xE0) * 0x1000 + (byte2 - 0x80) * 0x40 + (byte3 - 0x80)
    end

    local byte4 = string.byte(char, 4)
    if not byte2 or not byte3 or not byte4 then
        return nil
    end

    return (byte1 - 0xF0) * 0x40000
        + (byte2 - 0x80) * 0x1000
        + (byte3 - 0x80) * 0x40
        + (byte4 - 0x80)
end

local function utf8Sub(text, start_char, end_char)
    start_char = start_char or 1
    end_char = end_char or -1

    if end_char < 0 then
        end_char = utf8Length(text) + end_char + 1
    end

    local start_byte = 1
    local current_char = 1

    while current_char < start_char and start_byte <= #text do
        local byte = string.byte(text, start_byte)
        if byte < 0x80 then
            start_byte = start_byte + 1
        elseif byte < 0xE0 then
            start_byte = start_byte + 2
        elseif byte < 0xF0 then
            start_byte = start_byte + 3
        else
            start_byte = start_byte + 4
        end
        current_char = current_char + 1
    end

    local end_byte = start_byte
    while current_char <= end_char and end_byte <= #text do
        local byte = string.byte(text, end_byte)
        if byte < 0x80 then
            end_byte = end_byte + 1
        elseif byte < 0xE0 then
            end_byte = end_byte + 2
        elseif byte < 0xF0 then
            end_byte = end_byte + 3
        else
            end_byte = end_byte + 4
        end
        current_char = current_char + 1
    end

    return string.sub(text, start_byte, end_byte - 1)
end

local function isAllowedCharacter(char)
    if char:match("[%w]") then
        return true
    end

    local codepoint = utf8Codepoint(char)
    if not codepoint then
        return false
    end

    return (codepoint >= 0x4E00 and codepoint <= 0x9FFF)
        or (codepoint >= 0x3400 and codepoint <= 0x4DBF)
end

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "SessionController requires state")
    self.service = assert(options and options.service, "SessionController requires service")
    self.steam_id_provider = assert(options and options.steam_id_provider, "SessionController requires steam_id_provider")
    self.on_session_ready = assert(options and options.on_session_ready, "SessionController requires on_session_ready")
    self.pending_request = nil

    self:beginCheck()

    return self
end

function Controller:beginCheck()
    self.state.steam_id = self.steam_id_provider:getSteamID()
    self.state.phase = "checking"
    self.state.query_pending = true
    self.state.submit_pending = false
    self.state.status_message = "正在查询昵称..."
    self.state.error_message = ""
    self.pending_request = {
        kind = "fetch_nickname",
        timer = QUERY_DELAY,
    }
end

function Controller:update(dt)
    if not self.pending_request then
        return
    end

    self.pending_request.timer = self.pending_request.timer - dt
    if self.pending_request.timer > 0 then
        return
    end

    local request = self.pending_request
    self.pending_request = nil

    if request.kind == "fetch_nickname" then
        self:resolveFetchNickname()
    elseif request.kind == "submit_nickname" then
        self:resolveSubmitNickname(request.nickname)
    end
end

function Controller:resolveFetchNickname()
    local result = self.service:fetchNicknameBySteamID(self.state.steam_id)
    self.state.query_pending = false

    if not result.ok then
        self.state.phase = "editing"
        self.state.status_message = ""
        self.state.error_message = result.message or "查询昵称失败，请检查后端服务。"
        self.state.input_focused = true
        return
    end

    if result.ok and result.exists then
        self.on_session_ready({
            steam_id = self.state.steam_id,
            nickname = result.nickname,
        })
        return
    end

    self.state.phase = "editing"
    self.state.status_message = result.message or "请输入昵称。"
    self.state.error_message = ""
    self.state.input_focused = true
end

function Controller:resolveSubmitNickname(nickname)
    local result = self.service:submitNickname(self.state.steam_id, nickname)
    self.state.submit_pending = false

    if not result.ok then
        self.state.phase = "editing"
        self.state.error_message = result.message or "昵称提交失败，请稍后重试。"
        return
    end

    self.state.phase = "done"
    self.state.error_message = ""
    self.state.status_message = result.message or "昵称设置成功。"

    self.on_session_ready({
        steam_id = self.state.steam_id,
        nickname = result.nickname,
    })
end

function Controller:setHovered(x, y, view)
    self.state.button_hovered = view:isButtonHovered(x, y)
end

function Controller:focusInput(focused)
    self.state.input_focused = focused
end

function Controller:appendText(text)
    if self.state.phase ~= "editing" or not self.state.input_focused or self.state.submit_pending then
        return
    end

    if not isAllowedCharacter(text) then
        return
    end

    local current_length = utf8Length(self.state.nickname_input)
    if current_length >= MAX_NICKNAME_LENGTH then
        return
    end

    self.state.nickname_input = self.state.nickname_input .. text
    self.state.error_message = ""
end

function Controller:backspace()
    if self.state.phase ~= "editing" or not self.state.input_focused then
        return
    end

    local length = utf8Length(self.state.nickname_input)
    if length <= 0 then
        self.state.nickname_input = ""
        return
    end

    self.state.nickname_input = utf8Sub(self.state.nickname_input, 1, length - 1)
end

function Controller:validateNickname()
    local nickname = trim(self.state.nickname_input)
    local length = utf8Length(nickname)

    if nickname == "" then
        return false, "昵称不能为空。"
    end

    if length < MIN_NICKNAME_LENGTH then
        return false, "昵称至少需要 2 个字符。"
    end

    if length > MAX_NICKNAME_LENGTH then
        return false, "昵称不能超过 12 个字符。"
    end

    return true, nickname
end

function Controller:submit()
    if self.state.phase ~= "editing" or self.state.submit_pending or self.state.query_pending then
        return
    end

    local ok, value = self:validateNickname()
    if not ok then
        self.state.error_message = value
        self.state.status_message = ""
        return
    end

    self.state.nickname_input = value
    self.state.phase = "submitting"
    self.state.submit_pending = true
    self.state.error_message = ""
    self.state.status_message = "正在提交昵称..."
    self.pending_request = {
        kind = "submit_nickname",
        timer = SUBMIT_DELAY,
        nickname = value,
    }
end

function Controller:mousepressed(x, y, button, view)
    if button ~= 1 then
        return
    end

    if view:isInputHovered(x, y) then
        self:focusInput(true)
        return
    end

    self:focusInput(false)

    if view:isButtonHovered(x, y) then
        self:submit()
    end
end

function Controller:keypressed(key)
    if key == "backspace" then
        self:backspace()
        return
    end

    if key == "return" or key == "kpenter" then
        self:submit()
    end
end

return Controller
