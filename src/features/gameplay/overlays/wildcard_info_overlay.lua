local CardView = require("src.features.gameplay.components.card_view")
local I18n = require("src.core.i18n.i18n")

local WildcardInfoOverlay = {}
WildcardInfoOverlay.__index = WildcardInfoOverlay

local function getOverlayTitle()
    return I18n:t("gameplay.wildcard_title")
end

local function drawOuterPanel(frame)
    love.graphics.setColor(0.26, 0.15, 0.07, 0.60)
    love.graphics.rectangle("fill", frame.x, frame.y + 10, frame.width, frame.height, 26, 26)

    love.graphics.setColor(0.76, 0.48, 0.23, 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 26, 26)

    love.graphics.setColor(0.96, 0.90, 0.75, 0.98)
    love.graphics.rectangle("fill", frame.x + 12, frame.y + 12, frame.width - 24, frame.height - 24, 22, 22)

    love.graphics.setColor(1, 1, 1, 0.08)
    love.graphics.rectangle("fill", frame.x + 24, frame.y + 28, frame.width - 48, 12, 8, 8)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(0.47, 0.24, 0.12, 0.98)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 26, 26)
    love.graphics.rectangle("line", frame.x + 12, frame.y + 12, frame.width - 24, frame.height - 24, 22, 22)
    love.graphics.setLineWidth(1)
end

local function drawInsetCard(frame, tint)
    tint = tint or { 0.98, 0.95, 0.88, 0.98 }

    love.graphics.setColor(0.29, 0.17, 0.09, 0.14)
    love.graphics.rectangle("fill", frame.x, frame.y + 5, frame.width, frame.height, 18, 18)

    love.graphics.setColor(0.98, 0.95, 0.88, 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 18, 18)

    love.graphics.setColor(tint[1], tint[2], tint[3], tint[4] or 0.98)
    love.graphics.rectangle("fill", frame.x + 8, frame.y + 8, frame.width - 16, 14, 10, 10)

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.80, 0.60, 0.34, 0.94)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 18, 18)
    love.graphics.setLineWidth(1)
end

function WildcardInfoOverlay.new(options)
    local self = setmetatable({}, WildcardInfoOverlay)

    self.fonts = assert(options and options.fonts, "WildcardInfoOverlay requires fonts")
    self.style = assert(options and options.style, "WildcardInfoOverlay requires style")
    self.card_view = CardView.new()

    return self
end

function WildcardInfoOverlay:_getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_w = 320
    local panel_h = 334
    return {
        x = math.floor((width - panel_w) / 2),
        y = math.floor((height - panel_h) / 2),
        width = panel_w,
        height = panel_h,
    }
end

function WildcardInfoOverlay:draw(card_code, theme_config)
    local colors = self.style.colors
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel = self:_getPanelFrame()
    local card_panel = {
        x = panel.x + 30,
        y = panel.y + 104,
        width = panel.width - 60,
        height = panel.height - 136,
    }

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, width, height)

    drawOuterPanel(panel)
    drawInsetCard(card_panel, { 0.99, 0.92, 0.78, 0.98 })

    love.graphics.setColor(0.37, 0.18, 0.09, 1)
    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.printf(getOverlayTitle(), panel.x, panel.y + 28, panel.width, "center")

    self.card_view:draw(
        card_code,
        {
            x = card_panel.x + math.floor((card_panel.width - 124) / 2),
            y = card_panel.y + math.floor((card_panel.height - 174) / 2),
            width = 124,
            height = 174,
        },
        theme_config or {},
        {
            selected = false,
            hovered = false,
            relation = "self",
        },
        self.fonts
    )
end

return WildcardInfoOverlay
