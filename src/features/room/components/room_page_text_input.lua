local RoomPageTextInput = {}
RoomPageTextInput.__index = RoomPageTextInput

local function fitFont(fonts, text, width, candidates)
    local safe_text = tostring(text or "")
    for _, token in ipairs(candidates) do
        local font = fonts:get(token)
        if font:getWidth(safe_text) <= width then
            return font
        end
    end
    return fonts:get(candidates[#candidates])
end

function RoomPageTextInput.new(options)
    local self = setmetatable({}, RoomPageTextInput)

    self.id = assert(options and options.id, "RoomPageTextInput requires id")
    self.label = assert(options and options.label, "RoomPageTextInput requires label")
    self.value = options.value or ""
    self.display_value = options.display_value
    self.placeholder = options.placeholder or ""
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 280
    self.height = options.height or 42
    self.focused = options.focused == true
    self.editable = options.editable ~= false
    self.selector = options.selector == true
    self.label_font_token = options.label_font_token or "Caption"
    self.label_offset = options.label_offset or 18

    return self
end

function RoomPageTextInput:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function RoomPageTextInput:draw(fonts, style)
    local colors = style.colors

    local background = colors.card
    if not self.editable then
        background = colors.button_disabled_face
    elseif self.focused then
        background = colors.button_primary_face
    end

    love.graphics.setColor(self.focused and colors.button_primary_face or colors.card)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 12, 12)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(self.focused and colors.button_primary_border or colors.card_border)
    love.graphics.rectangle("line", self.x + 0.5, self.y + 0.5, self.width - 1, self.height - 1, 12, 12)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(background)
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width - 4, self.height - 4, 10, 10)

    local label_font = fonts:get(self.label_font_token)
    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(label_font)
    love.graphics.print(self.label, self.x + 2, self.y - self.label_offset)

    local resolved_display_value = self.display_value
    if resolved_display_value == nil or resolved_display_value == "" then
        resolved_display_value = self.value
    end

    local display_text = resolved_display_value ~= "" and resolved_display_value or self.placeholder
    local text_width = self.width - 28
    if self.selector then
        text_width = text_width - 26
    end
    local display_font = fitFont(fonts, display_text, text_width, { "TextSmall", "Text", "Caption" })
    love.graphics.setFont(display_font)
    if resolved_display_value ~= "" then
        love.graphics.setColor(colors.text_primary)
        love.graphics.printf(resolved_display_value, self.x + 14, self.y + math.floor((self.height - display_font:getHeight()) * 0.5), text_width, "left")
    else
        love.graphics.setColor(colors.text_muted)
        love.graphics.printf(self.placeholder, self.x + 14, self.y + math.floor((self.height - display_font:getHeight()) * 0.5), text_width, "left")
    end

    if self.selector then
        local arrow = ">"
        local arrow_font = fonts:get("TextSmall")
        love.graphics.setFont(arrow_font)
        love.graphics.setColor(self.editable and colors.text_secondary or colors.text_muted)
        love.graphics.print(
            arrow,
            self.x + self.width - 18 - arrow_font:getWidth(arrow),
            self.y + math.floor((self.height - arrow_font:getHeight()) * 0.5)
        )
    end
end

return RoomPageTextInput
