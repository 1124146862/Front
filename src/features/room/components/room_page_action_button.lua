local RoomPageActionButton = {}
RoomPageActionButton.__index = RoomPageActionButton

function RoomPageActionButton.new(options)
    local self = setmetatable({}, RoomPageActionButton)

    self.id = assert(options and options.id, "RoomPageActionButton requires id")
    self.label = assert(options and options.label, "RoomPageActionButton requires label")
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 140
    self.height = options.height or 48
    self.hovered = options.hovered == true
    self.enabled = options.enabled ~= false

    return self
end

function RoomPageActionButton:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function RoomPageActionButton:draw(fonts, style)
    local colors = style.colors
    local background = colors.button

    if not self.enabled then
        background = colors.button_disabled
    elseif self.hovered then
        background = colors.button_hover
    end

    love.graphics.setColor(background)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(fonts:get("TextSmall"))
    love.graphics.printf(self.label, self.x, self.y + 13, self.width, "center")
end

return RoomPageActionButton
