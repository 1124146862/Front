local Rock = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    stone      = C(131, 139, 150),
    stoneDark  = C(92, 100, 111),
    stoneLight = C(165, 174, 186),
    snow       = C(244, 247, 251),
    snowLight  = C(255, 255, 255),
    ice        = C(201, 226, 243),
    shadow     = C(86, 105, 127),
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

function Rock.draw(x, y, s, dir, style)
    dir = dir or 1
    style = style or 1

    -- 扩大画布以容纳更舒展的自然形状
    local W = 22 

    if style == 1 then
        -- 【形态 1：大石头 / 巨石】（左高右低的不规则形状）
        
        -- 宽阔的底部阴影
        dpx(x, y, W, dir, 3, 14, 16, 2, palette.shadow, s, 0.24)

        -- 石头主体基础块
        dpx(x, y, W, dir, 4, 10, 14, 4, palette.stone, s)
        dpx(x, y, W, dir, 5,  7, 12, 3, palette.stone, s)
        dpx(x, y, W, dir, 6,  4,  6, 3, palette.stone, s)
        
        -- 右侧稍矮的凸起
        dpx(x, y, W, dir, 15, 8, 3, 3, palette.stone, s)

        -- 左侧和上方的受光面（提亮边缘）
        dpx(x, y, W, dir, 4,  9, 2, 3, palette.stoneLight, s)
        dpx(x, y, W, dir, 5,  6, 2, 2, palette.stoneLight, s)
        dpx(x, y, W, dir, 12, 7, 2, 1, palette.stoneLight, s)

        -- 右侧和底部的暗部裂隙（增加粗糙的体积感）
        dpx(x, y, W, dir, 12, 10, 6, 4, palette.stoneDark, s)
        dpx(x, y, W, dir, 9,  12, 5, 2, palette.stoneDark, s)
        dpx(x, y, W, dir, 15, 8,  3, 2, palette.stoneDark, s)
        dpx(x, y, W, dir, 8,  9,  2, 3, palette.stoneDark, s) -- 中间的凹陷裂纹

        -- 错落的厚积雪覆盖
        dpx(x, y, W, dir, 5,  3, 8, 2, palette.snow, s)
        dpx(x, y, W, dir, 4,  5, 3, 1, palette.snow, s)
        dpx(x, y, W, dir, 12, 6, 4, 2, palette.snow, s)
        dpx(x, y, W, dir, 8,  5, 2, 2, palette.snow, s) -- 顺着裂缝流下的雪
        
        -- 积雪的高光点缀
        dpx(x, y, W, dir, 6,  3, 4, 1, palette.snowLight, s)
        dpx(x, y, W, dir, 13, 6, 2, 1, palette.snowLight, s)

        -- 偶尔露出的冰晶反光
        dpx(x, y, W, dir, 7,  11, 1, 1, palette.ice, s)
        dpx(x, y, W, dir, 14, 12, 1, 1, palette.ice, s)
        dpx(x, y, W, dir, 10, 7,  1, 1, palette.ice, s)

    else
        -- 【形态 2：小石头 / 碎卵石】（低矮扁平，适合做地面点缀）
        
        -- 短小紧凑的阴影
        dpx(x, y, W, dir, 5, 14, 10, 2, palette.shadow, s, 0.24)

        -- 石头主体
        dpx(x, y, W, dir, 6, 12, 8, 2, palette.stone, s)
        dpx(x, y, W, dir, 7, 10, 6, 2, palette.stone, s)

        -- 右侧背光面暗部
        dpx(x, y, W, dir, 11, 11, 3, 3, palette.stoneDark, s)
        dpx(x, y, W, dir, 8,  13, 4, 1, palette.stoneDark, s)

        -- 左侧受光面
        dpx(x, y, W, dir, 6, 11, 1, 2, palette.stoneLight, s)
        dpx(x, y, W, dir, 7, 10, 2, 1, palette.stoneLight, s)

        -- 薄薄的顶层积雪
        dpx(x, y, W, dir, 7,  9, 6, 1, palette.snow, s)
        dpx(x, y, W, dir, 6, 10, 2, 1, palette.snow, s)
        
        -- 积雪高光
        dpx(x, y, W, dir, 8,  9, 3, 1, palette.snowLight, s)

        -- 一点点冰晶点缀
        dpx(x, y, W, dir, 10, 12, 1, 1, palette.ice, s)
    end
end

function Rock.drawRandom(rng, x, y, s)
    -- 随机朝向（左右翻转，增加地形多样性）
    local dir = rng:random(0, 1) == 0 and -1 or 1
    -- 随机生成大石头(1)或小石头(2)
    local style = rng:random(1, 2)
    Rock.draw(x, y, s, dir, style)
end

return Rock