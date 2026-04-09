local FallHua = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    stem       = C(108, 112, 58),
    stemDark   = C(81, 85, 43),

    petalA     = C(228, 196, 86),   -- 金黄
    petalALight= C(245, 220, 124),

    petalB     = C(214, 141, 66),   -- 暖橙
    petalBLight= C(233, 174, 105),

    petalC     = C(235, 228, 210),  -- 偏白秋菊
    petalCLight= C(249, 243, 230),

    center     = C(130, 84, 37),
    shadow     = C(88, 62, 40),
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function dpx(ox, oy, spriteW, dir, rx, ry, w, h, c, s, a)
    local tx
    if dir == 1 then
        tx = rx
    else
        tx = spriteW - rx - (w or 1)
    end

    local sx = math.floor(ox + tx * s + 0.5)
    local sy = math.floor(oy + ry * s + 0.5)
    local sw = math.max(1, math.floor((w or 1) * s + 0.5))
    local sh = math.max(1, math.floor((h or 1) * s + 0.5))

    setColor(c, a)
    love.graphics.rectangle("fill", sx, sy, sw, sh)
end

local function getFlowerColors(style)
    if style == 1 then
        return palette.petalA, palette.petalALight
    elseif style == 2 then
        return palette.petalB, palette.petalBLight
    else
        return palette.petalC, palette.petalCLight
    end
end

function FallHua.draw(x, y, s, dir, style)
    dir = dir or 1
    style = style or 1

    local W = 20
    local petal, petalLight = getFlowerColors(style)

    -- 影子
    dpx(x, y, W, dir, 5, 15, 8, 1, palette.shadow, s, 0.14)

    -- 茎叶
    dpx(x, y, W, dir, 8, 9, 1, 6, palette.stemDark, s)
    dpx(x, y, W, dir, 11, 10, 1, 5, palette.stem, s)
    dpx(x, y, W, dir, 7, 12, 2, 1, palette.stem, s)
    dpx(x, y, W, dir, 11, 12, 2, 1, palette.stemDark, s)

    -- 左花
    dpx(x, y, W, dir, 4, 6, 1, 1, petal, s)
    dpx(x, y, W, dir, 5, 5, 2, 1, petal, s)
    dpx(x, y, W, dir, 5, 6, 2, 2, petalLight, s)
    dpx(x, y, W, dir, 6, 6, 1, 1, palette.center, s)

    -- 中花
    dpx(x, y, W, dir, 8, 4, 1, 1, petal, s)
    dpx(x, y, W, dir, 9, 3, 2, 1, petal, s)
    dpx(x, y, W, dir, 9, 4, 2, 2, petalLight, s)
    dpx(x, y, W, dir, 10, 4, 1, 1, palette.center, s)

    -- 右花
    dpx(x, y, W, dir, 12, 6, 1, 1, petal, s)
    dpx(x, y, W, dir, 13, 5, 2, 1, petal, s)
    dpx(x, y, W, dir, 13, 6, 2, 2, petalLight, s)
    dpx(x, y, W, dir, 14, 6, 1, 1, palette.center, s)
end

function FallHua.drawRandom(rng, x, y, s)
    local dir = rng:random(0, 1) == 0 and -1 or 1
    local style = rng:random(1, 3)
    FallHua.draw(x, y, s, dir, style)
end

return FallHua