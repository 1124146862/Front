local HandArrangement = require("src.features.gameplay.layouts.hand_arrangement")
local HandCardAnchorLayout = require("src.features.gameplay.layouts.hand_card_anchor_layout")
local CardView = require("src.features.gameplay.components.card_view")
local HandCardAnimator = require("src.features.gameplay.animators.hand_card_animator")
local PlayingCard = require("src.features.gameplay.components.playing_card")
local Helpers = require("src.features.gameplay.controllers.helpers")

local TributeHandStrip = {}
TributeHandStrip.__index = TributeHandStrip

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

local function filterHandCards(hand_cards, hidden_card_ids)
    local visible_cards = {}
    for _, card_id in ipairs(hand_cards or {}) do
        if hidden_card_ids[card_id] ~= true then
            visible_cards[#visible_cards + 1] = card_id
        end
    end
    return visible_cards
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

function TributeHandStrip.new(options)
    local self = setmetatable({}, TributeHandStrip)

    self.fonts = assert(options and options.fonts, "TributeHandStrip requires fonts")
    self.arrangement_builder = HandArrangement.new()
    self.layout_builder = HandCardAnchorLayout.new()
    self.card_view = CardView.new()
    self.animator = HandCardAnimator.new()
    self.cards = {}
    self.card_order = {}

    return self
end

function TributeHandStrip:_buildAnchors(frame, hand_cards, state, options)
    options = options or {}
    local hidden_card_ids = options.hidden_card_ids or {}
    local visible_cards = filterHandCards(hand_cards, hidden_card_ids)
    local full_hand_set = {}
    for _, card_id in ipairs(hand_cards or {}) do
        full_hand_set[card_id] = true
    end

    local pinned_groups = normalizePinnedGroups(state, full_hand_set)
    local pinned_visible_groups = {}
    local pinned_cards = {}
    for _, group in ipairs(pinned_groups) do
        local visible_group = {}
        for _, card_id in ipairs((group and (group.cards or group)) or {}) do
            if hidden_card_ids[card_id] ~= true then
                visible_group[#visible_group + 1] = card_id
                pinned_cards[#pinned_cards + 1] = card_id
            end
        end
        if #visible_group > 0 then
            pinned_visible_groups[#pinned_visible_groups + 1] = {
                cards = visible_group,
            }
        end
    end

    local pinned_set = {}
    for _, card_id in ipairs(pinned_cards) do
        pinned_set[card_id] = true
    end

    local normal_cards = {}
    for _, card_id in ipairs(visible_cards) do
        if not pinned_set[card_id] then
            normal_cards[#normal_cards + 1] = card_id
        end
    end

    local pinned_arrangement
    if #pinned_visible_groups > 0 then
        pinned_arrangement = buildPinnedArrangement(pinned_visible_groups)
    else
        pinned_arrangement = self.arrangement_builder:build(pinned_cards, {
            wildcard_card = ((state.game or {}).wildcard_card),
        })
    end
    local normal_arrangement = self.arrangement_builder:build(normal_cards, {
        wildcard_card = ((state.game or {}).wildcard_card),
    })
    local merged_arrangement = mergeArrangements(pinned_arrangement, normal_arrangement)
    local insets = options.insets or {}
    local anchors = self.layout_builder:build(frame, merged_arrangement, {
        fit_to_area = true,
        min_scale = 0.50,
        max_scale = 0.84,
        left_inset = insets.left or 18,
        right_inset = insets.right or 18,
        top_inset = insets.top or 18,
        bottom_inset = insets.bottom or 18,
    })
    table.sort(anchors, function(left, right)
        if left.z_index ~= right.z_index then
            return left.z_index < right.z_index
        end
        return tostring(left.card_id) < tostring(right.card_id)
    end)
    return anchors
end

function TributeHandStrip:_syncCards(frame, state, options)
    local hand_cards = ((state.game or {}).my_hand_cards) or {}
    local alive = {}
    self.card_order = {}

    for _, anchor in ipairs(self:_buildAnchors(frame, hand_cards, state, options)) do
        local card_id = anchor.card_id
        local component = self.cards[card_id]
        if not component then
            component = PlayingCard.new({
                card_id = card_id,
                card_view = self.card_view,
                animator = self.animator,
                fonts = self.fonts,
                x = anchor.x,
                y = anchor.y,
                width = anchor.width,
                height = anchor.height,
                theme_config = state.card_theme_config,
            })
            self.cards[card_id] = component
        end

        component:updateTarget(anchor, {
            selected = state.selected_tribute_card_id == card_id or state.selected_card_ids[card_id] == true,
            hovered = state.hovered_tribute_card_id == card_id,
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

function TributeHandStrip:update(dt, frame, state, options)
    self:_syncCards(frame, state, options)
    for _, card_id in ipairs(self.card_order) do
        self.cards[card_id]:update(dt)
    end
end

function TributeHandStrip:getHoveredCardId(x, y, frame, state, options)
    self:_syncCards(frame, state, options)
    for index = #self.card_order, 1, -1 do
        local card_id = self.card_order[index]
        local card = self.cards[card_id]
        if card and card:containsPoint(x, y) then
            return card_id
        end
    end
    return nil
end

function TributeHandStrip:getCardBounds(card_id)
    local card = self.cards[tostring(card_id or "")]
    if not card then
        return nil
    end
    return {
        x = card.position.x,
        y = card.position.y,
        width = card.width,
        height = card.height,
    }
end

function TributeHandStrip:draw(frame, state, options)
    self:_syncCards(frame, state, options)
    local hidden_card_ids = (options or {}).hidden_card_ids or {}
    for _, card_id in ipairs(self.card_order) do
        local card = self.cards[card_id]
        if card and hidden_card_ids[card_id] ~= true then
            card:draw()
        end
    end
end

return TributeHandStrip
