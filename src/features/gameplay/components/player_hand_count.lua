local PlayerHandCount = {}
PlayerHandCount.__index = PlayerHandCount
local FontConfig = require("src.core.font_config")
local I18n = require("src.core.i18n.i18n")
local CardBackStyle = require("src.features.gameplay.components.card_back_style")
local GameplayConfig = require("src.features.gameplay.gameplay_config")

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function lerp(from_value, to_value, t)
    return from_value + (to_value - from_value) * t
end

local function easeOutCubic(t)
    local one_minus_t = 1 - t
    return 1 - one_minus_t * one_minus_t * one_minus_t
end


function PlayerHandCount.new(options)
    local self = setmetatable({}, PlayerHandCount)

    self.fonts = assert(options and options.fonts, "PlayerHandCount requires fonts")
    self.style = assert(options and options.style, "PlayerHandCount requires style")
    self.count_font_cache = {}

    return self
end

function PlayerHandCount:_getCountFont(size)
    local rounded = math.max(16, math.floor(size + 0.5))
    local font_path = FontConfig.resolveLocaleFontPath(
        FontConfig.card_face_font_path,
        FontConfig.card_face_locale_font_paths,
        I18n:getLocale()
    )
    local key = table.concat({ tostring(font_path), tostring(rounded) }, "::")
    if not self.count_font_cache[key] then
        local ok, font = pcall(love.graphics.newFont, font_path, rounded)
        self.count_font_cache[key] = ok and font or love.graphics.newFont(rounded)
    end
    return self.count_font_cache[key]
end

function PlayerHandCount:draw(player, frame, options)
    options = options or {}
    local count = tonumber(player.hand_count) or 0
    local threshold = tonumber(GameplayConfig.low_hand_count_alert_threshold) or 10
    if count > threshold then
        return
    end
    local base_height = math.max(56, tonumber(frame.height) or 0)
    local height = math.max(28, math.floor(base_height * 0.6))
    local width = math.max(42, math.floor(height * 0.74))
    local gap = math.max(12, math.floor(height * 0.18))
    local x = frame.x + math.floor((frame.width - width) / 2)
    local y = frame.y + frame.height + 8

    if options.anchor == "left" then
        x = frame.x - width - gap
        y = frame.y + math.floor((frame.height - height) * 0.5)
    elseif options.anchor == "right" then
        x = frame.x + frame.width + gap
        y = frame.y + math.floor((frame.height - height) * 0.5)
    end

    local center_x = x + width * 0.5
    local center_y = y + height * 0.5
    local scale = 1
    local shake_x = 0
    local shake_y = 0
    local rotation = 0
    local alert = options.alert
    if type(alert) == "table" then
        local duration = math.max(0.001, tonumber(alert.duration) or 0.82)
        local remaining = clamp(tonumber(alert.remaining) or 0, 0, duration)
        local progress = clamp(1 - (remaining / duration), 0, 1)
        local shrink_t = clamp(progress / 0.42, 0, 1)
        scale = lerp(3.0, 1.0, easeOutCubic(shrink_t))
        local shake_phase = progress * math.pi * 14
        local shake_decay = 1 - clamp(progress / 0.72, 0, 1)
        local amplitude = math.max(width, height) * 0.18 * shake_decay
        shake_x = math.cos(shake_phase) * amplitude
        shake_y = math.sin(shake_phase * 0.8) * amplitude * 0.28
        rotation = math.sin(shake_phase * 0.65) * 0.10 * shake_decay
    end

    love.graphics.push()
    love.graphics.translate(math.floor(center_x + shake_x), math.floor(center_y + shake_y))
    if rotation ~= 0 then
        love.graphics.rotate(rotation)
    end
    if scale ~= 1 then
        love.graphics.scale(scale, scale)
    end

    local draw_x = -width * 0.5
    local draw_y = -height * 0.5
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.rectangle("fill", draw_x + 3, draw_y + 4, width, height, 10, 10)
    CardBackStyle.draw(draw_x, draw_y, width, height, options.back_id or "classic_grid")

    local count_text = tostring(count)
    local font = self:_getCountFont(height * 0.6)
    local text_w = font:getWidth(count_text)
    local text_h = font:getHeight()
    local tx = draw_x + math.floor((width - text_w) * 0.5)
    local ty = draw_y + math.floor((height - text_h) * 0.5) + math.floor(height * 0.02)

    love.graphics.setFont(font)
    love.graphics.setColor(0.05, 0.07, 0.10, 0.92)
    love.graphics.print(count_text, tx + 2, ty + 2)
    love.graphics.setColor(0.98, 0.99, 1.0, 1)
    love.graphics.print(count_text, tx, ty)
    love.graphics.pop()
end

return PlayerHandCount
