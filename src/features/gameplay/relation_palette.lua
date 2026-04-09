local RelationPalette = {}

local FRIENDLY = {
    shadow = { 0.05, 0.17, 0.07, 0.34 },
    fill = { 0.27, 0.56, 0.24, 0.94 },
    top_highlight = { 0.90, 0.98, 0.84, 0.20 },
    bottom_glow = { 0.07, 0.24, 0.09, 0.20 },
    outline_dark = { 0.05, 0.20, 0.08, 0.54 },
    outline_light = { 0.93, 0.99, 0.90, 0.30 },
    border = { 0.10, 0.30, 0.10, 0.84 },
    text = { 0.98, 1.00, 0.97, 0.98 },
}

local OPPONENT = {
    shadow = { 0.22, 0.07, 0.02, 0.34 },
    fill = { 0.85, 0.34, 0.16, 0.95 },
    top_highlight = { 1.00, 0.92, 0.84, 0.20 },
    bottom_glow = { 0.30, 0.09, 0.03, 0.20 },
    outline_dark = { 0.36, 0.10, 0.03, 0.56 },
    outline_light = { 1.00, 0.96, 0.90, 0.28 },
    border = { 0.44, 0.12, 0.04, 0.88 },
    text = { 1.00, 0.98, 0.96, 0.98 },
}

local NEUTRAL = {
    shadow = { 0.00, 0.00, 0.00, 0.30 },
    fill = { 0.26, 0.28, 0.30, 0.88 },
    top_highlight = { 0.96, 0.97, 1.00, 0.22 },
    bottom_glow = { 1.00, 1.00, 1.00, 0.08 },
    outline_dark = { 0.00, 0.00, 0.00, 0.42 },
    outline_light = { 1.00, 1.00, 1.00, 0.30 },
    border = { 0.18, 0.20, 0.22, 0.72 },
    text = { 1.00, 1.00, 1.00, 0.96 },
}

local function normalizeRoleKey(role_key)
    return tostring(role_key or "")
end

function RelationPalette.isFriendly(role_key)
    local key = normalizeRoleKey(role_key)
    return key == "self" or key == "opposite" or key == "teammate"
end

function RelationPalette.isOpponent(role_key)
    local key = normalizeRoleKey(role_key)
    return key == "next" or key == "previous" or key == "opponent"
end

function RelationPalette.get(role_key)
    if RelationPalette.isFriendly(role_key) then
        return FRIENDLY
    end
    if RelationPalette.isOpponent(role_key) then
        return OPPONENT
    end
    return NEUTRAL
end

return RelationPalette
