local WoodButton = require("src.core.ui.wood_button")

local NicknameCheckButton = {}
NicknameCheckButton.__index = NicknameCheckButton

function NicknameCheckButton.new(style)
    local self = setmetatable({}, NicknameCheckButton)

    self.style = style
    self.bounds = {
        x = 0,
        y = 0,
        w = 0,
        h = 0,
    }

    return self
end

function NicknameCheckButton:setBounds(x, y, width, height)
    self.bounds.x = x
    self.bounds.y = y
    self.bounds.w = width
    self.bounds.h = height
end

function NicknameCheckButton:contains(x, y)
    return x >= self.bounds.x
        and x <= self.bounds.x + self.bounds.w
        and y >= self.bounds.y
        and y <= self.bounds.y + self.bounds.h
end

function NicknameCheckButton:draw(fonts, label, hovered, disabled)
    WoodButton.draw(fonts, self.style, {
        label = label,
        x = self.bounds.x,
        y = self.bounds.y,
        width = self.bounds.w,
        height = self.bounds.h,
        hovered = hovered,
        enabled = not disabled,
        variant = "primary",
        font_token = "Button",
        radius = self.style.button.radius,
    })
end

return NicknameCheckButton
