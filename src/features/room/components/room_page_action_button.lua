local RoomPageActionButton = {}
RoomPageActionButton.__index = RoomPageActionButton
local WoodButton = require("src.core.ui.wood_button")

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
    self.variant = options.variant or "secondary"
    self.font_token = options.font_token or "Text"

    return self
end

function RoomPageActionButton:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function RoomPageActionButton:draw(fonts, style)
    WoodButton.draw(fonts, style, {
        label = self.label,
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        hovered = self.hovered,
        enabled = self.enabled,
        variant = self.variant,
        font_token = self.font_token,
        radius = 12,
        shadow_offset = 4,
        inner_inset = 5,
        light_chrome = true,
    })
end

return RoomPageActionButton
