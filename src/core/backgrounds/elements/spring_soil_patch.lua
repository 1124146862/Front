local SpringSoil = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    soil       = C(143, 113, 82),
    soilDark   = C(114, 88, 63),
    soilLight  = C(168, 137, 103),
    wet        = C(95, 79, 63),
    moss       = C(124, 145, 79),
    shadow     = C(81, 61, 44),
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

function SpringSoil.draw(x, y, s, dir, style)
    dir = dir or 1
    style = style or 1

    local W = 22

    if style == 1 then
        -- 大一点的湿土块
        dpx(x, y, W, dir, 3, 13, 15, 2, palette.shadow, s, 0.12)

        dpx(x, y, W, dir, 4, 10, 13, 3, palette.soil, s)
        dpx(x, y, W, dir, 6, 9,  9, 2, palette.soilLight, s)
        dpx(x, y, W, dir, 11, 10, 5, 2, palette.soilDark, s)

        dpx(x, y, W, dir, 7, 11, 3, 1, palette.wet, s, 0.55)
        dpx(x, y, W, dir, 5, 10, 2, 1, palette.moss, s, 0.55)

    elseif style == 2 then
        -- 偏细长的一块泥地
        dpx(x, y, W, dir, 4, 13, 13, 2, palette.shadow, s, 0.12)

        dpx(x, y, W, dir, 5, 11, 11, 2, palette.soil, s)
        dpx(x, y, W, dir, 6, 10, 8,  1, palette.soilLight, s)
        dpx(x, y, W, dir, 10, 11, 4, 2, palette.soilDark, s)

        dpx(x, y, W, dir, 8, 12, 3, 1, palette.wet, s, 0.55)

    else
        -- 两小块泥地拼在一起
        dpx(x, y, W, dir, 5, 13, 10, 2, palette.shadow, s, 0.10)

        dpx(x, y, W, dir, 6, 11, 4, 2, palette.soil, s)
        dpx(x, y, W, dir, 7, 10, 2, 1, palette.soilLight, s)
        dpx(x, y, W, dir, 8, 11, 2, 2, palette.soilDark, s)

        dpx(x, y, W, dir, 11, 10, 4, 3, palette.soil, s)
        dpx(x, y, W, dir, 11, 9,  2, 1, palette.soilLight, s)
        dpx(x, y, W, dir, 13, 11, 2, 2, palette.wet, s, 0.45)
    end
end

function SpringSoil.drawRandom(rng, x, y, s)
    local dir = rng:random(0, 1) == 0 and -1 or 1
    local style = rng:random(1, 3)
    SpringSoil.draw(x, y, s, dir, style)
end

return SpringSoil