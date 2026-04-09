local CardView = require("src.features.gameplay.components.card_view")
local RelationPalette = require("src.features.gameplay.relation_palette")

local LastPlayRegion = {}
LastPlayRegion.__index = LastPlayRegion

local LAST_PLAY_CARD_WIDTH = 100
local LAST_PLAY_CARD_HEIGHT = 136
local LAST_PLAY_CARD_GAP = 16
local LABEL_CARD_GAP = 14
local REGION_INNER_PADDING = 16
local LEFT_PATTERN_BRACKET = (utf8 and utf8.char(0x3010)) or "["
local RIGHT_PATTERN_BRACKET = (utf8 and utf8.char(0x3011)) or "]"

local function buildLastPlayLabel(last_play)
    local actor_label = tostring((last_play or {}).actor_label or "-")
    local pattern_label = tostring((last_play or {}).pattern_label or "")
    if pattern_label == "" then
        return actor_label
    end
    return string.format("[%s]-%s%s%s", actor_label, LEFT_PATTERN_BRACKET, pattern_label, RIGHT_PATTERN_BRACKET)
end

local function drawBoldLabel(font, text, x, y, width, color)
    love.graphics.setFont(font)
    love.graphics.setColor(0.02, 0.03, 0.05, 0.82)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.printf(text, x + dx, y + dy, width, "center")
            end
        end
    end
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.printf(text, x, y, width, "center")
end

local function drawLabelPanel(x, y, width, height, palette)
    palette = palette or RelationPalette.get(nil)

    love.graphics.setColor(palette.shadow)
    love.graphics.rectangle("fill", x - 1, y + 3, width + 2, height + 1, 13, 13)

    love.graphics.setColor(palette.shadow[1], palette.shadow[2], palette.shadow[3], math.min(0.24, palette.shadow[4] or 0.24))
    love.graphics.rectangle("fill", x, y + 1, width, height + 2, 12, 12)

    love.graphics.setColor(palette.fill)
    love.graphics.rectangle("fill", x, y, width, height, 12, 12)

    love.graphics.setColor(palette.top_highlight)
    love.graphics.rectangle("fill", x + 2, y + 2, width - 4, math.max(7, math.floor(height * 0.32)), 10, 10)

    love.graphics.setColor(palette.bottom_glow)
    love.graphics.rectangle("fill", x + 1, y + math.floor(height * 0.54), width - 2, math.max(6, math.floor(height * 0.30)), 10, 10)

    love.graphics.setColor(palette.outline_dark)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, 11, 11)

    love.graphics.setColor(palette.outline_light)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, width - 1, height - 1, 12, 12)
end

local function buildLabelPanel(font, text, frame_width)
    local safe_text = tostring(text or "-")
    local horizontal_padding = 12
    local vertical_padding = 5
    local min_width = 42
    local max_width = math.max(min_width, math.floor(frame_width - REGION_INNER_PADDING * 2))
    local text_width = font:getWidth(safe_text)
    local text_height = font:getHeight()
    local panel_width = math.max(min_width, math.min(max_width, text_width + horizontal_padding * 2))
    local panel_height = text_height + vertical_padding * 2

    return {
        text = safe_text,
        width = panel_width,
        height = panel_height,
        text_y_offset = math.max(1, vertical_padding - 2),
    }
end

function LastPlayRegion.new(options)
    local self = setmetatable({}, LastPlayRegion)

    self.fonts = assert(options and options.fonts, "LastPlayRegion requires fonts")
    self.style = assert(options and options.style, "LastPlayRegion requires style")
    self.card_view = CardView.new()

    return self
end

function LastPlayRegion:getCardFrames(frame, last_play)
    if not last_play or not last_play.cards or #last_play.cards == 0 then
        return {}
    end

    local card_width = LAST_PLAY_CARD_WIDTH
    local card_height = LAST_PLAY_CARD_HEIGHT
    local card_count = #last_play.cards
    local natural_gap = LAST_PLAY_CARD_GAP
    local natural_spacing = card_width + natural_gap
    local spacing = natural_spacing

    if card_count > 1 then
        local usable_width = math.max(frame.width - card_width, 0)
        local max_spacing = math.floor(usable_width / (card_count - 1))
        spacing = math.min(natural_spacing, max_spacing)
        spacing = math.max(spacing, 30)
    else
        spacing = 0
    end

    local total_width = card_width + spacing * math.max(card_count - 1, 0)
    local start_x = frame.x + math.floor((frame.width - total_width) / 2)
    local card_area_top = frame.y + REGION_INNER_PADDING
    local label_font = self.fonts:get("TextBig")
    local label_panel = buildLabelPanel(label_font, buildLastPlayLabel(last_play), frame.width)
    local card_area_height = math.max(
        card_height,
        frame.height - REGION_INNER_PADDING * 2 - label_panel.height - LABEL_CARD_GAP
    )
    local y = card_area_top + math.max(0, math.floor((card_area_height - card_height) * 0.5))
    local frames = {}

    for index, card_id in ipairs(last_play.cards) do
        frames[#frames + 1] = {
            card_id = card_id,
            x = start_x + (index - 1) * spacing,
            y = y,
            width = card_width,
            height = card_height,
        }
    end

    return frames
end

function LastPlayRegion:draw(frame, last_play, theme_config, options)
    if not last_play or not last_play.cards or #last_play.cards == 0 then
        return
    end

    options = options or {}

    love.graphics.setColor(0.88, 0.90, 0.84, 0.24)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 18, 18)

    love.graphics.setColor(0.96, 0.97, 0.93, 0.16)
    love.graphics.rectangle("fill", frame.x + 4, frame.y + 4, frame.width - 8, frame.height - 8, 16, 16)

    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", frame.x + 0.5, frame.y + 0.5, frame.width - 1, frame.height - 1, 18, 18)
    love.graphics.setLineWidth(1)

    if options.hide_cards then
        return
    end

    local card_frames = self:getCardFrames(frame, last_play)
    for _, card_frame in ipairs(card_frames) do
        self.card_view:draw(
            card_frame.card_id,
            card_frame,
            theme_config,
            {
                selected = false,
                hovered = false,
                relation = "neutral",
            },
            self.fonts
        )
    end

    if #card_frames > 0 then
        local first = card_frames[1]
        local last = card_frames[#card_frames]
        local cards_center_x = math.floor((first.x + (last.x + last.width)) * 0.5)
        local label_font = self.fonts:get("TextBig")
        local label_panel = buildLabelPanel(label_font, buildLastPlayLabel(last_play), frame.width)
        local label_x = cards_center_x - math.floor(label_panel.width * 0.5)
        local label_y = math.min(
            frame.y + frame.height - label_panel.height - REGION_INNER_PADDING,
            first.y + first.height + LABEL_CARD_GAP
        )
        local palette = RelationPalette.get(last_play.actor_role_key)

        drawLabelPanel(label_x, label_y, label_panel.width, label_panel.height, palette)
        drawBoldLabel(
            label_font,
            label_panel.text,
            label_x,
            label_y + label_panel.text_y_offset,
            label_panel.width,
            palette.text
        )
    end
end

return LastPlayRegion
