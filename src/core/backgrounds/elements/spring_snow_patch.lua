local SpringSnow = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    snow       = C(238, 241, 235),
    snowLight  = C(252, 252, 248),
    snowShadow = C(199, 205, 192),
    slush      = C(181, 189, 170),
    meltWater  = C(186, 205, 202),
    shadow     = C(104, 113, 101),
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

function SpringSnow.draw(x, y, s, dir, style)
    dir = dir or 1
    style = style or 1

    local W = 22

    if style == 1 then
        -- 扁平残雪块
        dpx(x, y, W, dir, 4, 13, 12, 2, palette.shadow, s, 0.14)

        dpx(x, y, W, dir, 5, 10, 10, 3, palette.snow, s)
        dpx(x, y, W, dir, 6, 9,  7, 2, palette.snow, s)
        dpx(x, y, W, dir, 8, 8,  3, 1, palette.snowLight, s)

        dpx(x, y, W, dir, 5, 12, 4, 1, palette.snowShadow, s, 0.65)
        dpx(x, y, W, dir, 11, 11, 3, 1, palette.slush, s, 0.65)

        dpx(x, y, W, dir, 9, 12, 2, 1, palette.meltWater, s, 0.50)

    elseif style == 2 then
        -- 边缘破碎一点的融雪
        dpx(x, y, W, dir, 3, 14, 14, 2, palette.shadow, s, 0.14)

        dpx(x, y, W, dir, 4, 11, 12, 2, palette.snow, s)
        dpx(x, y, W, dir, 5, 10, 9,  2, palette.snow, s)
        dpx(x, y, W, dir, 7, 9,  5, 1, palette.snowLight, s)

        dpx(x, y, W, dir, 5, 12, 2, 1, palette.slush, s, 0.70)
        dpx(x, y, W, dir, 10, 12, 4, 1, palette.snowShadow, s, 0.60)
        dpx(x, y, W, dir, 13, 11, 2, 1, palette.meltWater, s, 0.45)

    else
        -- 更小的一团残雪
        dpx(x, y, W, dir, 6, 13, 8, 2, palette.shadow, s, 0.12)

        dpx(x, y, W, dir, 7, 11, 6, 2, palette.snow, s)
        dpx(x, y, W, dir, 8, 10, 4, 1, palette.snowLight, s)
        dpx(x, y, W, dir, 7, 12, 2, 1, palette.snowShadow, s, 0.65)
        dpx(x, y, W, dir, 10, 12, 2, 1, palette.meltWater, s, 0.45)
    end
end

function SpringSnow.drawRandom(rng, x, y, s)
    local dir = rng:random(0, 1) == 0 and -1 or 1
    local style = rng:random(1, 3)
    SpringSnow.draw(x, y, s, dir, style)
end

return SpringSnow