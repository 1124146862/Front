local I18n = require("src.core.i18n.i18n")
local ButtonText = require("src.core.ui.button_text")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")
local Helpers = require("src.features.gameplay.controllers.helpers")
local TributeInfoOverlay = require("src.features.gameplay.overlays.tribute_info_overlay")
local TributeHandStrip = require("src.features.gameplay.components.tribute_hand_strip")
local CardView = require("src.features.gameplay.components.card_view")
local HandPinButton = require("src.features.gameplay.components.hand_pin_button")
local HandRankButton = require("src.features.gameplay.components.hand_rank_button")
local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")

local utf8lib = rawget(_G, "utf8")
if not utf8lib then
    local ok, loaded = pcall(require, "utf8")
    if ok and type(loaded) == "table" then
        utf8lib = loaded
    end
end

local TributeOverlay = {}
TributeOverlay.__index = TributeOverlay

local FLOW_STEPS = {
    { id = "anti_tribute", label_key = "gameplay.tribute_flow_step_anti" },
    { id = "tribute", label_key = "gameplay.tribute_flow_step_give" },
    { id = "return_tribute", label_key = "gameplay.tribute_flow_step_return" },
    { id = "result", label_key = "gameplay.tribute_flow_step_result" },
}

local AVATAR_FALLBACKS = { "avatar_9", "avatar_15", "avatar_21", "avatar_27" }
local OUTGOING_FLIGHT_DURATION = 0.42
local INCOMING_FLIGHT_DURATION = 0.50
	local HAND_AVATAR_CARD = {
	    side_padding = 14,
	    top_padding = 12,
	    pill_height = 24,
    avatar_top_gap = 12,
    text_gap = 10,
    meta_gap = 6,
    bottom_padding = 14,
    min_size = 64,
	    max_size = 118,
	}

	local RETURN_TRIBUTE_BUTTON_ENABLED = {
	    frame = { 0.67, 0.11, 0.12, 1 },
	    face = { 0.9, 0.2, 0.18, 1 },
	    shadow = { 0.31, 0.05, 0.05, 0.96 },
	    highlight = { 1, 0.79, 0.72, 0.3 },
	    border = { 0.45, 0.04, 0.05, 1 },
	    grain = { 0.55, 0.09, 0.09, 0.22 },
	    text = { 1, 0.94, 0.9, 1 },
	}

	local RETURN_TRIBUTE_BUTTON_HOVER = {
	    frame = { 0.74, 0.13, 0.12, 1 },
	    face = { 0.96, 0.25, 0.21, 1 },
	    shadow = { 0.35, 0.05, 0.05, 0.98 },
	    highlight = { 1, 0.86, 0.78, 0.34 },
	    border = { 0.52, 0.05, 0.05, 1 },
	    grain = { 0.62, 0.12, 0.1, 0.26 },
	    text = { 1, 0.96, 0.93, 1 },
	}

	local RETURN_TRIBUTE_BUTTON_DISABLED = {
	    frame = { 0.44, 0.2, 0.19, 0.98 },
	    face = { 0.66, 0.33, 0.31, 0.98 },
	    shadow = { 0.22, 0.1, 0.09, 0.84 },
	    highlight = { 0.95, 0.81, 0.78, 0.1 },
	    border = { 0.38, 0.15, 0.15, 0.72 },
	    grain = { 0.45, 0.23, 0.22, 0.12 },
	    text = { 0.98, 0.92, 0.89, 0.84 },
	}

	local function clamp(value, min_value, max_value)
	    if value < min_value then
	        return min_value
    end
    if value > max_value then
        return max_value
	    end
	    return value
	end

	local function getReturnTributeButtonPalette(enabled, hovered)
	    if not enabled then
	        return RETURN_TRIBUTE_BUTTON_DISABLED
	    end
	    if hovered then
	        return RETURN_TRIBUTE_BUTTON_HOVER
	    end
	    return RETURN_TRIBUTE_BUTTON_ENABLED
	end

local function contains(frame, x, y)
    return x >= frame.x and x <= frame.x + frame.width and y >= frame.y and y <= frame.y + frame.height
end

local function isContinuationByte(byte)
    return byte ~= nil and byte >= 0x80 and byte <= 0xBF
end

local function sanitizeUtf8(text)
    local value = tostring(text or "")
    if value == "" then
        return value
    end
    if utf8lib and utf8lib.len and pcall(utf8lib.len, value) then
        return value
    end

    local cleaned = {}
    local index = 1
    while index <= #value do
        local byte1 = string.byte(value, index)
        if not byte1 then
            break
        end
        if byte1 < 0x80 then
            cleaned[#cleaned + 1] = string.char(byte1)
            index = index + 1
        elseif byte1 >= 0xC2 and byte1 <= 0xDF then
            local byte2 = string.byte(value, index + 1)
            if isContinuationByte(byte2) then
                cleaned[#cleaned + 1] = value:sub(index, index + 1)
                index = index + 2
            else
                cleaned[#cleaned + 1] = "?"
                index = index + 1
            end
        elseif byte1 >= 0xE0 and byte1 <= 0xEF then
            local byte2 = string.byte(value, index + 1)
            local byte3 = string.byte(value, index + 2)
            local valid = isContinuationByte(byte2) and isContinuationByte(byte3)
            if valid and byte1 == 0xE0 then
                valid = byte2 >= 0xA0
            elseif valid and byte1 == 0xED then
                valid = byte2 <= 0x9F
            end
            if valid then
                cleaned[#cleaned + 1] = value:sub(index, index + 2)
                index = index + 3
            else
                cleaned[#cleaned + 1] = "?"
                index = index + 1
            end
        elseif byte1 >= 0xF0 and byte1 <= 0xF4 then
            local byte2 = string.byte(value, index + 1)
            local byte3 = string.byte(value, index + 2)
            local byte4 = string.byte(value, index + 3)
            local valid = isContinuationByte(byte2) and isContinuationByte(byte3) and isContinuationByte(byte4)
            if valid and byte1 == 0xF0 then
                valid = byte2 >= 0x90
            elseif valid and byte1 == 0xF4 then
                valid = byte2 <= 0x8F
            end
            if valid then
                cleaned[#cleaned + 1] = value:sub(index, index + 3)
                index = index + 4
            else
                cleaned[#cleaned + 1] = "?"
                index = index + 1
            end
        else
            cleaned[#cleaned + 1] = "?"
            index = index + 1
        end
    end
    return table.concat(cleaned)
end

local function utf8Length(text)
    local value = sanitizeUtf8(text)
    if value == "" then
        return 0
    end
    if utf8lib and utf8lib.len then
        local ok, length = pcall(utf8lib.len, value)
        if ok and type(length) == "number" then
            return length
        end
    end
    local _, count = string.gsub(value, "[^\128-\193]", "")
    return count
end

local function utf8Sub(text, start_char, end_char)
    local value = sanitizeUtf8(text)
    if value == "" then
        return value
    end
    start_char = math.max(tonumber(start_char) or 1, 1)
    end_char = end_char or -1
    local length = utf8Length(value)
    if end_char < 0 then
        end_char = length + end_char + 1
    end
    end_char = math.min(tonumber(end_char) or length, length)
    if start_char > end_char then
        return ""
    end
    if utf8lib and utf8lib.offset then
        local start_byte = utf8lib.offset(value, start_char)
        local end_byte = utf8lib.offset(value, end_char + 1)
        if not start_byte then
            return ""
        end
        if not end_byte then
            return value:sub(start_byte)
        end
        return value:sub(start_byte, end_byte - 1)
    end
    local start_byte = 1
    local current_char = 1
    while current_char < start_char and start_byte <= #value do
        local byte = string.byte(value, start_byte)
        if byte < 0x80 then
            start_byte = start_byte + 1
        elseif byte < 0xE0 then
            start_byte = start_byte + 2
        elseif byte < 0xF0 then
            start_byte = start_byte + 3
        else
            start_byte = start_byte + 4
        end
        current_char = current_char + 1
    end
    local end_byte = start_byte
    while current_char <= end_char and end_byte <= #value do
        local byte = string.byte(value, end_byte)
        if byte < 0x80 then
            end_byte = end_byte + 1
        elseif byte < 0xE0 then
            end_byte = end_byte + 2
        elseif byte < 0xF0 then
            end_byte = end_byte + 3
        else
            end_byte = end_byte + 4
        end
        current_char = current_char + 1
    end
    return value:sub(start_byte, end_byte - 1)
end

local function toRenderableText(font, text)
    local value = sanitizeUtf8(text)
    if value == "" then
        return value
    end

    local ok = pcall(font.getWidth, font, value)
    if ok then
        return value
    end

    local fallback = value:gsub("[\128-\255]", "?")
    ok = pcall(font.getWidth, font, fallback)
    if ok then
        return fallback
    end

    return "..."
end

local function safeFontWidth(font, text)
    local renderable = toRenderableText(font, text)
    local ok, width = pcall(font.getWidth, font, renderable)
    if ok and type(width) == "number" then
        return width, renderable
    end
    return 0, ""
end

local function textWidth(fonts, token, text)
    local width = safeFontWidth(fonts:get(token), text)
    return width
end

local function truncateText(fonts, token, text, max_width)
    local font = fonts:get(token)
    local value = toRenderableText(font, text)
    if value == "" then
        return value
    end
    if safeFontWidth(font, value) <= max_width then
        return value
    end
    local ellipsis = "..."
    local result = value
    local char_count = utf8Length(value)
    while char_count > 0 and safeFontWidth(font, result .. ellipsis) > max_width do
        char_count = char_count - 1
        result = utf8Sub(value, 1, char_count)
    end
    if result == "" then
        return ellipsis
    end
    return result .. ellipsis
end

local function measureWrappedText(font, text, width)
    local renderable = toRenderableText(font, text)
    if renderable == "" then
        return "", 0
    end

    local ok, _, wrapped = pcall(font.getWrap, font, renderable, math.max(1, width))
    if ok and type(wrapped) == "table" and #wrapped > 0 then
        return renderable, #wrapped * font:getHeight()
    end

    return renderable, font:getHeight()
end

local function buildFlowStepLabelSpec(fonts, text, max_width)
    local min_width = 88
    local horizontal_padding = 24
    local safe_max_width = math.max(min_width, math.floor(tonumber(max_width) or min_width))
    local font_tokens = { "Caption", "Label" }

    for _, token in ipairs(font_tokens) do
        local font = fonts:get(token)
        local label_width, renderable = safeFontWidth(font, text)
        local button_width = math.max(min_width, math.ceil(label_width + horizontal_padding))
        if button_width <= safe_max_width then
            return {
                font_token = token,
                text = renderable,
                width = button_width,
            }
        end
    end

    local fallback_token = "Label"
    local truncated = truncateText(fonts, fallback_token, text, safe_max_width - horizontal_padding)
    local fallback_width, renderable = safeFontWidth(fonts:get(fallback_token), truncated)
    return {
        font_token = fallback_token,
        text = renderable,
        width = math.max(min_width, math.min(safe_max_width, math.ceil(fallback_width + horizontal_padding))),
    }
end

local function buildHandAvatarCardLayout(fonts, card_frame)
    if not fonts or not card_frame then
        return nil
    end

    local name_font = fonts:get("Text")
    local meta_font = fonts:get("TextSmall")
    local name_height = name_font:getHeight()
    local meta_height = meta_font:getHeight()
    local footer_height = name_height + HAND_AVATAR_CARD.meta_gap + meta_height
    local avatar_top = card_frame.y + HAND_AVATAR_CARD.top_padding + HAND_AVATAR_CARD.pill_height + HAND_AVATAR_CARD.avatar_top_gap
    local max_width = math.max(
        HAND_AVATAR_CARD.min_size,
        card_frame.width - HAND_AVATAR_CARD.side_padding * 2
    )
    local max_height = math.max(
        HAND_AVATAR_CARD.min_size,
        card_frame.y + card_frame.height
            - HAND_AVATAR_CARD.bottom_padding
            - footer_height
            - HAND_AVATAR_CARD.text_gap
            - avatar_top
    )
    local preferred_size = math.floor(math.min(max_width, max_height))
    local avatar_size = math.min(HAND_AVATAR_CARD.max_size, preferred_size)
    avatar_size = math.max(HAND_AVATAR_CARD.min_size, avatar_size)
    avatar_size = math.min(avatar_size, math.floor(max_width), math.floor(max_height))
    avatar_size = math.max(1, avatar_size)

    local avatar_x = card_frame.x + math.floor((card_frame.width - avatar_size) * 0.5)
    local name_y = avatar_top + avatar_size + HAND_AVATAR_CARD.text_gap
    local meta_y = name_y + name_height + HAND_AVATAR_CARD.meta_gap

    return {
        avatar = {
            x = avatar_x,
            y = avatar_top,
            width = avatar_size,
            height = avatar_size,
        },
        name_y = name_y,
        meta_y = meta_y,
        footer_top = name_y - 8,
        footer_height = math.max(
            38,
            card_frame.y + card_frame.height - 18 - (name_y - 8)
        ),
    }
end

local function showsHand(phase)
    return phase == "self_tribute"
        or phase == "waiting_tribute"
        or phase == "self_return_tribute"
        or phase == "waiting_return_tribute"
end

local function isManualActionPhase(phase)
    return phase == "self_tribute"
        or phase == "self_return_tribute"
end

local function hasCandidateCards(tribute)
    return type((tribute or {}).candidate_cards) == "table" and #((tribute or {}).candidate_cards) > 0
end

local function canInteractWithHandSelection(state, tribute)
    return showsHand(tostring((tribute or {}).phase or ""))
        and state.action_waiting ~= true
end

local function canSubmitTributeAction(state, tribute)
    return canInteractWithHandSelection(state, tribute)
        and hasCandidateCards(tribute)
        and state.selected_tribute_card_id ~= nil
end

local function isAntiPhase(phase)
    return phase == "anti_tribute"
end

local function isChineseLocale()
    local locale = string.lower(tostring(I18n:getLocale() or ""))
    return locale == "zh-cn" or locale == "zh-tw"
end

local function getPhaseStepIndex(phase)
    if phase == "anti_tribute" then
        return 1
    end
    if phase == "self_tribute" or phase == "waiting_tribute" then
        return 2
    end
    if phase == "self_return_tribute" or phase == "waiting_return_tribute" then
        return 3
    end
    if phase == "result" then
        return 4
    end
    return 0
end

local function getFlowStepOrder(step_id)
    if step_id == "anti_tribute" then
        return 1
    end
    if step_id == "tribute" then
        return 2
    end
    if step_id == "return_tribute" then
        return 3
    end
    if step_id == "result" then
        return 4
    end
    return 0
end

local function getFlowStepVisualState(tribute, phase, step_id)
    local anti_tribute = ((tribute or {}).anti_tribute) == true
    if anti_tribute and phase == "result" then
        if step_id == "anti_tribute" then
            return "done"
        end
        if step_id == "result" then
            return "active"
        end
        return "skipped"
    end

    local current_step = getPhaseStepIndex(phase)
    local target_step = getFlowStepOrder(step_id)
    if current_step > target_step then
        return "done"
    end
    if current_step == target_step then
        return "active"
    end
    return "pending"
end

local function getPlayerBySeat(players, seat_index)
    local target = tonumber(seat_index)
    if not target then
        return nil
    end
    for _, player in ipairs(players or {}) do
        if tonumber(player.seat_index) == target then
            return player
        end
    end
    return nil
end

local function getMyTeamId(game)
    local my_seat = tonumber((game or {}).my_seat_index)
    for _, player in ipairs((game or {}).players or {}) do
        if tonumber(player.seat_index) == my_seat then
            return tonumber(player.team_id)
        end
    end
    return nil
end

local function getAntiTributeDisplayInfo(game, tribute)
    local my_team_id = getMyTeamId(game)
    local anti_team_id = tonumber((tribute or {}).anti_tribute_team_id)
    return {
        is_self_team = my_team_id ~= nil and anti_team_id ~= nil and my_team_id == anti_team_id,
    }
end

local function buildAntiJudgementCopy(game, tribute, colors)
    local anti_info = getAntiTributeDisplayInfo(game, tribute)
    local has_anti = tribute.anti_tribute == true
    local accent = colors.accent

    if has_anti then
        if anti_info.is_self_team then
            return I18n:t("gameplay.anti_judgement_status_self"), I18n:t("gameplay.anti_judgement_self_detail"), accent
        end
        return I18n:t("gameplay.anti_judgement_status_opponent"), I18n:t("gameplay.anti_judgement_opponent_detail"), colors.error or { 0.74, 0.30, 0.24, 1 }
    end

    return I18n:t("gameplay.anti_judgement_status_none"), I18n:t("gameplay.anti_judgement_none_detail"), colors.text_muted or colors.hud_subtext or { 0.4, 0.4, 0.4, 1 }
end

local function getAntiTributeBigJokerSeats(tribute)
    local seats = {}
    for _, seat in ipairs(((tribute or {}).anti_tribute_big_joker_seats) or {}) do
        local numeric = tonumber(seat)
        if numeric ~= nil then
            seats[#seats + 1] = numeric
        end
    end
    return seats
end

local function countMyBigJokers(game)
    local count = 0
    for _, card_id in ipairs(((game or {}).my_hand_cards) or {}) do
        if tostring(card_id):match("^RJ%-") ~= nil then
            count = count + 1
        end
    end
    return count
end

local function getSeatDisplay(game, seat_index)
    local seat = tonumber(seat_index)
    if not seat then
        return I18n:t("common.none")
    end
    local player = getPlayerBySeat((game or {}).players or {}, seat)
    local relation = Helpers.getRelativePositionLabel(tonumber((game or {}).my_seat_index) or 0, seat)
    local nickname = sanitizeUtf8((player or {}).nickname or "-")
    return string.format("%s %s", relation, nickname)
end

local function hasDisplayableSeat(game, seat_index)
    local seat = tonumber(seat_index)
    if seat == nil then
        return false
    end
    return getPlayerBySeat((game or {}).players or {}, seat) ~= nil
end

local function buildTributeRouteText(game, from_seat, to_seat, action_label)
    if not hasDisplayableSeat(game, from_seat) or not hasDisplayableSeat(game, to_seat) then
        return ""
    end
    local from_text = sanitizeUtf8(getSeatDisplay(game, from_seat))
    local to_text = sanitizeUtf8(getSeatDisplay(game, to_seat))
    local action_text = sanitizeUtf8(action_label or "")
    if from_text == "" or to_text == "" or action_text == "" then
        return ""
    end

    if isChineseLocale() then
        return string.format("%s \229\144\145 %s %s", from_text, to_text, action_text)
    end

    return string.format("%s -> %s %s", from_text, to_text, action_text)
end

local function buildTributeHeaderStatus(game, tribute)
    local phase = tostring((tribute or {}).phase or "")
    if phase == "self_tribute" or phase == "waiting_tribute" then
        return buildTributeRouteText(game, tribute.giver_seat, tribute.receiver_seat, I18n:t("gameplay.tribute_flow_step_give"))
    end
    if phase == "self_return_tribute" or phase == "waiting_return_tribute" then
        return buildTributeRouteText(game, tribute.giver_seat, tribute.receiver_seat, I18n:t("gameplay.tribute_flow_step_return"))
    end
    return ""
end

local function buildTributePhaseFallbackStatus(phase)
    if phase == "anti_tribute" then
        return I18n:t("gameplay.tribute_flow_step_anti")
    end
    if phase == "self_tribute" or phase == "waiting_tribute" then
        return I18n:t("gameplay.tribute_flow_step_give")
    end
    if phase == "self_return_tribute" or phase == "waiting_return_tribute" then
        return I18n:t("gameplay.tribute_flow_step_return")
    end
    if phase == "result" then
        return I18n:t("gameplay.tribute_flow_step_result")
    end
    return I18n:t("gameplay.tribute_status")
end

local function isSuspiciousTributeStatusText(text)
    local value = sanitizeUtf8(text)
    local none_label = sanitizeUtf8(I18n:t("common.none"))
    if value == "" or none_label == "" then
        return false
    end
    if value:find("-> " .. none_label, 1, true) ~= nil then
        return true
    end

    if value:find(none_label, 1, true) == nil then
        return false
    end

    local tribute_label = sanitizeUtf8(I18n:t("gameplay.tribute_flow_step_give"))
    local return_label = sanitizeUtf8(I18n:t("gameplay.tribute_flow_step_return"))
    return (tribute_label ~= "" and value:find(tribute_label, 1, true) ~= nil)
        or (return_label ~= "" and value:find(return_label, 1, true) ~= nil)
end

local replaceSeatTokensWithRelativeLabels

local function buildTributeHeaderText(game, tribute)
    local phase = tostring((tribute or {}).phase or "")
    if isAntiPhase(phase) then
        return buildTributePhaseFallbackStatus(phase)
    end

    local route_status = buildTributeHeaderStatus(game, tribute)
    if route_status ~= "" then
        return route_status
    end

    local message_status = replaceSeatTokensWithRelativeLabels(game, (tribute or {}).message or "")
    if message_status ~= "" and not isSuspiciousTributeStatusText(message_status) then
        return message_status
    end

    return buildTributePhaseFallbackStatus(phase)
end

replaceSeatTokensWithRelativeLabels = function(game, text)
    local value = sanitizeUtf8(text)
    if value == "" then
        return value
    end
    local my_seat = tonumber((game or {}).my_seat_index) or 0
    local function resolveSeatLabel(seat_text)
        local seat = tonumber(seat_text)
        if not seat then
            return "Seat" .. tostring(seat_text or "")
        end
        return Helpers.getRelativePositionLabel(my_seat, seat)
    end
    value = value:gsub("Seat(%d+)%b[]", resolveSeatLabel)
    value = value:gsub("Seat(%d+)", resolveSeatLabel)
    return value
end

local function parseTributeReceiverSeat(entry)
    local explicit = tonumber((entry or {}).receiver_seat)
    if explicit ~= nil then
        return explicit
    end
    local summary = tostring((entry or {}).summary or "")
    local giver_seat, receiver_seat = summary:match("^Seat(%d+)%b[] 向 Seat(%d+)%b[] 贡牌")
    if giver_seat and receiver_seat then
        return tonumber(receiver_seat)
    end
    local receiver_only = summary:match("向 Seat(%d+)%b[] 贡牌")
    return receiver_only and tonumber(receiver_only) or nil
end

local function findLatestTributeEntryForReceiver(history, receiver_seat)
    local target_receiver = tonumber(receiver_seat)
    if not target_receiver then
        return nil
    end
    for index = #(history or {}), 1, -1 do
        local entry = history[index]
        if tostring((entry or {}).action_type or "") == "tribute" and parseTributeReceiverSeat(entry) == target_receiver then
            return entry
        end
    end
    return nil
end

local function resolveAvatarId(player)
    local avatar_id = tostring((player or {}).avatar_id or "")
    if avatar_id ~= "" then
        return avatar_id
    end
    local seat_index = tonumber((player or {}).seat_index) or 0
    return AVATAR_FALLBACKS[(seat_index % #AVATAR_FALLBACKS) + 1]
end

local function resolveAccessories(player, my_seat_index, my_accessories)
    if type((player or {}).accessories) == "table" then
        return player.accessories
    end
    if tonumber((player or {}).seat_index) == tonumber(my_seat_index) and type(my_accessories) == "table" then
        return my_accessories
    end
    return nil
end

function TributeOverlay.new(options)
    local self = setmetatable({}, TributeOverlay)
    self.fonts = assert(options and options.fonts, "TributeOverlay requires fonts")
    self.style = assert(options and options.style, "TributeOverlay requires style")
    self.panel = WoodPanel.new(self.style)
    self.info_overlay = TributeInfoOverlay.new({ fonts = self.fonts, style = self.style })
    self.hand_strip = TributeHandStrip.new({ fonts = self.fonts })
    self.card_view = CardView.new()
    self.pin_button = HandPinButton.new()
    self.rank_button = HandRankButton.new()
    self.avatars_by_id = {}
    for _, avatar in ipairs(AvatarRegistry) do
        self.avatars_by_id[avatar.id] = avatar
    end
    self.active_transfer = nil
    self.last_action_waiting = false
    self.last_phase = ""
    self.action_attention_time = 0
    return self
end

function TributeOverlay:_getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_w = math.max(820, math.min(1080, width - 72))
    local panel_h = math.max(520, math.min(660, height - 56))
    return {
        x = math.floor((width - panel_w) * 0.5),
        y = math.floor((height - panel_h) * 0.5),
        width = panel_w,
        height = panel_h,
    }
end

function TributeOverlay:_getDisplayGame(state)
    local runtime_game = ((state or {}).game) or {}
    local snapshot_game = ((state or {}).tribute_overlay_snapshot)
    if tostring((state or {}).ui_phase or "") == "tribute"
        and not Helpers.hasActiveTribute(runtime_game)
        and snapshot_game ~= nil
    then
        return snapshot_game
    end
    return runtime_game
end

function TributeOverlay:_getFrames(state)
    local panel = self:_getPanelFrame()
    local inner = {
        x = panel.x + 24,
        y = panel.y + 24,
        width = panel.width - 48,
        height = panel.height - 48,
    }
    local game = self:_getDisplayGame(state)
    local tribute = ((game or {}).tribute) or {}
    local phase = tostring(tribute.phase or "")
    local gap = 12
    local header_h = 80
    local flow_h = 84
    local content_top = inner.y + header_h + gap + flow_h + gap

	    if showsHand(phase) then
	        local hand_height = inner.height - header_h - flow_h - gap * 2
	        local hand_panel = {
            x = inner.x,
            y = content_top,
            width = inner.width,
            height = math.max(290, hand_height),
        }
        local content_padding = 18
        local sidebar_gap = 18
        local sidebar_width = clamp(math.floor(hand_panel.width * 0.22), 176, 228)
        local hand = {
            x = hand_panel.x + content_padding,
            y = hand_panel.y + content_padding,
            width = hand_panel.width - content_padding * 2 - sidebar_width - sidebar_gap,
            height = hand_panel.height - content_padding * 2,
        }
	        local sidebar = {
	            x = hand.x + hand.width + sidebar_gap,
	            y = hand.y,
	            width = hand_panel.x + hand_panel.width - content_padding - (hand.x + hand.width + sidebar_gap),
	            height = hand.height,
	        }
	        local is_return_action = tribute.action_type == "return_tribute"
	        local action_gap = is_return_action and 12 or 10
	        local action_button
	        if is_return_action then
	            local button_height = clamp(math.floor(sidebar.height * 0.31), 102, 128)
	            action_button = {
	                x = sidebar.x + 4,
	                y = sidebar.y + sidebar.height - button_height - 4,
	                width = sidebar.width - 8,
	                height = button_height,
	                radius = 18,
	            }
	        else
	            local button_size = clamp(
	                math.floor(math.min(sidebar.width - 12, sidebar.height * 0.30)),
	                108,
	                math.max(108, sidebar.width - 12)
	            )
	            action_button = {
	                x = sidebar.x + math.floor((sidebar.width - button_size) * 0.5),
	                y = sidebar.y + sidebar.height - button_size - 4,
	                width = button_size,
	                height = button_size,
	                radius = 22,
	            }
	        end
	        local avatar_card = {
	            x = sidebar.x,
	            y = sidebar.y,
	            width = sidebar.width,
	            height = math.max(168, action_button.y - sidebar.y - action_gap),
	        }
	        return {
	            panel = panel,
            header = { x = inner.x, y = inner.y, width = inner.width, height = header_h },
            flow = { x = inner.x, y = inner.y + header_h + gap, width = inner.width, height = flow_h },
            hand_panel = hand_panel,
            hand = hand,
            hand_sidebar = sidebar,
            avatar_card = avatar_card,
            action_button = action_button,
        }
    end

    return {
        panel = panel,
        header = { x = inner.x, y = inner.y, width = inner.width, height = header_h },
        flow = { x = inner.x, y = inner.y + header_h + gap, width = inner.width, height = flow_h },
        main = { x = inner.x, y = content_top, width = inner.width, height = inner.height - header_h - flow_h - gap * 2 },
    }
end
function TributeOverlay:_getHandAvatarContext(state)
    local game = self:_getDisplayGame(state)
    local tribute = game.tribute or {}
    local phase = tostring(tribute.phase or "")
    local seat = nil
    local title = nil

    if phase == "self_tribute" or phase == "waiting_tribute" then
        seat = tribute.receiver_seat
        title = I18n:t("gameplay.tribute_task_receiver")
    elseif phase == "self_return_tribute" or phase == "waiting_return_tribute" then
        seat = tribute.receiver_seat
        title = I18n:t("gameplay.tribute_task_giver")
    end

    local player = getPlayerBySeat(game.players or {}, seat)
    if not player then
        return nil
    end

    return {
        player = player,
        title = title,
        nickname = sanitizeUtf8((player or {}).nickname or "-"),
        relation = Helpers.getRelativePositionLabel(tonumber(game.my_seat_index) or 0, tonumber(seat) or 0),
        subtitle = getSeatDisplay(game, seat),
    }
end

function TributeOverlay:_getHandAvatarFrame(frames)
    local avatar_card = (frames or {}).avatar_card
    local layout = buildHandAvatarCardLayout(self.fonts, avatar_card)
    return layout and layout.avatar or nil
end

function TributeOverlay:_getHandButtonBounds(frames)
    local hand = (frames or {}).hand
    if not hand then
        return nil
    end

    local pin_w, pin_h = self.pin_button:getSize()
    local rank_w, rank_h = self.rank_button:getSize()
    local padding = 12

    return {
        pin = {
            x = hand.x + padding,
            y = hand.y + padding,
            w = pin_w,
            h = pin_h,
        },
        rank = {
            x = hand.x + hand.width - rank_w - padding,
            y = hand.y + padding,
            w = rank_w,
            h = rank_h,
        },
    }
end

function TributeOverlay:_getHandStripOptions(state, frames)
    local hidden_card_ids = {}
    if self.active_transfer and self.active_transfer.hide_card_in_hand == true and self.active_transfer.card_id then
        hidden_card_ids[self.active_transfer.card_id] = true
    end
    local button_bounds = self:_getHandButtonBounds(frames)
    local top_reserve = 18
    if button_bounds then
        top_reserve = math.max(
            top_reserve,
            math.max(button_bounds.pin.h or 0, button_bounds.rank.h or 0) + 24
        )
    end
    return {
        hidden_card_ids = hidden_card_ids,
        insets = {
            top = top_reserve,
            left = 18,
            right = 18,
            bottom = 18,
        },
    }
end

function TributeOverlay:_buildFlightTargetFromAvatar(frame)
    if not frame then
        return nil
    end
    return {
        x = frame.x + math.floor(frame.width * 0.16),
        y = frame.y + math.floor(frame.height * 0.12),
        width = math.floor(frame.width * 0.68),
        height = math.floor(frame.height * 0.78),
    }
end

function TributeOverlay:_startFlight(card_id, source_bounds, target_bounds, duration)
    if not card_id or not source_bounds or not target_bounds then
        return
    end
    self.active_transfer = {
        card_id = card_id,
        source = source_bounds,
        target = target_bounds,
        elapsed = 0,
        duration = duration,
        hide_card_in_hand = true,
    }
end

function TributeOverlay:_tryStartOutgoingFlight(state, frames)
    local tribute = (self:_getDisplayGame(state).tribute) or {}
    if tostring(tribute.phase or "") ~= "self_tribute" then
        return
    end
    if state.action_waiting ~= true or self.last_action_waiting == true then
        return
    end

    local card_id = state.selected_tribute_card_id
    local source_bounds = self.hand_strip:getCardBounds(card_id)
    local target_bounds = self:_buildFlightTargetFromAvatar(self:_getHandAvatarFrame(frames))
    self:_startFlight(card_id, source_bounds, target_bounds, OUTGOING_FLIGHT_DURATION)
end

function TributeOverlay:_tryStartIncomingFlight(state, frames)
    local game = self:_getDisplayGame(state)
    local tribute = game.tribute or {}
    if tostring(tribute.phase or "") ~= "self_return_tribute" or self.last_phase == "self_return_tribute" then
        return
    end

    local latest_tribute = findLatestTributeEntryForReceiver(game.history or {}, game.my_seat_index)
    local card_id = latest_tribute and ((latest_tribute.cards or {})[1]) or nil
    local source_bounds = self:_buildFlightTargetFromAvatar(self:_getHandAvatarFrame(frames))
    local target_bounds = self.hand_strip:getCardBounds(card_id)
    self:_startFlight(card_id, source_bounds, target_bounds, INCOMING_FLIGHT_DURATION)
end

function TributeOverlay:_updateTransfer(dt)
    if not self.active_transfer then
        return
    end
    self.active_transfer.elapsed = self.active_transfer.elapsed + dt
    if self.active_transfer.elapsed >= self.active_transfer.duration then
        self.active_transfer = nil
    end
end

function TributeOverlay:update(dt, state)
    self.action_attention_time = (tonumber(self.action_attention_time) or 0) + dt
    local tribute = (self:_getDisplayGame(state).tribute) or nil
    if not tribute then
        self.active_transfer = nil
        self.last_action_waiting = false
        self.last_phase = ""
        self.rank_button:update(dt, false)
        self.pin_button:update(dt, false, false)
        return
    end

    local phase = tostring(tribute.phase or "")
    local frames = self:_getFrames(state)
    if showsHand(phase) then
        self.hand_strip:update(dt, frames.hand, state, self:_getHandStripOptions(state, frames))
        local can_arrange = state.action_waiting ~= true
        self.rank_button:update(dt, can_arrange and state.hovered_tribute_control == "rank_hand_cards")
        self.pin_button:update(
            dt,
            can_arrange and state.hovered_tribute_control == "pin_selected_cards",
            can_arrange and state.selected_tribute_card_id ~= nil
        )
        if not self.active_transfer then
            self:_tryStartOutgoingFlight(state, frames)
            if not self.active_transfer then
                self:_tryStartIncomingFlight(state, frames)
            end
        end
    else
        self.active_transfer = nil
        self.rank_button:update(dt, false)
        self.pin_button:update(dt, false, false)
    end

    self:_updateTransfer(dt)
    self.last_action_waiting = state.action_waiting == true
    self.last_phase = phase
end

function TributeOverlay:getHoveredCardId(x, y, state)
    local tribute = (self:_getDisplayGame(state).tribute) or nil
    if not tribute then
        return nil
    end
    if not canInteractWithHandSelection(state, tribute) then
        return nil
    end
    local frames = self:_getFrames(state)
    return self.hand_strip:getHoveredCardId(x, y, frames.hand, state, self:_getHandStripOptions(state, frames))
end

function TributeOverlay:getControlAt(x, y, state)
    local tribute = (self:_getDisplayGame(state).tribute) or nil
    if not tribute then
        return nil
    end
    if showsHand(tribute.phase) then
        local button_bounds = self:_getHandButtonBounds(self:_getFrames(state))
        if button_bounds and state.action_waiting ~= true then
            if self.rank_button:contains(button_bounds.rank, x, y) then
                return "rank_hand_cards"
            end
            if self.pin_button:contains(button_bounds.pin, x, y) then
                return "pin_selected_cards"
            end
        end
    end
    if showsHand(tribute.phase) then
        local frame = self:_getFrames(state).action_button
        local can_submit = canSubmitTributeAction(state, tribute)
        if contains(frame, x, y) and can_submit then
            return tribute.action_type == "return_tribute" and "submit_return_tribute" or "submit_tribute"
        end
    end
    return nil
end

function TributeOverlay:_drawHandControls(frames)
    local button_bounds = self:_getHandButtonBounds(frames)
    if not button_bounds then
        return
    end

    self.pin_button:draw(button_bounds.pin, {
        visible = true,
    })
    self.rank_button:draw(button_bounds.rank, {
        visible = true,
    })
end

function TributeOverlay:_drawSoftSection(frame)
    local colors = self.style.colors
    love.graphics.setColor(colors.panel_shadow)
    love.graphics.rectangle("fill", frame.x, frame.y + 4, frame.width, frame.height, 16, 16)
    love.graphics.setColor(colors.panel_inner)
    love.graphics.rectangle("fill", frame.x + 2, frame.y + 2, frame.width - 4, frame.height - 4, 14, 14)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(colors.panel_border)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 15, 15)
    love.graphics.setLineWidth(1)
end

function TributeOverlay:_drawPill(x, y, text, options)
    local colors = self.style.colors
    options = options or {}
    local font_token = options.font_token or "Caption"
    local font = self.fonts:get(font_token)
    local safe_text = toRenderableText(font, text)
    local width = options.width or (safeFontWidth(font, safe_text) + 24)
    local height = options.height or 30
    local fill = options.fill or colors.card_alt
    local border = options.border or colors.panel_border
    local text_color = options.text_color or colors.text_primary

    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", x, y, width, height, 15, 15)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(border)
    love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, 15, 15)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(text_color)
    love.graphics.setFont(font)
    love.graphics.printf(safe_text, x, y + math.floor((height - self.fonts:getSize(font_token)) * 0.5) - 1, width, "center")
end

function TributeOverlay:_drawHeader(state, frames)
    local colors = self.style.colors
    local game = self:_getDisplayGame(state)
    local tribute = game.tribute or {}
    local header = frames.header
    local duration = tonumber(state.tribute_countdown_duration or 0) or 0
    local remaining = tonumber(state.tribute_countdown_remaining or 0) or 0
    local ratio = duration > 0 and math.max(0, math.min(1, remaining / duration)) or 1
    local bar_x = header.x + 8
    local bar_y = header.y + 4
    local bar_w = header.width - 16
    local bar_h = 12

    love.graphics.setColor(colors.card_alt)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h, 6, 6)
    love.graphics.setColor(colors.accent)
    love.graphics.rectangle("fill", bar_x, bar_y, math.floor(bar_w * ratio), bar_h, 6, 6)

    ButtonText.draw(
        self.fonts:get("Text"),
        I18n:t("gameplay.tribute_title"),
        header.x + 8,
        header.y + 24,
        220,
        "left",
        colors.hud_title,
        { bold = true }
    )

    local status_source = buildTributeHeaderText(game, tribute)
    local status_text = truncateText(self.fonts, "TextSmall", status_source, header.width - 20)
    ButtonText.draw(
        self.fonts:get("TextSmall"),
        status_text,
        header.x + 10,
        header.y + 48,
        header.width - 20,
        "center",
        colors.hud_subtext,
        { bold = true }
    )
end

function TributeOverlay:_drawAntiSummaryPanel(frame, summary, detail, accent)
    local colors = self.style.colors
    self:_drawSoftSection(frame)

    love.graphics.setColor(accent[1], accent[2], accent[3], 0.14)
    love.graphics.rectangle("fill", frame.x + 16, frame.y + 18, frame.width - 32, frame.height - 36, 22, 22)

    local summary_token = isChineseLocale() and "Title2" or "Title3"
    local summary_font = self.fonts:get(summary_token)
    local detail_font = self.fonts:get("TextSmall")
    local summary_width = frame.width - 56
    local detail_width = frame.width - 72
    local safe_summary, summary_height = measureWrappedText(summary_font, summary, summary_width)
    local safe_detail, detail_height = measureWrappedText(detail_font, detail, detail_width)
    local gap = safe_detail ~= "" and 18 or 0
    local total_height = summary_height + gap + detail_height
    local start_y = frame.y + math.floor((frame.height - total_height) * 0.5)

    love.graphics.setColor(colors.hud_title)
    love.graphics.setFont(summary_font)
    love.graphics.printf(safe_summary, frame.x + 28, start_y, summary_width, "center")

    if safe_detail ~= "" then
        love.graphics.setColor(colors.hud_subtext)
        love.graphics.setFont(detail_font)
        love.graphics.printf(safe_detail, frame.x + 36, start_y + summary_height + gap, detail_width, "center")
    end
end

function TributeOverlay:_drawAntiJokerColumn(game, frame, seat_index, slot_index, theme_config, my_accessories, options)
    local colors = self.style.colors
    options = options or {}
    local joker_count = tonumber(options.joker_count)
    if joker_count == nil then
        joker_count = seat_index ~= nil and 1 or 0
    end
    self:_drawSoftSection(frame)

    self:_drawPill(frame.x + math.floor((frame.width - 84) * 0.5), frame.y + 12, "JOKER", {
        width = 84,
        height = 24,
        font_token = "Label",
        fill = colors.card_alt,
        border = colors.panel_border,
        text_color = colors.text_primary,
    })

    if seat_index == nil then
        love.graphics.setColor(colors.panel_grain[1], colors.panel_grain[2], colors.panel_grain[3], 0.18)
        love.graphics.rectangle("fill", frame.x + 18, frame.y + 58, frame.width - 36, frame.height - 76, 20, 20)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(colors.button_disabled_border)
        love.graphics.rectangle("line", frame.x + 19, frame.y + 59, frame.width - 38, frame.height - 78, 20, 20)
        love.graphics.setLineWidth(1)

        love.graphics.setColor(colors.text_muted)
        love.graphics.setFont(self.fonts:get("Text"))
        love.graphics.printf(I18n:t("gameplay.no_big_joker"), frame.x + 18, frame.y + math.floor(frame.height * 0.48), frame.width - 36, "center")
        return
    end

    local player = getPlayerBySeat((game or {}).players or {}, seat_index)
    local avatar = player and self.avatars_by_id[resolveAvatarId(player)] or nil
    local avatar_size = clamp(math.floor(math.min(frame.width, frame.height) * 0.26), 64, 84)
    local avatar_x = frame.x + math.floor((frame.width - avatar_size) * 0.5)
    local avatar_y = frame.y + 46

    if avatar then
        love.graphics.setColor(colors.panel_shadow[1], colors.panel_shadow[2], colors.panel_shadow[3], 0.16)
        love.graphics.rectangle("fill", avatar_x - 4, avatar_y + 4, avatar_size + 8, avatar_size + 8, 16, 16)
        AvatarTile.draw(self.style, avatar, {
            x = avatar_x,
            y = avatar_y,
            w = avatar_size,
            h = avatar_size,
        }, {
            compact = true,
            pin_frame = true,
            selected = true,
            content_padding_ratio = 0.03,
            accessories = resolveAccessories(player, game.my_seat_index, my_accessories),
        })
    end

    love.graphics.setColor(colors.hud_text)
    love.graphics.setFont(self.fonts:get("Label"))
    love.graphics.printf(
        truncateText(self.fonts, "Label", getSeatDisplay(game, seat_index), frame.width - 24),
        frame.x + 12,
        avatar_y + avatar_size + 8,
        frame.width - 24,
        "center"
    )

    if joker_count <= 0 then
        love.graphics.setColor(colors.panel_grain[1], colors.panel_grain[2], colors.panel_grain[3], 0.18)
        love.graphics.rectangle("fill", frame.x + 18, frame.y + frame.height - 140, frame.width - 36, 88, 18, 18)
        love.graphics.setColor(colors.text_muted)
        love.graphics.setFont(self.fonts:get("Text"))
        love.graphics.printf(
            I18n:t("gameplay.no_big_joker"),
            frame.x + 24,
            frame.y + frame.height - 108,
            frame.width - 48,
            "center"
        )
        return
    end

    local card_w = clamp(math.floor(frame.width * 0.58), 92, 118)
    local card_h = math.floor(card_w * 1.42)
    local card_x = frame.x + math.floor((frame.width - card_w) * 0.5)
    local card_y = math.min(frame.y + frame.height - card_h - 18, avatar_y + avatar_size + 42)
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.rectangle("fill", card_x + 4, card_y + 6, card_w, card_h, 12, 12)
    self.card_view:draw(
        slot_index == 1 and "RJ-1" or "RJ-2",
        { x = card_x, y = card_y, width = card_w, height = card_h },
        theme_config or {},
        { selected = true },
        self.fonts
    )
end

function TributeOverlay:_drawFlow(tribute, phase, frame)
    local colors = self.style.colors
    local accent = colors.accent
    local ink = colors.hud_text
    local muted = colors.text_muted
    local center_y = frame.y + 30
    local count = #FLOW_STEPS
    local start_x = frame.x + 60
    local end_x = frame.x + frame.width - 60
    local spacing = count > 1 and (end_x - start_x) / (count - 1) or 0
    local max_label_width = math.max(88, math.floor((spacing > 0 and spacing or (frame.width / math.max(count, 1))) - 16))
    local label_specs = {}

    for index, step in ipairs(FLOW_STEPS) do
        label_specs[index] = buildFlowStepLabelSpec(self.fonts, I18n:t(step.label_key), max_label_width)
    end

    self:_drawSoftSection(frame)

    for index, step in ipairs(FLOW_STEPS) do
        local x = math.floor(start_x + (index - 1) * spacing)
        local step_state = getFlowStepVisualState(tribute, phase, step.id)
        if index < count then
            local next_x = math.floor(start_x + index * spacing)
            local next_state = getFlowStepVisualState(tribute, phase, FLOW_STEPS[index + 1].id)
            local line_active = (step_state == "done") and (next_state == "done" or next_state == "active")
            love.graphics.setColor(line_active and accent or colors.button_disabled_face)
            love.graphics.setLineWidth(6)
            love.graphics.line(x + 22, center_y, next_x - 22, center_y)
            love.graphics.setLineWidth(1)
        end

        local fill = colors.button_disabled_face
        local border = colors.button_disabled_border
        local text_color = muted
        if step_state == "done" then
            fill = accent
            border = colors.panel_border
            text_color = colors.hud_text
        elseif step_state == "active" then
            fill = colors.button_primary_face
            border = colors.button_primary_border
            text_color = ink
        elseif step_state == "skipped" then
            fill = colors.card_alt
            border = colors.panel_border
            text_color = muted
        end

        love.graphics.setColor(fill)
        love.graphics.circle("fill", x, center_y, 18)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(border)
        love.graphics.circle("line", x, center_y, 18)
        love.graphics.setLineWidth(1)

        ButtonText.draw(
            self.fonts:get("Text"),
            tostring(index),
            x - 14,
            center_y - 10,
            28,
            "center",
            text_color,
            { bold = true }
        )

        local label_spec = label_specs[index]
        local label_width = label_spec and label_spec.width or 88
        local label_x = math.floor(clamp(x - label_width * 0.5, frame.x + 10, frame.x + frame.width - label_width - 10))
        local label_fill = colors.card_alt
        local label_border = colors.panel_border
        local label_text_color = step_state == "active" and colors.hud_title or ink
        if step_state == "done" then
            label_fill = accent
            label_text_color = colors.hud_text
        elseif step_state == "active" then
            label_fill = colors.button_primary_face
            label_border = colors.button_primary_border
        elseif step_state == "skipped" then
            label_text_color = muted
        end

        self:_drawPill(label_x, center_y + 24, label_spec and label_spec.text or "", {
            width = label_width,
            height = 30,
            font_token = label_spec and label_spec.font_token or "Label",
            fill = label_fill,
            border = label_border,
            text_color = label_text_color,
        })
    end
end

function TributeOverlay:_drawAvatarCard(state, frames, avatar_context)
    if not avatar_context or not avatar_context.player then
        return nil
    end

    local colors = self.style.colors
    local game = self:_getDisplayGame(state)
    local card_frame = frames.avatar_card
    local avatar_frame = self:_getHandAvatarFrame(frames)
    local avatar = self.avatars_by_id[resolveAvatarId(avatar_context.player)]
    local layout = buildHandAvatarCardLayout(self.fonts, card_frame)
    if not card_frame or not avatar_frame or not layout then
        return avatar_frame
    end

    self:_drawSoftSection(card_frame)
    love.graphics.setColor(colors.card_alt[1], colors.card_alt[2], colors.card_alt[3], 0.96)
    love.graphics.rectangle("fill", card_frame.x + 8, card_frame.y + 8, card_frame.width - 16, card_frame.height - 16, 16, 16)
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.rectangle(
        "fill",
        card_frame.x + 14,
        layout.footer_top,
        card_frame.width - 28,
        layout.footer_height,
        14,
        14
    )

    self:_drawPill(card_frame.x + 10, card_frame.y + 12, avatar_context.title or "", {
        width = card_frame.width - 20,
        height = 24,
        font_token = "TextSmall",
        fill = colors.card_alt,
        border = colors.panel_border,
        text_color = colors.text_primary,
    })

    if avatar then
        love.graphics.setColor(colors.panel_shadow[1], colors.panel_shadow[2], colors.panel_shadow[3], 0.18)
        love.graphics.rectangle("fill", avatar_frame.x - 5, avatar_frame.y + 5, avatar_frame.width + 10, avatar_frame.height + 10, 18, 18)
        AvatarTile.draw(self.style, avatar, {
            x = avatar_frame.x,
            y = avatar_frame.y,
            w = avatar_frame.width,
            h = avatar_frame.height,
        }, {
            compact = true,
            pin_frame = true,
            selected = true,
            content_padding_ratio = 0.02,
            accessories = resolveAccessories(avatar_context.player, game.my_seat_index, state.accessories),
        })
    else
        love.graphics.setColor(colors.panel_grain[1], colors.panel_grain[2], colors.panel_grain[3], 0.18)
        love.graphics.rectangle("fill", avatar_frame.x, avatar_frame.y, avatar_frame.width, avatar_frame.height, 18, 18)
    end

    ButtonText.draw(
        self.fonts:get("Text"),
        truncateText(self.fonts, "Text", avatar_context.nickname or "", card_frame.width - 28),
        card_frame.x + 15,
        layout.name_y + 1,
        card_frame.width - 28,
        "center",
        colors.panel_shadow,
        { bold = false }
    )
    ButtonText.draw(
        self.fonts:get("Text"),
        truncateText(self.fonts, "Text", avatar_context.nickname or "", card_frame.width - 28),
        card_frame.x + 14,
        layout.name_y,
        card_frame.width - 28,
        "center",
        colors.text_primary,
        { bold = false }
    )

    ButtonText.draw(
        self.fonts:get("TextSmall"),
        truncateText(
            self.fonts,
            "TextSmall",
            string.format("%s  %s", avatar_context.relation or "", avatar_context.title or ""),
            card_frame.width - 24
        ),
        card_frame.x + 13,
        layout.meta_y + 1,
        card_frame.width - 24,
        "center",
        colors.panel_shadow,
        { bold = false }
    )
    ButtonText.draw(
        self.fonts:get("TextSmall"),
        truncateText(
            self.fonts,
            "TextSmall",
            string.format("%s  %s", avatar_context.relation or "", avatar_context.title or ""),
            card_frame.width - 24
        ),
        card_frame.x + 12,
        layout.meta_y,
        card_frame.width - 24,
        "center",
        colors.text_primary,
        { bold = false }
    )
    return avatar_frame
end

function TributeOverlay:_drawAnimatedActionButton(state, frame, action_id)
    local colors = self.style.colors
	    local enabled = state.selected_tribute_card_id ~= nil and state.action_waiting ~= true
	    local hovered = state.hovered_tribute_control == action_id
	    local is_return_action = action_id == "submit_return_tribute"
	    local palette = is_return_action and getReturnTributeButtonPalette(enabled, hovered) or nil
	    local time = tonumber(self.action_attention_time) or 0
	    local pulse = 0.5 + 0.5 * math.sin(time * 4.6)
	    local bob = math.sin(time * 2.9) * (is_return_action and (enabled and 2 or 1) or (enabled and 4 or 2))
	    local scale = 1 + math.sin(time * 4.2) * (enabled and (is_return_action and 0.018 or 0.04) or 0.018) + (hovered and 0.02 or 0)
	    local orbit_radius = is_return_action and math.max(18, math.min(frame.width * 0.38, frame.height * 0.8)) or frame.width * 0.64
	    local glow_alpha = enabled and (is_return_action and 0.28 or 0.22) or 0.10
	    local center_x = frame.x + frame.width * 0.5
	    local center_y = frame.y + frame.height * 0.5 + bob
	    local glow_color = palette and palette.face or colors.button_primary_face
	    local ring_color = is_return_action and { 1, 0.8, 0.58, 1 } or colors.accent
	    local sparkle_color = palette and palette.highlight or colors.button_primary_highlight
	    local text_shadow_color = palette and palette.shadow or colors.button_primary_shadow
	    local text_color = palette and palette.text or colors.text_primary
	    local corner_radius = frame.radius or (is_return_action and 18 or 22)

	    love.graphics.setColor(
	        glow_color[1],
	        glow_color[2],
	        glow_color[3],
	        glow_alpha * (0.7 + pulse * 0.8)
	    )
	    love.graphics.rectangle(
	        "fill",
	        frame.x - 10 - pulse * (is_return_action and 3 or 5),
	        frame.y - 8 + bob - pulse * (is_return_action and 3 or 5),
	        frame.width + 20 + pulse * (is_return_action and 6 or 10),
	        frame.height + 20 + pulse * (is_return_action and 6 or 10),
	        corner_radius + 6,
	        corner_radius + 6
	    )

	    love.graphics.setLineWidth(3)
	    love.graphics.setColor(ring_color[1], ring_color[2], ring_color[3], enabled and (0.18 + pulse * 0.20) or 0.12)
	    love.graphics.rectangle(
	        "line",
	        frame.x - 6 - pulse * 4,
	        frame.y - 4 + bob - pulse * 4,
	        frame.width + 12 + pulse * 8,
	        frame.height + 12 + pulse * 8,
	        corner_radius + 2,
	        corner_radius + 2
	    )
	    love.graphics.setLineWidth(1)

	    for index = 1, 4 do
	        local angle = time * 1.8 + index * (math.pi * 0.5)
        local dot_x = center_x + math.cos(angle) * orbit_radius
        local dot_y = center_y + math.sin(angle) * orbit_radius * 0.7
	        local radius = enabled and (4 + pulse * 2) or 3
	        love.graphics.setColor(
	            sparkle_color[1],
	            sparkle_color[2],
	            sparkle_color[3],
	            enabled and ((is_return_action and 0.22 or 0.32) + pulse * 0.16) or 0.18
	        )
	        love.graphics.circle("fill", dot_x, dot_y, radius)
	    end

    love.graphics.push()
    love.graphics.translate(center_x, center_y)
    love.graphics.scale(scale, scale)

    WoodButton.draw(self.fonts, self.style, {
        label = "",
        x = -frame.width * 0.5,
        y = -frame.height * 0.5,
	        width = frame.width,
	        height = frame.height,
	        hovered = hovered,
	        enabled = enabled,
	        variant = "primary",
	        radius = corner_radius,
	        shadow_offset = 8,
	        inner_inset = 7,
	        palette_override = palette,
	    })

	    local shine_x = -frame.width * 0.58 + ((time * 86) % math.floor(frame.width * 1.9))
	    love.graphics.setColor(1, 0.98, 0.86, enabled and (0.10 + pulse * 0.08) or 0.05)
    love.graphics.polygon(
        "fill",
        shine_x, -frame.height * 0.5 + 8,
        shine_x + 14, -frame.height * 0.5 + 8,
        shine_x - 10, frame.height * 0.5 - 8,
        shine_x - 24, frame.height * 0.5 - 8
    )

	    local font_token = is_return_action and "Button" or (isChineseLocale() and "Text" or "Label")
	    local font = self.fonts:get(font_token)
	    local label = action_id == "submit_return_tribute"
	        and I18n:t("gameplay.return_tribute")
	        or I18n:t("gameplay.tribute_submit")
	    local horizontal_padding = is_return_action and 28 or 24
	    local safe_label, label_height = measureWrappedText(font, label, frame.width - horizontal_padding)
	    local text_y = -math.floor(label_height * 0.5) + (is_return_action and 1 or 0)
	    if is_return_action then
	        ButtonText.draw(
	            font,
	            safe_label,
	            -frame.width * 0.5 + 14,
	            text_y + 3,
	            frame.width - 28,
	            "center",
	            text_shadow_color,
	            { bold = true, bold_offset = 2 }
	        )
	        ButtonText.draw(
	            font,
	            safe_label,
	            -frame.width * 0.5 + 12,
	            text_y + 1,
	            frame.width - 24,
	            "center",
	            text_color,
	            { bold = true, bold_offset = 2 }
	        )
	    else
	        love.graphics.setColor(text_shadow_color)
	        love.graphics.setFont(font)
	        love.graphics.printf(safe_label, -frame.width * 0.5 + 14, text_y + 2, frame.width - 28, "center")
	        love.graphics.setColor(text_color)
	        love.graphics.setFont(font)
	        love.graphics.printf(safe_label, -frame.width * 0.5 + 12, text_y, frame.width - 24, "center")
	    end

	    love.graphics.pop()
	end

function TributeOverlay:_drawTransferCard(state)
    if not self.active_transfer then
        return
    end

    local progress = clamp(self.active_transfer.elapsed / math.max(self.active_transfer.duration, 0.001), 0, 1)
    local eased = 1 - (1 - progress) * (1 - progress)
    local source = self.active_transfer.source
    local target = self.active_transfer.target
    local x = source.x + (target.x - source.x) * eased
    local y = source.y + (target.y - source.y) * eased - math.sin(progress * math.pi) * 24
    local width = source.width + (target.width - source.width) * eased
    local height = source.height + (target.height - source.height) * eased

    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.rectangle("fill", x + 4, y + 6, width, height, 12, 12)
    self.card_view:draw(
        self.active_transfer.card_id,
        { x = x, y = y, width = width, height = height },
        state.card_theme_config or {},
        { selected = true, hovered = true },
        self.fonts
    )
end

function TributeOverlay:_drawHandSection(state, frames)
    local colors = self.style.colors
    local tribute = (self:_getDisplayGame(state).tribute) or {}
    local phase = tostring(tribute.phase or "")
    local avatar_context = self:_getHandAvatarContext(state)
    local strip_options = self:_getHandStripOptions(state, frames)

    self:_drawSoftSection(frames.hand_panel)
    love.graphics.setColor(colors.card_alt)
    love.graphics.rectangle("fill", frames.hand.x, frames.hand.y, frames.hand.width, frames.hand.height, 14, 14)
    self.hand_strip:draw(frames.hand, state, strip_options)
    self:_drawHandControls(frames)
    self:_drawAvatarCard(state, frames, avatar_context)
    self:_drawTransferCard(state)

    if isManualActionPhase(phase) then
        local action_id = tribute.action_type == "return_tribute" and "submit_return_tribute" or "submit_tribute"
        self:_drawAnimatedActionButton(state, frames.action_button, action_id)
    end
end

function TributeOverlay:_drawAntiJudgementStage(state, frames)
    local game = self:_getDisplayGame(state)
    local tribute = game.tribute or {}
    local colors = self.style.colors
    local summary, detail, accent = buildAntiJudgementCopy(game, tribute, colors)
    local gap = 14
    local content = {
        x = frames.main.x + 18,
        y = frames.main.y + 18,
        width = frames.main.width - 36,
        height = frames.main.height - 36,
    }
    local left_width = math.floor(content.width * 0.36)
    local right_width = math.floor((content.width - left_width - gap * 2) * 0.5)
    local summary_frame = {
        x = content.x,
        y = content.y,
        width = left_width,
        height = content.height,
    }

    self:_drawAntiSummaryPanel(summary_frame, summary, detail, accent)

    if tribute.anti_tribute == true then
        local seats = getAntiTributeBigJokerSeats(tribute)
        local first_joker_frame = {
            x = summary_frame.x + summary_frame.width + gap,
            y = content.y,
            width = right_width,
            height = content.height,
        }
        local second_joker_frame = {
            x = first_joker_frame.x + first_joker_frame.width + gap,
            y = content.y,
            width = content.x + content.width - (first_joker_frame.x + first_joker_frame.width + gap),
            height = content.height,
        }
        self:_drawAntiJokerColumn(game, first_joker_frame, seats[1], 1, state.card_theme_config or {}, state.accessories)
        self:_drawAntiJokerColumn(game, second_joker_frame, seats[2], 2, state.card_theme_config or {}, state.accessories)
        return
    end

    local self_joker_frame = {
        x = summary_frame.x + summary_frame.width + gap,
        y = content.y,
        width = content.x + content.width - (summary_frame.x + summary_frame.width + gap),
        height = content.height,
    }
    self:_drawAntiJokerColumn(
        game,
        self_joker_frame,
        tonumber(game.my_seat_index),
        1,
        state.card_theme_config or {},
        state.accessories,
        { joker_count = countMyBigJokers(game) }
    )
end

function TributeOverlay:_drawAntiJudgement(state, frames)
    local colors = self.style.colors
    local game = self:_getDisplayGame(state)
    local tribute = game.tribute or {}
    local anti_info = getAntiTributeDisplayInfo(game, tribute)
    local has_anti = tribute.anti_tribute == true
    local accent = colors.accent
    local title = I18n:t("gameplay.anti_judgement_none_title")
    local detail = I18n:t("gameplay.anti_judgement_none_detail")

    if has_anti then
        if anti_info.is_self_team then
            title = I18n:t("gameplay.anti_judgement_self_title")
            detail = I18n:t("gameplay.anti_judgement_self_detail")
            accent = colors.accent
        else
            title = I18n:t("gameplay.anti_judgement_opponent_title")
            detail = I18n:t("gameplay.anti_judgement_opponent_detail")
            accent = colors.error or { 0.74, 0.30, 0.24, 1 }
        end
    end

    self:_drawSoftSection(frames.main)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.14)
    love.graphics.rectangle("fill", frames.main.x + 22, frames.main.y + 28, frames.main.width - 44, frames.main.height - 56, 24, 24)

    local title_y = frames.main.y + math.floor(frames.main.height * 0.34)
    love.graphics.setColor(colors.hud_title)
    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.printf(title, frames.main.x + 30, title_y, frames.main.width - 60, "center")

    love.graphics.setColor(colors.hud_subtext)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf(detail, frames.main.x + 40, title_y + 58, frames.main.width - 80, "center")
end

function TributeOverlay:_drawEmbeddedTributeInfo(state, frame)
    local game = self:_getDisplayGame(state)
    local content_gap = 14
    local wildcard = {
        x = frame.x + 20,
        y = frame.y + 18,
        width = math.max(138, math.floor((frame.width - 40 - content_gap) * 0.2)),
        height = frame.height - 36,
    }
    local board = {
        x = wildcard.x + wildcard.width + content_gap,
        y = frame.y + 18,
        width = frame.width - 40 - wildcard.width - content_gap,
        height = frame.height - 36,
    }

    self.info_overlay:_drawWildcardPanel(wildcard, game, state.card_theme_config or {})
    self.info_overlay:_drawBoard(board, game, state.card_theme_config or {}, {
        my_seat_index = game.my_seat_index,
        my_accessories = state.accessories,
    })
end
function TributeOverlay:_drawResultSection(state, frames)
    self:_drawSoftSection(frames.main)
    self:_drawEmbeddedTributeInfo(state, frames.main)
end

function TributeOverlay:draw(state)
    local colors = self.style.colors
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local tribute = (self:_getDisplayGame(state).tribute) or {}
    local phase = tostring(tribute.phase or "")
    local frames = self:_getFrames(state)

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, width, height)

    self.panel:draw(frames.panel, {
        radius = 22,
        shadow_offset = 8,
        inner_inset = 12,
    })

    self:_drawHeader(state, frames)
    self:_drawFlow(tribute, phase, frames.flow)

    if isAntiPhase(phase) then
        self:_drawAntiJudgementStage(state, frames)
    elseif showsHand(phase) then
        self:_drawHandSection(state, frames)
    else
        self:_drawResultSection(state, frames)
    end
end

return TributeOverlay
