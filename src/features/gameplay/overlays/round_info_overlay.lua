local I18n = require("src.core.i18n.i18n")
local IconCloseButton = require("src.core.ui.icon_close_button")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")
local HandHistoryOverlay = require("src.features.gameplay.overlays.hand_history_overlay")
local TributeInfoOverlay = require("src.features.gameplay.overlays.tribute_info_overlay")

local RoundInfoOverlay = {}
RoundInfoOverlay.__index = RoundInfoOverlay

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.width
        and y >= bounds.y
        and y <= bounds.y + bounds.height
end

local function getRoundInfoTitle()
    return I18n:t("gameplay.round_info_title")
end

function RoundInfoOverlay.new(options)
    local self = setmetatable({}, RoundInfoOverlay)
    self.fonts = assert(options and options.fonts, "RoundInfoOverlay requires fonts")
    self.style = assert(options and options.style, "RoundInfoOverlay requires style")
    self.panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.hand_history_overlay = HandHistoryOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.tribute_info_overlay = TributeInfoOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    return self
end

function RoundInfoOverlay:getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_w = math.min(1180, math.max(760, width - 72))
    local panel_h = math.min(760, math.max(540, height - 48))
    panel_w = math.min(panel_w, math.max(320, width - 24))
    panel_h = math.min(panel_h, math.max(320, height - 24))
    return {
        x = math.floor((width - panel_w) * 0.5),
        y = math.floor((height - panel_h) * 0.5),
        width = panel_w,
        height = panel_h,
    }
end

function RoundInfoOverlay:getCloseButtonFrame()
    local panel = self:getPanelFrame()
    return {
        x = panel.x + panel.width - 60,
        y = panel.y + 18,
        width = 38,
        height = 38,
    }
end

function RoundInfoOverlay:getTabFrames()
    local panel = self:getPanelFrame()
    local top = panel.y + 90
    local gap = 14
    local width = math.floor((panel.width - 56 - gap) * 0.5)
    local left = panel.x + 28
    return {
        history = {
            x = left,
            y = top,
            width = width,
            height = 52,
        },
        tribute = {
            x = left + width + gap,
            y = top,
            width = width,
            height = 52,
        },
    }
end

function RoundInfoOverlay:getContentFrame()
    local panel = self:getPanelFrame()
    local tabs = self:getTabFrames()
    return {
        x = panel.x + 24,
        y = tabs.history.y + tabs.history.height + 22,
        width = panel.width - 48,
        height = panel.y + panel.height - (tabs.history.y + tabs.history.height + 22) - 24,
    }
end

function RoundInfoOverlay:getControlAt(x, y, options)
    options = options or {}
    if contains(self:getCloseButtonFrame(), x, y) then
        return "close_round_info"
    end

    local tabs = self:getTabFrames()
    if contains(tabs.history, x, y) then
        return "round_info_tab_history"
    end
    if options.tribute_available == true and contains(tabs.tribute, x, y) then
        return "round_info_tab_tribute"
    end
    return nil
end

function RoundInfoOverlay:_drawTab(frame, label, active, hovered, enabled)
    WoodButton.draw(self.fonts, self.style, {
        x = frame.x,
        y = frame.y,
        width = frame.width,
        height = frame.height,
        label = label,
        variant = active and "primary" or "secondary",
        hovered = hovered,
        enabled = enabled,
        font_token = "Text",
    })
end

function RoundInfoOverlay:draw(game, options)
    options = options or {}
    local colors = self.style.colors
    local panel = self:getPanelFrame()
    local close = self:getCloseButtonFrame()
    local tabs = self:getTabFrames()
    local content = self:getContentFrame()
    local active_tab = options.active_tab == "tribute" and options.tribute_available == true and "tribute" or "history"
    local hovered = tostring(options.hovered_control or "")

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    self.panel:draw(panel, {
        radius = 22,
        shadow_offset = 8,
        inner_inset = 12,
    })

    love.graphics.setColor(colors.hud_title)
    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.printf(getRoundInfoTitle(), panel.x, panel.y + 28, panel.width, "center")

    self.close_button:draw(close, hovered == "close_round_info")
    self:_drawTab(
        tabs.history,
        I18n:t("gameplay.history_button"),
        active_tab == "history",
        hovered == "round_info_tab_history",
        true
    )
    self:_drawTab(
        tabs.tribute,
        I18n:t("gameplay.tribute_info_button"),
        active_tab == "tribute",
        hovered == "round_info_tab_tribute",
        options.tribute_available == true
    )

    if active_tab == "tribute" then
        self.tribute_info_overlay:drawEmbedded(content, game, {
            card_theme_config = options.card_theme_config,
            my_seat_index = options.my_seat_index,
            my_accessories = options.my_accessories,
        })
        return
    end

    self.hand_history_overlay:drawEmbedded(content, {
        rows = options.history_rows or {},
        scroll = options.history_scroll,
        card_theme_config = options.card_theme_config,
    })
end

return RoundInfoOverlay
