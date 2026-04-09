local IconCloseButton = {}
IconCloseButton.__index = IconCloseButton

function IconCloseButton.new(options)
    local self = setmetatable({}, IconCloseButton)

    self.fonts = assert(options and options.fonts, "IconCloseButton requires fonts")
    self.style = assert(options and options.style, "IconCloseButton requires style")

    return self
end

function IconCloseButton:contains(frame, x, y)
    return x >= frame.x and x <= frame.x + frame.width and y >= frame.y and y <= frame.y + frame.height
end

function IconCloseButton:draw(frame, hovered)
    local colors = self.style.colors
    local face = hovered and colors.button_secondary_hover_face or colors.button_secondary_face
    local radius = 10

    love.graphics.setColor(colors.button_secondary_shadow)
    love.graphics.rectangle("fill", frame.x, frame.y + 4, frame.width, frame.height, radius, radius)

    love.graphics.setColor(colors.button_secondary_frame)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, radius, radius)

    love.graphics.setColor(face)
    love.graphics.rectangle("fill", frame.x + 4, frame.y + 4, frame.width - 8, frame.height - 8, radius - 3, radius - 3)

    love.graphics.setLineWidth(2)
    love.graphics.setColor(colors.button_secondary_border)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, radius, radius)
    love.graphics.rectangle("line", frame.x + 4, frame.y + 4, frame.width - 8, frame.height - 8, radius - 3, radius - 3)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(colors.button_secondary_text)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf("X", frame.x, frame.y + 8, frame.width, "center")
end

return IconCloseButton
