local PastelPatternBackground = {}

local function drawDiamond(cx, cy, size)
    love.graphics.polygon(
        "fill",
        cx, cy - size,
        cx + size, cy,
        cx, cy + size,
        cx - size, cy
    )
end

local function drawCapsule(x, y, w, h)
    love.graphics.rectangle("fill", x, y, w, h, h * 0.5, h * 0.5)
end

function PastelPatternBackground.draw(width, height, options)
    options = options or {}

    local palette = options.palette or {
        { 0.92, 0.72, 0.66, 0.44 },
        { 0.47, 0.77, 0.84, 0.44 },
        { 0.95, 0.84, 0.58, 0.44 },
        { 0.67, 0.79, 0.65, 0.44 },
        { 0.78, 0.58, 0.58, 0.44 },
        { 0.97, 0.72, 0.66, 0.44 },
    }

    love.graphics.setColor(0.96, 0.94, 0.89, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)

    local grid = tonumber(options.grid_size) or 52
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 0.26)
    for gx = 0, width, grid do
        love.graphics.line(gx, 0, gx, height)
    end
    for gy = 0, height, grid do
        love.graphics.line(0, gy, width, gy)
    end

    love.graphics.setColor(1, 1, 1, 0.15)
    for d = -height, width, grid do
        love.graphics.line(d, 0, d + height, height)
    end
    for d = 0, width + height, grid do
        love.graphics.line(d, 0, d - height, height)
    end

    local cell = tonumber(options.cell_size) or 86
    local rows = math.ceil(height / cell) + 1
    local cols = math.ceil(width / cell) + 1

    for row = 0, rows do
        for col = 0, cols do
            local cx = col * cell + ((row % 2 == 0) and 0 or cell * 0.5)
            local cy = row * cell
            local color = palette[((row + col) % #palette) + 1]
            love.graphics.setColor(color)

            local selector = (row * 5 + col * 7) % 6
            if selector == 0 then
                love.graphics.circle("fill", cx, cy, 23, 24)
            elseif selector == 1 then
                love.graphics.rectangle("fill", cx - 22, cy - 22, 44, 44, 11, 11)
            elseif selector == 2 then
                drawDiamond(cx, cy, 22)
            elseif selector == 3 then
                drawCapsule(cx - 18, cy - 8, 36, 16)
            elseif selector == 4 then
                love.graphics.circle("fill", cx, cy, 8, 18)
            else
                love.graphics.rectangle("fill", cx - 7, cy - 7, 14, 14, 5, 5)
            end
        end
    end
end

return PastelPatternBackground
