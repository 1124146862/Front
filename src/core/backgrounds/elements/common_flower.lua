local Hua = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    pink      = C(244, 164, 200),
    pinkDark  = C(212, 102, 153),
    pinkLight = C(252, 212, 228),
    blossom   = C(255, 238, 244),
    yellow    = C(245, 223, 113),
    cream     = C(255, 247, 225),
    leaf      = C(98, 161, 79),
    leafLight = C(130, 192, 101),
    stem      = C(76, 126, 59),
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function spx(ox, oy, rx, ry, w, h, c, s, a)
    local sx = math.floor(ox + rx * s + 0.5)
    local sy = math.floor(oy + ry * s + 0.5)
    local sw = math.max(1, math.floor((w or 1) * s + 0.5))
    local sh = math.max(1, math.floor((h or 1) * s + 0.5))
    setColor(c, a)
    love.graphics.rectangle("fill", sx, sy, sw, sh)
end

local function bloom(ox, oy, rx, ry, petal, s)
    spx(ox, oy, rx + 2, ry + 0, 1, 1, petal, s)
    spx(ox, oy, rx + 1, ry + 1, 1, 1, petal, s)
    spx(ox, oy, rx + 3, ry + 1, 1, 1, petal, s)
    spx(ox, oy, rx + 0, ry + 2, 1, 1, petal, s)
    spx(ox, oy, rx + 4, ry + 2, 1, 1, petal, s)
    spx(ox, oy, rx + 1, ry + 3, 1, 1, petal, s)
    spx(ox, oy, rx + 3, ry + 3, 1, 1, petal, s)
    spx(ox, oy, rx + 2, ry + 4, 1, 1, petal, s)
    spx(ox, oy, rx + 2, ry + 2, 1, 1, palette.yellow, s)
end

function Hua.drawType1(rng, x, y, s)
    -- 春日团花
    spx(x, y, 3, 8, 1, 6, palette.stem, s)
    spx(x, y, 9, 9, 1, 5, palette.stem, s)
    spx(x, y, 14, 8, 1, 6, palette.stem, s)

    spx(x, y, 2, 11, 2, 1, palette.leaf, s)
    spx(x, y, 4, 10, 2, 1, palette.leafLight, s)
    spx(x, y, 8, 11, 2, 1, palette.leaf, s)
    spx(x, y, 13, 10, 2, 1, palette.leafLight, s)

    bloom(x, y, 1, 2, palette.pink, s)
    bloom(x, y, 7, 3, palette.blossom, s)
    bloom(x, y, 12, 2, palette.pinkLight, s)
end

function Hua.drawType2(rng, x, y, s)
    -- 郁金香簇
    for i = 0, 2 do
        local ox = i * 6
        spx(x, y, ox + 2, 7, 1, 6, palette.stem, s)
        spx(x, y, ox + 1, 10, 1, 1, palette.leaf, s)
        spx(x, y, ox + 3, 10, 1, 1, palette.leafLight, s)

        local bloomColor
        if i == 0 then
            bloomColor = palette.pink
        elseif i == 1 then
            bloomColor = palette.pinkDark
        else
            bloomColor = palette.pinkLight
        end

        spx(x, y, ox + 1, 4, 3, 1, bloomColor, s)
        spx(x, y, ox + 2, 3, 1, 1, palette.pinkLight, s)
        spx(x, y, ox + 1, 5, 1, 1, palette.pinkDark, s)
        spx(x, y, ox + 3, 5, 1, 1, palette.pinkDark, s)
    end
end

function Hua.drawType3(rng, x, y, s)
    -- 野花小簇
    spx(x, y, 2, 8, 1, 5, palette.stem, s)
    spx(x, y, 7, 9, 1, 4, palette.stem, s)
    spx(x, y, 12, 8, 1, 5, palette.stem, s)
    spx(x, y, 5, 7, 1, 5, palette.stem, s)

    spx(x, y, 1, 10, 2, 1, palette.leaf, s)
    spx(x, y, 6, 10, 2, 1, palette.leafLight, s)
    spx(x, y, 11, 10, 2, 1, palette.leaf, s)

    bloom(x, y, 0, 2, palette.blossom, s)
    bloom(x, y, 5, 3, palette.pinkLight, s)
    bloom(x, y, 10, 2, palette.pink, s)

    spx(x, y, 5, 1, 1, 1, palette.cream, s)
    spx(x, y, 6, 2, 1, 1, palette.pinkLight, s)
end

function Hua.drawRandom(rng, x, y, s)
    local kind = rng:random(1, 3)
    if kind == 1 then
        Hua.drawType1(rng, x, y, s)
    elseif kind == 2 then
        Hua.drawType2(rng, x, y, s)
    else
        Hua.drawType3(rng, x, y, s)
    end
end

return Hua