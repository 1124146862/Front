local HandArrangement = {}
HandArrangement.__index = HandArrangement

local MAX_CARDS_PER_COLUMN = 6

local SUIT_ORDER = {
    S = 1,
    C = 2,
    H = 3,
    D = 4,
}

local BASE_RANK_ORDER = {
    A = 1,
    K = 2,
    Q = 3,
    J = 4,
    ["10"] = 5,
    ["9"] = 6,
    ["8"] = 7,
    ["7"] = 8,
    ["6"] = 9,
    ["5"] = 10,
    ["4"] = 11,
    ["3"] = 12,
    ["2"] = 13,
}

local function parseCard(card_id)
    local joker_rank, joker_copy = tostring(card_id):match("^(BJ)%-(%d+)$")
    if joker_rank then
        return {
            kind = "joker",
            joker = "BJ",
            rank = "BJ",
            copy_index = tonumber(joker_copy) or 1,
        }
    end

    joker_rank, joker_copy = tostring(card_id):match("^(RJ)%-(%d+)$")
    if joker_rank then
        return {
            kind = "joker",
            joker = "RJ",
            rank = "RJ",
            copy_index = tonumber(joker_copy) or 1,
        }
    end

    local suit, rank, copy_index = tostring(card_id):match("^([SHCD])%-(%w+)%-(%d+)$")
    return {
        kind = "normal",
        suit = suit or "S",
        rank = rank or "?",
        copy_index = tonumber(copy_index) or 1,
    }
end

local function getWildcardRank(wildcard_card)
    local _, rank = tostring(wildcard_card or ""):match("^([SHCD])%-(%w+)$")
    return rank
end

local function getGroupPriority(card, wildcard_rank)
    if card.kind == "joker" then
        if card.joker == "RJ" then
            return 1
        end
        return 2
    end

    if wildcard_rank and card.rank == wildcard_rank then
        return 3
    end

    return 3 + (BASE_RANK_ORDER[card.rank] or 99)
end

local function compareCards(left, right)
    local left_suit = SUIT_ORDER[left.suit] or 99
    local right_suit = SUIT_ORDER[right.suit] or 99
    if left_suit ~= right_suit then
        return left_suit < right_suit
    end

    return (left.copy_index or 1) < (right.copy_index or 1)
end

function HandArrangement.new()
    return setmetatable({}, HandArrangement)
end

function HandArrangement:build(cards, options)
    local wildcard_rank = getWildcardRank(options and options.wildcard_card)
    local grouped = {}

    for _, card_id in ipairs(cards or {}) do
        local card = parseCard(card_id)
        local group_key
        if card.kind == "joker" then
            group_key = card.joker
        else
            group_key = card.rank
        end

        if not grouped[group_key] then
            grouped[group_key] = {
                key = group_key,
                priority = getGroupPriority(card, wildcard_rank),
                cards = {},
            }
        end

        grouped[group_key].cards[#grouped[group_key].cards + 1] = {
            id = card_id,
            parsed = card,
        }
    end

    local groups = {}
    for _, group in pairs(grouped) do
        table.sort(group.cards, function(left, right)
            local left_card = left.parsed
            local right_card = right.parsed

            if left_card.kind == "joker" or right_card.kind == "joker" then
                return (left_card.copy_index or 1) < (right_card.copy_index or 1)
            end

            return compareCards(left_card, right_card)
        end)
        groups[#groups + 1] = group
    end

    table.sort(groups, function(left, right)
        if left.priority ~= right.priority then
            return left.priority < right.priority
        end
        return tostring(left.key) < tostring(right.key)
    end)

    local slots = {}
    local visual_column = 1
    for _, group in ipairs(groups) do
        for index, item in ipairs(group.cards) do
            local column_offset = math.floor((index - 1) / MAX_CARDS_PER_COLUMN)
            local row_index = (index - 1) % MAX_CARDS_PER_COLUMN
            local absolute_column = visual_column + column_offset
            slots[#slots + 1] = {
                card_id = item.id,
                group_key = group.key,
                visual_column = absolute_column,
                row_index = row_index,
                -- Draw order rule:
                -- 1. cards further to the right should stay above cards on the left
                -- 2. within the same column, lower cards should stay above upper cards
                z_index = absolute_column * 10 + (MAX_CARDS_PER_COLUMN - row_index),
            }
        end

        visual_column = visual_column + math.ceil(#group.cards / MAX_CARDS_PER_COLUMN)
    end

    return {
        slots = slots,
        visual_column_count = math.max(visual_column - 1, 0),
    }
end

return HandArrangement
