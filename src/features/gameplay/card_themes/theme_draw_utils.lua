local FontConfig = require("src.core.font_config")
local I18n = require("src.core.i18n.i18n")

local Utils = {
    font_cache = {},
}

local function getCardFaceFontPath()
    return FontConfig.resolveLocaleFontPath(
        FontConfig.card_face_font_path,
        FontConfig.card_face_locale_font_paths,
        I18n:getLocale()
    )
end

local function getFont(size)
    local font_path = getCardFaceFontPath()
    local key = table.concat({ tostring(font_path), tostring(size) }, "::")
    if not Utils.font_cache[key] then
        local ok, font = pcall(love.graphics.newFont, font_path, size)
        Utils.font_cache[key] = ok and font or love.graphics.newFont(size)
    end
    return Utils.font_cache[key]
end

local function measureVerticalLabel(font, text, gap)
    local max_width = 0
    for index = 1, #text do
        local char_width = font:getWidth(text:sub(index, index))
        if char_width > max_width then
            max_width = char_width
        end
    end

    local total_height = 0
    if #text > 0 then
        total_height = font:getHeight() * #text + (math.max(0, #text - 1) * gap)
    end

    return max_width, total_height
end

function Utils.drawCenteredText(text, x, y, width, height, size, color)
    local prev = love.graphics.getFont()
    local font = getFont(size)
    love.graphics.setFont(font)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    local text_y = y + math.floor((height - font:getHeight()) * 0.5)
    love.graphics.printf(text, x, text_y, width, "center")
    love.graphics.setFont(prev)
end

function Utils.drawCircle(cx, cy, radius, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.circle("fill", cx, cy, radius)
end

function Utils.drawRect(x, y, width, height, color, rx, ry)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.rectangle("fill", x, y, width, height, rx or 0, ry or rx or 0)
end

function Utils.drawDiamond(cx, cy, size, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.polygon("fill",
        cx, cy - size,
        cx + size, cy,
        cx, cy + size,
        cx - size, cy
    )
end

function Utils.drawCrown(cx, cy, width, height, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    local half = width * 0.5
    love.graphics.polygon("fill",
        cx - half, cy + height * 0.5,
        cx - half * 0.65, cy - height * 0.15,
        cx - half * 0.2, cy + height * 0.08,
        cx, cy - height * 0.4,
        cx + half * 0.2, cy + height * 0.08,
        cx + half * 0.65, cy - height * 0.15,
        cx + half, cy + height * 0.5
    )
    love.graphics.rectangle("fill", cx - half, cy + height * 0.35, width, height * 0.18)
end

function Utils.drawVerticalLabel(text, x, y, size, gap, color)
    local prev = love.graphics.getFont()
    local font = getFont(size)
    love.graphics.setFont(font)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    local cursor_y = y
    for index = 1, #text do
        love.graphics.print(text:sub(index, index), x, cursor_y)
        cursor_y = cursor_y + font:getHeight() + gap
    end
    love.graphics.setFont(prev)
end

function Utils.drawFittedVerticalLabel(text, x, y, width, height, preferred_size, gap, color, options)
    local prev = love.graphics.getFont()
    local size = math.max(1, math.floor(preferred_size or 1))
    local font = getFont(size)
    local max_width, total_height = measureVerticalLabel(font, text, gap)

    while size > 1 and (max_width > width or total_height > height) do
        size = size - 1
        font = getFont(size)
        max_width, total_height = measureVerticalLabel(font, text, gap)
    end

    local extra_x = math.floor(((options or {}).x_offset) or 0)
    local extra_y = math.floor(((options or {}).y_offset) or 0)
    local start_y = y + math.floor((height - total_height) * 0.5) + extra_y

    love.graphics.setFont(font)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)

    local cursor_y = start_y
    for index = 1, #text do
        local char = text:sub(index, index)
        local char_width = font:getWidth(char)
        local char_x = x + math.floor((width - char_width) * 0.5) + extra_x
        love.graphics.print(char, char_x, cursor_y)
        cursor_y = cursor_y + font:getHeight() + gap
    end

    love.graphics.setFont(prev)
end

return Utils
