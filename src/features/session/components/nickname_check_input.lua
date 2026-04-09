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
    local border = focused and colors.card_focus or colors.card_outline
    local display_text = value ~= "" and value or placeholder
    local text_color = value ~= "" and colors.text_primary or colors.text_secondary
    local x = self.bounds.x
    local y = self.bounds.y
    local w = self.bounds.w
    local h = self.bounds.h

    love.graphics.setColor(colors.card_shadow[1], colors.card_shadow[2], colors.card_shadow[3], colors.card_shadow[4])
    love.graphics.rectangle("fill", x, y + 3, w, h, self.style.input.radius, self.style.input.radius)

    love.graphics.setColor(colors.card_surface_secondary[1], colors.card_surface_secondary[2], colors.card_surface_secondary[3], colors.card_surface_secondary[4])
    love.graphics.rectangle("fill", x, y, w, h, self.style.input.radius, self.style.input.radius)

    love.graphics.setColor(colors.input_grain[1], colors.input_grain[2], colors.input_grain[3], colors.input_grain[4])
    love.graphics.rectangle("fill", x + 12, y + 12, w - 24, 2, 1, 1)
    love.graphics.rectangle("fill", x + 12, y + h - 14, w - 24, 2, 1, 1)

    love.graphics.setColor(border[1], border[2], border[3], border[4])
    love.graphics.setLineWidth(focused and 2 or 1)
    love.graphics.rectangle("line", x + 1, y + 1, w - 2, h - 2, self.style.input.radius, self.style.input.radius)
    love.graphics.setLineWidth(1)

    local font = fonts:get("TextBig")
    love.graphics.setFont(font)
    local text_x = x + 22
    local text_y = y + math.floor((h - font:getHeight()) / 2) - 1
    love.graphics.setColor(text_color[1], text_color[2], text_color[3], text_color[4])
    local prev_scissor_x, prev_scissor_y, prev_scissor_w, prev_scissor_h = love.graphics.getScissor()
    love.graphics.setScissor(x + 16, y + 8, math.max(0, w - 32), math.max(0, h - 16))
    love.graphics.print(display_text, text_x, text_y)
    -- subtle offset to simulate a slightly bolder weight
    love.graphics.print(display_text, text_x + 1, text_y)
    if prev_scissor_x then
        love.graphics.setScissor(prev_scissor_x, prev_scissor_y, prev_scissor_w, prev_scissor_h)
    else
        love.graphics.setScissor()
    end
end

return NicknameCheckInput
