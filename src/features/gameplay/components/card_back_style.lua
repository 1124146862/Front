local CardBackStyle = {}

local STYLES = {
    classic_grid = {
        border = { 0.99, 1.0, 1.0, 0.98 },
        face = { 0.20, 0.35, 0.60, 0.96 },
        line = { 0.90, 0.95, 0.99, 0.72 },
        accent = { 0.98, 0.99, 1.0, 0.82 },
        pattern = "grid",
    },
    emerald_lattice = {
        border = { 0.98, 1.0, 0.97, 0.98 },
        face = { 0.18, 0.47, 0.34, 0.97 },
        line = { 0.83, 0.95, 0.86, 0.74 },
        accent = { 0.96, 1.0, 0.96, 0.84 },
        pattern = "lattice",
    },
    crimson_fan = {
        border = { 1.0, 0.97, 0.96, 0.98 },
        face = { 0.67, 0.22, 0.26, 0.97 },
        line = { 0.96, 0.84, 0.82, 0.70 },
        accent = { 1.0, 0.96, 0.95, 0.84 },
        pattern = "fan",
    },
    violet_tile = {
        border = { 0.98, 0.97, 1.0, 0.98 },
        face = { 0.42, 0.31, 0.63, 0.97 },
        line = { 0.87, 0.82, 0.97, 0.72 },
        accent = { 0.97, 0.95, 1.0, 0.82 },
        pattern = "tile",
    },
    midnight_star = {
        border = { 0.95, 0.97, 1.0, 0.98 },
        face = { 0.10, 0.16, 0.28, 0.98 },
        line = { 0.63, 0.76, 0.95, 0.60 },
        accent = { 0.96, 0.92, 0.72, 0.88 },
        pattern = "star",
    },
}

local function resolveStyle(back_id)
    if back_id == "placeholder_clean" then
        back_id = "violet_tile"
    elseif back_id == "placeholder_dark" then
        back_id = "midnight_star"
    end
    return STYLES[back_id] or STYLES.classic_grid
end

local function drawGrid(left, top, width, height, style)
    love.graphics.setColor(style.line)
    local col_step = math.max(6, math.floor(width / 4))
    local row_step = math.max(7, math.floor(height / 6))
    for gx = left + 7, left + width - 7, col_step do
        love.graphics.rectangle("fill", gx, top + 6, 1, height - 12)
    end
    for gy = top + 8, top + height - 8, row_step do
        love.graphics.rectangle("fill", left + 6, gy, width - 12, 1)
    end
end

local function drawLattice(left, top, width, height, style)
    love.graphics.setColor(style.line)
    local step = math.max(10, math.floor(math.min(width, height) / 4))
    for i = -height, width + height, step do
        love.graphics.line(left + i, top, left + i + height, top + height)
        love.graphics.line(left + i, top + height, left + i + height, top)
    end
    love.graphics.setColor(style.accent[1], style.accent[2], style.accent[3], 0.28)
    local cx = left + width * 0.5
    local cy = top + height * 0.5
    local d = math.floor(math.min(width, height) * 0.14)
    love.graphics.polygon("fill", cx, cy - d, cx + d, cy, cx, cy + d, cx - d, cy)
end

local function drawFan(left, top, width, height, style)
    love.graphics.setColor(style.line)
    local cx = left + width * 0.5
    local base_y = top + height - 8
    for offset = -width * 0.45, width * 0.45, math.max(8, math.floor(width / 6)) do
        love.graphics.line(cx + offset * 0.2, base_y, left + width * 0.5 + offset, top + 8)
    end
    love.graphics.setColor(style.accent[1], style.accent[2], style.accent[3], 0.36)
    love.graphics.circle("fill", cx, top + height * 0.5, math.floor(math.min(width, height) * 0.13))
end

local function drawTile(left, top, width, height, style)
    love.graphics.setColor(style.line)
    local step = math.max(10, math.floor(math.min(width, height) / 3.5))
    local tile_w = math.max(6, step - 4)
    local tile_h = math.max(6, step - 4)
    for y = top + 8, top + height - 8, step do
        for x = left + 8, left + width - 8, step do
            love.graphics.rectangle("line", x, y, tile_w, tile_h, 2, 2)
        end
    end
    love.graphics.setColor(style.accent[1], style.accent[2], style.accent[3], 0.24)
    love.graphics.rectangle("fill", left + width * 0.3, top + height * 0.3, width * 0.4, height * 0.4, 4, 4)
end

local function drawStar(left, top, width, height, style)
    love.graphics.setColor(style.line)
    local stars = {
        { 0.28, 0.24, 1.0 },
        { 0.68, 0.22, 0.8 },
        { 0.52, 0.52, 1.1 },
        { 0.24, 0.72, 0.8 },
        { 0.74, 0.68, 1.0 },
    }
    for _, star in ipairs(stars) do
        local x = left + width * star[1]
        local y = top + height * star[2]
        local s = math.max(1, math.floor(star[3]))
        love.graphics.rectangle("fill", x - s, y, s * 2 + 1, 1)
        love.graphics.rectangle("fill", x, y - s, 1, s * 2 + 1)
    end
    love.graphics.setColor(style.accent[1], style.accent[2], style.accent[3], 0.30)
    love.graphics.circle("line", left + width * 0.5, top + height * 0.5, math.floor(math.min(width, height) * 0.18))
end

local function drawAccent(left, top, width, height, style)
    love.graphics.setColor(style.accent)
    local cx = left + width * 0.5
    local cy = top + height * 0.5
    local size = math.floor(math.min(width, height) * 0.14)
    love.graphics.polygon("fill", {
        cx, cy - size,
        cx + size, cy,
        cx, cy + size,
        cx - size, cy,
    })
end

function CardBackStyle.get(back_id)
    return resolveStyle(back_id)
end

function CardBackStyle.draw(left, top, width, height, back_id, options)
    local opts = options or {}
    local style = resolveStyle(back_id)
    local outer_radius = opts.outer_radius or math.max(3, math.floor(math.min(width, height) * 0.16))
    local inset = opts.inset or 2
    local inner_radius = opts.inner_radius or math.max(2, outer_radius - 2)
    local inner_left = left + inset
    local inner_top = top + inset
    local inner_width = width - inset * 2
    local inner_height = height - inset * 2

    love.graphics.setColor(style.border)
    love.graphics.rectangle("fill", left, top, width, height, outer_radius, outer_radius)

    love.graphics.setColor(style.face)
    love.graphics.rectangle("fill", inner_left, inner_top, inner_width, inner_height, inner_radius, inner_radius)

    love.graphics.stencil(function()
        love.graphics.rectangle("fill", inner_left, inner_top, inner_width, inner_height, inner_radius, inner_radius)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    if style.pattern == "grid" then
        drawGrid(left, top, width, height, style)
    elseif style.pattern == "lattice" then
        drawLattice(inner_left, inner_top, inner_width, inner_height, style)
    elseif style.pattern == "fan" then
        drawFan(inner_left, inner_top, inner_width, inner_height, style)
    elseif style.pattern == "tile" then
        drawTile(inner_left, inner_top, inner_width, inner_height, style)
    elseif style.pattern == "star" then
        drawStar(inner_left, inner_top, inner_width, inner_height, style)
    end

    drawAccent(left, top, width, height, style)
    love.graphics.setStencilTest()
end

return CardBackStyle
