local Kumu = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    bark       = C(113, 87, 67),
    barkDark   = C(82, 62, 47),
    barkLight  = C(145, 117, 91),
    cutFace    = C(166, 136, 107),
    ring       = C(126, 102, 80),
    snow       = C(244, 247, 251),
    snowLight  = C(255, 255, 255),
    shadow     = C(88, 103, 120),
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

function Kumu.draw(x, y, s, dir, style)
    dir = dir or 1
    style = style or 1

    -- 扩大画布宽度以容纳倾斜带来的横向延伸
    local W = 24 

    if style == 1 then
        -- 【形态 1：约30度角斜躺的长枯木】
        
        -- 底部阴影 (保持水平贴地)
        dpx(x, y, W, dir, 2, 13, 18, 2, palette.shadow, s, 0.22)

        -- 阶梯式主干 (从左下到右上倾斜)
        dpx(x, y, W, dir, 3, 10, 4, 4, palette.bark, s)
        dpx(x, y, W, dir, 7, 9,  4, 4, palette.bark, s)
        dpx(x, y, W, dir, 11, 8, 4, 4, palette.bark, s)
        dpx(x, y, W, dir, 15, 7, 3, 4, palette.bark, s)

        -- 顶部受光面 (高光轮廓)
        dpx(x, y, W, dir, 3,  10, 4, 1, palette.barkLight, s)
        dpx(x, y, W, dir, 7,  9,  4, 1, palette.barkLight, s)
        dpx(x, y, W, dir, 11, 8,  4, 1, palette.barkLight, s)

        -- 树皮暗部纹理
        dpx(x, y, W, dir, 4,  12, 2, 1, palette.barkDark, s)
        dpx(x, y, W, dir, 8,  11, 2, 1, palette.barkDark, s)
        dpx(x, y, W, dir, 12, 10, 3, 1, palette.barkDark, s)
        dpx(x, y, W, dir, 15, 9,  2, 1, palette.barkDark, s)

        -- 右侧截断年轮面
        dpx(x, y, W, dir, 18, 7, 2, 4, palette.cutFace, s)
        dpx(x, y, W, dir, 19, 8, 1, 2, palette.ring, s)

        -- 左上方伸出的断枝
        dpx(x, y, W, dir, 5, 8, 1, 2, palette.bark, s)
        dpx(x, y, W, dir, 4, 7, 1, 1, palette.cutFace, s)

        -- 阶梯状断续积雪
        dpx(x, y, W, dir, 3,  9, 2, 1, palette.snow, s)
        dpx(x, y, W, dir, 7,  8, 3, 1, palette.snow, s)
        dpx(x, y, W, dir, 11, 7, 3, 1, palette.snow, s)
        dpx(x, y, W, dir, 15, 6, 2, 1, palette.snow, s)
        
        -- 积雪高光点缀
        dpx(x, y, W, dir, 7, 8, 1, 1, palette.snowLight, s)
        dpx(x, y, W, dir, 11, 7, 1, 1, palette.snowLight, s)

    else
        -- 【形态 2：约60度角斜刺向上的参差断木】
        
        -- 底部阴影
        dpx(x, y, W, dir, 5, 14, 11, 2, palette.shadow, s, 0.22)

        -- 粗壮的底盘
        dpx(x, y, W, dir, 8, 10, 6, 4, palette.bark, s)
        -- 倾斜的中段
        dpx(x, y, W, dir, 6, 6,  5, 4, palette.bark, s)
        
        -- 参差不齐的顶部断裂面
        dpx(x, y, W, dir, 5, 3, 2, 3, palette.bark, s)
        dpx(x, y, W, dir, 7, 4, 1, 2, palette.bark, s)
        dpx(x, y, W, dir, 8, 5, 1, 1, palette.bark, s)

        -- 露出里面的原木色 (断层截面)
        dpx(x, y, W, dir, 5, 2, 2, 1, palette.cutFace, s)
        dpx(x, y, W, dir, 7, 3, 1, 1, palette.cutFace, s)

        -- 树皮受光面 (左侧边缘)
        dpx(x, y, W, dir, 8, 10, 1, 4, palette.barkLight, s)
        dpx(x, y, W, dir, 6, 6,  1, 4, palette.barkLight, s)
        dpx(x, y, W, dir, 5, 4,  1, 2, palette.barkLight, s)

        -- 深邃的树皮裂纹
        dpx(x, y, W, dir, 12, 10, 1, 4, palette.barkDark, s)
        dpx(x, y, W, dir, 9,  11, 1, 3, palette.barkDark, s)
        dpx(x, y, W, dir, 7,  7,  1, 2, palette.barkDark, s)

        -- 右侧斜下方的粗糙树瘤/断枝
        dpx(x, y, W, dir, 11, 7, 2, 2, palette.bark, s)
        dpx(x, y, W, dir, 13, 7, 1, 2, palette.cutFace, s)

        -- 积雪覆盖在不规则的凹槽和断层上
        dpx(x, y, W, dir, 5, 1, 2, 1, palette.snow, s)
        dpx(x, y, W, dir, 7, 2, 1, 1, palette.snow, s)
        dpx(x, y, W, dir, 9, 5, 2, 1, palette.snow, s)
        dpx(x, y, W, dir, 11, 6, 2, 1, palette.snow, s)
        dpx(x, y, W, dir, 5, 1, 1, 1, palette.snowLight, s)
    end
end

function Kumu.drawRandom(rng, x, y, s)
    local dir = rng:random(0, 1) == 0 and -1 or 1
    local style = rng:random(1, 2)
    Kumu.draw(x, y, s, dir, style)
end

return Kumu