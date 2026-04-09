local Controller = {}
Controller.__index = Controller

local AvatarRegistry = require("src.features.session.avatars.registry")
local I18n = require("src.core.i18n.i18n")
local NicknameGenerator = require("src.features.session.nickname_generator_clean")
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")
local MIN_NICKNAME_LENGTH = 2
local MAX_NICKNAME_LENGTH = 12
local QUERY_DELAY = 0.45
local SUBMIT_DELAY = 0.55
local PRESS_FEEDBACK_DURATION = 0.11
local NICKNAME_RANDOM_ONLY = true
local MISSING_REAL_STEAM_ID_MESSAGE = "未检测到真实 SteamID，请通过 Steam 启动游戏并确认已登录。"

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

local function buildAvatarOrder()
    local ids = {}
    for _, avatar in ipairs(AvatarRegistry) do
        ids[#ids + 1] = avatar.id
    end

    for index = #ids, 2, -1 do
        local swap_index = love.math.random(index)
        ids[index], ids[swap_index] = ids[swap_index], ids[index]
    end

    return ids
end

local function triggerPressFeedback(state, key)
    if not state or type(state.press_feedback) ~= "table" then
        return
    end
    state.press_feedback[key] = PRESS_FEEDBACK_DURATION
end

local function updatePressFeedback(state, dt)
    if not state or type(state.press_feedback) ~= "table" then
        return
    end
    local delta = tonumber(dt) or 0
    if delta <= 0 then
        return
    end
    for key, value in pairs(state.press_feedback) do
        local remaining = math.max(0, (tonumber(value) or 0) - delta)
        state.press_feedback[key] = remaining
    end
end

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "SessionController requires state")
    self.service = assert(options and options.service, "SessionController requires service")
    self.steam_id_provider = options and options.steam_id_provider or nil
    self.on_session_ready = assert(options and options.on_session_ready, "SessionController requires on_session_ready")
    self.pending_request = nil
    self.initial_fetch_result = options and options.initial_fetch_result or nil
    self.initial_steam_id = options and options.initial_steam_id or nil
    self.force_edit = options and options.force_edit == true
    self.auto_randomize = options and options.auto_randomize == true
    self.auto_randomized = false
    self.nickname_generator = NicknameGenerator.new()
    self.state.avatar_order = buildAvatarOrder()
    self.state.total_avatar_pages = math.max(1, math.ceil(#self.state.avatar_order / self.state.avatar_page_size))
    self:refreshAvatarPage()

    if self.initial_fetch_result ~= nil then
        self:resolveSteamID()
        if self.force_edit then
            self:enterForcedEdit(self.initial_fetch_result)
        else
            self:applyFetchResult(self.initial_fetch_result)
        end
    else
        self:beginCheck()
    end

    return self
end

function Controller:refreshAvatarPage()
    local start_index = (self.state.avatar_page - 1) * self.state.avatar_page_size + 1
    local visible_ids = {}

    for index = start_index, math.min(start_index + self.state.avatar_page_size - 1, #self.state.avatar_order) do
        visible_ids[#visible_ids + 1] = self.state.avatar_order[index]
    end

    self.state.avatar_visible_ids = visible_ids
end

function Controller:findAvatarIndex(avatar_id)
    if not avatar_id then
        return nil
    end

    for index, existing_id in ipairs(self.state.avatar_order) do
        if existing_id == avatar_id then
            return index
        end
    end

    return nil
end

function Controller:setSelectedAvatar(avatar_id)
    local selected_id = avatar_id
    local avatar_index = self:findAvatarIndex(selected_id)
    if not avatar_index then
        selected_id = nil
    end

    self.state.selected_avatar_id = selected_id
    self.state.avatar_explicit_selected = selected_id ~= nil

    if avatar_index then
        self.state.avatar_page = math.max(1, math.ceil(avatar_index / self.state.avatar_page_size))
    end

    self:refreshAvatarPage()
end

function Controller:getEffectiveAvatarId()
    return self.state.selected_avatar_id or self.state.avatar_visible_ids[1] or "avatar_1"
end

function Controller:changeAvatarPage(delta)
    local total_pages = self.state.total_avatar_pages
    local next_page = self.state.avatar_page + delta
    if next_page < 1 then
        next_page = total_pages
    elseif next_page > total_pages then
        next_page = 1
    end

    self.state.avatar_page = next_page
    self:refreshAvatarPage()
    self.state.hovered_avatar_id = nil
end

function Controller:selectAvatar(avatar_id)
    self:setSelectedAvatar(avatar_id)
end

function Controller:clearNickname()
    self.state.nickname_input = ""
    self.state.error_message = ""
end

function Controller:resolveSteamID()
    local steam_id = self.initial_steam_id or (self.steam_id_provider and self.steam_id_provider:getSteamID()) or ""
    self.state.steam_id = steam_id
    return steam_id
end

function Controller:showMissingSteamIDError()
    self.state.phase = "editing"
    self.state.query_pending = false
    self.state.submit_pending = false
    self.state.status_message = ""
    self.state.error_message = MISSING_REAL_STEAM_ID_MESSAGE
    self.state.input_focused = false
    self.pending_request = nil
end

function Controller:randomizeNickname()
    self.state.nickname_input = self.nickname_generator:generate(I18n:getLocale())
    self.state.error_message = ""
    self.state.input_focused = false
end

function Controller:autoRandomizeIfNeeded()
    if not self.auto_randomize or self.auto_randomized then
        return
    end
    if self.state.phase ~= "editing" then
        return
    end
    if self.state.nickname_input ~= "" then
        return
    end
    self:randomizeNickname()
    self.auto_randomized = true
end

function Controller:beginCheck()
    if self:resolveSteamID() == "" then
        self:showMissingSteamIDError()
        return
    end
    self.state.phase = "checking"
    self.state.query_pending = true
    self.state.submit_pending = false
    self.state.status_message = I18n:t("session.checking")
    self.state.error_message = ""
    self.pending_request = {
        kind = "fetch_nickname",
        timer = QUERY_DELAY,
    }
end

function Controller:update(dt)
    updatePressFeedback(self.state, dt)

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
        self:resolveSubmitNickname(request.nickname, request.avatar_id)
    end
end

function Controller:resolveFetchNickname()
    if tostring(self.state.steam_id or "") == "" then
        self:showMissingSteamIDError()
        return
    end
    local result = self.service:fetchNicknameBySteamID(self.state.steam_id)
    self.state.query_pending = false
    if self.force_edit then
        self:enterForcedEdit(result)
        return
    end

    self:applyFetchResult(result)
end

function Controller:applyFetchResult(result)
    if not result.ok then
        self.state.phase = "editing"
        self.state.status_message = ""
        self.state.error_message = result.message or I18n:t("session.query_failed")
        self.state.input_focused = false
        return
    end

    if result.ok and result.exists then
        self.on_session_ready({
            steam_id = self.state.steam_id,
            nickname = result.nickname,
            avatar_id = result.avatar_id or "avatar_1",
            coins = tonumber(result.coins) or 300,
            accessories = result.accessories or {
                owned_item_ids = {},
                equipped = {},
            },
            card_settings = result.card_settings or {
                theme_id = ThemeCatalog.DEFAULT_THEME_ID,
                back_id = "classic_grid",
            },
        })
        return
    end

    self.state.phase = "editing"
    self.state.status_message = ""
    self.state.error_message = ""
    self.state.input_focused = false
    self:autoRandomizeIfNeeded()
end

function Controller:enterForcedEdit(result)
    self.state.phase = "editing"
    self.state.query_pending = false
    self.state.submit_pending = false
    self.state.status_message = ""
    self.state.input_focused = false
    self.state.hovered_avatar_id = nil

    if not result.ok then
        self.state.nickname_input = ""
        self.state.error_message = result.message or I18n:t("session.query_failed")
        self:setSelectedAvatar(nil)
        return
    end

    if result.exists then
        self.state.nickname_input = result.nickname or ""
        self.state.error_message = ""
        self:setSelectedAvatar(result.avatar_id or "avatar_1")
        return
    end

    self.state.nickname_input = ""
    self.state.error_message = ""
    self:setSelectedAvatar(nil)
end

function Controller:resolveSubmitNickname(nickname, avatar_id)
    local result = self.service:submitNickname(self.state.steam_id, nickname, avatar_id)
    self.state.submit_pending = false

    if not result.ok then
        self.state.phase = "editing"
        self.state.error_message = result.message or I18n:t("session.submit_failed")
        return
    end

    self.state.phase = "done"
    self.state.error_message = ""
    self.state.status_message = result.message or I18n:t("session.submit_success")

    local latest_result = self.service:fetchNicknameBySteamID(self.state.steam_id)
    if latest_result.ok and latest_result.exists then
        result = {
            nickname = latest_result.nickname,
            avatar_id = latest_result.avatar_id or result.avatar_id or avatar_id or "avatar_1",
            coins = tonumber(latest_result.coins) or tonumber(result.coins) or 300,
            accessories = latest_result.accessories or result.accessories,
            card_settings = latest_result.card_settings or result.card_settings,
        }
    end

    self.on_session_ready({
        steam_id = self.state.steam_id,
        nickname = result.nickname,
        avatar_id = result.avatar_id or avatar_id or "avatar_1",
        coins = tonumber(result.coins) or 300,
        accessories = result.accessories or {
            owned_item_ids = {},
            equipped = {},
        },
        card_settings = result.card_settings or {
            theme_id = ThemeCatalog.DEFAULT_THEME_ID,
            back_id = "classic_grid",
        },
    })
end

function Controller:setHovered(x, y, view)
    self.state.button_hovered = view:isButtonHovered(x, y)
    self.state.random_button_hovered = view:isRandomButtonHovered(x, y)
    self.state.hovered_avatar_prev = view:isAvatarPrevHovered(x, y)
    self.state.hovered_avatar_next = view:isAvatarNextHovered(x, y)
    self.state.hovered_avatar_id = view:getAvatarAt(x, y, self.state)
end

function Controller:focusInput(focused)
    if NICKNAME_RANDOM_ONLY then
        self.state.input_focused = false
        return
    end
    self.state.input_focused = focused
end

function Controller:appendText(text)
    if NICKNAME_RANDOM_ONLY then
        return
    end
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
    if NICKNAME_RANDOM_ONLY then
        return
    end
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
        return false, I18n:t("session.nickname_empty")
    end

    if length < MIN_NICKNAME_LENGTH then
        return false, I18n:t("session.nickname_min")
    end

    if length > MAX_NICKNAME_LENGTH then
        return false, I18n:t("session.nickname_max")
    end

    return true, nickname
end

function Controller:submit()
    if self.state.phase ~= "editing" or self.state.submit_pending or self.state.query_pending then
        return
    end

    if tostring(self.state.steam_id or "") == "" then
        self:showMissingSteamIDError()
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
    self.state.status_message = I18n:t("session.submit_pending")
    local avatar_id = self:getEffectiveAvatarId()
    self.pending_request = {
        kind = "submit_nickname",
        timer = SUBMIT_DELAY,
        nickname = value,
        avatar_id = avatar_id,
    }
end

function Controller:mousepressed(x, y, button, view)
    if button ~= 1 then
        return false
    end

    if view:isRandomButtonHovered(x, y) then
        triggerPressFeedback(self.state, "random")
        self:randomizeNickname()
        return true
    end

    if view:isAvatarPrevHovered(x, y) then
        triggerPressFeedback(self.state, "avatar_prev")
        self:changeAvatarPage(-1)
        self:focusInput(false)
        return true
    end

    if view:isAvatarNextHovered(x, y) then
        triggerPressFeedback(self.state, "avatar_next")
        self:changeAvatarPage(1)
        self:focusInput(false)
        return true
    end

    local avatar_id = view:getAvatarAt(x, y, self.state)
    if avatar_id then
        self:selectAvatar(avatar_id)
        self:focusInput(false)
        return true
    end

    if view:isInputHovered(x, y) then
        self:focusInput(false)
        return false
    end

    self:focusInput(false)

    if view:isButtonHovered(x, y) then
        triggerPressFeedback(self.state, "submit")
        self:submit()
        return true
    end
    return false
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
