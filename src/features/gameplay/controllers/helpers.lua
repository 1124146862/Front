local I18n = require("src.core.i18n.i18n")

local Helpers = {}
local PINNED_SUIT_ORDER = {
    S = 1,
    C = 2,
    H = 3,
    D = 4,
}

local PINNED_RANK_ORDER = {
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["10"] = 10,
    J = 11,
    Q = 12,
    K = 13,
    A = 14,
    BJ = 15,
    RJ = 16,
}
local SEQUENCE_RANKS = { "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A" }
local SEQUENCE_RANK_INDEX = {}
for index, rank in ipairs(SEQUENCE_RANKS) do
    SEQUENCE_RANK_INDEX[rank] = index
end

local LAST_PLAY_PATTERN_LABELS = {
    zh = {
        single = "单张",
        pair = "对子",
        triple = "三张",
        full_house = "三带二",
        straight = "顺子",
        straight_flush = "同花顺",
        bomb = "炸弹",
        joker_bomb = "王炸",
        consecutive_pairs = "连对",
        triple_run = "钢板",
    },
    en = {
        single = "Single",
        pair = "Pair",
        triple = "Triple",
        full_house = "Full House",
        straight = "Straight",
        straight_flush = "Straight Flush",
        bomb = "Bomb",
        joker_bomb = "Bomb",
        consecutive_pairs = "Consecutive Pairs",
        triple_run = "Triple Run",
    },
}

local function parsePinnedCard(card_id)
    local black_copy = tostring(card_id):match("^BJ%-(%d+)$")
    if black_copy then
        return {
            kind = "joker",
            rank = "BJ",
            suit = "",
            copy_index = tonumber(black_copy) or 1,
        }
    end

    local red_copy = tostring(card_id):match("^RJ%-(%d+)$")
    if red_copy then
        return {
            kind = "joker",
            rank = "RJ",
            suit = "",
            copy_index = tonumber(red_copy) or 1,
        }
    end

    local suit, rank, copy_index = tostring(card_id):match("^([SHCD])%-(%w+)%-(%d+)$")
    return {
        kind = "normal",
        rank = rank or "?",
        suit = suit or "S",
        copy_index = tonumber(copy_index) or 1,
    }
end

local function isSmallWheel(cards)
    if #cards ~= 5 then
        return false
    end

    local seen = {}
    for _, card_id in ipairs(cards) do
        local parsed = parsePinnedCard(card_id)
        if parsed.kind ~= "normal" then
            return false
        end
        seen[parsed.rank] = true
    end

    return seen.A and seen["2"] and seen["3"] and seen["4"] and seen["5"]
end

local function isSmallFiveStraight(cards)
    if #cards ~= 5 then
        return false
    end

    local seen = {}
    for _, card_id in ipairs(cards) do
        local parsed = parsePinnedCard(card_id)
        if parsed.kind ~= "normal" then
            return false
        end
        seen[parsed.rank] = true
    end

    return seen["2"] and seen["3"] and seen["4"] and seen["5"] and seen["6"]
end

local function parseWildcardCard(wildcard_card)
    local suit, rank = tostring(wildcard_card or ""):match("^([SHCD])%-(%w+)$")
    return suit, rank
end

local function isWildcardCard(card_id, wildcard_card)
    local parsed = parsePinnedCard(card_id)
    if parsed.kind ~= "normal" then
        return false
    end
    local suit, rank = parseWildcardCard(wildcard_card)
    return parsed.suit == suit and parsed.rank == rank
end

local function copyCards(cards)
    local copied = {}
    for _, card_id in ipairs(cards or {}) do
        copied[#copied + 1] = card_id
    end
    return copied
end

local function getLastPlayPatternLabel(pattern_type)
    local normalized_pattern_type = tostring(pattern_type or "")
    if normalized_pattern_type == "" then
        return nil
    end

    local locale = string.lower(tostring(I18n:getLocale() or ""))
    local locale_key = locale:match("^zh") and "zh" or "en"
    return (LAST_PLAY_PATTERN_LABELS[locale_key] or {})[normalized_pattern_type]
end

local function arrangeSequenceCards(cards, options)
    local pattern_type = tostring((options or {}).pattern_type or "")
    if pattern_type ~= "straight" and pattern_type ~= "straight_flush" then
        return nil
    end
    if tonumber((options or {}).card_count or 0) ~= 5 then
        return nil
    end

    local copied = copyCards(cards)
    if #copied ~= 5 then
        return nil
    end

    local target_ranks = {}
    local main_rank = tostring((options or {}).main_rank or "")
    if isSmallWheel(copied) or main_rank == "5" then
        target_ranks = { "A", "2", "3", "4", "5" }
    elseif isSmallFiveStraight(copied) or main_rank == "6" then
        target_ranks = { "2", "3", "4", "5", "6" }
    else
        local main_index = SEQUENCE_RANK_INDEX[main_rank]
        if not main_index or main_index < 5 then
            return nil
        end
        for index = main_index, main_index - 4, -1 do
            target_ranks[#target_ranks + 1] = SEQUENCE_RANKS[index]
        end
    end

    local wildcard_card = tostring((options or {}).wildcard_card or "")
    local wildcard_cards = {}
    local rank_to_cards = {}
    for _, card_id in ipairs(copied) do
        if isWildcardCard(card_id, wildcard_card) then
            wildcard_cards[#wildcard_cards + 1] = card_id
        else
            local parsed = parsePinnedCard(card_id)
            rank_to_cards[parsed.rank] = rank_to_cards[parsed.rank] or {}
            rank_to_cards[parsed.rank][#rank_to_cards[parsed.rank] + 1] = card_id
        end
    end

    local function sortBySuitAndCopy(card_ids)
        table.sort(card_ids, function(left_id, right_id)
            local left = parsePinnedCard(left_id)
            local right = parsePinnedCard(right_id)
            local left_suit = PINNED_SUIT_ORDER[left.suit] or 99
            local right_suit = PINNED_SUIT_ORDER[right.suit] or 99
            if left_suit ~= right_suit then
                return left_suit < right_suit
            end
            return (left.copy_index or 1) < (right.copy_index or 1)
        end)
    end

    for _, bucket in pairs(rank_to_cards) do
        sortBySuitAndCopy(bucket)
    end
    sortBySuitAndCopy(wildcard_cards)

    local arranged = {}
    for _, rank in ipairs(target_ranks) do
        local bucket = rank_to_cards[rank]
        if bucket and #bucket > 0 then
            arranged[#arranged + 1] = table.remove(bucket, 1)
        elseif #wildcard_cards > 0 then
            arranged[#arranged + 1] = table.remove(wildcard_cards, 1)
        end
    end

    if #arranged == #copied then
        return arranged
    end
    return nil
end

function Helpers.sortPinnedGroupCards(cards, options)
    local arranged_sequence = arrangeSequenceCards(cards, options)
    if arranged_sequence then
        return arranged_sequence
    end

    local sorted = copyCards(cards)

    local wheel_mode = isSmallWheel(sorted)

    table.sort(sorted, function(left_id, right_id)
        local left = parsePinnedCard(left_id)
        local right = parsePinnedCard(right_id)

        local left_rank = PINNED_RANK_ORDER[left.rank] or 99
        local right_rank = PINNED_RANK_ORDER[right.rank] or 99

        if wheel_mode then
            if left.rank == "A" then left_rank = 1 end
            if right.rank == "A" then right_rank = 1 end
            if left_rank ~= right_rank then
                return left_rank < right_rank
            end
        else
            if left_rank ~= right_rank then
                return left_rank > right_rank
            end
        end

        local left_suit = PINNED_SUIT_ORDER[left.suit] or 99
        local right_suit = PINNED_SUIT_ORDER[right.suit] or 99
        if left_suit ~= right_suit then
            return left_suit < right_suit
        end

        return (left.copy_index or 1) < (right.copy_index or 1)
    end)

    return sorted
end

function Helpers.getRelativePositionKey(my_seat_index, other_seat_index)
    local relative = (other_seat_index - my_seat_index + 4) % 4
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

function Helpers.getRelativePositionLabel(my_seat_index, other_seat_index)
    local key = Helpers.getRelativePositionKey(my_seat_index, other_seat_index)
    if key == "self" then
        return I18n:t("gameplay.self")
    end
    if key == "next" then
        return I18n:t("gameplay.next")
    end
    if key == "opposite" then
        return I18n:t("gameplay.opposite")
    end
    return I18n:t("gameplay.previous")
end

function Helpers.getPlayRelationKey(actor_role_key)
    if actor_role_key == "opposite" then
        return "teammate"
    end
    if actor_role_key == "next" or actor_role_key == "previous" then
        return "opponent"
    end
    return "self"
end

function Helpers.collectSelectedCards(state)
    local selected = {}
    local hand_cards = ((state.game or {}).my_hand_cards) or {}
    for _, card_id in ipairs(hand_cards) do
        if state.selected_card_ids[card_id] then
            selected[#selected + 1] = card_id
        end
    end
    return selected
end

function Helpers.buildCommandId(state, prefix)
    local next_seq = tonumber(state.next_command_seq or 1)
    state.next_command_seq = next_seq + 1
    return string.format("%s-%s-%s-%d", tostring(prefix), tostring(state.room_id), tostring(state.steam_id), next_seq)
end

function Helpers.buildLastPlayViewModel(game)
    local leading_play = (game or {}).leading_play
    if not leading_play or not leading_play.cards or #leading_play.cards == 0 then
        return nil
    end

    return {
        seat_index = leading_play.seat_index,
        actor_role_key = Helpers.getRelativePositionKey(game.my_seat_index or 0, leading_play.seat_index or 0),
        actor_label = Helpers.getRelativePositionLabel(game.my_seat_index or 0, leading_play.seat_index or 0),
        pattern_type = leading_play.pattern_type,
        pattern_label = getLastPlayPatternLabel(leading_play.pattern_type),
        cards = Helpers.sortPinnedGroupCards(leading_play.cards, {
            pattern_type = leading_play.pattern_type,
            main_rank = leading_play.main_rank,
            card_count = leading_play.card_count,
            wildcard_card = game.wildcard_card,
        }),
    }
end

function Helpers.hasActiveTribute(game)
    local tribute = (game or {}).tribute
    return tribute ~= nil and tribute.phase ~= nil and tribute.phase ~= "complete"
end

function Helpers.isMyTurn(state)
    local game = state.game or {}
    return game.current_actor_seat ~= nil and game.current_actor_seat == game.my_seat_index
end

function Helpers.hasPlayControl(state)
    local game = state.game or {}
    if game.has_play_control ~= nil then
        return game.has_play_control == true
    end
    return Helpers.isMyTurn(state)
end

return Helpers
