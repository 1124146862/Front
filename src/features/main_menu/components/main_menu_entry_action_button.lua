local MainMenuEntryActionButton = {}
MainMenuEntryActionButton.__index = MainMenuEntryActionButton
local ButtonText = require("src.core.ui.button_text")

local function fillRounded(x, y, w, h, r)
    love.graphics.rectangle("fill", x, y, w, h, r, r)
end

local function lineRounded(x, y, w, h, r)
    love.graphics.rectangle("line", x, y, w, h, r, r)
end

local function drawThinWoodCard(fonts, style, options)
    local colors = style.colors
    local x = options.x
    local y = options.y
    local w = options.width
    local h = options.height
    local hovered = options.hovered == true
    local enabled = options.enabled ~= false
    local variant = options.variant or "secondary"
    local radius = options.radius or 16

    local shadow = { 0.27, 0.15, 0.07, enabled and 0.28 or 0.18 }
    local face = colors.button_secondary_face
    local face_hover = colors.button_secondary_hover_face
    local border = { 0.58, 0.38, 0.21, 0.58 }
    local text = colors.button_secondary_text
    local highlight = { 1.0, 0.97, 0.88, 0.55 }

    if variant == "primary" then
        face = { 0.99, 0.90, 0.69, 1 }
        face_hover = { 1.0, 0.93, 0.75, 1 }
        border = { 0.66, 0.39, 0.18, 0.72 }
        text = { 0.46, 0.21, 0.1, 1 }
        highlight = { 1.0, 0.98, 0.90, 0.65 }
    elseif not enabled then
        face = { 0.84, 0.79, 0.68, 0.96 }
        face_hover = face
        border = { 0.49, 0.42, 0.33, 0.44 }
        text = colors.button_disabled_text
        shadow = { 0.24, 0.2, 0.14, 0.14 }
        highlight = { 1.0, 0.98, 0.92, 0.22 }
    end

    local current_face = hovered and enabled and face_hover or face

    love.graphics.setColor(shadow)
    fillRounded(x, y + 4, w, h, radius)

    love.graphics.setColor(current_face)
    fillRounded(x, y, w, h, radius)

    love.graphics.setColor(highlight)
    fillRounded(x + 2, y + 2, w - 4, math.max(10, math.floor(h * 0.24)), math.max(8, radius - 4))

    love.graphics.setColor(border)
    love.graphics.setLineWidth(2)
    lineRounded(x + 1, y + 1, w - 2, h - 2, radius)
    love.graphics.setLineWidth(1)

    local grain = hovered and 0.12 or 0.08
    love.graphics.setColor(0.64, 0.43, 0.24, grain)
    local left = x + 18
    local right = x + w - 18
    love.graphics.rectangle("fill", left, y + 14, right - left, 2, 1, 1)
    love.graphics.rectangle("fill", left, y + h - 18, right - left, 2, 1, 1)

    local font = fonts:get(options.font_token or "Button")
    local text_y = y + math.floor((h - font:getHeight()) * 0.5) - 1

    ButtonText.draw(font, options.label, x, text_y, w, "center", text, {
        bold = options.bold == true,
        bold_offset = options.bold_offset or 1,
    })
end

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
    self.variant = options.variant or "primary"

    return self
end

function MainMenuEntryActionButton:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function MainMenuEntryActionButton.drawButton(fonts, style, options)
    drawThinWoodCard(fonts, style, options)
end

function MainMenuEntryActionButton:draw(fonts, style)
    MainMenuEntryActionButton.drawButton(fonts, style, {
        label = self.label,
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        hovered = self.hovered,
        enabled = self.enabled,
        variant = self.variant,
        font_token = "Button",
    })
end

return MainMenuEntryActionButton
