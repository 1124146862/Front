local RoomPageTextInput = {}
RoomPageTextInput.__index = RoomPageTextInput

function RoomPageTextInput.new(options)
    local self = setmetatable({}, RoomPageTextInput)

    self.id = assert(options and options.id, "RoomPageTextInput requires id")
    self.label = assert(options and options.label, "RoomPageTextInput requires label")
    self.value = options.value or ""
    self.placeholder = options.placeholder or ""
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 280
    self.height = options.height or 42
    self.focused = options.focused == true

    return self
end

function RoomPageTextInput:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function RoomPageTextInput:draw(fonts, style)
    local colors = style.colors

    love.graphics.setColor(self.focused and colors.button_hover or colors.card_alt)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

    love.graphics.setColor(colors.text_muted)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.print(self.label, self.x, self.y - 20)

    love.graphics.setFont(fonts:get("TextSmall"))
    if self.value ~= "" then
        love.graphics.setColor(colors.text_primary)
        love.graphics.printf(self.value, self.x + 12, self.y + 12, self.width - 24, "left")
    else
        love.graphics.setColor(colors.text_muted)
        love.graphics.printf(self.placeholder, self.x + 12, self.y + 12, self.width - 24, "left")
    end
end

return RoomPageTextInput
