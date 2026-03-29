local LobbyPageTextInput = {}
LobbyPageTextInput.__index = LobbyPageTextInput

function LobbyPageTextInput.new(options)
    local self = setmetatable({}, LobbyPageTextInput)

    self.id = assert(options and options.id, "LobbyPageTextInput requires id")
    self.label = assert(options and options.label, "LobbyPageTextInput requires label")
    self.value = options.value or ""
    self.placeholder = options.placeholder or ""
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 200
    self.height = options.height or 42
    self.focused = options.focused == true

    return self
end

function LobbyPageTextInput:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function LobbyPageTextInput:draw(fonts, style)
    local colors = style.colors

    love.graphics.setColor(self.focused and colors.button_hover or colors.row)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.setColor(colors.text_muted)
    love.graphics.print(self.label, self.x, self.y - 22)

    love.graphics.setFont(fonts:get("TextSmall"))
    if self.value ~= "" then
        love.graphics.setColor(colors.text_primary)
        love.graphics.printf(self.value, self.x + 12, self.y + 12, self.width - 24, "left")
    else
        love.graphics.setColor(colors.text_muted)
        love.graphics.printf(self.placeholder, self.x + 12, self.y + 12, self.width - 24, "left")
    end
end

return LobbyPageTextInput
