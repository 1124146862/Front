local CardView = {}
CardView.__index = CardView
local I18n = require("src.core.i18n.i18n")
local CardThemeManager = require("src.features.gameplay.card_themes.card_theme_manager")
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")
local FontConfig = require("src.core.font_config")

local SUIT_SYMBOLS = {
    S = "♠",
    H = "♥",
    C = "♣",
    D = "♦",
}

local HIGH_CONTRAST_SUIT_COLORS = {
    S = { 0.12, 0.15, 0.18, 1 },
    H = { 0.86, 0.28, 0.26, 1 },
    C = { 0.14, 0.47, 0.88, 1 },
    D = { 0.18, 0.70, 0.28, 1 },
}

local DEFAULT_SUIT_COLORS = {
    S = { 0.12, 0.15, 0.18, 1 },
    H = { 0.86, 0.28, 0.26, 1 },
    C = { 0.12, 0.15, 0.18, 1 },
    D = { 0.86, 0.28, 0.26, 1 },
}

local FACE_TINTS = {
    neutral = { 0.98, 0.98, 0.98, 1 },
    teammate = { 0.86, 0.94, 0.82, 1 },
    opponent = { 0.98, 0.90, 0.76, 1 },
    self = { 0.98, 0.98, 0.98, 1 },
}

local WILDCARD_RANK_COLOR = { 0.88, 0.68, 0.18, 1 }
local WILDCARD_RANK_BOLD = 1

local function drawDiamond(x, y, size)
    local w, h = size * 0.45, size * 0.55
    love.graphics.polygon("fill", x, y - h, x + w, y, x, y + h, x - w, y)
end

local function drawHeart(x, y, size)
    local r = size * 0.28
    love.graphics.circle("fill", x - r, y - r * 0.5, r)
    love.graphics.circle("fill", x + r, y - r * 0.5, r)
    love.graphics.polygon("fill",
        x - r * 1.95, y - r * 0.1,
        x + r * 1.95, y - r * 0.1,
        x, y + size * 0.6
    )
end

local function drawSpade(x, y, size)
    local r = size * 0.28
    love.graphics.circle("fill", x - r, y + r * 0.5, r)
    love.graphics.circle("fill", x + r, y + r * 0.5, r)
    love.graphics.polygon("fill",
        x - r * 1.95, y + r * 0.1,
        x + r * 1.95, y + r * 0.1,
        x, y - size * 0.6
    )
    love.graphics.polygon("fill", x, y, x - r, y + size * 0.65, x + r, y + size * 0.65)
end

local function drawClub(x, y, size)
    local r = size * 0.26
    love.graphics.circle("fill", x, y - r * 1.1, r)
    love.graphics.circle("fill", x - r * 1.05, y + r * 0.3, r)
    love.graphics.circle("fill", x + r * 1.05, y + r * 0.3, r)
    love.graphics.polygon("fill", x, y, x - r * 0.8, y + size * 0.65, x + r * 0.8, y + size * 0.65)
end

local function drawSuitSymbol(suit, x, y, size)
    if suit == "D" then
        drawDiamond(x, y, size)
    elseif suit == "H" then
        drawHeart(x, y, size)
    elseif suit == "S" then
        drawSpade(x, y, size)
    elseif suit == "C" then
        drawClub(x, y, size)
    end
end

local STYLE = {
    TEXT_SIZE = 27,
    TEXT_BOLD = 0,
    SUIT_SIZE = 16,
    SUIT_GAP = 4,
    PAD_X = 6,
    PAD_Y = 4,
    WATERMARK_SIZE = 52,
    CENTER_SUIT_SIZE = 28,
}

local CORNER_RANK_SCALE = {
    ["2"] = { x = 1.12, y = 1.08 },
}

local function parseCard(card_id)
    local joker_rank, joker_copy = tostring(card_id):match("^(BJ)%-(%d+)$")
    if joker_rank then
        return {
            kind = "joker",
            rank = I18n:t("gameplay.small_joker"),
            short_rank = "JOKER",
            suit = nil,
            copy_index = joker_copy,
        }
    end

    joker_rank, joker_copy = tostring(card_id):match("^(RJ)%-(%d+)$")
    if joker_rank then
        return {
            kind = "joker",
            rank = I18n:t("gameplay.big_joker"),
            short_rank = "JOKER",
            suit = nil,
            copy_index = joker_copy,
        }
    end

    local suit, rank, copy_index = tostring(card_id):match("^([SHCD])%-(%w+)%-(%d+)$")
    if suit and rank then
        return {
            kind = "normal",
            rank = rank,
            short_rank = rank,
            suit = suit,
            copy_index = copy_index,
        }
    end

    suit, rank = tostring(card_id):match("^([SHCD])%-(%w+)$")
    return {
        kind = "normal",
        rank = rank or "?",
        short_rank = rank or "?",
        suit = suit or "S",
        copy_index = copy_index,
    }
end

local function getSuitColor(theme_config, suit)
    local palette = (theme_config or {}).high_contrast and HIGH_CONTRAST_SUIT_COLORS or DEFAULT_SUIT_COLORS
    return palette[suit] or { 0.12, 0.15, 0.18, 1 }
end

function CardView.new()
    return setmetatable({
        font_cache = {},
        theme_manager = CardThemeManager.new(),
    }, CardView)
end

function CardView:_getCardFont(size)
    local font_path = FontConfig.resolveLocaleFontPath(
        FontConfig.card_face_font_path,
        FontConfig.card_face_locale_font_paths,
        I18n:getLocale()
    )
    local key = table.concat({ tostring(font_path), tostring(size) }, "::")
    if not self.font_cache[key] then
        local ok, font = pcall(love.graphics.newFont, font_path, size)
        self.font_cache[key] = ok and font or love.graphics.newFont(size)
    end

    return self.font_cache[key]
end

local function drawBoldText(text, x, y, boldness, color)
    local offset = math.max(0, math.floor(boldness or 0))
    local r, g, b, a = 0, 0, 0, 1
    if type(color) == "table" then
        r, g, b, a = color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1
    end

    if offset > 0 then
        love.graphics.setColor(0.02, 0.02, 0.03, (a or 1) * 0.55)
        love.graphics.print(text, x - offset, y)
        love.graphics.print(text, x + offset, y)
        love.graphics.print(text, x, y - offset)
        love.graphics.print(text, x, y + offset)
    end

    love.graphics.setColor(r, g, b, a)
    love.graphics.print(text, x, y)
end

local function drawScaledBoldText(text, x, y, scale_x, scale_y, boldness, color)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale_x or 1, scale_y or scale_x or 1)
    drawBoldText(text, 0, 0, boldness, color)
    love.graphics.pop()
end

local function drawVerticalBoldText(font, text, x, y, line_gap, boldness, color)
    love.graphics.setFont(font)
    local cursor_y = y
    for index = 1, #text do
        local char = text:sub(index, index)
        drawBoldText(char, x, cursor_y, boldness, color)
        cursor_y = cursor_y + font:getHeight() + line_gap
    end
end

local function drawVerticalText(font, text, x, y, line_gap, color)
    love.graphics.setFont(font)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    local cursor_y = y
    for index = 1, #text do
        local char = text:sub(index, index)
        love.graphics.print(char, x, cursor_y)
        cursor_y = cursor_y + font:getHeight() + line_gap
    end
end

local function getCornerRankScale(rank)
    local scale = CORNER_RANK_SCALE[tostring(rank or "")]
    if not scale then
        return 1, 1
    end
    return scale.x or 1, scale.y or 1
end

local function getFaceTint(display_state)
    local relation = tostring((display_state or {}).relation or (display_state or {}).play_relation or "neutral")
    return FACE_TINTS[relation] or FACE_TINTS.neutral
end

local function parseWildcardCard(wildcard_card)
    local suit, rank = tostring(wildcard_card or ""):match("^([SHCD])%-(%w+)$")
    return suit, rank
end

local function isWildcardCard(card, wildcard_card)
    if not card or card.kind ~= "normal" then
        return false
    end
    local wildcard_suit, wildcard_rank = parseWildcardCard(wildcard_card)
    return card.suit == wildcard_suit and tostring(card.rank) == tostring(wildcard_rank)
end

local function drawCardBorder(frame, border_color, display_state)
    love.graphics.setColor(border_color)
    love.graphics.setLineWidth(display_state.selected and 3 or 2)
    love.graphics.rectangle("line", frame.x, frame.y, frame.width, frame.height, 10, 10)
    love.graphics.setLineWidth(1)
end

function CardView:draw(card_id, frame, theme_config, display_state, fonts)
    local card = parseCard(card_id)
    display_state = display_state or {}
    local simple_face = display_state.simple_face == true
    local is_wildcard = isWildcardCard(card, display_state.wildcard_card or (theme_config or {}).wildcard_card)

    local border_color = { 0.2, 0.24, 0.3, 1 }
    if display_state.selected then
        border_color = { 0.98, 0.76, 0.28, 1 }
    elseif display_state.hovered then
        border_color = { 0.66, 0.8, 0.92, 1 }
    end

    local face_tint = getFaceTint(display_state)
    love.graphics.setColor(face_tint[1], face_tint[2], face_tint[3], face_tint[4] or 1)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 10, 10)

    local theme_id = ThemeCatalog.normalizeThemeId((theme_config or {}).theme_id)
    if card.kind == "joker" then
        if not simple_face then
            self.theme_manager:drawJoker(theme_id, frame, {
                is_big_joker = tostring(card_id):match("^RJ%-") ~= nil,
            })
            drawCardBorder(frame, border_color, display_state)
            return
        end

        local is_big = tostring(card_id):match("^RJ%-") ~= nil
        local text_color = is_big and { 0.82, 0.22, 0.2, 1 } or { 0.12, 0.14, 0.18, 1 }
        local top_text = "JOKER"
        local small_font_size = math.max(12, math.floor(frame.width * 0.16))
        local big_font_size = math.max(20, math.floor(frame.width * 0.28))

        local top_font = self:_getCardFont(small_font_size)
        love.graphics.setFont(top_font)
        love.graphics.setColor(text_color)
        local top_width = top_font:getWidth(top_text)
        local top_scale = 1
        if top_width > frame.width - 12 then
            top_scale = (frame.width - 12) / top_width
        end
        love.graphics.push()
        love.graphics.translate(frame.x + 8, frame.y + 6)
        love.graphics.scale(top_scale, top_scale)
        love.graphics.print(top_text, 0, 0)
        love.graphics.pop()

        local center_font = self:_getCardFont(big_font_size)
        local center_text = "JOKER"
        love.graphics.setFont(center_font)
        local max_width = frame.width - 12
        local text_width = center_font:getWidth(center_text)
        local draw_scale = 1
        if text_width > max_width then
            draw_scale = max_width / text_width
        end
        local cx = frame.x + (frame.width - text_width * draw_scale) * 0.5
        local cy = frame.y + (frame.height - center_font:getHeight() * draw_scale) * 0.5
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.scale(draw_scale, draw_scale)
        drawBoldText(center_text, 0, 0, 1, text_color)
        love.graphics.pop()

        drawCardBorder(frame, border_color, display_state)
        return
    end

    local suit_color = getSuitColor(theme_config, card.suit)
    local top_y = frame.y + STYLE.PAD_Y

    local rank_font = self:_getCardFont(STYLE.TEXT_SIZE)
    local watermark_font = self:_getCardFont(STYLE.WATERMARK_SIZE)
    local center_font = self:_getCardFont(STYLE.CENTER_SUIT_SIZE)

    love.graphics.setFont(rank_font)
    local rank_x = frame.x + STYLE.PAD_X
    local rank_y = top_y - 1
    local rank_scale_x, rank_scale_y = getCornerRankScale(card.short_rank)
    local rank_color = is_wildcard and WILDCARD_RANK_COLOR or { 0.05, 0.05, 0.07, 0.95 }
    local rank_boldness = is_wildcard and WILDCARD_RANK_BOLD or STYLE.TEXT_BOLD
    drawScaledBoldText(card.short_rank, rank_x, rank_y, rank_scale_x, rank_scale_y, rank_boldness, rank_color)

    local rank_width = rank_font:getWidth(card.short_rank) * rank_scale_x
    local rank_height = rank_font:getHeight() * rank_scale_y
    local suit_center_x = rank_x + rank_width + STYLE.SUIT_GAP + math.floor(STYLE.SUIT_SIZE * 0.5)
    local suit_center_y = rank_y + math.floor(rank_height * 0.46)
    love.graphics.setColor(suit_color)
    drawSuitSymbol(card.suit, suit_center_x, suit_center_y, STYLE.SUIT_SIZE)

    local face_rank = tostring(card.short_rank or "")
    if (not simple_face) and (face_rank == "J" or face_rank == "Q" or face_rank == "K") then
        local drawn = self.theme_manager:drawFace(theme_id, face_rank, frame, {
            suit = card.suit,
            suit_color = suit_color,
            rank = face_rank,
        })
        if drawn then
            drawCardBorder(frame, border_color, display_state)
            return
        end
    end

    local center_y = frame.y + math.floor(frame.height * 0.48)
    love.graphics.setFont(watermark_font)
    love.graphics.setColor(suit_color[1], suit_color[2], suit_color[3], 0.06)
    drawSuitSymbol(card.suit, frame.x + frame.width * 0.5, center_y, STYLE.WATERMARK_SIZE)

    love.graphics.setFont(center_font)
    love.graphics.setColor(suit_color[1], suit_color[2], suit_color[3], 0.92)
    drawSuitSymbol(card.suit, frame.x + frame.width * 0.5, center_y, STYLE.CENTER_SUIT_SIZE)

    drawCardBorder(frame, border_color, display_state)
end

return CardView
