local WoodButton = {}
WoodButton.__index = WoodButton
local ButtonText = require("src.core.ui.button_text")

local function resolvePalette(style, variant, enabled, hovered)
    local colors = style.colors
    if not enabled then
        return {
            frame = colors.button_disabled_frame,
            face = colors.button_disabled_face,
            shadow = colors.button_disabled_shadow,
            highlight = colors.button_disabled_highlight,
            border = colors.button_disabled_border,
            grain = colors.button_disabled_grain,
            text = colors.button_disabled_text,
        }
    end

    if variant == "secondary" then
        return {
            frame = colors.button_secondary_frame,
            face = hovered and colors.button_secondary_hover_face or colors.button_secondary_face,
            shadow = colors.button_secondary_shadow,
            highlight = colors.button_secondary_highlight,
            border = colors.button_secondary_border,
            grain = colors.button_secondary_grain,
            text = colors.button_secondary_text,
        }
    end

    return {
        frame = colors.button_primary_frame,
        face = hovered and colors.button_primary_hover_face or colors.button_primary_face,
        shadow = colors.button_primary_shadow,
        highlight = colors.button_primary_highlight,
        border = colors.button_primary_border,
        grain = colors.button_primary_grain,
        text = colors.button_primary_text,
    }
end

	function WoodButton.draw(fonts, style, options)
	    local hovered = options.hovered == true
	    local enabled = options.enabled ~= false
	    local palette = options.palette_override or resolvePalette(style, options.variant or "primary", enabled, hovered)
	    local layout = style.layout or {}
	    local radius = options.radius or layout.button_radius or 10
    local shadow_offset = options.shadow_offset or layout.button_shadow_offset or 6
    local inset = options.inner_inset or layout.button_inner_inset or 6
    local font_token = options.font_token or "Button"
    local font = (options.locale and fonts.getForLocale)
        and fonts:getForLocale(font_token, options.locale)
        or fonts:get(font_token)
    local text_y = math.floor(options.y + (options.height - font:getHeight()) / 2) - 1
    local light_chrome = options.light_chrome == true
    local face_x = options.x + inset
    local face_y = options.y + inset
    local face_width = options.width - inset * 2
    local face_height = options.height - inset * 2

    love.graphics.setColor(palette.shadow)
    love.graphics.rectangle("fill", options.x, options.y + shadow_offset, options.width, options.height, radius, radius)

    love.graphics.setColor(palette.frame)
    love.graphics.rectangle("fill", options.x, options.y, options.width, options.height, radius, radius)

    love.graphics.setColor(palette.face)
    love.graphics.rectangle("fill", face_x, face_y, face_width, face_height, math.max(4, radius - 4), math.max(4, radius - 4))

    if not light_chrome then
        love.graphics.setColor(palette.highlight)
        love.graphics.rectangle(
            "fill",
            face_x + 2,
            face_y + 2,
            face_width - 4,
            math.max(10, math.floor(face_height * 0.2)),
            math.max(4, radius - 6),
            math.max(4, radius - 6)
        )

        love.graphics.setColor(palette.grain)
        for index = 0, 2 do
            local grain_y = math.floor(face_y + 15 + index * math.max(10, face_height * 0.23))
            love.graphics.rectangle("fill", face_x + 8, grain_y, face_width - 16, 2, 1, 1)
        end
    end

    love.graphics.setLineWidth(light_chrome and 1 or 2)
    love.graphics.setColor(palette.border)
    love.graphics.rectangle("line", options.x + 1, options.y + 1, options.width - 2, options.height - 2, radius, radius)
    if not light_chrome then
        love.graphics.rectangle("line", face_x + 1, face_y + 1, face_width - 2, face_height - 2, math.max(4, radius - 4), math.max(4, radius - 4))
    end
    love.graphics.setLineWidth(1)

    ButtonText.draw(font, options.label, options.x, text_y, options.width, "center", palette.text, {
        bold = options.bold ~= false,
        bold_offset = options.bold_offset or 1,
    })
end

return WoodButton
