local WardrobeButton = {}
WardrobeButton.__index = WardrobeButton

local function fillRect(x, y, w, h)
    love.graphics.rectangle("fill", x, y, w, h)
end

local function drawPixel(ox, oy, ps, gx, gy, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    fillRect(ox + gx * ps, oy + gy * ps, ps, ps)
end

local function drawPixels(ox, oy, ps, cells, color)
    for _, cell in ipairs(cells) do
        drawPixel(ox, oy, ps, cell[1], cell[2], color)
    end
end

local function drawShirt(ox, oy, ps)
    drawPixels(ox, oy, ps, {
        {2, 0}, {3, 0}, {6, 0}, {7, 0},
        {1, 1}, {2, 1}, {3, 1}, {4, 1}, {5, 1}, {6, 1}, {7, 1}, {8, 1},
        {0, 2}, {1, 2}, {2, 2}, {4, 2}, {5, 2}, {7, 2}, {8, 2}, {9, 2},
        {1, 3}, {2, 3}, {3, 3}, {4, 3}, {5, 3}, {6, 3}, {7, 3}, {8, 3},
        {2, 4}, {3, 4}, {4, 4}, {5, 4}, {6, 4}, {7, 4},
        {2, 5}, {3, 5}, {4, 5}, {5, 5}, {6, 5}, {7, 5},
        {2, 6}, {3, 6}, {4, 6}, {5, 6}, {6, 6}, {7, 6},
        {2, 7}, {3, 7}, {4, 7}, {5, 7}, {6, 7}, {7, 7},
    }, {0.34, 0.68, 0.98, 1})
    drawPixels(ox, oy, ps, {
        {4, 2}, {5, 2}, {4, 3}, {5, 3},
    }, {0.98, 0.86, 0.34, 1})
    drawPixels(ox, oy, ps, {
        {2, 4}, {2, 5}, {7, 4}, {7, 5},
        {3, 7}, {6, 7},
    }, {0.15, 0.28, 0.56, 1})
end

function WardrobeButton.new()
    return setmetatable({}, WardrobeButton)
end

function WardrobeButton:draw(frame, options)
    options = options or {}
    if options.visible == false then
        return
    end

    local hovered = options.hovered == true
    local pressed = options.pressed == true

    local bg = { 0.08, 0.08, 0.08, 0.86 }
    local border = { 1, 1, 1, 0.18 }

    if hovered then
        bg = { 0.14, 0.14, 0.14, 0.94 }
        border = { 1, 1, 1, 0.28 }
    end
    if pressed then
        bg = { 0.05, 0.05, 0.05, 0.98 }
    end

    love.graphics.setColor(0, 0, 0, 0.22)
    fillRect(frame.x + 2, frame.y + 2, frame.width, frame.height)

    love.graphics.setColor(bg)
    fillRect(frame.x, frame.y, frame.width, frame.height)

    love.graphics.setColor(border)
    love.graphics.rectangle("line", frame.x, frame.y, frame.width, frame.height)

    local ps = math.max(2, math.floor(math.min(frame.width / 14, frame.height / 14)))
    local icon_w = 10 * ps
    local icon_h = 8 * ps
    local ox = math.floor(frame.x + (frame.width - icon_w) * 0.5)
    local oy = math.floor(frame.y + (frame.height - icon_h) * 0.5)

    drawShirt(ox, oy, ps)
end

return WardrobeButton
