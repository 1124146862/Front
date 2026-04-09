local GameplayLayout = {}
local HAND_VERTICAL_LIFT_RATIO = 0.03
local SELF_AVATAR_RATIO = 0.75
local FOOTER_MARGIN = 12
local FOOTER_ROW_GAP = 8

local function clamp(value, lower, upper)
    if value < lower then
        return lower
    end
    if value > upper then
        return upper
    end
    return value
end

function GameplayLayout.build(window_width, window_height, options)
    options = options or {}

    local side_padding = options.side_padding or clamp(math.floor(window_width * 0.02), 16, 36)
    local top_padding = options.top_padding or clamp(math.floor(window_height * 0.018), 12, 26)
    local bottom_padding = options.bottom_padding or clamp(math.floor(window_height * 0.012), 6, 16)

    local board = {
        x = side_padding,
        y = top_padding,
        width = window_width - side_padding * 2,
        height = window_height - top_padding - bottom_padding,
    }

    local center_x = board.x + math.floor(board.width * 0.5)

    local play_width = clamp(math.floor(board.width * 0.56), 560, math.floor(board.width * 0.68))
    local play_height = clamp(math.floor(board.height * 0.27), 210, 252)
    local play_x = center_x - math.floor(play_width * 0.5)

    local hand_width = clamp(math.floor(board.width * 0.58), 620, math.floor(board.width * 0.70))
    local hand_height = clamp(math.floor(board.height * 0.42), 228, 342)
    local hand_x = center_x - math.floor(hand_width * 0.5)
    local hand_y = board.y + math.floor(board.height * 0.78) - math.floor(hand_height * 0.5)
    hand_y = hand_y + math.floor(board.height * 0.035)
    hand_y = hand_y - math.floor(board.height * HAND_VERTICAL_LIFT_RATIO)

    local avatar_size = clamp(math.floor(math.min(board.width, board.height) * 0.108), 72, 108)
    local middle_shift = 0
    local side_center_y = board.y + math.floor(board.height * 0.35)
    local play_y = side_center_y - math.floor(play_height * 0.5) + middle_shift
    local side_y = side_center_y - math.floor(avatar_size * 0.5) + middle_shift
    local top_gap = (side_center_y - math.floor(play_height * 0.5)) - board.y
    local opposite_y = board.y
    if top_gap > avatar_size then
        opposite_y = board.y + math.floor((top_gap - avatar_size) * 0.5)
    end
    opposite_y = math.max(board.y, opposite_y - math.floor(board.height * 0.015))
    local opposite_frame = {
        x = center_x - math.floor(avatar_size * 0.5),
        y = opposite_y,
        width = avatar_size,
        height = avatar_size,
    }

    local left_gap = play_x - board.x
    local right_gap = board.x + board.width - (play_x + play_width)
    local previous_x = board.x + math.floor((left_gap - avatar_size) * 0.5)
    local next_x = play_x + play_width + math.floor((right_gap - avatar_size) * 0.5)
    previous_x = math.max(board.x, previous_x)
    next_x = math.min(board.x + board.width - avatar_size, next_x)

    local previous_frame = {
        x = previous_x,
        y = side_y,
        width = avatar_size,
        height = avatar_size,
    }
    local next_frame = {
        x = next_x,
        y = side_y,
        width = avatar_size,
        height = avatar_size,
    }
    local action_w = 170
    local action_h = 56
    local action_gap = 26
    local action_y = hand_y + math.floor(hand_height * 0.55) - math.floor(action_h * 0.5)
    local action_left_x = hand_x - action_w - action_gap
    local action_right_x = hand_x + hand_width + action_gap
    action_left_x = math.max(board.x + 8, action_left_x)
    action_right_x = math.min(board.x + board.width - action_w - 8, action_right_x)

    local small_w = 56
    local small_h = 56
    local self_avatar_size = math.max(48, math.floor(avatar_size * SELF_AVATAR_RATIO))
    local footer_row_height = math.max(small_h, self_avatar_size)
    local board_bottom = board.y + board.height
    local footer_y = board_bottom - footer_row_height - FOOTER_MARGIN
    local button_y = footer_y + math.floor((footer_row_height - small_h) * 0.5)
    local self_y = footer_y + math.floor((footer_row_height - self_avatar_size) * 0.5)
    local pin_x = board.x + FOOTER_MARGIN
    local rank_x = board.x + board.width - small_w - FOOTER_MARGIN
    local self_x = center_x - math.floor(self_avatar_size * 0.5)
    local hand_bottom_limit = footer_y - FOOTER_ROW_GAP
    if hand_y + hand_height > hand_bottom_limit then
        hand_y = hand_bottom_limit - hand_height
    end
    local hand_top_limit = board.y + 8
    if hand_y < hand_top_limit then
        hand_y = hand_top_limit
    end
    local self_frame = {
        x = self_x,
        y = self_y,
        width = self_avatar_size,
        height = self_avatar_size,
    }

    local settings_size = 52
    local settings_button = {
        x = board.x + board.width - settings_size - 18,
        y = board.y + 10,
        width = settings_size,
        height = settings_size,
    }
    local mute_button = {
        x = board.x + 18,
        y = board.y + 10,
        width = 52,
        height = 52,
    }

    local hand_count_width = 26
    local hand_count_height = 34
    local hand_count_gap = 10
    local function buildHandCountTarget(frame, anchor)
        local x = frame.x + math.floor((frame.width - hand_count_width) * 0.5)
        local y = frame.y + frame.height + 8
        if anchor == "left" then
            x = frame.x - hand_count_width - hand_count_gap
            y = frame.y + math.floor((frame.height - hand_count_height) * 0.5)
        elseif anchor == "right" then
            x = frame.x + frame.width + hand_count_gap
            y = frame.y + math.floor((frame.height - hand_count_height) * 0.5)
        end
        return {
            x = x,
            y = y,
            width = hand_count_width,
            height = hand_count_height,
        }
    end

    return {
        board = board,
        last_play_frame = {
            x = play_x,
            y = play_y,
            width = play_width,
            height = play_height,
        },
        hand_frame = {
            x = hand_x,
            y = hand_y,
            width = hand_width,
            height = hand_height,
        },
        players = {
            opposite = opposite_frame,
            previous = previous_frame,
            next = next_frame,
            self = self_frame,
        },
        deal_targets = {
            opposite = buildHandCountTarget(opposite_frame, "right"),
            previous = buildHandCountTarget(previous_frame, "right"),
            next = buildHandCountTarget(next_frame, "left"),
            self = {
                x = hand_x,
                y = hand_y,
                width = hand_width,
                height = hand_height,
            },
        },
        action_bar = {
            pass = {
                x = action_left_x,
                y = action_y,
                width = action_w,
                height = action_h,
            },
            play = {
                x = action_right_x,
                y = action_y,
                width = action_w,
                height = action_h,
            },
        },
        hand_buttons = {
            pin = {
                x = pin_x,
                y = button_y,
                w = small_w,
                h = small_h,
            },
            rank = {
                x = rank_x,
                y = button_y,
                w = small_w,
                h = small_h,
            },
        },
        settings_button = settings_button,
        mute_button = mute_button,
        debug_button = {
            x = settings_button.x - 146 - 14,
            y = settings_button.y + 12,
            width = 146,
            height = 34,
        },
        tribute_info_button = {
            x = settings_button.x - 146 - 14,
            y = settings_button.y + 52,
            width = 146,
            height = 34,
        },
    }
end

return GameplayLayout
