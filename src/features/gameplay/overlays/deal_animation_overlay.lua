local DealAnimationOverlay = {}
DealAnimationOverlay.__index = DealAnimationOverlay

local CardBackStyle = require("src.features.gameplay.components.card_back_style")
local CardView = require("src.features.gameplay.components.card_view")

local TOTAL_DEAL_CARDS = 108
local TRAVEL_DURATION = 0.24
local HAND_CARD_WIDTH = 110
local HAND_CARD_HEIGHT = 154

local DECK_MAX_VISIBLE_LAYERS = 11
local PLAYER_MAX_VISIBLE_LAYERS = 9
local STACK_OFFSET_RATIO = 0.022
local PLAYER_STACK_THICKNESS_RATIO = 0.25

local OPEN_INTRO_WEIGHT = 0.45
local OPEN_CUT_WEIGHT = 0.60
local OPEN_FLIP_WEIGHT = 0.45
local OPEN_RESTACK_WEIGHT = 0.45
local OPEN_DEAL_WEIGHT = 4.05

local CLOSED_INTRO_WEIGHT = 0.8
local CLOSED_DEAL_WEIGHT = 5.2

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function lerp(from_value, to_value, t)
    return from_value + (to_value - from_value) * t
end

local function easeOutCubic(t)
    local one_minus_t = 1 - t
    return 1 - one_minus_t * one_minus_t * one_minus_t
end

local function easeInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    end
    local f = (2 * t) - 2
    return 0.5 * f * f * f + 1
end

local function computeVisibleStackLayers(card_count, max_card_count, max_layers, options)
    options = options or {}
    local count = math.max(0, math.floor(tonumber(card_count) or 0))
    if count <= 0 then
        return 0
    end

    local total = math.max(1, math.floor(tonumber(max_card_count) or count))
    local layer_limit = math.max(2, math.floor(tonumber(max_layers) or PLAYER_MAX_VISIBLE_LAYERS))
    local mode = options.mode or "ratio"

    if mode == "count" then
        return clamp(count, 1, math.min(count, layer_limit))
    end

    local progress = clamp(count / total, 0, 1)
    return clamp(math.ceil(progress * layer_limit), 1, math.min(count, layer_limit))
end

local function getRelativePositionLabel(my_seat_index, other_seat_index)
    local my_index = tonumber(my_seat_index) or 0
    local other_index = tonumber(other_seat_index) or 0
    local relative = (other_index - my_index + 4) % 4
    if relative == 0 then
        return "self"
    end
    if relative == 1 then
        return "next"
    end
    if relative == 2 then
        return "opposite"
    end
    return "previous"
end

local function getPhaseProgress(phase, elapsed)
    if phase.duration <= 0 then
        if elapsed >= phase.finish then
            return 1, false, true
        end
        return 0, false, false
    end
    if elapsed <= phase.start then
        return 0, false, false
    end
    if elapsed >= phase.finish then
        return 1, false, true
    end
    return clamp((elapsed - phase.start) / phase.duration, 0, 1), true, false
end

local function buildPhases(duration, show_open_card)
    local phases = {}
    local cursor = 0

    local function addPhase(name, weight, total_weight)
        local phase_duration = duration * (weight / total_weight)
        phases[name] = {
            start = cursor,
            duration = phase_duration,
            finish = cursor + phase_duration,
        }
        cursor = cursor + phase_duration
    end

    if show_open_card then
        local total_weight = OPEN_INTRO_WEIGHT + OPEN_CUT_WEIGHT + OPEN_FLIP_WEIGHT + OPEN_RESTACK_WEIGHT + OPEN_DEAL_WEIGHT
        addPhase("intro", OPEN_INTRO_WEIGHT, total_weight)
        addPhase("cut", OPEN_CUT_WEIGHT, total_weight)
        addPhase("flip", OPEN_FLIP_WEIGHT, total_weight)
        addPhase("restack", OPEN_RESTACK_WEIGHT, total_weight)
        addPhase("deal", OPEN_DEAL_WEIGHT, total_weight)
    else
        local total_weight = CLOSED_INTRO_WEIGHT + CLOSED_DEAL_WEIGHT
        addPhase("intro", CLOSED_INTRO_WEIGHT, total_weight)
        phases.cut = { start = cursor, duration = 0, finish = cursor }
        phases.flip = { start = cursor, duration = 0, finish = cursor }
        phases.restack = { start = cursor, duration = 0, finish = cursor }
        addPhase("deal", CLOSED_DEAL_WEIGHT, total_weight)
    end

    return phases
end

local function getPileLayerOffsets(card_width, card_height, visible_layers, stack_max_layers, options)
    options = options or {}
    local max_offset_x = options.stack_offset_x or math.max(1, math.floor(card_width * STACK_OFFSET_RATIO))
    local max_offset_y = options.stack_offset_y or math.max(1, math.floor(card_height * STACK_OFFSET_RATIO))
    local spread_t = clamp((visible_layers - 1) / math.max(1, stack_max_layers - 1), 0, 1)
    local offset_x = math.max(1, math.floor(lerp(1, max_offset_x, spread_t) + 0.5))
    local offset_y = math.max(1, math.floor(lerp(1, max_offset_y, spread_t) + 0.5))
    return offset_x, offset_y
end

local function getDeckStackOffsetLimits(card_width, card_height)
    return {
        x = math.max(1, math.floor(card_width * STACK_OFFSET_RATIO)),
        y = math.max(1, math.floor(card_height * STACK_OFFSET_RATIO)),
    }
end

local function getPlayerStackOffsetLimits(card_width, card_height)
    local deck_offsets = getDeckStackOffsetLimits(card_width, card_height)
    local deck_spread_layers = math.max(1, DECK_MAX_VISIBLE_LAYERS - 1)
    local player_spread_layers = math.max(1, PLAYER_MAX_VISIBLE_LAYERS - 1)
    local spread_ratio = (deck_spread_layers / player_spread_layers) * PLAYER_STACK_THICKNESS_RATIO
    return {
        x = math.max(1, math.floor(deck_offsets.x * spread_ratio + 0.5)),
        y = math.max(1, math.floor(deck_offsets.y * spread_ratio + 0.5)),
    }
end

local function buildSeatTargets(target_frames, window_width, window_height, card_width, card_height, my_seat_index)
    local fallback_targets = {
        opposite = { x = window_width * 0.5 - card_width * 0.5, y = window_height * 0.18 - card_height * 0.5 },
        next = { x = window_width * 0.78 - card_width * 0.5, y = window_height * 0.47 - card_height * 0.5 },
        self = { x = window_width * 0.5 - card_width * 0.5, y = window_height * 0.75 - card_height * 0.5 },
        previous = { x = window_width * 0.22 - card_width * 0.5, y = window_height * 0.47 - card_height * 0.5 },
    }
    local side_gap = math.max(8, math.floor(card_width * 0.08))
    local vertical_gap = math.max(10, math.floor(card_height * 0.08))

    local function buildTargetNearAvatar(frame, role)
        local centered_y = frame.y + math.floor((frame.height - card_height) * 0.5)
        local centered_x = frame.x + math.floor((frame.width - card_width) * 0.5)

        if role == "previous" then
            return {
                x = frame.x + frame.width + side_gap,
                y = centered_y,
            }
        end

        if role == "next" then
            return {
                x = frame.x - card_width - side_gap,
                y = centered_y,
            }
        end

        if role == "opposite" then
            return {
                x = frame.x + frame.width + side_gap,
                y = centered_y,
            }
        end

        return {
            x = centered_x,
            y = frame.y + frame.height + vertical_gap,
        }
    end

    local seat_targets = {}
    for seat_index = 0, 3 do
        local role = getRelativePositionLabel(my_seat_index, seat_index)
        local frame = (target_frames or {})[role]
        local target = fallback_targets[role]
        if frame and frame.x and frame.y and frame.width and frame.height then
            target = buildTargetNearAvatar(frame, role)
        end
        seat_targets[seat_index] = {
            x = clamp(target.x, 8, window_width - card_width - 8),
            y = clamp(target.y, 8, window_height - card_height - 8),
            role = role,
            rotation = (role == "next" and 0.05) or (role == "previous" and -0.05) or 0,
        }
    end

    return seat_targets
end

local function getPileTopOrigin(pile, options)
    options = options or {}
    local count = math.max(0, math.floor(tonumber(pile.count) or 0))
    if count <= 0 then
        return pile.x, pile.y
    end

    local card_width = pile.width or HAND_CARD_WIDTH
    local card_height = pile.height or HAND_CARD_HEIGHT
    local stack_max_count = options.stack_max_count or TOTAL_DEAL_CARDS
    local stack_max_layers = options.stack_max_layers or PLAYER_MAX_VISIBLE_LAYERS
    local visible_layers = computeVisibleStackLayers(count, stack_max_count, stack_max_layers, {
        mode = options.stack_mode,
    })
    local offset_x, offset_y = getPileLayerOffsets(card_width, card_height, visible_layers, stack_max_layers, options)
    local top_x = pile.x - math.max(0, (visible_layers - 1) * offset_x)
    local top_y = pile.y - math.max(0, (visible_layers - 1) * offset_y)
    return top_x, top_y
end

local function countCardsForSeat(card_count, seat_index, deal_start_seat)
    local start_seat = tonumber(deal_start_seat) or 0
    local one_based = ((seat_index - start_seat + 4) % 4) + 1
    if card_count < one_based then
        return 0
    end
    return math.floor((card_count - one_based) / 4) + 1
end

function DealAnimationOverlay.new(options)
    local self = setmetatable({}, DealAnimationOverlay)
    self.fonts = assert(options and options.fonts, "DealAnimationOverlay requires fonts")
    self.style = assert(options and options.style, "DealAnimationOverlay requires style")
    self.card_view = CardView.new()
    return self
end

function DealAnimationOverlay:_drawCardBack(center_x, center_y, width, height, back_id, transform)
    transform = transform or {}
    love.graphics.push()
    love.graphics.translate(center_x, center_y)
    if transform.rotation and transform.rotation ~= 0 then
        love.graphics.rotate(transform.rotation)
    end
    love.graphics.scale(transform.scale_x or 1, transform.scale_y or 1)
    CardBackStyle.draw(-width * 0.5, -height * 0.5, width, height, back_id, {
        outer_radius = 6,
        inset = 2,
        inner_radius = 4,
    })
    love.graphics.pop()
end

function DealAnimationOverlay:_drawCardFace(card_id, center_x, center_y, width, height, theme_config, transform)
    transform = transform or {}
    love.graphics.push()
    love.graphics.translate(center_x, center_y)
    if transform.rotation and transform.rotation ~= 0 then
        love.graphics.rotate(transform.rotation)
    end
    love.graphics.scale(transform.scale_x or 1, transform.scale_y or 1)
    self.card_view:draw(
        card_id,
        {
            x = -width * 0.5,
            y = -height * 0.5,
            width = width,
            height = height,
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
    love.graphics.pop()
end

function DealAnimationOverlay:_drawPile(pile, back_id, theme_config, options)
    options = options or {}
    local count = math.max(0, math.floor(tonumber(pile.count) or 0))
    if count <= 0 then
        return
    end

    local card_width = pile.width or HAND_CARD_WIDTH
    local card_height = pile.height or HAND_CARD_HEIGHT
    local rotation = options.rotation or 0
    local top_mode = options.top_mode or "back"
    local stack_max_count = options.stack_max_count or TOTAL_DEAL_CARDS
    local stack_max_layers = options.stack_max_layers or PLAYER_MAX_VISIBLE_LAYERS
    local visible_layers = computeVisibleStackLayers(count, stack_max_count, stack_max_layers, {
        mode = options.stack_mode,
    })
    local offset_x, offset_y = getPileLayerOffsets(card_width, card_height, visible_layers, stack_max_layers, options)
    local spread_x = math.max(0, (visible_layers - 1) * offset_x)
    local spread_y = math.max(0, (visible_layers - 1) * offset_y)
    local top_x = pile.x - spread_x
    local top_y = pile.y - spread_y

    love.graphics.setColor(0.04, 0.05, 0.08, options.shadow_alpha or 0.16)
    love.graphics.ellipse(
        "fill",
        pile.x + card_width * 0.50 - spread_x * 0.06,
        pile.y + card_height + 8 - spread_y * 0.08,
        card_width * 0.56 + spread_x * 0.08,
        8 + spread_y * 0.06
    )

    local draw_top_card = top_mode ~= "none"
    local background_layers = visible_layers
    if draw_top_card and visible_layers > 0 then
        background_layers = visible_layers - 1
    end

    for index = 0, background_layers - 1 do
        local layer_x = pile.x - index * offset_x
        local layer_y = pile.y - index * offset_y
        self:_drawCardBack(
            layer_x + card_width * 0.5,
            layer_y + card_height * 0.5,
            card_width,
            card_height,
            back_id,
            {
                rotation = rotation,
            }
        )
    end

    if top_mode == "back" then
        self:_drawCardBack(
            top_x + card_width * 0.5,
            top_y + card_height * 0.5,
            card_width,
            card_height,
            back_id,
            {
                rotation = rotation,
                scale_x = options.top_scale_x or 1,
                scale_y = options.top_scale_y or 1,
            }
        )
    elseif top_mode == "face" and options.top_card_id then
        self:_drawCardFace(
            options.top_card_id,
            top_x + card_width * 0.5,
            top_y + card_height * 0.5,
            card_width,
            card_height,
            theme_config,
            {
                rotation = rotation,
                scale_x = options.top_scale_x or 1,
                scale_y = options.top_scale_y or 1,
            }
        )
    end
end

function DealAnimationOverlay:draw(remaining_seconds, total_duration, theme_config, target_frames, options)
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local duration = math.max(0.1, tonumber(total_duration) or 0.1)
    local remaining = math.max(0, tonumber(remaining_seconds) or 0)
    local elapsed = clamp(duration - remaining, 0, duration)
    options = options or {}

    local card_back_id = ((theme_config or {}).back_id) or "classic_grid"
    local card_width = HAND_CARD_WIDTH
    local card_height = HAND_CARD_HEIGHT
    local deck_stack_offsets = getDeckStackOffsetLimits(card_width, card_height)
    local player_stack_offsets = getPlayerStackOffsetLimits(card_width, card_height)

    local my_seat_index = tonumber(options.my_seat_index or 0) or 0
    local deal_start_seat = tonumber(options.deal_start_seat)
    if deal_start_seat == nil then
        deal_start_seat = tonumber(options.open_card_seat) or 0
    end
    local open_card_id = options.open_card_id
    local open_card_seat = tonumber(options.open_card_seat)
    local open_card_cut_count = tonumber(options.open_card_cut_count)
    local open_card_deal_index = tonumber(options.open_card_deal_index)
    if open_card_deal_index == nil and open_card_cut_count ~= nil then
        open_card_deal_index = open_card_cut_count + 1
    end

    local show_open_card = open_card_id ~= nil
        and open_card_id ~= ""
        and open_card_seat ~= nil
        and open_card_cut_count ~= nil
        and open_card_deal_index ~= nil
    if show_open_card then
        open_card_cut_count = clamp(math.floor(open_card_cut_count), 1, TOTAL_DEAL_CARDS - 1)
        open_card_deal_index = clamp(math.floor(open_card_deal_index), 1, TOTAL_DEAL_CARDS)
    end

    local phases = buildPhases(duration, show_open_card)
    local seat_targets = buildSeatTargets(target_frames, window_width, window_height, card_width, card_height, my_seat_index)

    local deck_base_x = window_width * 0.5 - card_width * 0.5
    local deck_base_y = window_height * 0.5 - card_height * 0.5
    local cut_target_x = deck_base_x + card_width * 1.18
    local cut_target_y = deck_base_y - card_height * 0.10
    local function getSeatStackBase(seat_index)
        local seat_target = seat_targets[seat_index]
        return seat_target.x, seat_target.y, seat_target.rotation, seat_target.role
    end

    local function getVisibleSeatCount(card_count, seat_index)
        local total_for_seat = countCardsForSeat(card_count, seat_index, deal_start_seat)
        if show_open_card and seat_index == open_card_seat and card_count >= open_card_deal_index then
            total_for_seat = math.max(0, total_for_seat - 1)
        end
        return total_for_seat
    end

    local function computeSeatCardTarget(card_index)
        local seat_index = (deal_start_seat + ((card_index - 1) % 4)) % 4
        local visible_count = getVisibleSeatCount(card_index, seat_index)
        local base_x, base_y, rotation, role = getSeatStackBase(seat_index)
        local top_x, top_y = getPileTopOrigin({
            x = base_x,
            y = base_y,
            width = card_width,
            height = card_height,
            count = visible_count,
        }, {
            stack_max_count = countCardsForSeat(TOTAL_DEAL_CARDS, seat_index, deal_start_seat),
            stack_max_layers = PLAYER_MAX_VISIBLE_LAYERS,
            stack_mode = "count",
            stack_offset_x = player_stack_offsets.x,
            stack_offset_y = player_stack_offsets.y,
        })
        return top_x, top_y, rotation, seat_index, role
    end

    local function computeOpenCardTargetForSeat(seat_index, visible_count)
        local base_x, base_y, rotation, role = getSeatStackBase(seat_index)
        local stack_top_x, stack_top_y = getPileTopOrigin({
            x = base_x,
            y = base_y,
            width = card_width,
            height = card_height,
            count = math.max(1, visible_count),
        }, {
            stack_max_count = countCardsForSeat(TOTAL_DEAL_CARDS, seat_index, deal_start_seat),
            stack_max_layers = PLAYER_MAX_VISIBLE_LAYERS,
            stack_mode = "count",
            stack_offset_x = player_stack_offsets.x,
            stack_offset_y = player_stack_offsets.y,
        })
        local side_gap = math.max(10, math.floor(card_width * 0.18))
        local open_x = 0
        if role == "next" then
            open_x = base_x - card_width - side_gap
        else
            open_x = stack_top_x + card_width + side_gap
        end
        local open_y = stack_top_y
        open_x = clamp(open_x, 8, window_width - card_width - 8)
        open_y = clamp(open_y, 8, window_height - card_height - 8)
        return open_x, open_y, rotation, seat_index
    end

    local function computeOpenCardTarget(card_index)
        local seat_index = (deal_start_seat + ((card_index - 1) % 4)) % 4
        local visible_count = getVisibleSeatCount(card_index, seat_index)
        return computeOpenCardTargetForSeat(seat_index, visible_count)
    end

    local function computeFinalOpenCardTarget()
        if not show_open_card then
            return nil, nil, 0, nil
        end
        local final_visible_count = getVisibleSeatCount(TOTAL_DEAL_CARDS, open_card_seat)
        return computeOpenCardTargetForSeat(open_card_seat, final_visible_count)
    end

    local function drawPlayerStacks(settled_cards)
        for seat_index = 0, 3 do
            local settled_for_seat = getVisibleSeatCount(settled_cards, seat_index)
            if settled_for_seat > 0 then
                local base_x, base_y, rotation = getSeatStackBase(seat_index)
                self:_drawPile(
                    {
                        x = base_x,
                        y = base_y,
                        width = card_width,
                        height = card_height,
                        count = settled_for_seat,
                },
                card_back_id,
                theme_config,
                {
                    rotation = rotation,
                    stack_max_count = countCardsForSeat(TOTAL_DEAL_CARDS, seat_index, deal_start_seat),
                    stack_max_layers = PLAYER_MAX_VISIBLE_LAYERS,
                    stack_mode = "count",
                    stack_offset_x = player_stack_offsets.x,
                    stack_offset_y = player_stack_offsets.y,
                }
            )
            end
        end
    end

    local intro_t = select(1, getPhaseProgress(phases.intro, elapsed))
    local cut_t, cut_active = getPhaseProgress(phases.cut, elapsed)
    local flip_t, flip_active = getPhaseProgress(phases.flip, elapsed)
    local restack_t, restack_active = getPhaseProgress(phases.restack, elapsed)
    local _, deal_active = getPhaseProgress(phases.deal, elapsed)

    if not show_open_card and not deal_active then
        local breathe = 1 + math.sin(intro_t * math.pi) * 0.008
        self:_drawPile(
            {
                x = deck_base_x,
                y = deck_base_y,
                width = card_width,
                height = card_height,
                count = TOTAL_DEAL_CARDS,
            },
            card_back_id,
            theme_config,
            {
                stack_max_count = TOTAL_DEAL_CARDS,
                stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                stack_offset_x = deck_stack_offsets.x,
                stack_offset_y = deck_stack_offsets.y,
                top_scale_x = breathe,
                top_scale_y = breathe,
            }
        )
        return
    end

    if show_open_card then
        local main_pile_count = TOTAL_DEAL_CARDS - open_card_cut_count
        local full_deck_top_x, full_deck_top_y = getPileTopOrigin({
            x = deck_base_x,
            y = deck_base_y,
            width = card_width,
            height = card_height,
            count = TOTAL_DEAL_CARDS,
        }, {
            stack_max_count = TOTAL_DEAL_CARDS,
            stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
            stack_offset_x = deck_stack_offsets.x,
            stack_offset_y = deck_stack_offsets.y,
        })

        if cut_active and not flip_active and not restack_active and not deal_active then
            local motion_t = easeInOutCubic(cut_t)
            local packet_x = lerp(full_deck_top_x, cut_target_x, motion_t)
            local packet_y = lerp(full_deck_top_y, cut_target_y, motion_t) - math.sin(cut_t * math.pi) * 18

            self:_drawPile(
                {
                    x = deck_base_x,
                    y = deck_base_y,
                    width = card_width,
                    height = card_height,
                    count = main_pile_count,
                },
                card_back_id,
                theme_config,
                {
                    stack_max_count = TOTAL_DEAL_CARDS,
                    stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                    stack_offset_x = deck_stack_offsets.x,
                    stack_offset_y = deck_stack_offsets.y,
                }
            )
            self:_drawPile(
                {
                    x = packet_x,
                    y = packet_y,
                    width = card_width,
                    height = card_height,
                    count = open_card_cut_count,
                },
                card_back_id,
                theme_config,
                {
                    rotation = 0.02,
                    stack_max_count = TOTAL_DEAL_CARDS,
                    stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                    stack_offset_x = deck_stack_offsets.x,
                    stack_offset_y = deck_stack_offsets.y,
                }
            )
            return
        end

        if flip_active and not restack_active and not deal_active then
            local flip_card_x, flip_card_y = getPileTopOrigin({
                x = deck_base_x,
                y = deck_base_y,
                width = card_width,
                height = card_height,
                count = math.max(1, main_pile_count),
            }, {
                stack_max_count = TOTAL_DEAL_CARDS,
                stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                stack_offset_x = deck_stack_offsets.x,
                stack_offset_y = deck_stack_offsets.y,
            })
            local flip_scale_x = 1
            local draw_face = false
            if flip_t < 0.5 then
                draw_face = false
                flip_scale_x = math.max(0.04, 1 - flip_t * 2)
            else
                draw_face = true
                flip_scale_x = math.max(0.04, (flip_t - 0.5) * 2)
            end

            self:_drawPile(
                {
                    x = deck_base_x,
                    y = deck_base_y,
                    width = card_width,
                    height = card_height,
                    count = math.max(1, main_pile_count),
                },
                card_back_id,
                theme_config,
                {
                    stack_max_count = TOTAL_DEAL_CARDS,
                    stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                    stack_offset_x = deck_stack_offsets.x,
                    stack_offset_y = deck_stack_offsets.y,
                    top_mode = "none",
                }
            )
            self:_drawPile(
                {
                    x = cut_target_x,
                    y = cut_target_y,
                    width = card_width,
                    height = card_height,
                    count = open_card_cut_count,
                },
                card_back_id,
                theme_config,
                {
                    rotation = 0.02,
                    stack_max_count = TOTAL_DEAL_CARDS,
                    stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                    stack_offset_x = deck_stack_offsets.x,
                    stack_offset_y = deck_stack_offsets.y,
                }
            )

            if flip_scale_x > 0.16 then
                if draw_face then
                    self:_drawCardFace(
                        open_card_id,
                        flip_card_x + card_width * 0.5,
                        flip_card_y + card_height * 0.5,
                        card_width,
                        card_height,
                        theme_config,
                        { scale_x = flip_scale_x }
                    )
                else
                    self:_drawCardBack(
                        flip_card_x + card_width * 0.5,
                        flip_card_y + card_height * 0.5,
                        card_width,
                        card_height,
                        card_back_id,
                        { scale_x = flip_scale_x }
                    )
                end
            end
            return
        end

        if restack_active and not deal_active then
            local packet_return_t = easeInOutCubic(restack_t)
            local open_card_x, open_card_y = getPileTopOrigin({
                x = deck_base_x,
                y = deck_base_y,
                width = card_width,
                height = card_height,
                count = math.max(1, main_pile_count),
            }, {
                stack_max_count = TOTAL_DEAL_CARDS,
                stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                stack_offset_x = deck_stack_offsets.x,
                stack_offset_y = deck_stack_offsets.y,
            })
            local packet_target_x = open_card_x
            local packet_target_y = open_card_y
            local packet_rotation = lerp(0.02, 0, packet_return_t)

            self:_drawPile(
                {
                    x = deck_base_x,
                    y = deck_base_y,
                    width = card_width,
                    height = card_height,
                    count = math.max(1, main_pile_count),
                },
                card_back_id,
                theme_config,
                {
                    stack_max_count = TOTAL_DEAL_CARDS,
                    stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                    stack_offset_x = deck_stack_offsets.x,
                    stack_offset_y = deck_stack_offsets.y,
                    top_mode = "none",
                }
            )

            self:_drawCardFace(
                open_card_id,
                open_card_x + card_width * 0.5,
                open_card_y + card_height * 0.5,
                card_width,
                card_height,
                theme_config
            )

            self:_drawPile(
                {
                    x = lerp(cut_target_x, packet_target_x, packet_return_t),
                    y = lerp(cut_target_y, packet_target_y, packet_return_t) - math.sin(packet_return_t * math.pi) * 12,
                    width = card_width,
                    height = card_height,
                    count = open_card_cut_count,
                },
                card_back_id,
                theme_config,
                {
                    rotation = packet_rotation,
                    stack_max_count = TOTAL_DEAL_CARDS,
                    stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                    stack_offset_x = deck_stack_offsets.x,
                    stack_offset_y = deck_stack_offsets.y,
                }
            )
            return
        end
    end

    local deal_elapsed = clamp(elapsed - phases.deal.start, 0, phases.deal.duration)
    -- Reserve the final travel window so the last launched cards finish landing
    -- before the overlay enters its terminal static frame.
    local launch_window = math.max(0, phases.deal.duration - TRAVEL_DURATION)
    local cards_per_second = launch_window > 0 and (TOTAL_DEAL_CARDS / launch_window) or 0
    local launched_cards = 0
    if deal_elapsed > 0 then
        if launch_window <= 0 then
            launched_cards = TOTAL_DEAL_CARDS
        else
            launched_cards = clamp(math.floor(deal_elapsed * cards_per_second) + 1, 0, TOTAL_DEAL_CARDS)
        end
    end

    local settled_cards = 0
    if launch_window <= 0 then
        if deal_elapsed >= phases.deal.duration then
            settled_cards = TOTAL_DEAL_CARDS
        end
    elseif deal_elapsed >= TRAVEL_DURATION then
        settled_cards = clamp(
            math.floor((deal_elapsed - TRAVEL_DURATION) * cards_per_second + 1),
            0,
            TOTAL_DEAL_CARDS
        )
    end

    self:_drawPile(
        {
            x = deck_base_x,
            y = deck_base_y,
            width = card_width,
            height = card_height,
            count = math.max(0, TOTAL_DEAL_CARDS - launched_cards),
        },
        card_back_id,
        theme_config,
        {
            stack_max_count = TOTAL_DEAL_CARDS,
            stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
            stack_offset_x = deck_stack_offsets.x,
            stack_offset_y = deck_stack_offsets.y,
        }
    )

    drawPlayerStacks(settled_cards)

    local final_open_x, final_open_y, final_open_rotation = computeFinalOpenCardTarget()

    if show_open_card and settled_cards >= open_card_deal_index then
        self:_drawCardFace(
            open_card_id,
            final_open_x + card_width * 0.5,
            final_open_y + card_height * 0.5,
            card_width,
            card_height,
            theme_config
        )
    end

    local visible_moving_start = math.max(1, launched_cards - 10)
    local visible_moving_end = math.min(TOTAL_DEAL_CARDS, launched_cards)
    for card_index = visible_moving_start, visible_moving_end do
        local launch_time = (card_index - 1) / cards_per_second
        local t = (deal_elapsed - launch_time) / TRAVEL_DURATION
        if t >= 0 and t <= 1 then
            local eased = easeOutCubic(t)
            local source_x, source_y = getPileTopOrigin({
                x = deck_base_x,
                y = deck_base_y,
                width = card_width,
                height = card_height,
                count = math.max(0, TOTAL_DEAL_CARDS - (card_index - 1)),
            }, {
                stack_max_count = TOTAL_DEAL_CARDS,
                stack_max_layers = DECK_MAX_VISIBLE_LAYERS,
                stack_offset_x = deck_stack_offsets.x,
                stack_offset_y = deck_stack_offsets.y,
            })

            if show_open_card and card_index == open_card_deal_index then
                local open_target_x = final_open_x
                local open_target_y = final_open_y
                local rotation = final_open_rotation
                self:_drawCardFace(
                    open_card_id,
                    lerp(source_x, open_target_x, eased) + card_width * 0.5,
                    lerp(source_y, open_target_y, eased) + card_height * 0.5 - math.sin(t * math.pi) * 18,
                    card_width,
                    card_height,
                    theme_config,
                    { rotation = rotation }
                )
            else
                local target_x, target_y, rotation = computeSeatCardTarget(card_index)
                self:_drawCardBack(
                    lerp(source_x, target_x, eased) + card_width * 0.5,
                    lerp(source_y, target_y, eased) + card_height * 0.5 - math.sin(t * math.pi) * 18,
                    card_width,
                    card_height,
                    card_back_id,
                    { rotation = rotation }
                )
            end
        end
    end
end

return DealAnimationOverlay
