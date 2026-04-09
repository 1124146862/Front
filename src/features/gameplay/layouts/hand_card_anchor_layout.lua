local Platform = require("src.infra.system.platform")

local HandCardAnchorLayout = {}
HandCardAnchorLayout.__index = HandCardAnchorLayout

local BASE_CARD_WIDTH = 87
local BASE_CARD_HEIGHT = 122
local BASE_ROW_OFFSET = 38
local WINDOWS_HAND_SCALE = 1.2
local HORIZONTAL_SPACING_MULTIPLIER = 1.5
local MIN_HORIZONTAL_SPACING = 30
local MAX_HORIZONTAL_SPACING = 50
local MIN_CARD_SCALE = 0.68

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function scaleHandMetric(value)
    if Platform.isWindows() then
        return math.floor(value * WINDOWS_HAND_SCALE + 0.5)
    end
    return value
end

function HandCardAnchorLayout.new()
    return setmetatable({}, HandCardAnchorLayout)
end

function HandCardAnchorLayout:build(area, arrangement, options)
    options = options or {}
    local slots = arrangement and arrangement.slots or {}
    local visual_column_count = arrangement and arrangement.visual_column_count or 0
    if #slots == 0 or visual_column_count == 0 then
        return {}
    end

    local left_inset = math.max(0, tonumber(options.left_inset) or 0)
    local right_inset = math.max(0, tonumber(options.right_inset) or 0)
    local top_inset = math.max(0, tonumber(options.top_inset) or 0)
    local bottom_inset = math.max(0, tonumber(options.bottom_inset) or 2)
    local content_x = area.x + left_inset
    local content_y = area.y + top_inset
    local content_width = math.max(1, area.width - left_inset - right_inset)
    local content_height = math.max(1, area.height - top_inset - bottom_inset)

    local card_width = scaleHandMetric(BASE_CARD_WIDTH)
    local card_height = scaleHandMetric(BASE_CARD_HEIGHT)
    local row_offset = scaleHandMetric(BASE_ROW_OFFSET)
    if options.fit_to_area == true then
        local max_row_index = 0
        for _, slot in ipairs(slots) do
            max_row_index = math.max(max_row_index, tonumber(slot.row_index) or 0)
        end

        local stack_height = card_height + max_row_index * row_offset
        local height_scale = stack_height > 0 and (content_height / stack_height) or 1
        local width_scale = card_width > 0 and (content_width / card_width) or 1
        local max_scale = math.min(1, tonumber(options.max_scale) or 1)
        local scale = math.min(max_scale, height_scale, width_scale)
        scale = clamp(scale, options.min_scale or MIN_CARD_SCALE, max_scale)

        card_width = math.max(1, math.floor(card_width * scale))
        card_height = math.max(1, math.floor(card_height * scale))
        row_offset = math.max(1, math.floor(row_offset * scale))
    end

    local available_span = math.max(content_width - card_width, 0)
    local horizontal_spacing = 0
    if visual_column_count > 1 then
        local max_spacing_by_width = available_span / (visual_column_count - 1)
        local min_spacing = scaleHandMetric(MIN_HORIZONTAL_SPACING)
        local max_spacing = scaleHandMetric(MAX_HORIZONTAL_SPACING)
        if options.fit_to_area == true then
            local spacing_scale = card_width / math.max(scaleHandMetric(BASE_CARD_WIDTH), 1)
            min_spacing = math.max(1, math.floor(min_spacing * spacing_scale))
            max_spacing = math.max(min_spacing, math.floor(max_spacing * spacing_scale))
        end
        horizontal_spacing = clamp(
            max_spacing_by_width / HORIZONTAL_SPACING_MULTIPLIER,
            min_spacing,
            max_spacing
        ) * HORIZONTAL_SPACING_MULTIPLIER
        horizontal_spacing = math.min(horizontal_spacing, max_spacing_by_width)
    end

    local total_span = horizontal_spacing * math.max(visual_column_count - 1, 0) + card_width
    local start_x = content_x + math.floor((content_width - total_span) / 2)
    local anchor_bottom = content_y + content_height - card_height

    local anchors = {}
    for _, slot in ipairs(slots) do
        anchors[#anchors + 1] = {
            card_id = slot.card_id,
            x = math.floor(start_x + (slot.visual_column - 1) * horizontal_spacing),
            y = anchor_bottom - slot.row_index * row_offset,
            width = card_width,
            height = card_height,
            z_index = slot.z_index,
        }
    end

    return anchors
end

return HandCardAnchorLayout
