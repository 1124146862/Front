local MainMenuEntryActionButton = {}
MainMenuEntryActionButton.__index = MainMenuEntryActionButton

function MainMenuEntryActionButton.new(options)
    local self = setmetatable({}, MainMenuEntryActionButton)

    self.id = assert(options and options.id, "MainMenuEntryActionButton requires id")
    self.label = assert(options and options.label, "MainMenuEntryActionButton requires label")
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 300
    self.height = options.height or 60
    self.hovered = options.hovered == true
    self.enabled = options.enabled ~= false

    return self
end

function MainMenuEntryActionButton:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function MainMenuEntryActionButton:draw(fonts, style)
    local colors = style.colors
    local background = colors.button

    if not self.enabled then
        background = colors.button_disabled
    elseif self.hovered then
        background = colors.button_hover
    end

    love.graphics.setColor(background)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(fonts:get("Button"))
    love.graphics.printf(self.label, self.x, self.y + 16, self.width, "center")
end

return MainMenuEntryActionButton
