local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")
local CardView = require("src.features.gameplay.components.card_view")
local I18n = require("src.core.i18n.i18n")
local ButtonText = require("src.core.ui.button_text")
local IconCloseButton = require("src.core.ui.icon_close_button")
local WoodPanel = require("src.core.ui.wood_panel")

local HandHistoryOverlay = {}
HandHistoryOverlay.__index = HandHistoryOverlay

local MAX_VISIBLE_ROWS = 3
local CARD_SCALE = 1.8
local MAX_CARD_HEIGHT = math.floor(76 * CARD_SCALE)
local MAX_AVATAR_SIZE = math.floor(68 * CARD_SCALE)

local FRIENDLY_ROW_VISUALS = {
    shadow = { 0.18, 0.28, 0.15, 0.22 },
    fill = { 0.78, 0.88, 0.66, 0.98 },
    top_highlight = { 0.96, 1.00, 0.92, 0.34 },
    bottom_glow = { 0.48, 0.64, 0.39, 0.18 },
    border = { 0.34, 0.50, 0.25, 0.96 },
    outline = { 0.93, 0.99, 0.88, 0.58 },
    text = { 0.18, 0.28, 0.13, 1.00 },
    text_shadow = { 0.96, 1.00, 0.92, 0.36 },
}

local OPPONENT_ROW_VISUALS = {
    shadow = { 0.30, 0.11, 0.06, 0.24 },
    fill = { 0.86, 0.43, 0.27, 0.98 },
    top_highlight = { 1.00, 0.89, 0.82, 0.24 },
    bottom_glow = { 0.56, 0.18, 0.09, 0.18 },
    border = { 0.56, 0.19, 0.10, 0.98 },
    outline = { 1.00, 0.96, 0.92, 0.42 },
    text = { 1.00, 0.97, 0.94, 1.00 },
    text_shadow = { 0.35, 0.08, 0.04, 0.54 },
}

local NEUTRAL_ROW_VISUALS = {
    shadow = { 0.10, 0.10, 0.12, 0.20 },
    fill = { 0.20, 0.24, 0.28, 0.96 },
    top_highlight = { 0.95, 0.97, 1.00, 0.08 },
    bottom_glow = { 0.02, 0.03, 0.04, 0.20 },
    border = { 0.22, 0.25, 0.30, 0.96 },
    outline = { 1.00, 1.00, 1.00, 0.18 },
    text = { 0.98, 0.98, 0.99, 0.98 },
    text_shadow = { 0.00, 0.00, 0.00, 0.36 },
}

local ROLE_LABEL_VISUALS = {
    self = {
        text = { 0.08, 0.08, 0.08, 1.00 },
        shadow = { 0.88, 0.95, 0.82, 0.72 },
    },
    opposite = {
        text = { 0.22, 0.24, 0.22, 1.00 },
        shadow = { 0.90, 0.97, 0.85, 0.72 },
    },
    previous = {
        text = { 0.47, 0.12, 0.06, 1.00 },
        shadow = { 1.00, 0.92, 0.85, 0.82 },
    },
    next = {
        text = { 1.00, 0.94, 0.89, 1.00 },
        shadow = { 0.43, 0.10, 0.04, 0.90 },
    },
    teammate = {
        text = { 0.22, 0.24, 0.22, 1.00 },
        shadow = { 0.90, 0.97, 0.85, 0.72 },
    },
    opponent = {
        text = { 1.00, 0.94, 0.89, 1.00 },
        shadow = { 0.43, 0.10, 0.04, 0.90 },
    },
    neutral = {
        text = { 0.98, 0.98, 0.99, 0.98 },
        shadow = { 0.00, 0.00, 0.00, 0.42 },
    },
}

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.width
        and y >= bounds.y
        and y <= bounds.y + bounds.height
end

local function clamp(value, lower, upper)
    if value < lower then
        return lower
    end
    if value > upper then
        return upper
    end
    return value
end

local function getVisibleRow(rows, scroll, visible_index)
    local total = #(rows or {})
    local row_index = total - scroll - visible_index + 1
    if row_index < 1 or row_index > total then
        return nil
    end
    return rows[row_index]
end

local function formatVisibleRange(scroll, visible_count, total)
    if total <= 0 or visible_count <= 0 then
        return string.format("0 / %d", total)
    end

    local newest_index = math.max(total - scroll, 1)
    local oldest_index = math.max(total - scroll - visible_count + 1, 1)
    if newest_index == oldest_index then
        return string.format("%d / %d", newest_index, total)
    end
    return string.format("%d-%d / %d", newest_index, oldest_index, total)
end

local function getRowVisuals(role_key)
    local key = tostring(role_key or "")
    if key == "self" or key == "opposite" or key == "teammate" then
        return FRIENDLY_ROW_VISUALS
    end
    if key == "next" or key == "previous" or key == "opponent" then
        return OPPONENT_ROW_VISUALS
    end
    return NEUTRAL_ROW_VISUALS
end

local function getRoleLabelVisuals(role_key)
    return ROLE_LABEL_VISUALS[tostring(role_key or "")] or ROLE_LABEL_VISUALS.neutral
end

local function drawRowPanel(frame, visuals)
    visuals = visuals or NEUTRAL_ROW_VISUALS

    love.graphics.setColor(visuals.shadow)
    love.graphics.rectangle("fill", frame.x, frame.y + 4, frame.width, frame.height, 16, 16)

    love.graphics.setColor(visuals.fill)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 16, 16)

    love.graphics.setColor(visuals.top_highlight)
    love.graphics.rectangle("fill", frame.x + 3, frame.y + 3, frame.width - 6, 14, 12, 12)

    love.graphics.setColor(visuals.bottom_glow)
    love.graphics.rectangle("fill", frame.x + 3, frame.y + frame.height - 17, frame.width - 6, 11, 12, 12)

    love.graphics.setColor(visuals.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 16, 16)

    love.graphics.setColor(visuals.outline)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", frame.x + 3.5, frame.y + 3.5, frame.width - 7, frame.height - 7, 13, 13)
    love.graphics.setLineWidth(1)
end

local function drawPassBadge(fonts, colors, frame)
    love.graphics.setColor(0.30, 0.20, 0.12, 0.22)
    love.graphics.rectangle("fill", frame.x, frame.y + 3, frame.width, frame.height, 12, 12)

    love.graphics.setColor(colors.button_secondary_face[1], colors.button_secondary_face[2], colors.button_secondary_face[3], 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 12, 12)

    love.graphics.setColor(colors.button_secondary_border)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", frame.x + 0.5, frame.y + 0.5, frame.width - 1, frame.height - 1, 12, 12)
    love.graphics.setLineWidth(1)

    ButtonText.draw(fonts:get("Title3"), "PASS", frame.x, frame.y + 2, frame.width, "center", { 0.30, 0.16, 0.08, 1 }, {
        bold = true,
        bold_offset = 1,
    })
end

local function drawIndexBadge(fonts, colors, frame, value)
    love.graphics.setColor(0.30, 0.20, 0.12, 0.24)
    love.graphics.rectangle("fill", frame.x, frame.y + 3, frame.width, frame.height, 12, 12)

    love.graphics.setColor(colors.button_primary_face[1], colors.button_primary_face[2], colors.button_primary_face[3], 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 12, 12)

    love.graphics.setColor(colors.button_primary_border)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", frame.x + 0.5, frame.y + 0.5, frame.width - 1, frame.height - 1, 12, 12)
    love.graphics.setLineWidth(1)

    ButtonText.draw(fonts:get("TextBig"), tostring(value or ""), frame.x, frame.y + 4, frame.width, "center", colors.button_primary_text, {
        bold = true,
        bold_offset = 1,
    })
end

function HandHistoryOverlay.new(options)
    local self = setmetatable({}, HandHistoryOverlay)
    self.fonts = assert(options and options.fonts, "HandHistoryOverlay requires fonts")
    self.style = assert(options and options.style, "HandHistoryOverlay requires style")
    self.panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.card_view = CardView.new()
    self.avatars_by_id = {}
    for _, avatar in ipairs(AvatarRegistry) do
        self.avatars_by_id[avatar.id] = avatar
    end
    return self
end

function HandHistoryOverlay:getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_w = math.min(1040, width - 120)
    local panel_h = math.min(700, height - 108)
    return {
        x = math.floor((width - panel_w) * 0.5),
        y = math.floor((height - panel_h) * 0.5),
        width = panel_w,
        height = panel_h,
    }
end

function HandHistoryOverlay:getCloseButtonFrame()
    local panel = self:getPanelFrame()
    return {
        x = panel.x + panel.width - 66,
        y = panel.y + 18,
        width = 40,
        height = 40,
    }
end

function HandHistoryOverlay:getControlAt(x, y)
    if contains(self:getCloseButtonFrame(), x, y) then
        return "close_hand_history"
    end
    return nil
end

function HandHistoryOverlay:_drawCardStrip(frame, cards, theme_config)
    local card_count = #(cards or {})
    if card_count <= 0 then
        return
    end

    local card_h = math.min(frame.height - 10, MAX_CARD_HEIGHT)
    local card_w = math.floor(card_h / 1.36)
    local step = 0
    if card_count > 1 then
        local min_step = math.max(18, math.floor(card_w * 0.34))
        local max_step = card_w + math.max(8, math.floor(card_w * 0.18))
        local natural_step = math.floor((frame.width - card_w) / (card_count - 1))
        step = math.max(min_step, math.min(max_step, natural_step))
    end

    local start_x = frame.x + 10
    local card_y = frame.y + math.floor((frame.height - card_h) * 0.5)

    love.graphics.setScissor(frame.x, frame.y, frame.width, frame.height)
    for index, card_id in ipairs(cards) do
        self.card_view:draw(card_id, {
            x = start_x + (index - 1) * step,
            y = card_y,
            width = card_w,
            height = card_h,
        }, theme_config or {}, {
            selected = false,
            hovered = false,
            relation = "neutral",
        }, self.fonts)
    end
    love.graphics.setScissor()
end

function HandHistoryOverlay:_drawRow(frame, row, theme_config)
    local colors = self.style.colors
    local row_visuals = getRowVisuals((row or {}).role_key)
    drawRowPanel(frame, row_visuals)

    local index_frame = {
        x = frame.x + 14,
        y = frame.y + math.floor((frame.height - 46) * 0.5),
        width = 50,
        height = 46,
    }
    drawIndexBadge(self.fonts, colors, index_frame, (row or {}).display_index)

    local avatar_size = math.min(frame.height - 20, MAX_AVATAR_SIZE)
    local avatar_bounds = {
        x = index_frame.x + index_frame.width + 14,
        y = frame.y + math.floor((frame.height - avatar_size) * 0.5),
        w = avatar_size,
        h = avatar_size,
    }
    local avatar = self.avatars_by_id[tostring((row or {}).avatar_id or "")] or self.avatars_by_id.avatar_1
    if avatar then
        AvatarTile.draw(self.style, avatar, avatar_bounds, {
            compact = true,
            selected = false,
            hovered = false,
            pin_frame = true,
            accessories = (row or {}).accessories,
        })
    end

    local label_x = avatar_bounds.x + avatar_bounds.w + 16
    local label_w = 138
    local label_font = self.fonts:get("TextBig")
    local label_y = frame.y + math.floor((frame.height - label_font:getHeight()) * 0.5) - 2
    local label_visuals = getRoleLabelVisuals((row or {}).role_key)
    ButtonText.draw(label_font, tostring((row or {}).role_label or "-"), label_x, label_y, label_w, "left", label_visuals.text, {
        bold = true,
        bold_offset = 1,
        shadow_color = label_visuals.shadow,
    })

    local content_frame = {
        x = label_x + label_w + 12,
        y = frame.y + 8,
        width = math.max(160, frame.x + frame.width - (label_x + label_w + 24)),
        height = frame.height - 16,
    }
    if tostring((row or {}).action_type or "") == "pass" then
        drawPassBadge(self.fonts, colors, {
            x = content_frame.x + 4,
            y = content_frame.y + math.floor((content_frame.height - 54) * 0.5),
            width = 148,
            height = 54,
        })
        return
    end

    self:_drawCardStrip(content_frame, (row or {}).cards or {}, theme_config)
end

function HandHistoryOverlay:drawEmbedded(frame, options)
    options = options or {}
    local colors = self.style.colors
    local rows = options.rows or {}
    local scroll = clamp(tonumber(options.scroll) or 0, 0, math.max(#rows - MAX_VISIBLE_ROWS, 0))
    local visible_count = math.min(MAX_VISIBLE_ROWS, #rows)
    local row_gap = 12
    local header_h = 32
    local footer_h = 8
    local list_top = frame.y + header_h
    local list_height = math.max(0, frame.height - header_h - footer_h)
    local row_height = math.max(48, math.floor((list_height - row_gap * (MAX_VISIBLE_ROWS - 1)) / MAX_VISIBLE_ROWS))

    love.graphics.setColor(colors.hud_subtext)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf(I18n:t("gameplay.history_scroll_hint"), frame.x, frame.y, frame.width, "left")
    love.graphics.printf(formatVisibleRange(scroll, visible_count, #rows), frame.x, frame.y, frame.width, "right")

    if #rows == 0 then
        love.graphics.setColor(colors.text_secondary)
        love.graphics.setFont(self.fonts:get("TextBig"))
        love.graphics.printf(
            I18n:t("gameplay.history_empty"),
            frame.x,
            frame.y + math.floor((frame.height - self.fonts:get("TextBig"):getHeight()) * 0.5),
            frame.width,
            "center"
        )
        return
    end

    for visible_index = 1, visible_count do
        local row = getVisibleRow(rows, scroll, visible_index)
        if row then
            self:_drawRow({
                x = frame.x,
                y = list_top + (visible_index - 1) * (row_height + row_gap),
                width = frame.width,
                height = row_height,
            }, row, options.card_theme_config)
        end
    end
end

function HandHistoryOverlay:draw(options)
    options = options or {}
    local colors = self.style.colors
    local panel = self:getPanelFrame()

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    self.panel:draw(panel, {
        radius = 22,
        shadow_offset = 10,
        inner_inset = 12,
    })

    self.close_button:draw(self:getCloseButtonFrame(), options.close_hovered == true)

    love.graphics.setColor(colors.hud_title)
    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.printf(I18n:t("gameplay.history_title"), panel.x, panel.y + 30, panel.width, "center")

    self:drawEmbedded({
        x = panel.x + 28,
        y = panel.y + 70,
        width = panel.width - 56,
        height = panel.height - 104,
    }, options)
end

return HandHistoryOverlay
