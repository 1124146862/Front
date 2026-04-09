local FallRock = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    stone         = C(136, 122, 106),
    stoneDark     = C(96, 84, 73),
    stoneVeryDark = C(68, 58, 48),  -- 新增：更深的岩石阴影色
    moss          = C(121, 124, 72),
    dust          = C(153, 125, 86),  -- 稍微调暗了灰尘色，避免反白
    shadow        = C(86, 68, 55),
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

function FallRock.draw(x, y, s, dir, style)
    dir = dir or 1
    style = style or 1

    local W = 24

    if style == 1 then
        -- 大石头 / 巨石
        dpx(x, y, W, dir, 3, 15, 17, 2, palette.shadow, s, 0.24)

        -- 基础石块 (原有的高光部分 stoneLight 现已替换为 stone 以去掉偏白效果并保留形状)
        dpx(x, y, W, dir, 4, 10, 15, 5, palette.stone, s)
        dpx(x, y, W, dir, 5,  7, 13, 3, palette.stone, s)
        dpx(x, y, W, dir, 7,  4,  7, 3, palette.stone, s)
        dpx(x, y, W, dir, 15, 8,  3, 2, palette.stone, s)
        dpx(x, y, W, dir, 4,  9,  2, 3, palette.stone, s) 
        dpx(x, y, W, dir, 5,  6,  3, 2, palette.stone, s) 
        dpx(x, y, W, dir, 11, 7,  2, 1, palette.stone, s) 

        -- 第一层阴影
        dpx(x, y, W, dir, 12, 10, 6, 5, palette.stoneDark, s)
        dpx(x, y, W, dir, 9,  12, 5, 2, palette.stoneDark, s)
        dpx(x, y, W, dir, 8,   9, 2, 3, palette.stoneDark, s)
        dpx(x, y, W, dir, 15,  8, 2, 2, palette.stoneDark, s)
        dpx(x, y, W, dir, 10,  8, 1, 4, palette.stoneDark, s)
        dpx(x, y, W, dir, 11, 10, 2, 1, palette.stoneDark, s)

        -- 第二层更深的阴影 (新增)
        dpx(x, y, W, dir, 14, 12, 4, 3, palette.stoneVeryDark, s)
        dpx(x, y, W, dir, 10, 13, 4, 1, palette.stoneVeryDark, s)
        dpx(x, y, W, dir, 16, 9,  1, 1, palette.stoneVeryDark, s)

        -- 苔藓与灰尘装饰
        dpx(x, y, W, dir, 6, 5, 3, 1, palette.moss, s)
        dpx(x, y, W, dir, 9, 6, 2, 1, palette.moss, s, 0.9) -- 去掉苔藓高光
        dpx(x, y, W, dir, 13, 9, 2, 1, palette.dust, s, 0.75)

    elseif style == 2 then
        -- 中石头
        dpx(x, y, W, dir, 5, 14, 12, 2, palette.shadow, s, 0.22)

        -- 基础石块
        dpx(x, y, W, dir, 6, 10, 10, 4, palette.stone, s)
        dpx(x, y, W, dir, 7,  7,  8, 3, palette.stone, s)
        dpx(x, y, W, dir, 9,  5,  4, 2, palette.stone, s)
        dpx(x, y, W, dir, 6,  9,  2, 2, palette.stone, s)
        dpx(x, y, W, dir, 7,  7,  2, 1, palette.stone, s)
        dpx(x, y, W, dir, 10, 6,  1, 1, palette.stone, s)

        -- 第一层阴影
        dpx(x, y, W, dir, 12, 10, 4, 4, palette.stoneDark, s)
        dpx(x, y, W, dir, 9,  12, 4, 2, palette.stoneDark, s)
        dpx(x, y, W, dir, 10, 8,  1, 2, palette.stoneDark, s)

        -- 第二层更深的阴影 (新增)
        dpx(x, y, W, dir, 13, 12, 3, 2, palette.stoneVeryDark, s)
        dpx(x, y, W, dir, 10, 13, 3, 1, palette.stoneVeryDark, s)

        -- 苔藓与灰尘装饰
        dpx(x, y, W, dir, 8, 6, 2, 1, palette.moss, s)
        dpx(x, y, W, dir, 11, 9, 2, 1, palette.dust, s, 0.75)

    else
        -- 小碎石 / 卵石堆
        dpx(x, y, W, dir, 6, 14, 10, 2, palette.shadow, s, 0.20)

        -- 碎石 1
        dpx(x, y, W, dir, 6, 11, 4, 3, palette.stone, s)
        dpx(x, y, W, dir, 6, 10, 2, 1, palette.stone, s)
        dpx(x, y, W, dir, 8, 12, 2, 2, palette.stoneDark, s)
        dpx(x, y, W, dir, 9, 13, 1, 1, palette.stoneVeryDark, s) -- 加深

        -- 碎石 2
        dpx(x, y, W, dir, 10, 10, 4, 4, palette.stone, s)
        dpx(x, y, W, dir, 10, 9,  2, 1, palette.stone, s)
        dpx(x, y, W, dir, 12, 11, 2, 3, palette.stoneDark, s)
        dpx(x, y, W, dir, 13, 12, 1, 2, palette.stoneVeryDark, s) -- 加深

        -- 碎石 3
        dpx(x, y, W, dir, 14, 12, 3, 2, palette.stone, s)
        dpx(x, y, W, dir, 14, 11, 1, 1, palette.stone, s)
        dpx(x, y, W, dir, 15, 12, 2, 2, palette.stoneDark, s)
        dpx(x, y, W, dir, 16, 13, 1, 1, palette.stoneVeryDark, s) -- 加深

        -- 苔藓装饰
        dpx(x, y, W, dir, 11, 9, 1, 1, palette.moss, s)
        dpx(x, y, W, dir, 15, 11, 1, 1, palette.moss, s, 0.9)
    end
end

function FallRock.drawRandom(rng, x, y, s)
    local dir = rng:random(0, 1) == 0 and -1 or 1

    local roll = rng:random(100)
    local style
    if roll <= 22 then
        style = 1
    elseif roll <= 68 then
        style = 2
    else
        style = 3
    end

    FallRock.draw(x, y, s, dir, style)
end

return FallRock