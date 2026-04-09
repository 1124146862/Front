local MuteButton = {}
MuteButton.__index = MuteButton

local function fillRect(x, y, w, h)
    love.graphics.rectangle("fill", x, y, w, h)
end

local function contains(frame, x, y)
    return x >= frame.x
        and x <= frame.x + frame.width
        and y >= frame.y
        and y <= frame.y + frame.height
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

local function drawSpeaker(ox, oy, ps, color)
    local cells = {
        { 2, 4 }, { 3, 4 }, { 4, 4 },
        { 2, 5 }, { 3, 5 }, { 4, 5 },
        { 2, 6 }, { 3, 6 }, { 4, 6 },

        { 5, 3 }, { 5, 4 }, { 5, 5 }, { 5, 6 }, { 5, 7 },
        { 6, 2 }, { 6, 3 }, { 6, 4 }, { 6, 5 }, { 6, 6 }, { 6, 7 }, { 6, 8 },
        { 7, 2 }, { 7, 3 }, { 7, 4 }, { 7, 5 }, { 7, 6 }, { 7, 7 }, { 7, 8 },
    }
    drawPixels(ox, oy, ps, cells, color)
end

local function drawWaves(ox, oy, ps, color)
    local cells = {
        { 9, 3 }, { 10, 4 }, { 10, 5 }, { 10, 6 }, { 9, 7 },
        { 12, 2 }, { 13, 3 }, { 14, 4 }, { 14, 5 }, { 14, 6 }, { 13, 7 }, { 12, 8 },
    }
    drawPixels(ox, oy, ps, cells, color)
end

local function drawMuteCross(ox, oy, ps, color)
    local cells = {
        { 9, 2 }, { 10, 3 }, { 11, 4 }, { 12, 5 }, { 13, 6 }, { 14, 7 },
        { 14, 2 }, { 13, 3 }, { 12, 4 }, { 11, 5 }, { 10, 6 }, { 9, 7 },
        { 8, 1 }, { 15, 8 }, { 15, 1 }, { 8, 8 },
    }
    drawPixels(ox, oy, ps, cells, color)
end

function MuteButton.new()
    return setmetatable({}, MuteButton)
end

function MuteButton:contains(frame, x, y)
    return contains(frame, x, y)
end

function MuteButton:draw(frame, options)
    options = options or {}
    if options.visible == false then
        return
    end

    local muted = options.muted == true
    local hovered = options.hovered == true
    local pressed = options.pressed == true

    local bg = { 0.08, 0.08, 0.08, 0.86 }
    local border = { 1, 1, 1, 0.18 }
    local icon = { 0.96, 0.96, 0.96, 1 }
    local accent = muted and { 0.92, 0.28, 0.28, 1 } or { 0.96, 0.82, 0.22, 1 }

    if hovered then
        bg = { 0.14, 0.14, 0.14, 0.94 }
        border = { 1, 1, 1, 0.28 }
    end

    if pressed then
        bg = { 0.05, 0.05, 0.05, 0.98 }
    end

    love.graphics.setColor(0, 0, 0, 0.22)
    fillRect(frame.x + 2, frame.y + 2, frame.width, frame.height)

    love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
    fillRect(frame.x, frame.y, frame.width, frame.height)

    love.graphics.setColor(border[1], border[2], border[3], border[4])
    love.graphics.rectangle("line", frame.x, frame.y, frame.width, frame.height)

    local ps = math.max(2, math.floor(math.min(frame.width / 16, frame.height / 11)))
    local icon_w = 16 * ps
    local icon_h = 11 * ps
    local ox = math.floor(frame.x + (frame.width - icon_w) * 0.5)
    local oy = math.floor(frame.y + (frame.height - icon_h) * 0.5)

    drawSpeaker(ox, oy, ps, icon)
    if muted then
        drawMuteCross(ox, oy, ps, accent)
    else
        drawWaves(ox, oy, ps, accent)
    end
end

return MuteButton
