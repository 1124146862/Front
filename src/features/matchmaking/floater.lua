local I18n = require("src.core.i18n.i18n")

local MatchmakingFloater = {}
MatchmakingFloater.__index = MatchmakingFloater

local MATCHED_TITLE_FALLBACK = (utf8 and utf8.char(0x5339, 0x914D, 0x6210, 0x529F)) or "Matched"
local MATCHED_SUBTITLE_FALLBACK = (utf8 and utf8.char(0x6B63, 0x5728, 0x8FDB, 0x5165, 0x623F, 0x95F4)) or "Entering room"

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.width
        and y >= bounds.y
        and y <= bounds.y + bounds.height
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

local function formatElapsed(seconds)
    local total = math.max(0, math.floor((tonumber(seconds) or 0) + 0.5))
    local mins = math.floor(total / 60)
    local secs = total % 60
    return string.format("%02d:%02d", mins, secs)
end

local function tOr(key, fallback, params)
    local value = I18n:t(key, params)
    if value == key then
        return fallback
    end
    return value
end

function MatchmakingFloater.new(options)
    local self = setmetatable({}, MatchmakingFloater)
    self.fonts = assert(options and options.fonts, "MatchmakingFloater requires fonts")
    self.style = assert(options and options.style, "MatchmakingFloater requires style")
    return self
end

function MatchmakingFloater:isVisible(state)
    return state and (state.queue_active == true or state.matched_holding == true)
end

function MatchmakingFloater:getFrame(state)
    local is_matched = state and state.matched_holding == true
    local width = is_matched and 300 or 228
    local height = is_matched and 72 or 66
    local margin = 18
    local screen_w = love.graphics.getWidth()
    local screen_h = love.graphics.getHeight()
    local default_x = margin
    local default_y = math.floor((screen_h - height) * 0.5)
    local x = default_x
    local y = default_y

    if state and state.floater_x ~= nil and state.floater_y ~= nil then
        x = tonumber(state.floater_x) or default_x
        y = tonumber(state.floater_y) or default_y
    end

    local max_x = math.max(margin, screen_w - width - margin)
    local max_y = math.max(margin, screen_h - height - margin)
    x = clamp(x, margin, max_x)
    y = clamp(y, margin, max_y)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
    }
end

function MatchmakingFloater:getCloseBounds(state)
    local frame = self:getFrame(state)
    return {
        x = frame.x + frame.width - 26,
        y = frame.y + 8,
        width = 16,
        height = 16,
    }
end

function MatchmakingFloater:getControlAt(x, y, state)
    if not self:isVisible(state) or not state.can_cancel then
        return nil
    end
    if contains(self:getCloseBounds(state), x, y) then
        return "close"
    end
    return nil
end

function MatchmakingFloater:draw(state)
    if not self:isVisible(state) then
        return
    end

    local frame = self:getFrame(state)
    local colors = self.style.colors
    local is_matched = state.matched_holding == true
    local hovered_close = state.hovered_close == true

    local face = is_matched and { 0.99, 0.92, 0.72, 0.97 } or { 0.98, 0.91, 0.74, 0.95 }
    local border = is_matched and { 0.58, 0.31, 0.14, 0.95 } or { 0.47, 0.28, 0.14, 0.92 }
    local shadow = is_matched and { 0.22, 0.12, 0.05, 0.32 } or { 0.18, 0.1, 0.04, 0.26 }
    local accent = is_matched and { 0.83, 0.46, 0.18, 0.92 } or { 0.74, 0.48, 0.24, 0.86 }

    love.graphics.setColor(shadow)
    love.graphics.rectangle("fill", frame.x, frame.y + 5, frame.width, frame.height, 18, 18)

    love.graphics.setColor(face)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 18, 18)

    love.graphics.setColor(1.0, 0.97, 0.88, is_matched and 0.55 or 0.42)
    love.graphics.rectangle("fill", frame.x + 3, frame.y + 3, frame.width - 6, math.max(12, math.floor(frame.height * 0.26)), 15, 15)

    love.graphics.setColor(border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 18, 18)
    love.graphics.setLineWidth(1)

    if is_matched then
        love.graphics.setColor(accent)
        love.graphics.circle("fill", frame.x + 26, frame.y + math.floor(frame.height * 0.5), 7)

        love.graphics.setColor(colors.text_primary)
        love.graphics.setFont(self.fonts:get("TextSmall"))
        love.graphics.printf(
            tOr("main_menu.matchmaking_success_title", MATCHED_TITLE_FALLBACK),
            frame.x + 44,
            frame.y + 14,
            frame.width - 60,
            "left"
        )

        love.graphics.setColor(colors.text_secondary)
        love.graphics.setFont(self.fonts:get("Label"))
        love.graphics.printf(
            tOr("main_menu.matchmaking_success_subtitle", MATCHED_SUBTITLE_FALLBACK),
            frame.x + 44,
            frame.y + 38,
            frame.width - 60,
            "left"
        )
        return
    end

    local count_text = string.format(
        "%d/%d",
        tonumber(state.player_count) or 0,
        tonumber(state.required_player_count) or 4
    )
    local phase = tostring(state.phase or "searching")
    local phase_text = tOr("main_menu.matchmaking_phase_searching", "Waiting")
    local timer_text = formatElapsed(state.elapsed_seconds)

    if phase == "starting" then
        phase_text = tOr("main_menu.matchmaking_phase_starting", "Starting")
        timer_text = string.format("%.1fs", math.max(0, tonumber(state.countdown_seconds) or 0))
    elseif phase == "matched" then
        phase_text = tOr("main_menu.matchmaking_phase_matched", "Entering")
    end

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(count_text, frame.x + 14, frame.y + 12, 88, "center")

    love.graphics.setColor(accent)
    love.graphics.rectangle("fill", frame.x + 94, frame.y + 14, 2, frame.height - 28, 1, 1)

    local text_x = frame.x + 108
    local text_width = frame.width - 142

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Label"))
    love.graphics.printf(phase_text, text_x, frame.y + 17, text_width, "left")

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Label"))
    love.graphics.printf(timer_text, text_x, frame.y + 39, text_width, "left")

    if state.can_cancel then
        local close_bounds = self:getCloseBounds(state)
        local close_face = hovered_close and { 0.93, 0.75, 0.60, 0.98 } or { 0.89, 0.79, 0.66, 0.94 }
        love.graphics.setColor(close_face)
        love.graphics.rectangle("fill", close_bounds.x, close_bounds.y, close_bounds.width, close_bounds.height, 5, 5)
        love.graphics.setColor(border)
        love.graphics.rectangle("line", close_bounds.x + 0.5, close_bounds.y + 0.5, close_bounds.width - 1, close_bounds.height - 1, 5, 5)
        love.graphics.setColor(colors.text_secondary)
        love.graphics.setFont(self.fonts:get("Caption"))
        love.graphics.printf("x", close_bounds.x, close_bounds.y - 1, close_bounds.width, "center")
    end
end

return MatchmakingFloater
