local Chrome = {}
local ButtonText = require("src.core.ui.button_text")

local function setColor(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

function Chrome.drawSoftButton(fonts, style, frame, label, hovered, opts)
    opts = opts or {}
    local colors = style.colors
    local radius = opts.radius or 18
    local enabled = opts.enabled ~= false
    local pressed = opts.pressed == true
    local offset_y = pressed and 2 or 0
    local shadow = { 0.18, 0.12, 0.08, pressed and 0.06 or (hovered and 0.14 or 0.08) }
    local face = hovered and { 1.00, 0.985, 0.955, 0.98 } or { 0.995, 0.98, 0.945, 0.96 }
    local outline = hovered and { 0.88, 0.67, 0.40, 0.46 } or { 0.72, 0.55, 0.34, 0.18 }
    local text_color = colors.text_primary

    if not enabled then
        pressed = false
        offset_y = 0
        shadow = { 0.18, 0.12, 0.08, 0.05 }
        face = { 0.92, 0.89, 0.84, 0.88 }
        outline = { 0.62, 0.46, 0.29, 0.16 }
        text_color = colors.text_muted or colors.text_secondary
    end
    if pressed then
        face = { 0.94, 0.90, 0.84, 0.98 }
        outline = { 0.62, 0.46, 0.29, 0.36 }
    end

    love.graphics.setColor(shadow[1], shadow[2], shadow[3], shadow[4])
    love.graphics.rectangle("fill", frame.x, frame.y + 2 + offset_y, frame.w, frame.h, radius, radius)

    love.graphics.setColor(face[1], face[2], face[3], face[4])
    love.graphics.rectangle("fill", frame.x, frame.y + offset_y, frame.w, frame.h, radius, radius)

    if enabled then
        love.graphics.setColor(1, 1, 1, pressed and 0.08 or (hovered and 0.26 or 0.16))
        love.graphics.rectangle(
            "fill",
            frame.x + 2,
            frame.y + 2 + offset_y,
            frame.w - 4,
            math.max(5, math.floor(frame.h * 0.18)),
            radius - 2,
            radius - 2
        )
    end

    love.graphics.setColor(outline[1], outline[2], outline[3], outline[4])
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", frame.x + 0.5, frame.y + offset_y + 0.5, frame.w - 1, frame.h - 1, radius, radius)
    love.graphics.setLineWidth(1)

    local font = fonts:get(opts.font_token or "Text")
    local text_y = frame.y + offset_y + math.floor((frame.h - font:getHeight()) / 2) - 1
    ButtonText.draw(font, label, frame.x, text_y, frame.w, "center", text_color, {
        bold = opts.bold ~= false,
        bold_offset = opts.bold_offset or 1,
    })
end

function Chrome.drawPagerButton(fonts, style, frame, glyph, hovered)
    local colors = style.colors
    local shadow = { 0.18, 0.12, 0.08, hovered and 0.12 or 0.07 }
    local face = hovered and { 0.998, 0.987, 0.955, 0.98 } or { 0.994, 0.98, 0.946, 0.96 }
    local outline = hovered and { 0.88, 0.67, 0.40, 0.40 } or { 0.72, 0.55, 0.34, 0.14 }
    local radius = 14

    love.graphics.setColor(shadow[1], shadow[2], shadow[3], hovered and 0.12 or 0.08)
    love.graphics.rectangle("fill", frame.x, frame.y + 2, frame.w, frame.h, radius, radius)

    love.graphics.setColor(face[1], face[2], face[3], face[4])
    love.graphics.rectangle("fill", frame.x, frame.y, frame.w, frame.h, radius, radius)

    love.graphics.setColor(1, 1, 1, hovered and 0.26 or 0.16)
    love.graphics.rectangle(
        "fill",
        frame.x + 2,
        frame.y + 2,
        frame.w - 4,
        math.max(6, math.floor(frame.h * 0.22)),
        radius - 2,
        radius - 2
    )

    love.graphics.setColor(outline[1], outline[2], outline[3], outline[4])
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", frame.x + 0.5, frame.y + 0.5, frame.w - 1, frame.h - 1, radius, radius)
    love.graphics.setLineWidth(1)

    local font = fonts:get("Text")
    ButtonText.draw(font, glyph, frame.x, frame.y + math.floor((frame.h - font:getHeight()) / 2) - 1, frame.w, "center", colors.text_primary, {
        bold = false,
    })
end

function Chrome.drawCloseButton(fonts, style, frame, hovered)
    local colors = style.colors
    local shadow = { 0.18, 0.12, 0.08, hovered and 0.14 or 0.08 }
    local face = hovered and { 1.00, 0.985, 0.955, 0.98 } or { 0.995, 0.98, 0.945, 0.96 }
    local outline = hovered and { 0.88, 0.67, 0.40, 0.46 } or { 0.72, 0.55, 0.34, 0.18 }

    love.graphics.setColor(shadow[1], shadow[2], shadow[3], shadow[4])
    love.graphics.rectangle("fill", frame.x, frame.y + 2, frame.w, frame.h, 18, 18)
    love.graphics.setColor(face[1], face[2], face[3], face[4])
    love.graphics.rectangle("fill", frame.x, frame.y, frame.w, frame.h, 18, 18)
    love.graphics.setColor(1, 1, 1, hovered and 0.26 or 0.16)
    love.graphics.rectangle("fill", frame.x + 2, frame.y + 2, frame.w - 4, math.max(5, math.floor(frame.h * 0.18)), 16, 16)
    love.graphics.setColor(outline[1], outline[2], outline[3], outline[4])
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", frame.x + 0.5, frame.y + 0.5, frame.w - 1, frame.h - 1, 18, 18)
    love.graphics.setLineWidth(1)

    local font = fonts:get("Text")
    ButtonText.draw(font, "X", frame.x, frame.y + math.floor((frame.h - font:getHeight()) / 2) - 1, frame.w, "center", colors.text_primary, {
        bold = false,
    })
end

function Chrome.drawSoftPanel(frame, radius, tone)
    radius = radius or 18
    tone = tone or "default"

    local shadow_alpha = tone == "section" and 0.14 or 0.10
    local fill_alpha = tone == "section" and 0.92 or 0.96

    love.graphics.setColor(0.24, 0.16, 0.08, shadow_alpha)
    love.graphics.rectangle("fill", frame.x, frame.y + 2, frame.w, frame.h, radius, radius)
    love.graphics.setColor(1.0, 0.985, 0.94, fill_alpha)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.w, frame.h, radius, radius)
end

return Chrome
