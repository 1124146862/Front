local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")
local CardView = require("src.features.gameplay.components.card_view")
local RelationPalette = require("src.features.gameplay.relation_palette")
local I18n = require("src.core.i18n.i18n")
local IconCloseButton = require("src.core.ui.icon_close_button")
local WoodPanel = require("src.core.ui.wood_panel")

local RemainingCardsOverlay = {}
RemainingCardsOverlay.__index = RemainingCardsOverlay

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.width
        and y >= bounds.y
        and y <= bounds.y + bounds.height
end

local function drawRowCard(colors, frame)
    love.graphics.setColor(0.24, 0.14, 0.08, 0.10)
    love.graphics.rectangle("fill", frame.x, frame.y + 4, frame.width, frame.height, 14, 14)

    love.graphics.setColor(colors.card_alt[1], colors.card_alt[2], colors.card_alt[3], 0.94)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 14, 14)

    love.graphics.setColor(colors.panel_border[1], colors.panel_border[2], colors.panel_border[3], 0.22)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 14, 14)
    love.graphics.setLineWidth(1)
end

local function measureRolePillWidth(fonts, label)
    local text = tostring(label or "")
    local font = fonts:get("Caption")
    local pad_x = 14
    local min_width = 72
    return math.max(min_width, font:getWidth(text) + pad_x * 2)
end

local function drawRolePill(colors, fonts, frame, label, role_key)
    local font = fonts:get("Caption")
    local palette = RelationPalette.get(role_key)
    love.graphics.setColor(palette.fill[1], palette.fill[2], palette.fill[3], 0.96)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 10, 10)
    love.graphics.setColor(palette.border[1], palette.border[2], palette.border[3], 0.78)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", frame.x + 0.5, frame.y + 0.5, frame.width - 1, frame.height - 1, 10, 10)
    love.graphics.setColor(palette.text)
    love.graphics.setFont(font)
    love.graphics.print(tostring(label or ""), frame.x + math.floor((frame.width - font:getWidth(tostring(label or ""))) * 0.5), frame.y + 4)
end

local function drawFinishTag(fonts, frame, label_key)
    if not label_key or label_key == "" then
        return
    end

    local fill = { 0.90, 0.43, 0.21, 0.98 }
    local border = { 0.99, 0.94, 0.78, 0.96 }
    if label_key == "second" then
        fill = { 0.36, 0.52, 0.78, 0.98 }
        border = { 0.86, 0.92, 0.99, 0.94 }
    elseif label_key == "third" then
        fill = { 0.68, 0.47, 0.24, 0.98 }
        border = { 0.95, 0.88, 0.76, 0.94 }
    elseif label_key == "last" then
        fill = { 0.36, 0.36, 0.40, 0.98 }
        border = { 0.86, 0.86, 0.90, 0.90 }
    end

    love.graphics.setColor(0.22, 0.10, 0.05, 0.28)
    love.graphics.rectangle("fill", frame.x, frame.y + 2, frame.width, frame.height, 9, 9)
    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 9, 9)
    love.graphics.setColor(border)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", frame.x + 0.5, frame.y + 0.5, frame.width - 1, frame.height - 1, 9, 9)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1.0, 0.98, 0.92, 1.0)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.printf(I18n:t("gameplay.finish_tag_" .. label_key), frame.x, frame.y + 4, frame.width, "center")
end

local function backOut(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    local x = math.max(0, math.min(1, t))
    return 1 + c3 * (x - 1) * (x - 1) * (x - 1) + c1 * (x - 1) * (x - 1)
end

local function drawHeroBanner(frame)
    love.graphics.setColor(0.30, 0.47, 0.26, 0.15)
    love.graphics.rectangle("fill", frame.x, frame.y + 6, frame.width, frame.height, 20, 20)

    love.graphics.setColor(0.96, 0.91, 0.78, 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 20, 20)

    love.graphics.setColor(0.86, 0.92, 0.77, 0.98)
    love.graphics.rectangle("fill", frame.x + 8, frame.y + 8, frame.width - 16, 18, 10, 10)

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.63, 0.76, 0.53, 0.98)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 20, 20)
    love.graphics.setLineWidth(1)
end

local function drawCountdownBar(frame, progress)
    local clamped = math.max(0, math.min(1, tonumber(progress) or 0))
    local fill_width = math.max(0, math.floor(frame.width * clamped))

    love.graphics.setColor(0.81, 0.73, 0.56, 0.34)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 8, 8)

    if fill_width > 0 then
        love.graphics.setColor(0.98, 0.28, 0.20, 0.96)
        love.graphics.rectangle("fill", frame.x, frame.y, fill_width, frame.height, 8, 8)

        if fill_width > 4 then
            love.graphics.setColor(1, 1, 1, 0.16)
            love.graphics.rectangle(
                "fill",
                frame.x + 2,
                frame.y + 2,
                math.max(0, fill_width - 4),
                math.max(4, math.floor(frame.height * 0.38)),
                6,
                6
            )
        end
    end

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.97, 0.27, 0.21, 0.92)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 8, 8)
    love.graphics.setLineWidth(1)
end

local function buildResultSummary(settlement, my_team_id)
    settlement = settlement or {}
    local winning_team_id = settlement.winning_team_id
    if winning_team_id == nil or my_team_id == nil then
        return "", nil
    end
    local is_my_win = tonumber(winning_team_id) == tonumber(my_team_id)
    return I18n:t(is_my_win and "gameplay.remaining_cards_result_win" or "gameplay.remaining_cards_result_lose"), is_my_win
end

local function hasLevelSettlementData(settlement)
    settlement = settlement or {}
    if tostring(settlement.current_wildcard_card or "") ~= "" then
        return true
    end
    if tostring(settlement.next_wildcard_card or "") ~= "" then
        return true
    end
    if settlement.upgraded_team_id ~= nil then
        return true
    end
    if #((settlement.team_levels_before) or {}) > 0 then
        return true
    end
    if #((settlement.team_levels_after) or {}) > 0 then
        return true
    end
    return false
end

local function resolveSettlementGameMode(options)
    options = options or {}
    local game_mode = tostring(options.game_mode or "")
    if game_mode == "level" then
        return "level"
    end
    if hasLevelSettlementData(options.settlement) then
        return "level"
    end
    return "classic"
end

local function buildLevelGainSummary(options)
    options = options or {}
    if resolveSettlementGameMode(options) ~= "level" then
        return ""
    end

    local settlement = options.settlement or {}
    local upgraded_team_id = settlement.upgraded_team_id
    if upgraded_team_id == nil then
        upgraded_team_id = settlement.winning_team_id
    end
    local level_gain = tonumber(settlement.level_gain) or 0
    local my_team_id = options.my_team_id
    if upgraded_team_id == nil or my_team_id == nil or level_gain <= 0 then
        return ""
    end

    local summary_key = tonumber(upgraded_team_id) == tonumber(my_team_id)
        and "gameplay.remaining_cards_level_gain_self"
        or "gameplay.remaining_cards_level_gain_opponent"
    return I18n:t(summary_key, {
        levels = tostring(level_gain),
    })
end

local function shouldShowMergedSummary(options)
    options = options or {}
    local result_text = buildResultSummary(options.settlement, options.my_team_id)
    return result_text ~= "" or buildLevelGainSummary(options) ~= ""
end

function RemainingCardsOverlay.new(options)
    local self = setmetatable({}, RemainingCardsOverlay)
    self.fonts = assert(options and options.fonts, "RemainingCardsOverlay requires fonts")
    self.style = assert(options and options.style, "RemainingCardsOverlay requires style")
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

function RemainingCardsOverlay:getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_w = math.min(1240, width - 88)
    local panel_h = math.min(768, height - 84)
    return {
        x = math.floor((width - panel_w) * 0.5),
        y = math.floor((height - panel_h) * 0.5),
        width = panel_w,
        height = panel_h,
    }
end

function RemainingCardsOverlay:getAnimatedPanelFrame(options)
    local target = self:getPanelFrame()
    options = options or {}
    local reveal_remaining = math.max(tonumber(options.reveal_remaining) or 0, 0)
    if reveal_remaining > 0 then
        return nil
    end

    local intro_duration = math.max(tonumber(options.intro_duration) or 0, 0)
    local intro_remaining = math.max(tonumber(options.intro_remaining) or 0, 0)
    local progress = 1
    if intro_duration > 0 then
        progress = 1 - (math.min(intro_duration, intro_remaining) / intro_duration)
    end
    progress = math.max(0, math.min(1, progress))
    local eased = backOut(progress)
    local start_y = -target.height - 48
    return {
        x = target.x,
        y = math.floor(start_y + (target.y - start_y) * eased),
        width = target.width,
        height = target.height,
        progress = progress,
    }
end

function RemainingCardsOverlay:getCloseButtonFrame(options)
    local panel = self:getAnimatedPanelFrame(options) or self:getPanelFrame()
    return {
        x = panel.x + panel.width - 66,
        y = panel.y + 18,
        width = 40,
        height = 40,
    }
end

function RemainingCardsOverlay:getControlAt(x, y, options)
    options = options or {}
    if not options.can_skip or (tonumber(options.reveal_remaining) or 0) > 0 then
        return nil
    end
    local close = self:getCloseButtonFrame(options)
    if contains(close, x, y) then
        return "close_remaining_cards"
    end
    return nil
end

function RemainingCardsOverlay:_drawCardStrip(frame, cards, theme_config)
    local colors = self.style.colors
    if not cards or #cards == 0 then
        love.graphics.setColor(colors.text_secondary or colors.text_primary)
        love.graphics.setFont(self.fonts:get("Caption"))
        love.graphics.printf(I18n:t("gameplay.remaining_cards_empty"), frame.x, frame.y + math.floor((frame.height - 16) * 0.5), frame.width, "center")
        return
    end

    local card_h = math.min(frame.height - 8, 118)
    local card_w = math.floor(card_h / 1.36)
    local step = 0
    if #cards > 1 then
        local min_overlap_step = math.max(16, math.floor(card_w * 0.28))
        local max_open_step = card_w + math.max(8, math.floor(card_w * 0.14))
        local natural_step = math.floor((frame.width - card_w) / (#cards - 1))
        step = math.max(min_overlap_step, math.min(max_open_step, natural_step))
    end
    local total_w = card_w + (#cards - 1) * step
    local start_x = frame.x + math.max(0, math.floor((frame.width - total_w) * 0.5))
    local card_y = frame.y + math.floor((frame.height - card_h) * 0.5)

    love.graphics.setScissor(frame.x, frame.y, frame.width, frame.height)
    for index, card_id in ipairs(cards) do
        self.card_view:draw(card_id, {
            x = start_x + (index - 1) * step,
            y = card_y,
            width = card_w,
            height = card_h,
        }, theme_config, {
            selected = false,
            hovered = false,
            relation = "self",
        }, self.fonts)
    end
    love.graphics.setScissor()
end

function RemainingCardsOverlay:_drawRow(frame, row, theme_config)
    local colors = self.style.colors
    drawRowCard(colors, frame)

    local avatar_size = math.max(62, math.min(frame.height - 18, 74))
    local avatar_bounds = {
        x = frame.x + 14,
        y = frame.y + math.floor((frame.height - avatar_size) * 0.5),
        w = avatar_size,
        h = avatar_size,
    }
    local avatar = self.avatars_by_id[tostring(row.avatar_id or "")] or self.avatars_by_id.avatar_1
    if avatar then
        AvatarTile.draw(self.style, avatar, avatar_bounds, {
            hovered = false,
            selected = false,
            pin_frame = true,
            accessories = row.accessories,
        })
    end

    if row.finish_tag_key then
        local tag_label = I18n:t("gameplay.finish_tag_" .. row.finish_tag_key)
        local tag_width = math.max(48, self.fonts:get("Caption"):getWidth(tag_label) + 18)
        drawFinishTag(self.fonts, {
            x = avatar_bounds.x + avatar_bounds.w - tag_width - 2,
            y = avatar_bounds.y - 6,
            width = tag_width,
            height = 24,
        }, row.finish_tag_key)
    end

    local info_x = avatar_bounds.x + avatar_bounds.w + 16
    local role_label = tostring(row.role_label or "")
    local role_width = measureRolePillWidth(self.fonts, role_label)
    local info_w = math.max(166, math.min(236, math.floor(frame.width * 0.18), role_width + 12))
    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf(tostring(row.nickname or "-"), info_x, frame.y + 20, info_w, "left")

    drawRolePill(colors, self.fonts, {
        x = info_x,
        y = frame.y + math.min(frame.height - 36, 58),
        width = role_width,
        height = 22,
    }, role_label, row.role_key)

    local cards_frame = {
        x = info_x + info_w + 18,
        y = frame.y + 8,
        width = math.max(120, frame.x + frame.width - (info_x + info_w + 32)),
        height = frame.height - 16,
    }
    self:_drawCardStrip(cards_frame, row.cards or {}, theme_config)
end

function RemainingCardsOverlay:draw(options)
    options = options or {}
    local colors = self.style.colors
    local panel = self:getAnimatedPanelFrame(options)
    local theme_config = options.card_theme_config or {}
    local rows = options.rows or {}
    local can_skip = options.can_skip == true
    local reveal_remaining = math.max(tonumber(options.reveal_remaining) or 0, 0)
    if not panel then
        return
    end
    local result_text, is_my_win = buildResultSummary(options.settlement, options.my_team_id)
    local level_gain_text = buildLevelGainSummary(options)
    local countdown_duration = math.max(tonumber(options.countdown_duration) or 0, 0)
    local countdown_remaining = math.max(tonumber(options.countdown_remaining) or 0, 0)
    local show_countdown = countdown_duration > 0
    local countdown_progress = show_countdown and math.max(0, math.min(1, countdown_remaining / countdown_duration)) or 0
    local close_visible = can_skip and reveal_remaining <= 0
    local header_clearance = close_visible and 34 or 0
    local header_right_inset = close_visible and 56 or 0

    love.graphics.setColor(colors.overlay[1], colors.overlay[2], colors.overlay[3], (colors.overlay[4] or 0.54) * panel.progress)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    self.panel:draw(panel, {
        radius = 22,
        shadow_offset = 10,
        inner_inset = 12,
    })

    local content = {
        x = panel.x + 34,
        y = panel.y + 30,
        width = panel.width - 68,
        height = panel.height - 60,
    }

    if close_visible then
        self.close_button:draw(self:getCloseButtonFrame(options), options.button_hovered == true)
    end

    local hero_h = (shouldShowMergedSummary(options) or show_countdown) and (show_countdown and 116 or 92) or 0
    if hero_h > 0 then
        local hero = {
            x = content.x + 4,
            y = content.y + 6 + header_clearance,
            width = content.width - 8 - header_right_inset,
            height = hero_h,
        }
        drawHeroBanner(hero)

        local has_result_text = result_text ~= ""
        local has_level_gain_text = level_gain_text ~= ""
        local title_font = self.fonts:get("Title2")
        local subtitle_font = self.fonts:get("TextBig")
        local text_region_y = hero.y
        local text_region_h = hero.height
        if show_countdown then
            text_region_y = hero.y + 2
            text_region_h = hero.height - 24
        end

        if has_result_text and has_level_gain_text then
            local inset = 28
            local gap = 24
            local column_w = math.floor((hero.width - inset * 2 - gap) * 0.5)
            local left_x = hero.x + inset
            local right_x = left_x + column_w + gap

            love.graphics.setColor(0.73, 0.79, 0.60, 0.42)
            love.graphics.rectangle("fill", hero.x + math.floor(hero.width * 0.5) - 1, hero.y + 18, 2, hero.height - 36, 1, 1)

            if is_my_win == true then
                love.graphics.setColor(0.22, 0.56, 0.24, 1)
            else
                love.graphics.setColor(0.76, 0.20, 0.18, 1)
            end
            love.graphics.setFont(title_font)
            love.graphics.printf(
                result_text,
                left_x,
                text_region_y + math.floor((text_region_h - title_font:getHeight()) * 0.5) - 2,
                column_w,
                "center"
            )

            love.graphics.setColor(0.40, 0.22, 0.10, 1)
            love.graphics.setFont(subtitle_font)
            love.graphics.printf(
                level_gain_text,
                right_x,
                text_region_y + math.floor((text_region_h - subtitle_font:getHeight()) * 0.5),
                column_w,
                "center"
            )
        else
            if has_result_text then
                if is_my_win == true then
                    love.graphics.setColor(0.22, 0.56, 0.24, 1)
                else
                    love.graphics.setColor(0.76, 0.20, 0.18, 1)
                end
                love.graphics.setFont(title_font)
                love.graphics.printf(
                    result_text,
                    hero.x + 20,
                    text_region_y + math.floor((text_region_h - title_font:getHeight()) * 0.5) - 2,
                    hero.width - 40,
                    "center"
                )
            end

            if has_level_gain_text then
                love.graphics.setColor(0.40, 0.22, 0.10, 1)
                love.graphics.setFont(subtitle_font)
                love.graphics.printf(
                    level_gain_text,
                    hero.x + 20,
                    text_region_y + math.floor((text_region_h - subtitle_font:getHeight()) * 0.5),
                    hero.width - 40,
                    "center"
                )
            end
        end

        if show_countdown then
            drawCountdownBar({
                x = hero.x + 20,
                y = hero.y + hero.height - 24,
                width = hero.width - 40,
                height = 12,
            }, countdown_progress)
        end
    end

    local list_frame = {
        x = content.x,
        y = content.y + hero_h + (hero_h > 0 and 16 or 12) + header_clearance,
        width = content.width,
        height = content.height - hero_h - (hero_h > 0 and 16 or 12) - header_clearance,
    }

    if reveal_remaining <= 0 then
        local row_gap = 14
        local row_count = math.max(#rows, 1)
        local list_top = list_frame.y + 6
        local available_h = math.max(0, list_frame.height - 12 - row_gap * (row_count - 1))
        local row_h = math.max(118, math.min(146, math.floor(available_h / row_count)))
        for index, row in ipairs(rows) do
            local row_frame = {
                x = list_frame.x + 4,
                y = list_top + (index - 1) * (row_h + row_gap),
                width = list_frame.width - 8,
                height = row_h,
            }
            self:_drawRow(row_frame, row, theme_config)
        end
    end
end

return RemainingCardsOverlay
