local Toast = {}
Toast.__index = Toast

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function easeOutCubic(value)
    local inverse = 1 - clamp(value, 0, 1)
    return 1 - inverse * inverse * inverse
end

local function withAlpha(color, alpha)
    return {
        color[1] or 1,
        color[2] or 1,
        color[3] or 1,
        (color[4] == nil and 1 or color[4]) * alpha,
    }
end

function Toast.new(options)
    local self = setmetatable({}, Toast)

    self.fonts = assert(options and options.fonts, "Toast requires fonts")
    self.colors = assert(options and options.colors, "Toast requires colors")

    return self
end

function Toast:draw(message, options)
    if not message or message == "" then
        return
    end

    options = options or {}

    local font = self.fonts:get(options.font or "TextSmall")
    local horizontal_padding = options.horizontal_padding or 24
    local vertical_padding = options.vertical_padding or 18
    local min_width = options.min_width or 220
    local max_width = options.max_width or 420
    local width = options.width or 420
    if options.auto_width == true then
        width = clamp(font:getWidth(tostring(message)) + horizontal_padding * 2, min_width, max_width)
    end

    local height = options.height or 56
    local content_width = math.max(60, width - horizontal_padding * 2)
    local _, wrapped_lines = font:getWrap(tostring(message), content_width)
    local line_count = math.max(1, #wrapped_lines)
    if options.auto_height == true then
        height = math.max(height, line_count * font:getHeight() + vertical_padding * 2)
    end

    local x = options.x or math.floor((love.graphics.getWidth() - width) / 2)
    local base_y = options.y or (love.graphics.getHeight() - height - 56)
    local radius = options.radius or 18

    local enter_progress = easeOutCubic(options.enter_progress or 1)
    local drop_distance = options.enter_drop or 42
    local y = base_y - (1 - enter_progress) * drop_distance
    local alpha = clamp((options.alpha or 1) * (0.22 + 0.78 * enter_progress), 0, 1)

    if options.variant == "wood_notice" then
        local shadow = options.shadow_color or { 0.18, 0.09, 0.02, 0.28 }
        local frame = options.frame_color or { 0.35, 0.19, 0.07, 0.98 }
        local face = options.background_color or { 0.73, 0.52, 0.29, 0.97 }
        local inner = options.inner_color or { 0.83, 0.62, 0.36, 0.97 }
        local grain = options.grain_color or { 0.43, 0.24, 0.1, 0.18 }
        local highlight = options.highlight_color or { 0.96, 0.84, 0.62, 0.2 }
        local border = options.border_color or { 0.27, 0.13, 0.04, 1 }
        local text_color = options.text_color or { 0.17, 0.08, 0.02, 1 }
        local text_shadow = options.text_shadow_color or { 0.98, 0.9, 0.76, 0.22 }
        local inset = options.inner_inset or 7
        local grain_count = options.grain_count or 4
        local shadow_offset = options.shadow_offset or 6

        love.graphics.setColor(withAlpha(shadow, alpha))
        love.graphics.rectangle("fill", x, y + shadow_offset, width, height, radius, radius)

        love.graphics.setColor(withAlpha(frame, alpha))
        love.graphics.rectangle("fill", x, y, width, height, radius, radius)

        love.graphics.setColor(withAlpha(inner, alpha))
        love.graphics.rectangle(
            "fill",
            x + inset,
            y + inset,
            width - inset * 2,
            height - inset * 2,
            math.max(6, radius - 5),
            math.max(6, radius - 5)
        )

        love.graphics.setColor(withAlpha(face, alpha * 0.92))
        love.graphics.rectangle(
            "fill",
            x + inset + 2,
            y + inset + 2,
            width - inset * 2 - 4,
            height - inset * 2 - 4,
            math.max(5, radius - 7),
            math.max(5, radius - 7)
        )

        love.graphics.setColor(withAlpha(highlight, alpha))
        love.graphics.rectangle(
            "fill",
            x + inset + 10,
            y + inset + 6,
            width - inset * 2 - 20,
            math.max(8, math.floor((height - inset * 2) * 0.18)),
            math.max(4, radius - 8),
            math.max(4, radius - 8)
        )

        love.graphics.setColor(withAlpha(grain, alpha))
        for index = 0, grain_count - 1 do
            local ratio = (index + 1) / (grain_count + 1)
            local grain_y = math.floor(y + inset + 8 + ratio * (height - inset * 2 - 16))
            local grain_x = x + inset + 14 + (index % 2) * 10
            local grain_width = width - inset * 2 - 28 - (index % 2) * 18
            love.graphics.rectangle("fill", grain_x, grain_y, grain_width, 2, 1, 1)
        end

        love.graphics.setLineWidth(2)
        love.graphics.setColor(withAlpha(border, alpha))
        love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, radius, radius)
        love.graphics.rectangle(
            "line",
            x + inset + 1,
            y + inset + 1,
            width - inset * 2 - 2,
            height - inset * 2 - 2,
            math.max(6, radius - 5),
            math.max(6, radius - 5)
        )
        love.graphics.setLineWidth(1)

        local text_y = math.floor(y + (height - line_count * font:getHeight()) / 2) - 1
        love.graphics.setFont(font)
        love.graphics.setColor(withAlpha(text_shadow, alpha))
        love.graphics.printf(message, x + horizontal_padding, text_y + 1, content_width, "center")
        love.graphics.setColor(withAlpha(text_color, alpha))
        love.graphics.printf(message, x + horizontal_padding, text_y, content_width, "center")
        return
    end

    local background = options.background_color or { 0.08, 0.1, 0.13, 0.9 }
    local border = options.border_color or self.colors.error
    local text_color = options.text_color or self.colors.text_primary

    love.graphics.setColor(withAlpha(background, alpha))
    love.graphics.rectangle("fill", x, y, width, height, radius, radius)

    love.graphics.setColor(withAlpha(border, alpha))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, radius, radius)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(withAlpha(text_color, alpha))
    love.graphics.setFont(font)
    local text_y = math.floor(y + (height - line_count * font:getHeight()) / 2)
    love.graphics.printf(message, x + horizontal_padding, text_y, content_width, "center")
end

return Toast
