local GamePlayTimerStyle = {}

local function deepCopy(src)
    if type(src) ~= "table" then
        return src
    end

    local dst = {}
    for k, v in pairs(src) do
        dst[k] = deepCopy(v)
    end
    return dst
end

GamePlayTimerStyle.default = {
    w = 40,
    h = 40,
    offsetY = 10,
    -- 保持和之前逻辑一致，最后 5 秒高亮并播报
    sfxThreshold = 5,

    shadowColor = { 0, 0, 0, 0.35 },
    shadowOffsetX = 4,
    shadowOffsetY = 6,

    frameOuter = { 0.17, 0.22, 0.30, 1 },
    frameMid = { 0.36, 0.46, 0.58, 1 },
    frameLight = { 0.76, 0.84, 0.92, 1 },
    frameInner = { 0.10, 0.13, 0.18, 1 },
    frameRadius = 8,

    bgUnlit = { 0.55, 0.58, 0.55, 1 },
    bgLitGreen = { 0.45, 0.70, 0.45, 1 },

    lightSourceGreen = { 0.60, 0.98, 0.50, 1 },

    segmentOn = { 0.10, 0.12, 0.10, 0.95 },
    segmentOff = { 0.10, 0.12, 0.10, 0.10 },

    seg_t = 3,
    seg_w_h = 6,
    seg_w_v = 9,
    digit_gap = 4,
}

GamePlayTimerStyle.segmentMap = {
    [0] = { true, true, true, true, true, true, false },
    [1] = { false, true, true, false, false, false, false },
    [2] = { true, true, false, true, true, false, true },
    [3] = { true, true, true, true, false, false, true },
    [4] = { false, true, true, false, false, true, true },
    [5] = { true, false, true, true, false, true, true },
    [6] = { true, false, true, true, true, true, true },
    [7] = { true, true, true, false, false, false, false },
    [8] = { true, true, true, true, true, true, true },
    [9] = { true, true, true, true, false, true, true },
}

function GamePlayTimerStyle.getDefaultStyle()
    return deepCopy(GamePlayTimerStyle.default)
end

function GamePlayTimerStyle.apply(style, overrides)
    if type(style) ~= "table" or type(overrides) ~= "table" then
        return
    end

    for k, v in pairs(overrides) do
        style[k] = deepCopy(v)
    end
end

local function drawSegment(x, y, w, h, active, colorOn, colorOff)
    love.graphics.setColor(active and colorOn or colorOff)
    love.graphics.rectangle("fill", x, y, w, h)
end

local function drawDigit(style, x, y, digit, colorOn)
    local seg = GamePlayTimerStyle.segmentMap[tonumber(digit) or 0]
    local t = style.seg_t
    local wh = style.seg_w_h
    local wv = style.seg_w_v
    local off = style.segmentOff

    drawSegment(x + t, y, wh, t, seg[1], colorOn, off)
    drawSegment(x + t + wh, y + t, t, wv, seg[2], colorOn, off)
    drawSegment(x + t + wh, y + t * 2 + wv, t, wv, seg[3], colorOn, off)
    drawSegment(x + t, y + t * 2 + wv * 2, wh, t, seg[4], colorOn, off)
    drawSegment(x, y + t * 2 + wv, t, wv, seg[5], colorOn, off)
    drawSegment(x, y + t, t, wv, seg[6], colorOn, off)
    drawSegment(x + t, y + t + wv, wh, t, seg[7], colorOn, off)
end

local function drawShadow(x, y, s)
    love.graphics.setColor(s.shadowColor)
    love.graphics.rectangle(
        "fill",
        (x - 8) + s.shadowOffsetX,
        (y - 8) + s.shadowOffsetY,
        s.w + 16,
        s.h + 16,
        s.frameRadius,
        s.frameRadius
    )
end

local function drawSolidFrame(x, y, s)
    local radius = s.frameRadius or 8

    love.graphics.setColor(s.frameOuter)
    love.graphics.rectangle("fill", x - 8, y - 8, s.w + 16, s.h + 16, radius, radius)

    love.graphics.setColor(s.frameMid)
    love.graphics.rectangle("fill", x - 5, y - 5, s.w + 10, s.h + 10, math.max(4, radius - 2), math.max(4, radius - 2))

    love.graphics.setColor(s.frameLight)
    love.graphics.rectangle("fill", x - 2, y - 2, s.w + 4, s.h + 4, math.max(3, radius - 4), math.max(3, radius - 4))

    love.graphics.setColor(s.frameInner)
    love.graphics.rectangle("fill", x - 1, y - 1, s.w + 2, s.h + 2, math.max(2, radius - 5), math.max(2, radius - 5))
end

local function drawScreen(timer, x, y, s)
    local isFinalCountdown = timer.running and (tonumber(timer.remaining) or 0) > 0 and (timer.remaining <= s.sfxThreshold)

    love.graphics.setScissor(math.floor(x), math.floor(y), math.floor(s.w), math.floor(s.h))

    if isFinalCountdown then
        love.graphics.setColor(s.bgLitGreen)
        love.graphics.rectangle("fill", x, y, s.w, s.h)

        for i = 1, 6 do
            local alpha = 0.22 - i * 0.03
            if alpha > 0 then
                love.graphics.setColor(
                    s.lightSourceGreen[1],
                    s.lightSourceGreen[2],
                    s.lightSourceGreen[3],
                    alpha
                )
                love.graphics.circle("fill", x + 1, y + 1, 6 + i * 8)
            end
        end
    else
        love.graphics.setColor(s.bgUnlit)
        love.graphics.rectangle("fill", x, y, s.w, s.h)
    end

    love.graphics.setScissor()
end

local function drawDigits(timer, x, y, s)
    local remainInt = timer:getRemainingInt()
    local numStr = string.format("%02d", remainInt)

    local digitWidth = s.seg_t * 2 + s.seg_w_h
    local digitHeight = s.seg_t * 3 + s.seg_w_v * 2
    local totalWidth = digitWidth * 2 + s.digit_gap

    local startX = x + (s.w - totalWidth) / 2
    local startY = y + (s.h - digitHeight) / 2

    for i = 1, #numStr do
        local dx = startX + (i - 1) * (digitWidth + s.digit_gap)
        drawDigit(s, dx, startY, numStr:sub(i, i), s.segmentOn)
    end
end

function GamePlayTimerStyle.draw(timer)
    if not timer or not timer.visible or not timer.currentSeat then
        return
    end

    local anchor = timer.anchors and timer.anchors[timer.currentSeat]
    if not anchor then
        return
    end

    local x = anchor.x
    local y = anchor.y
    local s = timer.style or GamePlayTimerStyle.default

    drawShadow(x, y, s)
    drawSolidFrame(x, y, s)
    drawScreen(timer, x, y, s)
    drawDigits(timer, x, y, s)
end

return GamePlayTimerStyle
