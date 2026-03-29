local NicknameCheckInput = {}
NicknameCheckInput.__index = NicknameCheckInput

function NicknameCheckInput.new(style)
    local self = setmetatable({}, NicknameCheckInput)

    self.style = style
    self.bounds = {
        x = 0,
        y = 0,
        w = 0,
        h = 0,
    }

    return self
end

function NicknameCheckInput:setBounds(x, y, width, height)
    self.bounds.x = x
    self.bounds.y = y
    self.bounds.w = width
    self.bounds.h = height
end

function NicknameCheckInput:contains(x, y)
    return x >= self.bounds.x
        and x <= self.bounds.x + self.bounds.w
        and y >= self.bounds.y
        and y <= self.bounds.y + self.bounds.h
end

function NicknameCheckInput:draw(fonts, value, placeholder, focused)
    local colors = self.style.colors
    local border = focused and colors.input_focus or colors.input_border
    local display_text = value ~= "" and value or placeholder
    local text_color = value ~= "" and colors.text_primary or colors.text_secondary

    love.graphics.setColor(colors.input_fill[1], colors.input_fill[2], colors.input_fill[3], colors.input_fill[4])
    love.graphics.rectangle(
        "fill",
        self.bounds.x,
        self.bounds.y,
        self.bounds.w,
        self.bounds.h,
        self.style.input.radius,
        self.style.input.radius
    )

    love.graphics.setColor(border[1], border[2], border[3], border[4])
    love.graphics.rectangle(
        "line",
        self.bounds.x,
        self.bounds.y,
        self.bounds.w,
        self.bounds.h,
        self.style.input.radius,
        self.style.input.radius
    )

    love.graphics.setFont(fonts:get("Text"))
    love.graphics.setColor(text_color[1], text_color[2], text_color[3], text_color[4])
    love.graphics.print(display_text, self.bounds.x + 20, self.bounds.y + 18)
end

return NicknameCheckInput
