local CardView = require("src.features.gameplay.components.card_view")
local I18n = require("src.core.i18n.i18n")
local WoodButton = require("src.core.ui.wood_button")

local SettlementOverlay = {}
SettlementOverlay.__index = SettlementOverlay

local LEVEL_RANKS = {
    ["2"] = true,
    ["3"] = true,
    ["4"] = true,
    ["5"] = true,
    ["6"] = true,
    ["7"] = true,
    ["8"] = true,
    ["9"] = true,
    ["10"] = true,
    J = true,
    Q = true,
    K = true,
    A = true,
}

local LEVEL_ORDER = {
    "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A",
}

local function getSuitLabel(suit)
    local suffix = ({
        S = "spade",
        H = "heart",
        C = "club",
        D = "diamond",
    })[tostring(suit or "")]
    if not suffix then
        return tostring(suit or "")
    end
    return I18n:t("gameplay.suit_" .. suffix)
end

local function getWildcardLabel(card_code)
    local suit, rank = tostring(card_code or ""):match("^([SHCD])%-(%w+)$")
    if suit and rank then
        return string.format("%s%s", getSuitLabel(suit), rank)
    end
    return tostring(card_code or I18n:t("common.none"))
end

local function normalizeRank(rank)
    local raw = tostring(rank or ""):upper()
    if LEVEL_RANKS[raw] then
        return raw
    end
    return nil
end

local function normalizeLevelCard(card_like, fallback_rank)
    local suit, rank = tostring(card_like or ""):match("^([SHCD])%-(%w+)$")
    if suit and normalizeRank(rank) then
        return suit .. "-" .. normalizeRank(rank)
    end

    local normalized_rank = normalizeRank(card_like)
    if normalized_rank then
        return "H-" .. normalized_rank
    end

    local fallback = normalizeRank(fallback_rank)
    if fallback then
        return "H-" .. fallback
    end

    return nil
end

local function extractLevelRank(card_like)
    local suit, rank = tostring(card_like or ""):match("^([SHCD])%-(%w+)$")
    if suit and normalizeRank(rank) then
        return normalizeRank(rank)
    end
    return normalizeRank(card_like)
end

local function advanceLevelRank(rank, gain)
    local base_rank = normalizeRank(rank)
    if not base_rank then
        return nil
    end
    local current_index = nil
    for index, candidate in ipairs(LEVEL_ORDER) do
        if candidate == base_rank then
            current_index = index
            break
        end
    end
    if not current_index then
        return nil
    end
    local target_index = math.min(current_index + math.max(tonumber(gain) or 0, 0), #LEVEL_ORDER)
    return LEVEL_ORDER[target_index]
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

local function resolveSettlementGameMode(game_mode, settlement)
    if tostring(game_mode or "") == "level" then
        return "level"
    end
    if hasLevelSettlementData(settlement) then
        return "level"
    end
    return "classic"
end

local function drawOuterPanel(frame)
    love.graphics.setColor(0.26, 0.15, 0.07, 0.56)
    love.graphics.rectangle("fill", frame.x, frame.y + 12, frame.width, frame.height, 28, 28)

    love.graphics.setColor(0.75, 0.47, 0.23, 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 28, 28)

    love.graphics.setColor(0.98, 0.93, 0.82, 0.99)
    love.graphics.rectangle("fill", frame.x + 12, frame.y + 12, frame.width - 24, frame.height - 24, 24, 24)

    love.graphics.setColor(1, 1, 1, 0.08)
    love.graphics.rectangle("fill", frame.x + 28, frame.y + 30, frame.width - 56, 12, 8, 8)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(0.48, 0.25, 0.12, 0.98)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 28, 28)
    love.graphics.rectangle("line", frame.x + 12, frame.y + 12, frame.width - 24, frame.height - 24, 24, 24)
    love.graphics.setLineWidth(1)
end

local function drawCardPanel(frame, tint)
    tint = tint or { 0.99, 0.95, 0.87, 0.98 }

    love.graphics.setColor(0.29, 0.17, 0.09, 0.14)
    love.graphics.rectangle("fill", frame.x, frame.y + 6, frame.width, frame.height, 18, 18)

    love.graphics.setColor(0.99, 0.96, 0.90, 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 18, 18)

    love.graphics.setColor(tint[1], tint[2], tint[3], tint[4] or 0.98)
    love.graphics.rectangle("fill", frame.x + 8, frame.y + 8, frame.width - 16, 14, 10, 10)

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.82, 0.61, 0.35, 0.94)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 18, 18)
    love.graphics.setLineWidth(1)
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

local function drawChip(frame, active)
    if active then
        love.graphics.setColor(0.34, 0.58, 0.38, 0.18)
        love.graphics.rectangle("fill", frame.x, frame.y + 2, frame.width, frame.height, 12, 12)
        love.graphics.setColor(0.88, 0.96, 0.83, 0.98)
        love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 12, 12)
        love.graphics.setColor(0.38, 0.60, 0.36, 0.94)
        love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 12, 12)
    else
        love.graphics.setColor(0.44, 0.27, 0.14, 0.10)
        love.graphics.rectangle("fill", frame.x, frame.y + 2, frame.width, frame.height, 12, 12)
        love.graphics.setColor(0.98, 0.94, 0.86, 0.98)
        love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 12, 12)
        love.graphics.setColor(0.78, 0.58, 0.34, 0.94)
        love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 12, 12)
    end
end

local function drawProgressBar(frame, progress)
    love.graphics.setColor(0.77, 0.67, 0.50, 0.46)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 10, 10)

    love.graphics.setColor(0.78, 0.47, 0.20, 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, math.max(0, math.floor(frame.width * progress)), frame.height, 10, 10)

    love.graphics.setColor(1, 1, 1, 0.10)
    love.graphics.rectangle("fill", frame.x + 2, frame.y + 2, math.max(0, math.floor(frame.width * progress) - 4), math.max(4, frame.height * 0.35), 8, 8)

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.49, 0.29, 0.16, 0.72)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 10, 10)
    love.graphics.setLineWidth(1)
end

local function drawTeamLevelRow(fonts, x, y, width, team_index, before_rank, after_rank, active)
    local row = {
        x = x,
        y = y,
        width = width,
        height = 34,
    }
    drawChip(row, active)

    love.graphics.setColor(0.56, 0.30, 0.14, 1)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.print(I18n:t("gameplay.settlement_team_label", {
        team = tostring(team_index),
    }), x + 12, y + 8)

    love.graphics.setColor(0.34, 0.18, 0.08, 1)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.printf(tostring(before_rank) .. " -> " .. tostring(after_rank), x + 92, y + 8, width - 104, "left")
end

local function drawLevelChip(fonts, frame, label, value, active)
    drawChip(frame, active)
    love.graphics.setColor(0.56, 0.30, 0.14, 1)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.printf(label .. " " .. tostring(value), frame.x + 8, frame.y + 8, frame.width - 16, "center")
end

function SettlementOverlay.new(options)
    local self = setmetatable({}, SettlementOverlay)
    self.fonts = assert(options and options.fonts, "SettlementOverlay requires fonts")
    self.style = assert(options and options.style, "SettlementOverlay requires style")
    self.card_view = CardView.new()
    return self
end

function SettlementOverlay:_getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_w = 840
    local panel_h = 540
    return {
        x = math.floor((width - panel_w) / 2),
        y = math.floor((height - panel_h) / 2),
        width = panel_w,
        height = panel_h,
    }
end

function SettlementOverlay:getNextHandButtonFrame()
    local panel = self:_getPanelFrame()
    return {
        x = panel.x + math.floor((panel.width - 220) / 2),
        y = panel.y + panel.height - 92,
        width = 220,
        height = 54,
    }
end

function SettlementOverlay:getControlAt(x, y, options)
    if not options or not options.is_single_player then
        return nil
    end
    local frame = self:getNextHandButtonFrame()
    if x >= frame.x and x <= frame.x + frame.width and y >= frame.y and y <= frame.y + frame.height then
        return "next_hand"
    end
    return nil
end

function SettlementOverlay:draw(settlement, options)
    local colors = self.style.colors
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel = self:_getPanelFrame()
    local theme_config = (options or {}).card_theme_config or {}
    settlement = settlement or {}
    options = options or {}
    local game_mode = resolveSettlementGameMode(options.game_mode, settlement)
    local my_team_id = options.my_team_id
    local upgraded_team_id = settlement.upgraded_team_id
    if upgraded_team_id == nil then
        upgraded_team_id = settlement.winning_team_id
    end
    local winning_team_id = settlement.winning_team_id
    if winning_team_id == nil then
        winning_team_id = upgraded_team_id
    end
    local level_gain = tonumber(settlement.level_gain) or 0
    local score_gain = tonumber(settlement.score_gain) or level_gain
    local is_my_win = my_team_id ~= nil and tonumber(winning_team_id or -1) == tonumber(my_team_id)
    local score_text = is_my_win and I18n:t("gameplay.settlement_score_gain_my_team", {
        score = tostring(score_gain),
    }) or I18n:t("gameplay.settlement_score_gain_opponent", {
        score = tostring(score_gain),
    })
    local team_levels_after = settlement.team_levels_after or {}
    if #team_levels_after == 0 then
        team_levels_after = options.team_levels or {}
    end

    local hero = {
        x = panel.x + 34,
        y = panel.y + 56,
        width = panel.width - 68,
        height = 94,
    }

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, width, height)

    drawOuterPanel(panel)

    if game_mode ~= "level" then
        local simple_hero = {
            x = panel.x + 48,
            y = panel.y + 108,
            width = panel.width - 96,
            height = 168,
        }
        drawHeroBanner(simple_hero)

        love.graphics.setColor(is_my_win and 0.28 or 0.52, is_my_win and 0.56 or 0.24, is_my_win and 0.28 or 0.18, 1)
        love.graphics.setFont(self.fonts:get("Title2"))
        love.graphics.printf(
            score_text,
            simple_hero.x + 24,
            simple_hero.y + 50,
            simple_hero.width - 48,
            "center"
        )

        if options.is_single_player then
            local button = self:getNextHandButtonFrame()
            WoodButton.draw(self.fonts, self.style, {
                label = I18n:t("gameplay.next_hand"),
                x = button.x,
                y = button.y,
                width = button.width,
                height = button.height,
                hovered = options.button_hovered == true,
                enabled = true,
                variant = "primary",
                font_token = "Text",
                radius = 14,
            })
            return
        end

        local duration = math.max(tonumber(options.countdown_duration) or 0, 0)
        local remaining = math.max(tonumber(options.countdown_remaining) or 0, 0)
        local progress = duration > 0 and math.max(0, math.min(1, remaining / duration)) or 0
        local progress_frame = {
            x = panel.x + 92,
            y = panel.y + panel.height - 74,
            width = panel.width - 184,
            height = 18,
        }

        drawProgressBar(progress_frame, progress)
        return
    end

    drawHeroBanner(hero)

    love.graphics.setColor(0.40, 0.22, 0.10, 1)
    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.printf(score_text, hero.x + 24, hero.y + 22, hero.width - 48, "center")

    local content_x = panel.x + 34
    local content_w = panel.width - 68
    local arrow_w = 64
    local card_row_y = hero.y + hero.height + 18
    local available_h = panel.y + panel.height - card_row_y - 120
    local card_panel_h = math.max(200, math.min(230, available_h))
    local card_panel_w = math.floor((content_w - arrow_w) / 2)

    local current_card = {
        x = content_x,
        y = card_row_y,
        width = card_panel_w,
        height = card_panel_h,
    }
    local next_card = {
        x = content_x + card_panel_w + arrow_w,
        y = card_row_y,
        width = card_panel_w,
        height = card_panel_h,
    }

    local function drawLevelCard(frame, label, card_id)
        drawCardPanel(frame, { 0.99, 0.93, 0.78, 0.98 })
        local label_font = self.fonts:get("TextBig")
        local label_y = frame.y + 10
        local label_h = label_font:getHeight()

        love.graphics.setFont(label_font)
        love.graphics.setColor(1.0, 0.94, 0.82, 0.9)
        love.graphics.printf(label, frame.x, label_y + 1, frame.width, "center")
        love.graphics.setColor(0.58, 0.31, 0.15, 1)
        love.graphics.printf(label, frame.x, label_y, frame.width, "center")

        local card_y = frame.y + 18 + label_h
        local card_h = frame.height - (card_y - frame.y) - 14
        local card_w = math.floor(card_h / 1.38)
        local card_x = frame.x + math.floor((frame.width - card_w) * 0.5)

        if card_id and card_id ~= "" then
            self.card_view:draw(
                card_id,
                {
                    x = card_x,
                    y = card_y,
                    width = card_w,
                    height = card_h,
                },
                theme_config,
                {
                    selected = false,
                    hovered = false,
                    relation = "self",
                    simple_face = true,
                },
                self.fonts
            )
        else
            love.graphics.setColor(0.45, 0.26, 0.12, 0.9)
            love.graphics.setFont(self.fonts:get("Title2"))
            love.graphics.printf("?", card_x, card_y + math.floor(card_h * 0.3), card_w, "center")
        end
    end

    local upgraded_team_index = tonumber(upgraded_team_id)
    local team_next_rank = upgraded_team_index ~= nil and team_levels_after[upgraded_team_index + 1] or nil
    local current_card_id = normalizeLevelCard(settlement.current_wildcard_card, nil)
    if not current_card_id then
        current_card_id = normalizeLevelCard(options.wildcard_card, nil)
    end

    local next_card_id = normalizeLevelCard(settlement.next_wildcard_card, nil)
    if not next_card_id then
        next_card_id = normalizeLevelCard(nil, team_next_rank)
    end
    if not next_card_id then
        next_card_id = normalizeLevelCard(options.next_level_rank, nil)
    end
    if not next_card_id then
        local current_rank = extractLevelRank(current_card_id) or extractLevelRank(options.wildcard_card)
        local derived_next_rank = advanceLevelRank(current_rank, level_gain)
        next_card_id = normalizeLevelCard(nil, derived_next_rank)
    end

    drawLevelCard(current_card, I18n:t("gameplay.settlement_current_level_label"), current_card_id)
    drawLevelCard(next_card, I18n:t("gameplay.settlement_next_level_label"), next_card_id)

    local arrow_x = current_card.x + current_card.width
    local arrow_y = card_row_y
    love.graphics.setColor(0.62, 0.37, 0.18, 1)
    love.graphics.setLineWidth(3)
    local mid_y = arrow_y + card_panel_h * 0.5
    love.graphics.line(arrow_x + 10, mid_y, arrow_x + arrow_w - 12, mid_y)
    love.graphics.polygon("fill", arrow_x + arrow_w - 12, mid_y, arrow_x + arrow_w - 26, mid_y - 8, arrow_x + arrow_w - 26, mid_y + 8)
    love.graphics.setLineWidth(1)

    if options.is_single_player then
        local button = self:getNextHandButtonFrame()
        WoodButton.draw(self.fonts, self.style, {
            label = I18n:t("gameplay.next_hand"),
            x = button.x,
            y = button.y,
            width = button.width,
            height = button.height,
            hovered = options.button_hovered == true,
            enabled = true,
            variant = "primary",
            font_token = "Text",
            radius = 14,
        })
        return
    end

    local duration = math.max(tonumber(options.countdown_duration) or 0, 0)
    local remaining = math.max(tonumber(options.countdown_remaining) or 0, 0)
    local progress = duration > 0 and math.max(0, math.min(1, remaining / duration)) or 0
    local progress_frame = {
        x = panel.x + 92,
        y = panel.y + panel.height - 74,
        width = panel.width - 184,
        height = 18,
    }

    drawProgressBar(progress_frame, progress)
end

return SettlementOverlay
