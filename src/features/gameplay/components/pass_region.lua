local PassRegion = {}
PassRegion.__index = PassRegion
local FontConfig = require("src.core.font_config")
local I18n = require("src.core.i18n.i18n")
local FONT_CACHE = {}

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp01(value)
    local v = tonumber(value) or 0
    if v < 0 then
        return 0
    end
    if v > 1 then
        return 1
    end
    return v
end

local function approach(current, target, speed, dt)
    local t = 1 - math.exp(-speed * dt)
    return lerp(current, target, t)
end

function PassRegion.new(options)
    local self = setmetatable({}, PassRegion)
    self.fonts = assert(options and options.fonts, "PassRegion requires fonts")
    self.style = options and options.style or {}
    self.alpha = 0
    self.targetAlpha = 0
    self.rise = 0
    return self
end

local function getCardFaceFontPath()
    return FontConfig.resolveLocaleFontPath(
        FontConfig.card_face_font_path,
        FontConfig.card_face_locale_font_paths,
        I18n:getLocale()
    )
end

local function getPassFont(size)
    local resolved_size = size or 20
    local font_path = getCardFaceFontPath()
    local key = table.concat({ tostring(font_path), tostring(resolved_size) }, "::")
    if not FONT_CACHE[key] then
        local ok, font = pcall(love.graphics.newFont, font_path, resolved_size)
        FONT_CACHE[key] = ok and font or love.graphics.newFont(resolved_size)
    end
    return FONT_CACHE[key]
end

function PassRegion:clear()
    self.targetAlpha = 0
end

function PassRegion:update(dt, visible)
    self.targetAlpha = visible and 1 or 0
    self.alpha = approach(self.alpha, self.targetAlpha, 18, dt)
    self.rise = approach(self.rise, visible and 8 or 0, 16, dt)

    if self.targetAlpha <= 0.001 and self.alpha <= 0.02 then
        self.alpha = 0
        self.rise = 0
    end
end

local function drawTextShadow(font, text, x, y, width, alpha)
    love.graphics.setFont(font)
    love.graphics.setColor(0.04, 0.05, 0.07, 0.72 * (alpha or 1))
    love.graphics.printf(text, x - 1, y, width, "center")
    love.graphics.printf(text, x + 1, y, width, "center")
    love.graphics.printf(text, x, y - 1, width, "center")
    love.graphics.printf(text, x, y + 1, width, "center")
end

local function resolveBadgeStyle(options)
    options = options or {}
    local tone = tostring(options.tone or "default")

    if tone == "blue" then
        return {
            shadow = { 0.05, 0.10, 0.20, 0.34 },
            bg = { 0.12, 0.34, 0.68, 0.94 },
            bg_hover = { 0.18, 0.42, 0.80, 0.98 },
            border = { 0.84, 0.94, 1.00, 0.48 },
            text = { 0.97, 0.99, 1.00, 1.00 },
        }
    end

    return {
        shadow = { 0, 0, 0, 0.35 },
        bg = { 0.08, 0.08, 0.08, 0.92 },
        bg_hover = { 0.16, 0.16, 0.18, 0.96 },
        border = { 1, 1, 1, 0.25 },
        text = { 0.96, 0.96, 0.96, 1 },
    }
end

function PassRegion.drawBadge(fonts, frame, options)
    options = options or {}
    local alpha = tonumber(options.alpha) or 1
    if alpha <= 0.01 then
        return
    end

    local text = tostring(options.label or I18n:t("gameplay.pass"))
    local font_size = tonumber(options.font_size) or 22
    local hovered = options.hovered == true
    local press_strength = clamp01(options.press_strength)
    local pressed = press_strength > 0.001
    local enabled = options.enabled ~= false
    local palette = resolveBadgeStyle(options)
    local font = nil
    if fonts and fonts.get then
        font = fonts:get(options.font_token or "TextBig")
    else
        font = getPassFont(font_size)
    end
    love.graphics.setFont(font)

    local text_w = font:getWidth(text)
    local text_h = font:getHeight()
    local pad_x = tonumber(options.pad_x) or 20
    local pad_y = tonumber(options.pad_y) or 10
    local bw = math.max(frame.width, text_w + pad_x * 2)
    local bh = math.max(frame.height, text_h + pad_y * 2)
    local bx = math.floor(frame.x + (frame.width - bw) * 0.5)
    local by = math.floor(frame.y + (frame.height - bh) * 0.5)

    local bg = hovered and palette.bg_hover or palette.bg
    if pressed then
        local depth = press_strength ^ 1.8
        bg = {
            bg[1] * (1 - 0.24 * depth),
            bg[2] * (1 - 0.24 * depth),
            bg[3] * (1 - 0.24 * depth),
            bg[4],
        }
    end
    local border_alpha = hovered and 0.72 or 1
    local text_alpha = enabled and 1 or 0.52
    local bg_alpha = enabled and 1 or 0.62
    local depth = press_strength ^ 1.8
    local offset_y = math.floor(6 * depth + 0.5)

    love.graphics.setColor(palette.shadow[1], palette.shadow[2], palette.shadow[3], palette.shadow[4] * alpha)
    love.graphics.rectangle("fill", bx + 3, by + 3 + offset_y, bw, bh)

    love.graphics.setColor(bg[1], bg[2], bg[3], bg[4] * alpha * bg_alpha)
    love.graphics.rectangle("fill", bx, by + offset_y, bw, bh)

    if not pressed then
        love.graphics.setColor(1, 1, 1, 0.06 * alpha * bg_alpha)
        love.graphics.rectangle("fill", bx + 2, by + 2, bw - 4, math.max(10, math.floor(bh * 0.2)))
    end

    love.graphics.setColor(palette.border[1], palette.border[2], palette.border[3], palette.border[4] * alpha * border_alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx, by + offset_y, bw, bh)
    love.graphics.setLineWidth(1)

    local text_y = by + offset_y + math.floor((bh - text_h) * 0.5) - 1
    drawTextShadow(font, text, bx, text_y, bw, alpha * text_alpha)
    love.graphics.setColor(palette.text[1], palette.text[2], palette.text[3], palette.text[4] * alpha * text_alpha)
    love.graphics.printf(text, bx, text_y, bw, "center")
end

function PassRegion:draw(frame, options)
    options = options or {}
    local alpha = tonumber(options.alpha_override) or self.alpha
    if alpha <= 0.01 then
        return
    end
    local rise = tonumber(options.rise_override) or self.rise
    local gap = math.max(4, math.floor(frame.height * 0.08))
    local badge_height = math.max(32, math.floor(frame.height * 0.38))
    local anchor = tostring(options.anchor or "below")
    local badge_frame = {
        x = frame.x,
        y = frame.y + frame.height + gap + rise,
        width = frame.width,
        height = badge_height,
    }
    if anchor == "above" then
        badge_frame.y = frame.y - badge_height - gap - rise
    elseif anchor == "right" then
        badge_frame.x = frame.x + frame.width + gap + rise
        badge_frame.y = frame.y + math.floor((frame.height - badge_height) * 0.5)
    end

    PassRegion.drawBadge(self.fonts, badge_frame, {
        label = tostring(options.label or I18n:t("gameplay.pass")),
        alpha = alpha,
        enabled = true,
        hovered = false,
        tone = options.tone or "default",
        font_size = tonumber(options.font_size) or 20,
        font_token = options.font_token or "TextBig",
        pad_x = tonumber(options.pad_x) or 12,
        pad_y = tonumber(options.pad_y) or 6,
    })
end

return PassRegion
