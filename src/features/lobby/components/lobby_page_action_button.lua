local LobbyPageActionButton = {}
LobbyPageActionButton.__index = LobbyPageActionButton

local function drawIOSButton(fonts, style, options)
    local colors = style.colors
    local enabled = options.enabled ~= false
    local hovered = options.hovered == true
    local variant = options.variant or "secondary"
    local radius = options.radius or 14

    local face
    local border
    local text_color
    if not enabled then
        face = colors.button_disabled_face
        border = colors.button_disabled_border
        text_color = colors.button_disabled_text
    elseif variant == "primary" then
        face = hovered and colors.button_primary_hover_face or colors.button_primary_face
        border = colors.button_primary_border
        text_color = colors.button_primary_text
    else
        face = hovered and colors.button_secondary_hover_face or colors.button_secondary_face
        border = colors.button_secondary_border
        text_color = colors.button_secondary_text
    end

    love.graphics.setColor(colors.button_primary_shadow or { 0, 0, 0, 0.2 })
    love.graphics.rectangle("fill", options.x, options.y + 2, options.width, options.height, radius, radius)

    love.graphics.setColor(face)
    love.graphics.rectangle("fill", options.x, options.y, options.width, options.height, radius, radius)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(border)
    love.graphics.rectangle("line", options.x + 0.5, options.y + 0.5, options.width - 1, options.height - 1, radius, radius)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(text_color)
    love.graphics.setFont(fonts:get(options.font_token or "TextSmall"))
    love.graphics.printf(options.label, options.x, options.y + math.floor(options.height * 0.26), options.width, "center")
end

function LobbyPageActionButton.new(options)
    local self = setmetatable({}, LobbyPageActionButton)

    self.id = assert(options and options.id, "LobbyPageActionButton requires id")
    self.label = assert(options and options.label, "LobbyPageActionButton requires label")
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 140
    self.height = options.height or 48
    self.hovered = options.hovered == true
    self.enabled = options.enabled ~= false
    self.variant = options.variant or "secondary"
    self.font_token = options.font_token or "TextSmall"

    return self
end

function LobbyPageActionButton:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function LobbyPageActionButton:draw(fonts, style)
    drawIOSButton(fonts, style, {
        label = self.label,
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        hovered = self.hovered,
        enabled = self.enabled,
        variant = self.variant,
        font_token = self.font_token,
        radius = 14,
    })
end

return LobbyPageActionButton
