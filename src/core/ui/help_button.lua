local HelpButton = {}
HelpButton.__index = HelpButton

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

local function drawQuestionIcon(ox, oy, ps, color)
    local cells = {
        { 2, 0 }, { 3, 0 }, { 4, 0 }, { 5, 0 },
        { 1, 1 }, { 6, 1 },
        { 6, 2 },
        { 5, 3 },
        { 4, 4 },
        { 4, 5 },
        { 4, 6 },
        { 4, 9 }, { 4, 10 },
    }
    drawPixels(ox, oy, ps, cells, color)
end

function HelpButton.new()
    return setmetatable({}, HelpButton)
end

function HelpButton:draw(frame, options)
    options = options or {}
    if options.visible == false then
        return
    end

    local hovered = options.hovered == true
    local pressed = options.pressed == true

    local bg = { 0.08, 0.08, 0.08, 0.86 }
    local border = { 1, 1, 1, 0.18 }
    local icon = { 0.96, 0.96, 0.96, 1 }

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

    local ps = math.max(2, math.floor(math.min(frame.width / 12, frame.height / 14)))
    local icon_w = 8 * ps
    local icon_h = 12 * ps
    local ox = math.floor(frame.x + (frame.width - icon_w) * 0.5)
    local oy = math.floor(frame.y + (frame.height - icon_h) * 0.5)

    drawQuestionIcon(ox, oy, ps, icon)
end

return HelpButton
