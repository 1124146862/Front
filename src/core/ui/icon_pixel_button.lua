local IconPixelButton = {}
IconPixelButton.__index = IconPixelButton

function IconPixelButton.new(options)
    local self = setmetatable({}, IconPixelButton)
    self.style = assert(options and options.style, "IconPixelButton requires style")
    return self
end

function IconPixelButton:contains(frame, x, y)
    return x >= frame.x and x <= frame.x + frame.width and y >= frame.y and y <= frame.y + frame.height
end

function IconPixelButton:draw(frame, options)
    options = options or {}
    local hovered = options.hovered == true
    local colors = self.style.colors
    local palette = options.palette or {}
    local radius = options.radius or 12
    local inset = options.inset or 6
    local shadow_offset = options.shadow_offset or 5
    local frame_color = palette.frame or colors.button_secondary_frame
    local face_color = palette.face or colors.button_secondary_face
    local hover_face_color = palette.hover_face or colors.button_secondary_hover_face
    local shadow_color = palette.shadow or colors.button_secondary_shadow
    local highlight_color = palette.highlight or colors.button_secondary_highlight
    local border_color = palette.border or colors.button_secondary_border
    local face = hovered and hover_face_color or face_color

    love.graphics.setColor(shadow_color)
    love.graphics.rectangle("fill", frame.x, frame.y + shadow_offset, frame.width, frame.height, radius, radius)

    love.graphics.setColor(frame_color)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, radius, radius)

    local inner_x = frame.x + inset
    local inner_y = frame.y + inset
    local inner_w = frame.width - inset * 2
    local inner_h = frame.height - inset * 2

    love.graphics.setColor(face)
    love.graphics.rectangle("fill", inner_x, inner_y, inner_w, inner_h, math.max(5, radius - 5), math.max(5, radius - 5))

    love.graphics.setColor(highlight_color)
    love.graphics.rectangle(
        "fill",
        inner_x + 2,
        inner_y + 2,
        inner_w - 4,
        math.max(8, math.floor(inner_h * 0.24)),
        math.max(4, radius - 7),
        math.max(4, radius - 7)
    )

    love.graphics.setLineWidth(2)
    love.graphics.setColor(border_color)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, radius, radius)
    love.graphics.rectangle("line", inner_x + 1, inner_y + 1, inner_w - 2, inner_h - 2, math.max(5, radius - 5), math.max(5, radius - 5))
    love.graphics.setLineWidth(1)

    if options.draw_icon then
        options.draw_icon({
            x = inner_x,
            y = inner_y,
            width = inner_w,
            height = inner_h,
        }, hovered)
    end
end

return IconPixelButton
