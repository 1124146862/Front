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
    local colors = self.style.colors
    local fill = colors.button_fill
    local border = colors.button_border

    if disabled then
        fill = colors.disabled
        border = colors.disabled
    elseif hovered then
        fill = colors.button_hover
        border = colors.button_hover_border
    end

    love.graphics.setColor(fill[1], fill[2], fill[3], fill[4])
    love.graphics.rectangle(
        "fill",
        self.bounds.x,
        self.bounds.y,
        self.bounds.w,
        self.bounds.h,
        self.style.button.radius,
        self.style.button.radius
    )

    love.graphics.setColor(border[1], border[2], border[3], border[4])
    love.graphics.rectangle(
        "line",
        self.bounds.x,
        self.bounds.y,
        self.bounds.w,
        self.bounds.h,
        self.style.button.radius,
        self.style.button.radius
    )

    love.graphics.setFont(fonts:get("Button"))
    love.graphics.setColor(colors.text_primary[1], colors.text_primary[2], colors.text_primary[3], colors.text_primary[4])
    love.graphics.printf(label, self.bounds.x, self.bounds.y + 20, self.bounds.w, "center")
end

return NicknameCheckButton
