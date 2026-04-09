local I18n = require("src.core.i18n.i18n")
local Toast = require("src.core.ui.toast")
local MainMenuService = require("src.features.main_menu.service")
local MatchmakingFloater = require("src.features.matchmaking.floater")
local HttpClient = require("src.infra.network.http_client")

local MatchmakingManager = {}
MatchmakingManager.__index = MatchmakingManager

local POLL_INTERVAL_SECONDS = 1.0
local MATCHED_HOLD_SECONDS = 3.0
local NOTICE_SECONDS = 2.4
local REQUEST_COOLDOWN_SECONDS = 0.35

local function tOr(key, fallback, params)
    local value = I18n:t(key, params)
    if value == key then
        return fallback
    end
    return value
end

local function clamp(value, min_value, max_value)
    if max_value < min_value then
        return min_value
    end
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function pointInFrame(x, y, frame)
    return x >= frame.x
        and x <= frame.x + frame.width
        and y >= frame.y
        and y <= frame.y + frame.height
end

local function buildDefaultState(previous)
    return {
        queue_active = false,
        phase = "idle",
        player_count = 0,
        required_player_count = 4,
        elapsed_seconds = 0,
        countdown_seconds = 0,
        can_cancel = false,
        hovered_close = false,
        matched_holding = false,
        matched_room_id = nil,
        matched_hold_elapsed = 0,
        poll_elapsed = 0,
        floater_x = previous and previous.floater_x or nil,
        floater_y = previous and previous.floater_y or nil,
        floater_dragging = false,
        floater_drag_offset_x = 0,
        floater_drag_offset_y = 0,
    }
end

function MatchmakingManager.new(options)
    local self = setmetatable({}, MatchmakingManager)

    self.fonts = assert(options and options.fonts, "MatchmakingManager requires fonts")
    self.style = assert(options and options.style, "MatchmakingManager requires style")
    self.get_steam_id = assert(options and options.get_steam_id, "MatchmakingManager requires get_steam_id")
    self.on_enter_room = assert(options and options.on_enter_room, "MatchmakingManager requires on_enter_room")
    self.service = (options and options.service) or MainMenuService.new({
        http_client = HttpClient.new(),
    })
    self.floater = MatchmakingFloater.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.toast = Toast.new({
        fonts = self.fonts,
        colors = self.style.colors,
    })
    self.state = buildDefaultState()
    self.notice_message = ""
    self.notice_elapsed = 0
    self.request_cooldown_remaining = 0

    return self
end

function MatchmakingManager:showNotice(message)
    self.notice_message = tostring(message or "")
    self.notice_elapsed = self.notice_message ~= "" and NOTICE_SECONDS or 0
end

function MatchmakingManager:clearState()
    self.state = buildDefaultState(self.state)
end

function MatchmakingManager:getSnapshot()
    return {
        queue_active = self.state.queue_active == true,
        phase = self.state.phase or "idle",
        player_count = tonumber(self.state.player_count) or 0,
        required_player_count = tonumber(self.state.required_player_count) or 4,
        elapsed_seconds = tonumber(self.state.elapsed_seconds) or 0,
        countdown_seconds = tonumber(self.state.countdown_seconds) or 0,
        can_cancel = self.state.can_cancel == true,
        hovered_close = self.state.hovered_close == true,
        matched_holding = self.state.matched_holding == true,
    }
end

function MatchmakingManager:isBusy()
    return self.state.queue_active == true or self.state.matched_holding == true
end

function MatchmakingManager:beginMatchedHold(room_id, result)
    self.state.queue_active = false
    self.state.phase = "matched"
    self.state.player_count = tonumber((result or {}).player_count) or 4
    self.state.required_player_count = tonumber((result or {}).required_player_count) or 4
    self.state.elapsed_seconds = tonumber((result or {}).elapsed_seconds) or self.state.elapsed_seconds or 0
    self.state.countdown_seconds = tonumber((result or {}).countdown_seconds) or 0
    self.state.can_cancel = false
    self.state.hovered_close = false
    self.state.matched_holding = true
    self.state.matched_room_id = tostring(room_id)
    self.state.matched_hold_elapsed = 0
    self.state.poll_elapsed = 0
end

function MatchmakingManager:applyResult(result, options)
    options = options or {}
    if not result or result.ok ~= true then
        return false
    end

    local phase = result.phase or "idle"
    if options.from_join == true and phase == "idle" then
        phase = "searching"
    end

    if phase == "matched" and result.room_id then
        self:beginMatchedHold(result.room_id, result)
        return true
    end

    if phase == "idle" then
        self:clearState()
        return true
    end

    self.state.queue_active = true
    self.state.phase = phase
    self.state.player_count = tonumber(result.player_count) or 0
    self.state.required_player_count = tonumber(result.required_player_count) or 4
    self.state.elapsed_seconds = tonumber(result.elapsed_seconds) or 0
    self.state.countdown_seconds = tonumber(result.countdown_seconds) or 0
    self.state.can_cancel = true
    self.state.poll_elapsed = 0
    self.state.matched_holding = false
    self.state.matched_room_id = nil
    self.state.matched_hold_elapsed = 0
    return true
end

function MatchmakingManager:start()
    if (tonumber(self.request_cooldown_remaining) or 0) > 0 then
        return {
            ok = false,
            active = self:isBusy(),
        }
    end

    if self:isBusy() then
        return {
            ok = false,
            active = true,
        }
    end

    local steam_id = self.get_steam_id()
    if not steam_id then
        local message = tOr("main_menu.matchmaking_join_failed", "Failed to enter matchmaking.")
        self:showNotice(message)
        return {
            ok = false,
            message = message,
        }
    end

    local result = self.service:joinMatchmaking(steam_id)
    self.request_cooldown_remaining = REQUEST_COOLDOWN_SECONDS
    if not result or result.ok ~= true then
        local message = (result and result.message) or tOr("main_menu.matchmaking_join_failed", "Failed to enter matchmaking.")
        self:showNotice(message)
        return {
            ok = false,
            message = message,
        }
    end

    self:applyResult(result, { from_join = true })
    return {
        ok = true,
        active = true,
    }
end

function MatchmakingManager:cancel()
    if (tonumber(self.request_cooldown_remaining) or 0) > 0 then
        return {
            ok = false,
            active = self:isBusy(),
        }
    end

    if self.state.matched_holding == true then
        return {
            ok = false,
            active = true,
        }
    end

    if self.state.queue_active ~= true then
        self:clearState()
        return {
            ok = true,
            active = false,
        }
    end

    local steam_id = self.get_steam_id()
    if not steam_id then
        self:clearState()
        return {
            ok = true,
            active = false,
        }
    end

    local result = self.service:cancelMatchmaking(steam_id)
    self.request_cooldown_remaining = REQUEST_COOLDOWN_SECONDS
    if not result or result.ok ~= true then
        local message = (result and result.message) or tOr("main_menu.matchmaking_cancel_failed", "Failed to cancel matchmaking.")
        self:showNotice(message)
        return {
            ok = false,
            active = true,
            message = message,
        }
    end

    self:clearState()
    return {
        ok = true,
        active = false,
    }
end

function MatchmakingManager:toggle()
    if self.state.queue_active == true or self.state.matched_holding == true then
        return self:cancel()
    end
    return self:start()
end

function MatchmakingManager:update(dt)
    dt = tonumber(dt) or 0

    if self.request_cooldown_remaining > 0 then
        self.request_cooldown_remaining = math.max(0, self.request_cooldown_remaining - dt)
    end

    if self.notice_elapsed > 0 then
        self.notice_elapsed = math.max(0, self.notice_elapsed - dt)
        if self.notice_elapsed <= 0 then
            self.notice_message = ""
        end
    end

    if self.state.matched_holding == true then
        self.state.matched_hold_elapsed = (tonumber(self.state.matched_hold_elapsed) or 0) + dt
        if self.state.matched_hold_elapsed >= MATCHED_HOLD_SECONDS and self.state.matched_room_id then
            local room_id = self.state.matched_room_id
            self:clearState()
            self.on_enter_room(room_id)
        end
        return
    end

    if self.state.queue_active ~= true then
        return
    end

    self.state.poll_elapsed = (tonumber(self.state.poll_elapsed) or 0) + dt
    if self.state.poll_elapsed < POLL_INTERVAL_SECONDS then
        return
    end

    self.state.poll_elapsed = 0
    local steam_id = self.get_steam_id()
    if not steam_id then
        self:clearState()
        return
    end

    local result = self.service:fetchMatchmakingStatus(steam_id, true)
    if not result or result.ok ~= true then
        return
    end

    self:applyResult(result)
end

function MatchmakingManager:draw()
    self.floater:draw(self.state)

    if self.notice_message ~= "" and self.notice_elapsed > 0 then
        self.toast:draw(self.notice_message, {
            border_color = { 0.76, 0.35, 0.18, 0.95 },
            background_color = { 0.18, 0.12, 0.08, 0.92 },
            text_color = { 1.0, 0.95, 0.88, 1 },
        })
    end
end

function MatchmakingManager:mousemoved(x, y)
    if self.state.floater_dragging == true then
        local frame = self.floater:getFrame(self.state)
        local margin = 18
        local screen_w = love.graphics.getWidth()
        local screen_h = love.graphics.getHeight()
        local max_x = math.max(margin, screen_w - frame.width - margin)
        local max_y = math.max(margin, screen_h - frame.height - margin)
        local next_x = x - (tonumber(self.state.floater_drag_offset_x) or 0)
        local next_y = y - (tonumber(self.state.floater_drag_offset_y) or 0)
        self.state.floater_x = clamp(next_x, margin, max_x)
        self.state.floater_y = clamp(next_y, margin, max_y)
        self.state.hovered_close = false
        return
    end

    self.state.hovered_close = self.floater:getControlAt(x, y, self.state) == "close"
end

function MatchmakingManager:mousepressed(x, y, button)
    if button ~= 1 then
        return false
    end

    if not self.floater:isVisible(self.state) then
        return false
    end

    if self.floater:getControlAt(x, y, self.state) ~= "close" then
        local frame = self.floater:getFrame(self.state)
        if pointInFrame(x, y, frame) then
            self.state.floater_dragging = true
            self.state.floater_drag_offset_x = x - frame.x
            self.state.floater_drag_offset_y = y - frame.y
            return true
        end
        return false
    end

    self:cancel()
    return true
end

function MatchmakingManager:mousereleased(x, y, button)
    if button ~= 1 then
        return false
    end
    if self.state.floater_dragging == true then
        self.state.floater_dragging = false
        return true
    end
    return false
end

function MatchmakingManager:shutdown()
    if self.state.queue_active ~= true then
        return
    end

    local steam_id = self.get_steam_id()
    if not steam_id then
        return
    end

    self.service:cancelMatchmaking(steam_id)
end

return MatchmakingManager
