 local SpringSprout = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    stem       = C(116, 170, 82),
    stemDark   = C(84, 128, 58),
    leaf       = C(166, 216, 112),
    leafLight  = C(208, 236, 154),
    bud        = C(188, 223, 124),
    budLight   = C(226, 243, 176),
    shadow     = C(86, 104, 60),
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

function SpringSprout.draw(x, y, s, dir, style)
    dir = dir or 1
    style = style or 1

    -- 比原来更紧凑
    local W = 16

    if style == 1 then
        -- 低矮双芽簇
        dpx(x, y, W, dir, 3, 13, 8, 1, palette.shadow, s, 0.12)

        -- 左芽
        dpx(x, y, W, dir, 5, 10, 1, 3, palette.stemDark, s)
        dpx(x, y, W, dir, 4, 9,  2, 1, palette.leaf, s)
        dpx(x, y, W, dir, 5, 8,  2, 1, palette.leafLight, s)

        -- 右芽
        dpx(x, y, W, dir, 8, 9,  1, 4, palette.stem, s)
        dpx(x, y, W, dir, 8, 8,  2, 1, palette.leaf, s)
        dpx(x, y, W, dir, 9, 7,  2, 1, palette.leafLight, s)

        -- 中间小芽点
        dpx(x, y, W, dir, 7, 11, 1, 1, palette.bud, s)

    elseif style == 2 then
        -- 三芽簇，中间稍高
        dpx(x, y, W, dir, 2, 13, 10, 1, palette.shadow, s, 0.12)

        -- 左
        dpx(x, y, W, dir, 4, 10, 1, 3, palette.stemDark, s)
        dpx(x, y, W, dir, 3, 9,  2, 1, palette.leaf, s)

        -- 中
        dpx(x, y, W, dir, 7, 8,  1, 5, palette.stem, s)
        dpx(x, y, W, dir, 7, 7,  2, 1, palette.leafLight, s)
        dpx(x, y, W, dir, 8, 6,  2, 1, palette.leaf, s)

        -- 右
        dpx(x, y, W, dir, 10, 10, 1, 3, palette.stemDark, s)
        dpx(x, y, W, dir, 10, 9,  2, 1, palette.leaf, s)

        dpx(x, y, W, dir, 6, 11, 1, 1, palette.budLight, s)

    else
        -- 贴地一点的嫩芽团
        dpx(x, y, W, dir, 3, 13, 9, 1, palette.shadow, s, 0.10)

        -- 左叶
        dpx(x, y, W, dir, 4, 10, 2, 2, palette.leaf, s)
        dpx(x, y, W, dir, 5, 9,  2, 1, palette.leafLight, s)

        -- 中叶
        dpx(x, y, W, dir, 7, 9,  2, 3, palette.leaf, s)
        dpx(x, y, W, dir, 8, 8,  2, 1, palette.leafLight, s)

        -- 右叶
        dpx(x, y, W, dir, 10, 10, 2, 2, palette.leaf, s)
        dpx(x, y, W, dir, 10, 9,  2, 1, palette.bud, s)

        dpx(x, y, W, dir, 7, 11, 1, 1, palette.stemDark, s)
    end
end

function SpringSprout.drawRandom(rng, x, y, s)
    local dir = rng:random(0, 1) == 0 and -1 or 1
    local style = rng:random(1, 3)
    SpringSprout.draw(x, y, s, dir, style)
end

return SpringSprout