local NicknameCheckLayout = {}

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

function NicknameCheckLayout.compute(style, width, height, show_close, visible_count)
    local panel_width = clamp(style.panel.width, 760, width - 80)
    local columns = style.avatar.columns
    local max_rows = math.max(1, style.avatar.rows or 4)
    local resolved_visible_count = math.max(1, tonumber(visible_count) or (columns * max_rows))
    local rows = math.max(1, math.min(max_rows, math.ceil(resolved_visible_count / columns)))

    local base_tile = style.avatar.tile
    local base_gap = style.avatar.gap
    local base_preview = style.avatar.preview
    local close_size = 40
    local title_y_offset = 20
    local input_top_gap = 82
    local outer_pad_top = 18
    local outer_pad_bottom = 22
    local section_gap = 24
    local panel_inner_gap = 18
    local grid_inner_pad = 22
    local pager_gap = 18
    local pager_label_gap = 18
    local preview_label_gap = 18
    local grid_panel_bottom_pad = 8
    local pager_width = 118
    local pager_height = 46
    local preview_top_pad = 22
    local preview_bottom_pad = 18
    local preview_label_h = 26
    local confirm_gap = 10
    local confirm_bottom_pad = 14
    local error_gap = 10
    local error_h = 22

    local panel_x = math.floor((width - panel_width) * 0.5)

    local function scaleValue(value, scale, min_value)
        local scaled = math.floor(value * scale)
        if min_value then
            return math.max(min_value, scaled)
        end
        return scaled
    end

    local base_grid_width = base_tile * columns + base_gap * (columns - 1)
    local base_grid_height = base_tile * rows + base_gap * (rows - 1)
    local base_left_panel_h = grid_inner_pad + base_grid_height + grid_panel_bottom_pad
    local base_left_group_h = base_left_panel_h + pager_label_gap + pager_height
    local base_section_h = math.max(base_left_group_h, base_left_group_h) + outer_pad_top + outer_pad_bottom
    local fixed_height =
        input_top_gap
        + style.input.height
        + 18
        + confirm_gap
        + error_h
        + error_gap
        + style.button.height
        + confirm_bottom_pad
    local available_height = height - 32
    local available_for_section = available_height - fixed_height
    local scale = 1
    if available_for_section > 0 and base_section_h > 0 then
        scale = math.min(1, available_for_section / base_section_h)
    end
    scale = clamp(scale, 0.6, 1)

    local tile = scaleValue(base_tile, scale, 44)
    local gap = scaleValue(base_gap, scale, 6)
    local preview_size = scaleValue(base_preview, scale, 120)
    outer_pad_top = scaleValue(outer_pad_top, scale, 10)
    outer_pad_bottom = scaleValue(outer_pad_bottom, scale, 12)
    section_gap = scaleValue(section_gap, scale, 12)
    panel_inner_gap = scaleValue(panel_inner_gap, scale, 10)
    grid_inner_pad = scaleValue(grid_inner_pad, scale, 12)
    pager_gap = scaleValue(pager_gap, scale, 12)
    pager_label_gap = scaleValue(pager_label_gap, scale, 10)
    preview_label_gap = scaleValue(preview_label_gap, scale, 10)
    grid_panel_bottom_pad = scaleValue(grid_panel_bottom_pad, scale, 6)
    pager_width = scaleValue(pager_width, scale, 90)
    pager_height = scaleValue(pager_height, scale, 36)
    preview_top_pad = scaleValue(preview_top_pad, scale, 12)
    preview_bottom_pad = scaleValue(preview_bottom_pad, scale, 12)
    preview_label_h = scaleValue(preview_label_h, scale, 18)

    local grid_width = tile * columns + gap * (columns - 1)
    local grid_height = tile * rows + gap * (rows - 1)
    local left_section_w = grid_width + grid_inner_pad * 2
    local right_section_w = preview_size + grid_inner_pad * 2 + scaleValue(56, scale, 32)
    local section_w = left_section_w + right_section_w + section_gap
    local section_x = panel_x + math.floor((panel_width - section_w) * 0.5)
    local left_section_x = section_x
    local right_section_x = left_section_x + left_section_w + section_gap

    local grid_panel_x = left_section_x + panel_inner_gap
    local grid_panel_w = left_section_w - panel_inner_gap * 2
    local grid_x = grid_panel_x + grid_inner_pad
    local pager_row_width = pager_width * 2 + pager_gap
    local pager_x = grid_panel_x + math.floor((grid_panel_w - pager_row_width) * 0.5)

    local random_width = style.small_button.width
    local small_gap = 12
    -- Keep the nickname field compact so the header feels lighter.
    local input_row_width = clamp(math.floor(panel_width * 0.5), 420, 480)
    local input_x = panel_x + math.floor((panel_width - input_row_width) * 0.5)
    local input_width = input_row_width - random_width - small_gap
    local random_x = input_x + input_width + small_gap

    local left_panel_h = grid_inner_pad + grid_height + grid_panel_bottom_pad
    local left_group_h = left_panel_h + pager_label_gap + pager_height

    local preview_panel_x = right_section_x + panel_inner_gap
    local preview_panel_w = right_section_w - panel_inner_gap * 2
    local preview_panel_h = preview_top_pad + preview_size + preview_label_gap + preview_label_h + preview_bottom_pad
    local preview_x = preview_panel_x + math.floor((preview_panel_w - preview_size) * 0.5)
    local section_content_h = math.max(left_group_h, preview_panel_h)
    local section_h = section_content_h + outer_pad_top + outer_pad_bottom

    local input_y = 0
    local section_y = 0
    local button_y = 0
    local content_height =
        input_top_gap
        + style.input.height
        + 18
        + section_h
        + confirm_gap
        + error_h
        + error_gap
        + style.button.height
        + confirm_bottom_pad
    local panel_height = math.min(math.max(content_height, 520), height - 32)
    local panel_y = math.floor((height - panel_height) * 0.5)

    input_y = panel_y + input_top_gap
    section_y = input_y + style.input.height + 18
    button_y = section_y + section_h + confirm_gap + error_h + error_gap

    local section_content_y = section_y + outer_pad_top
    local left_group_y = section_content_y + math.floor((section_content_h - left_group_h) * 0.5)
    local grid_panel_y = left_group_y
    local grid_y = grid_panel_y + grid_inner_pad
    local pager_y = grid_panel_y + left_panel_h + pager_label_gap
    local preview_panel_y = section_content_y + math.floor((section_content_h - preview_panel_h) * 0.5)
    local preview_y = preview_panel_y + preview_top_pad

    return {
        panel = {
            x = panel_x,
            y = panel_y,
            w = panel_width,
            h = panel_height,
        },
        close_button = show_close and {
            x = panel_x + panel_width - 58,
            y = panel_y + title_y_offset,
            w = close_size,
            h = close_size,
        } or nil,
        input = {
            x = input_x,
            y = input_y,
            w = input_width,
            h = style.input.height,
        },
        random_button = {
            x = random_x,
            y = input_y,
            w = random_width,
            h = style.small_button.height,
        },
        avatar_section = {
            x = section_x,
            y = section_y,
            w = section_w,
            h = section_h,
        },
        avatar_grid_panel = {
            x = grid_panel_x,
            y = grid_panel_y,
            w = grid_panel_w,
            h = left_panel_h,
        },
        avatar_preview_panel = {
            x = preview_panel_x,
            y = preview_panel_y,
            w = preview_panel_w,
            h = preview_panel_h,
        },
        avatar_grid = {
            x = grid_x,
            y = grid_y,
            w = grid_width,
            h = grid_height,
        },
        avatar_pager_prev = {
            x = pager_x,
            y = pager_y,
            w = pager_width,
            h = pager_height,
        },
        avatar_pager_next = {
            x = pager_x + pager_width + pager_gap,
            y = pager_y,
            w = pager_width,
            h = pager_height,
        },
        avatar_preview = {
            x = preview_x,
            y = preview_y,
            w = preview_size,
            h = preview_size,
        },
        avatar_preview_label = {
            x = preview_panel_x + 12,
            y = preview_y + preview_size + preview_label_gap,
            w = preview_panel_w - 24,
            h = preview_label_h,
        },
        button = {
            x = panel_x + math.floor((panel_width - style.button.width) * 0.5),
            y = button_y,
            w = style.button.width,
            h = style.button.height,
        },
        error = {
            x = input_x,
            y = button_y - error_h - error_gap,
            w = input_row_width,
            h = error_h,
        },
        title = {
            x = panel_x,
            y = panel_y + title_y_offset + 6,
            w = panel_width,
        },
        steam_id = {
            x = panel_x + 28,
            y = panel_y + title_y_offset + 20,
            w = 260,
            h = 24,
        },
    }
end

return NicknameCheckLayout
