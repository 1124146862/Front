local HandArrangement = require("src.features.gameplay.layouts.hand_arrangement")
local HandCardAnchorLayout = require("src.features.gameplay.layouts.hand_card_anchor_layout")
local HandCardAnimator = require("src.features.gameplay.animators.hand_card_animator")
local Helpers = require("src.features.gameplay.controllers.helpers")
local CardView = require("src.features.gameplay.components.card_view")
local PlayingCard = require("src.features.gameplay.components.playing_card")
local HandPinButton = require("src.features.gameplay.components.hand_pin_button")
local HandRankButton = require("src.features.gameplay.components.hand_rank_button")

local HandAreaOverlay = {}
HandAreaOverlay.__index = HandAreaOverlay

local function flattenPinnedGroups(groups)
    local flat = {}
    for _, group in ipairs(groups or {}) do
        local cards = group and (group.cards or group) or {}
        for _, card_id in ipairs(cards) do
            flat[#flat + 1] = card_id
        end
    end
    return flat
end

local function normalizePinnedGroups(state, hand_set)
    local source_groups = state.pinned_card_groups
    local groups = {}
    local flat = {}
    local seen = {}

    if type(source_groups) == "table" and #source_groups > 0 then
        for _, group in ipairs(source_groups) do
            local next_group = {}
            local cards = group and (group.cards or group) or {}
            for _, card_id in ipairs(cards) do
                if hand_set[card_id] and not seen[card_id] then
                    seen[card_id] = true
                    next_group[#next_group + 1] = card_id
                end
            end
            if #next_group > 0 then
                local sorted_group = Helpers.sortPinnedGroupCards(next_group)
                groups[#groups + 1] = {
                    cards = sorted_group,
                }
                for _, card_id in ipairs(sorted_group) do
                    flat[#flat + 1] = card_id
                end
            end
        end
    end

    if #groups == 0 and type(state.pinned_card_ids) == "table" and #state.pinned_card_ids > 0 then
        local next_group = {}
        for _, card_id in ipairs(state.pinned_card_ids) do
            if hand_set[card_id] and not seen[card_id] then
                seen[card_id] = true
                next_group[#next_group + 1] = card_id
            end
        end
        if #next_group > 0 then
            groups = {
                { cards = Helpers.sortPinnedGroupCards(next_group) },
            }
            flat = flattenPinnedGroups(groups)
        end
    end

    state.pinned_card_groups = groups
    state.pinned_card_ids = flat
    return groups
end

function HandAreaOverlay.new(options)
    local self = setmetatable({}, HandAreaOverlay)

    self.fonts = assert(options and options.fonts, "HandAreaOverlay requires fonts")
    self.style = assert(options and options.style, "HandAreaOverlay requires style")
    self.arrangement_builder = HandArrangement.new()
    self.layout_builder = HandCardAnchorLayout.new()
    self.animator = HandCardAnimator.new()
    self.card_view = CardView.new()
    self.cards = {}
    self.card_order = {}
    self.pin_button = HandPinButton.new()
    self.rank_button = HandRankButton.new()

    return self
end

function HandAreaOverlay:_getArea(layout)
    if layout and layout.hand_frame then
        local frame = layout.hand_frame
        local width = math.max(320, frame.width - 40)
        local pin_h = (((layout.hand_buttons or {}).pin) or {}).h or 0
        local rank_h = (((layout.hand_buttons or {}).rank) or {}).h or 0
        local button_reserve = math.max(pin_h, rank_h)
        local bottom_inset = math.max(18, math.floor(button_reserve * 0.32))
        local target_height = 182
        local max_height = math.max(132, frame.height - bottom_inset - 16)
        local area_height = math.min(target_height, max_height)
        return {
            x = frame.x + 20,
            y = frame.y + frame.height - area_height - bottom_inset,
            width = width,
            height = area_height,
        }
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local pin_reserve = 106

    return {
        x = 120,
        y = height - 276,
        width = width - 240 - pin_reserve,
        height = 196,
    }
end

function HandAreaOverlay:_getButtonBounds(layout)
    if layout and layout.hand_buttons and layout.hand_buttons.pin and layout.hand_buttons.rank then
        return {
            pin = {
                x = layout.hand_buttons.pin.x,
                y = layout.hand_buttons.pin.y,
                w = layout.hand_buttons.pin.w,
                h = layout.hand_buttons.pin.h,
            },
            rank = {
                x = layout.hand_buttons.rank.x,
                y = layout.hand_buttons.rank.y,
                w = layout.hand_buttons.rank.w,
                h = layout.hand_buttons.rank.h,
            },
        }
    end

    if layout and layout.hand_frame then
        local rank_w, rank_h = self.rank_button:getSize()
        local pin_w, pin_h = self.pin_button:getSize()
        local gap = 10
        local total_w = rank_w + gap + pin_w
        local left = layout.hand_frame.x + math.floor((layout.hand_frame.width - total_w) * 0.5)
        local base_y = layout.hand_frame.y + layout.hand_frame.height - math.max(rank_h, pin_h) - 8
        return {
            pin = {
                x = left + rank_w + gap,
                y = base_y + (math.max(rank_h, pin_h) - pin_h),
                w = pin_w,
                h = pin_h,
            },
            rank = {
                x = left,
                y = base_y + (math.max(rank_h, pin_h) - rank_h),
                w = rank_w,
                h = rank_h,
            },
        }
    end

    local height = love.graphics.getHeight()
    local button_w, button_h = self.pin_button:getSize()
    local rank_w, rank_h = self.rank_button:getSize()
    local gap = 16
    local total_w = rank_w + gap + button_w
    local max_h = math.max(button_h, rank_h)
    local area = self:_getArea(nil)
    local group_x = math.floor(area.x + area.width * 0.5 - total_w * 0.5)
    local base_y = math.min(height - max_h - 10, area.y + area.height + 8)
    return {
        rank = {
            x = group_x,
            y = base_y + (max_h - rank_h),
            w = rank_w,
            h = rank_h,
        },
        pin = {
            x = group_x + rank_w + gap,
            y = base_y + (max_h - button_h),
            w = button_w,
            h = button_h,
        },
    }
end

local function mergeArrangements(left_arrangement, right_arrangement)
    local merged_slots = {}
    local left_columns = math.max(0, tonumber((left_arrangement or {}).visual_column_count) or 0)

    for _, slot in ipairs((left_arrangement or {}).slots or {}) do
        merged_slots[#merged_slots + 1] = {
            card_id = slot.card_id,
            visual_column = slot.visual_column,
            row_index = slot.row_index,
        }
    end

    for _, slot in ipairs((right_arrangement or {}).slots or {}) do
        merged_slots[#merged_slots + 1] = {
            card_id = slot.card_id,
            visual_column = (slot.visual_column or 1) + left_columns,
            row_index = slot.row_index,
        }
    end

    local total_columns = left_columns + math.max(0, tonumber((right_arrangement or {}).visual_column_count) or 0)
    for _, slot in ipairs(merged_slots) do
        slot.z_index = (slot.visual_column or 1) * 100 + (100 - (slot.row_index or 0))
    end

    return {
        slots = merged_slots,
        visual_column_count = total_columns,
    }
end

local function buildPinnedArrangement(groups)
    local slots = {}
    local visual_column = 1

    for _, group in ipairs(groups or {}) do
        local cards = group and (group.cards or group) or {}
        for row_index, card_id in ipairs(cards) do
            local zero_based_row = row_index - 1
            slots[#slots + 1] = {
                card_id = card_id,
                visual_column = visual_column,
                row_index = zero_based_row,
                z_index = visual_column * 100 + (100 - zero_based_row),
            }
        end
        visual_column = visual_column + 1
    end

    return {
        slots = slots,
        visual_column_count = math.max(visual_column - 1, 0),
    }
end

function HandAreaOverlay:_syncCards(state, layout)
    local game = state.game or {}
    local hand_cards = game.my_hand_cards or {}
    local hand_set = {}
    for _, card_id in ipairs(hand_cards) do
        hand_set[card_id] = true
    end

    local pinned_groups = normalizePinnedGroups(state, hand_set)
    local pinned_cards = state.pinned_card_ids or {}
    local pinned_set = {}
    for _, card_id in ipairs(pinned_cards) do
        pinned_set[card_id] = true
    end

    local normal_cards = {}
    for _, card_id in ipairs(hand_cards) do
        if not pinned_set[card_id] then
            normal_cards[#normal_cards + 1] = card_id
        end
    end

    local pinned_arrangement
    if #pinned_groups > 0 then
        pinned_arrangement = buildPinnedArrangement(pinned_groups)
    else
        pinned_arrangement = self.arrangement_builder:build(pinned_cards, {
            wildcard_card = game.wildcard_card,
        })
    end
    local normal_arrangement = self.arrangement_builder:build(normal_cards, {
        wildcard_card = game.wildcard_card,
    })
    local merged_arrangement = mergeArrangements(pinned_arrangement, normal_arrangement)
    local anchors = self.layout_builder:build(self:_getArea(layout), merged_arrangement)

    local alive = {}

    table.sort(anchors, function(left, right)
        if left.z_index ~= right.z_index then
            return left.z_index < right.z_index
        end
        return tostring(left.card_id) < tostring(right.card_id)
    end)

    self.card_order = {}
    for _, anchor in ipairs(anchors) do
        local card_id = anchor.card_id
        local component = self.cards[card_id]
        if not component then
            component = PlayingCard.new({
                card_id = card_id,
                card_view = self.card_view,
                animator = self.animator,
                fonts = self.fonts,
                theme_config = state.card_theme_config,
                x = anchor.x,
                y = anchor.y,
                width = anchor.width,
                height = anchor.height,
            })
            self.cards[card_id] = component
        end

        component:updateTarget(anchor, {
            selected = state.selected_card_ids[card_id] == true,
            hovered = state.hovered_card_id == card_id,
            theme_config = state.card_theme_config,
        })

        alive[card_id] = true
        self.card_order[#self.card_order + 1] = card_id
    end

    for card_id in pairs(self.cards) do
        if not alive[card_id] then
            self.cards[card_id] = nil
        end
    end
end

function HandAreaOverlay:update(dt, state, layout)
    self:_syncCards(state, layout)
    local selected_count = 0
    for _ in pairs(state.selected_card_ids or {}) do
        selected_count = selected_count + 1
    end
    self.rank_button:update(dt, state.hovered_control == "rank_hand_cards")
    self.pin_button:update(dt, state.hovered_control == "pin_selected_cards", selected_count > 0)
    for _, card_id in ipairs(self.card_order) do
        self.cards[card_id]:update(dt)
    end
end

function HandAreaOverlay:getHoveredCardId(x, y, state, layout)
    self:_syncCards(state, layout)

    for index = #self.card_order, 1, -1 do
        local card_id = self.card_order[index]
        local card = self.cards[card_id]
        if card and card:containsPoint(x, y) then
            return card_id
        end
    end

    return nil
end

function HandAreaOverlay:draw(state, layout)
    self:_syncCards(state, layout)

    for _, card_id in ipairs(self.card_order) do
        local card = self.cards[card_id]
        if card then
            card:draw()
        end
    end

    local button_bounds = self:_getButtonBounds(layout)
    self.rank_button:draw(button_bounds.rank, {
        visible = true,
    })
    self.pin_button:draw(button_bounds.pin, {
        visible = true,
    })
end

function HandAreaOverlay:getControlAt(x, y, _, layout)
    local button_bounds = self:_getButtonBounds(layout)
    if self.rank_button:contains(button_bounds.rank, x, y) then
        return "rank_hand_cards"
    end
    if self.pin_button:contains(button_bounds.pin, x, y) then
        return "pin_selected_cards"
    end
    return nil
end

return HandAreaOverlay
