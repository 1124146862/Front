local AvatarTile = {}
local AccessoryRenderer = require("src.features.session.accessories.renderer")

local PATTERNS = {
    {
        primary = { { 1, 1 }, { 2, 1 }, { 3, 1 }, { 4, 1 }, { 1, 2 }, { 4, 2 }, { 2, 3 }, { 3, 3 }, { 2, 4 }, { 3, 4 } },
        secondary = { { 0, 0 }, { 5, 0 }, { 0, 5 }, { 5, 5 }, { 1, 5 }, { 4, 5 } },
        detail = { { 2, 2 }, { 3, 2 } },
    },
    {
        primary = { { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 1, 1 }, { 4, 1 }, { 1, 2 }, { 4, 2 }, { 2, 4 }, { 3, 4 } },
        secondary = { { 0, 2 }, { 5, 2 }, { 0, 3 }, { 5, 3 }, { 1, 5 }, { 4, 5 } },
        detail = { { 2, 2 }, { 3, 2 }, { 2, 3 }, { 3, 3 } },
    },
    {
        primary = { { 2, 0 }, { 3, 0 }, { 1, 1 }, { 4, 1 }, { 0, 2 }, { 5, 2 }, { 0, 3 }, { 5, 3 }, { 1, 4 }, { 4, 4 }, { 2, 5 }, { 3, 5 } },
        secondary = { { 2, 1 }, { 3, 1 }, { 2, 4 }, { 3, 4 } },
        detail = { { 2, 2 }, { 3, 2 } },
    },
    {
        primary = { { 1, 1 }, { 2, 1 }, { 3, 1 }, { 4, 1 }, { 1, 2 }, { 4, 2 }, { 1, 3 }, { 4, 3 }, { 2, 4 }, { 3, 4 } },
        secondary = { { 0, 0 }, { 5, 0 }, { 0, 5 }, { 5, 5 }, { 2, 0 }, { 3, 0 } },
        detail = { { 2, 2 }, { 3, 2 }, { 2, 3 }, { 3, 3 } },
    },
    {
        primary = { { 0, 1 }, { 5, 1 }, { 1, 2 }, { 4, 2 }, { 2, 3 }, { 3, 3 }, { 2, 4 }, { 3, 4 } },
        secondary = { { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 0, 5 }, { 5, 5 } },
        detail = { { 1, 3 }, { 4, 3 } },
    },
    {
        primary = { { 1, 1 }, { 4, 1 }, { 1, 2 }, { 4, 2 }, { 2, 3 }, { 3, 3 }, { 2, 4 }, { 3, 4 }, { 1, 5 }, { 4, 5 } },
        secondary = { { 2, 0 }, { 3, 0 }, { 0, 2 }, { 5, 2 }, { 0, 4 }, { 5, 4 } },
        detail = { { 2, 2 }, { 3, 2 } },
    },
    {
        primary = { { 0, 1 }, { 1, 1 }, { 4, 1 }, { 5, 1 }, { 1, 2 }, { 4, 2 }, { 2, 3 }, { 3, 3 }, { 1, 4 }, { 4, 4 } },
        secondary = { { 2, 0 }, { 3, 0 }, { 2, 5 }, { 3, 5 } },
        detail = { { 2, 2 }, { 3, 2 }, { 2, 4 }, { 3, 4 } },
    },
    {
        primary = { { 2, 0 }, { 3, 0 }, { 1, 1 }, { 4, 1 }, { 0, 2 }, { 5, 2 }, { 1, 3 }, { 4, 3 }, { 2, 4 }, { 3, 4 } },
        secondary = { { 0, 5 }, { 1, 5 }, { 4, 5 }, { 5, 5 }, { 2, 2 }, { 3, 2 } },
        detail = { { 2, 3 }, { 3, 3 } },
    },
}

local function drawCells(cells, color, start_x, start_y, cell_size)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    for _, cell in ipairs(cells) do
        local x = start_x + cell[1] * cell_size
        local y = start_y + cell[2] * cell_size
        love.graphics.rectangle("fill", x, y, cell_size, cell_size)
    end
end

local function buildContentBounds(bounds, options, default_padding_ratio)
    local padding_ratio = (options and options.content_padding_ratio) or default_padding_ratio or 0.12
    local padding = math.max(2, math.floor(math.min(bounds.w, bounds.h) * padding_ratio))
    if options and options.compact == true then
        padding = math.max(1, math.floor(math.min(bounds.w, bounds.h) * padding_ratio))
    end
    return {
        x = bounds.x + padding,
        y = bounds.y + padding,
        w = math.max(1, bounds.w - padding * 2),
        h = math.max(1, bounds.h - padding * 2),
    }
end

local function resolveBackdropColor(avatar, surface)
    if avatar and avatar.pixel_art and avatar.pixel_art.background then
        return avatar.pixel_art.background
    end

    if avatar and avatar.colors and avatar.colors.bg then
        return avatar.colors.bg
    end

    return surface
end

local function drawBackdropRect(avatar, rect, surface)
    local background = resolveBackdropColor(avatar, surface)

    love.graphics.setColor(background[1], background[2], background[3], background[4] or 1)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, rect.radius or 12, rect.radius or 12)
end

local function buildArtBackdropRect(bounds, art_x, art_y, art_w, art_h, options)
    local compact = options and options.compact == true
    local preview = options and options.preview == true
    local margin = compact and 8 or (preview and 10 or 6)
    local radius = compact and 12 or (preview and 18 or 12)
    local size = math.max(art_w, art_h) + margin * 2
    local center_x = art_x + art_w * 0.5
    local center_y = art_y + art_h * 0.5
    local x = math.floor(center_x - size * 0.5)
    local y = math.floor(center_y - size * 0.5)
    local min_x = bounds.x + 2
    local min_y = bounds.y + 2
    local max_x = bounds.x + bounds.w - size - 2
    local max_y = bounds.y + bounds.h - size - 2

    if max_x < min_x then
        x = bounds.x + math.floor((bounds.w - size) * 0.5)
    else
        x = math.max(min_x, math.min(x, max_x))
    end

    if max_y < min_y then
        y = bounds.y + math.floor((bounds.h - size) * 0.5)
    else
        y = math.max(min_y, math.min(y, max_y))
    end

    return {
        x = x,
        y = y,
        w = math.min(size, bounds.w - 4),
        h = math.min(size, bounds.h - 4),
        radius = radius,
    }
end

local function drawPixelArt(avatar, bounds, options, surface, content_bounds)
    local art = avatar.pixel_art
    if not art or not art.rows or #art.rows == 0 then
        return false
    end

    local row_count = #art.rows
    local column_count = 0
    for _, row in ipairs(art.rows) do
        column_count = math.max(column_count, #row)
    end

    if column_count == 0 then
        return false
    end

    content_bounds = content_bounds or buildContentBounds(bounds, options, 0.12)
    local available_width = content_bounds.w
    local available_height = content_bounds.h
    local cell_size = math.max(1, math.floor(math.min(available_width / column_count, available_height / row_count)))
    local art_width = cell_size * column_count
    local art_height = cell_size * row_count
    local start_x = content_bounds.x + math.floor((content_bounds.w - art_width) / 2)
    local start_y = content_bounds.y + math.floor((content_bounds.h - art_height) / 2)

    if not (options and options.compact == true) and not (options and options.candidate_grid == true) then
        drawBackdropRect(avatar, buildArtBackdropRect(bounds, start_x, start_y, art_width, art_height, options), surface)
    end

    for row_index, row in ipairs(art.rows) do
        for column_index = 1, #row do
            local token = row:sub(column_index, column_index)
            local color = art.palette and art.palette[token]
            if color then
                local x = start_x + (column_index - 1) * cell_size
                local y = start_y + (row_index - 1) * cell_size
                love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
                love.graphics.rectangle("fill", x, y, cell_size, cell_size)
            end
        end
    end

    return true
end

local function drawCustomAvatar(avatar, bounds, options, surface, content_bounds)
    if type(avatar.draw) ~= "function" then
        return false
    end

    content_bounds = content_bounds or buildContentBounds(bounds, options, 0.08)
    local preview = options and options.preview == true
    local compact = options and options.compact == true
    if not compact and not (options and options.candidate_grid == true) then
        local inset = preview and 8 or 4
        drawBackdropRect(avatar, {
            x = content_bounds.x - inset,
            y = content_bounds.y - inset,
            w = content_bounds.w + inset * 2,
            h = content_bounds.h + inset * 2,
            radius = preview and 18 or 12,
        }, surface)
    end
    avatar.draw(content_bounds)
    return true
end

local function drawFallbackPattern(avatar, bounds, options, surface)
    local content_bounds = buildContentBounds(bounds, options, 0.08)
    local pixel_size = math.max(1, math.floor(math.min(content_bounds.w, content_bounds.h) / 6))
    local pixel_w = pixel_size * 6
    local pixel_h = pixel_size * 6
    local pixel_x = content_bounds.x + math.floor((content_bounds.w - pixel_w) / 2)
    local pixel_y = content_bounds.y + math.floor((content_bounds.h - pixel_h) / 2)
    local pattern = PATTERNS[avatar.seed] or PATTERNS[1]

    if not (options and options.compact == true) and not (options and options.candidate_grid == true) then
        drawBackdropRect(
            avatar,
            buildArtBackdropRect(bounds, pixel_x, pixel_y, pixel_w, pixel_h, options),
            surface
        )
    end
    drawCells(pattern.secondary, avatar.colors.secondary, pixel_x, pixel_y, pixel_size)
    drawCells(pattern.primary, avatar.colors.primary, pixel_x, pixel_y, pixel_size)
    drawCells(pattern.detail, avatar.colors.detail, pixel_x, pixel_y, pixel_size)
end

function AvatarTile.draw(style, avatar, bounds, options)
    local colors = style.colors
    local hovered = options and options.hovered == true
    local selected = options and options.selected == true
    local compact = options and options.compact == true
    local candidate_grid = options and options.candidate_grid == true
    local pin_frame = options and options.pin_frame == true
    local has_equipped_frame = false
    local palette = avatar.colors
    local shadow = colors.card_shadow or colors.avatar_shadow or { 0.22, 0.14, 0.08, 0.10 }
    local surface = colors.card_surface or colors.avatar_fill or { 0.99, 0.95, 0.84, 0.96 }
    local border = colors.card_outline or colors.avatar_border or { 0.51, 0.31, 0.16, 0.16 }
    if pin_frame then
        shadow = colors.button_secondary_shadow or { 0, 0, 0, 0.35 }
        surface = colors.button_secondary_face or surface
        border = colors.button_secondary_border or border
        if selected then
            border = colors.button_primary_border or colors.avatar_selected or border
        elseif hovered then
            surface = colors.button_secondary_hover_face or surface
            border = colors.avatar_hover or border
        end
    else
        if selected then
            border = colors.card_outline_selected or colors.avatar_selected
        elseif hovered then
            border = colors.card_outline_hover or colors.avatar_hover
        end
    end

    local shadow_alpha = (shadow[4] or 0.10) * (selected and 1.15 or 1)
    local shadow_offset = pin_frame and 3 or (compact and 1 or 2)
    local radius = pin_frame and 0 or style.avatar.radius
    if not has_equipped_frame then
        love.graphics.setColor(shadow[1], shadow[2], shadow[3], shadow_alpha)
        love.graphics.rectangle("fill", bounds.x, bounds.y + shadow_offset, bounds.w, bounds.h, radius, radius)

        love.graphics.setColor(surface[1], surface[2], surface[3], surface[4])
        love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.w, bounds.h, radius, radius)

        if not compact and not candidate_grid then
            love.graphics.setColor(1, 1, 1, hovered and 0.18 or 0.12)
            love.graphics.rectangle("fill", bounds.x + 2, bounds.y + 2, bounds.w - 4, math.max(6, math.floor(bounds.h * 0.16)), math.max(0, radius - 2), math.max(0, radius - 2))
        end
    end

    local default_padding = type(avatar.draw) == "function" and 0.08 or 0.12
    if has_equipped_frame then
        default_padding = type(avatar.draw) == "function" and 0.03 or 0.05
    elseif compact then
        default_padding = type(avatar.draw) == "function" and 0.01 or 0.02
    end
    if candidate_grid then
        default_padding = type(avatar.draw) == "function" and 0.03 or 0.06
    end
    local content_bounds = buildContentBounds(bounds, options, default_padding)

    if not drawCustomAvatar(avatar, bounds, options, colors.card_surface_secondary or surface, content_bounds)
        and not drawPixelArt(avatar, bounds, options, colors.card_surface_secondary or surface, content_bounds) then
        drawFallbackPattern(avatar, bounds, options, colors.card_surface_secondary or surface)
    end

    if not has_equipped_frame then
        if candidate_grid and not (selected or hovered) then
            love.graphics.setLineWidth(1)
            return
        end
        love.graphics.setLineWidth(pin_frame and 3 or (selected and 1.5 or 1))
        love.graphics.setColor(border[1], border[2], border[3], border[4])
        love.graphics.rectangle("line", bounds.x + 0.5, bounds.y + 0.5, bounds.w - 1, bounds.h - 1, radius, radius)
        if pin_frame then
            love.graphics.setColor(1, 0.97, 0.88, 0.18)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", bounds.x + 2.5, bounds.y + 2.5, bounds.w - 5, bounds.h - 5)
        end
    end
    love.graphics.setLineWidth(1)
end

function AvatarTile.drawArt(style, avatar, bounds, options)
    local colors = style.colors
    local surface = colors.card_surface_secondary or colors.card_surface or colors.avatar_fill or { 0.99, 0.95, 0.84, 0.96 }
    local art_options = {
        compact = true,
        candidate_grid = true,
        content_padding_ratio = options and options.content_padding_ratio or 0.06,
    }
    if options and options.preview == true then
        art_options.preview = true
    end

    if not drawCustomAvatar(avatar, bounds, art_options, surface)
        and not drawPixelArt(avatar, bounds, art_options, surface) then
        drawFallbackPattern(avatar, bounds, art_options, surface)
    end
end

return AvatarTile
