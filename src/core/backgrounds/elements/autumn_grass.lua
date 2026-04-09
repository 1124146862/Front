local FallCao = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    straw      = C(177, 148, 86),
    strawDark  = C(126, 103, 58),
    strawLight = C(214, 189, 118),
    olive      = C(124, 118, 60),
    shadow     = C(86, 66, 43),
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

function FallCao.draw(x, y, s, dir, style)
    dir = dir or 1
    style = style or 1

    local W = 18

    if style == 1 then
        -- 低矮稀疏枯草
        dpx(x, y, W, dir, 3, 14, 10, 1, palette.shadow, s, 0.18)

        dpx(x, y, W, dir, 4, 10, 1, 4, palette.strawDark, s)
        dpx(x, y, W, dir, 6, 8,  1, 6, palette.straw, s)
        dpx(x, y, W, dir, 8, 7,  1, 7, palette.strawLight, s)
        dpx(x, y, W, dir, 10, 9, 1, 5, palette.straw, s)
        dpx(x, y, W, dir, 12, 11, 1, 3, palette.olive, s)

        dpx(x, y, W, dir, 5, 11, 3, 1, palette.strawDark, s)
        dpx(x, y, W, dir, 8, 12, 3, 1, palette.straw, s)
        dpx(x, y, W, dir, 10, 10, 2, 1, palette.strawLight, s)

    else
        -- 稍厚一点的一簇枯草
        dpx(x, y, W, dir, 2, 14, 12, 1, palette.shadow, s, 0.20)

        dpx(x, y, W, dir, 4, 10, 1, 4, palette.strawDark, s)
        dpx(x, y, W, dir, 5, 8,  1, 6, palette.straw, s)
        dpx(x, y, W, dir, 7, 6,  1, 8, palette.strawLight, s)
        dpx(x, y, W, dir, 8, 7,  1, 7, palette.straw, s)
        dpx(x, y, W, dir, 10, 9, 1, 5, palette.olive, s)
        dpx(x, y, W, dir, 11, 8, 1, 6, palette.straw, s)
        dpx(x, y, W, dir, 13, 10, 1, 4, palette.strawDark, s)

        dpx(x, y, W, dir, 5, 12, 4, 1, palette.strawDark, s)
        dpx(x, y, W, dir, 8, 11, 4, 1, palette.straw, s)
        dpx(x, y, W, dir, 10, 10, 2, 1, palette.strawLight, s)
    end
end

function FallCao.drawRandom(rng, x, y, s)
    local dir = rng:random(0, 1) == 0 and -1 or 1
    local style = rng:random(1, 2)
    FallCao.draw(x, y, s, dir, style)
end

return FallCao