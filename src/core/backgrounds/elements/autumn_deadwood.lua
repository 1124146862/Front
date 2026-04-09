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

    -- 稍微加宽，给树杈留空间
    local W = 26

    if style == 1 then
        -- 【形态 1：斜躺长枯木，带小树杈】

        -- 底部阴影
        dpx(x, y, W, dir, 2, 13, 18, 2, palette.shadow, s, 0.22)

        -- 主干（从左下到右上）
        dpx(x, y, W, dir, 3, 10, 4, 4, palette.bark, s)
        dpx(x, y, W, dir, 7,  9, 4, 4, palette.bark, s)
        dpx(x, y, W, dir, 11, 8, 4, 4, palette.bark, s)
        dpx(x, y, W, dir, 15, 7, 3, 4, palette.bark, s)

        -- 顶部受光面
        dpx(x, y, W, dir, 3,  10, 4, 1, palette.barkLight, s)
        dpx(x, y, W, dir, 7,   9, 4, 1, palette.barkLight, s)
        dpx(x, y, W, dir, 11,  8, 4, 1, palette.barkLight, s)

        -- 树皮暗部纹理
        dpx(x, y, W, dir, 4,  12, 2, 1, palette.barkDark, s)
        dpx(x, y, W, dir, 8,  11, 2, 1, palette.barkDark, s)
        dpx(x, y, W, dir, 12, 10, 3, 1, palette.barkDark, s)
        dpx(x, y, W, dir, 15,  9, 2, 1, palette.barkDark, s)

        -- 右侧截断年轮面
        dpx(x, y, W, dir, 18, 7, 2, 4, palette.cutFace, s)
        dpx(x, y, W, dir, 19, 8, 1, 2, palette.ring, s)

        -- 左上断枝（原有，稍强化）
        dpx(x, y, W, dir, 5, 8, 1, 2, palette.bark, s)
        dpx(x, y, W, dir, 4, 7, 1, 1, palette.cutFace, s)

        -- 中段上方小树杈
        dpx(x, y, W, dir, 10, 6, 1, 2, palette.bark, s)
        dpx(x, y, W, dir, 9,  5, 1, 1, palette.bark, s)
        dpx(x, y, W, dir, 9,  4, 1, 1, palette.cutFace, s)

        -- 右段下侧短树杈
        dpx(x, y, W, dir, 14, 10, 2, 1, palette.bark, s)
        dpx(x, y, W, dir, 16, 10, 1, 1, palette.cutFace, s)

    else
        -- 【形态 2：斜刺断木，带小树杈】

        -- 底部阴影
        dpx(x, y, W, dir, 5, 14, 11, 2, palette.shadow, s, 0.22)

        -- 粗壮底盘
        dpx(x, y, W, dir, 8, 10, 6, 4, palette.bark, s)

        -- 倾斜中段
        dpx(x, y, W, dir, 6, 6, 5, 4, palette.bark, s)

        -- 顶部破裂段
        dpx(x, y, W, dir, 5, 3, 2, 3, palette.bark, s)
        dpx(x, y, W, dir, 7, 4, 1, 2, palette.bark, s)
        dpx(x, y, W, dir, 8, 5, 1, 1, palette.bark, s)

        -- 顶部截面
        dpx(x, y, W, dir, 5, 2, 2, 1, palette.cutFace, s)
        dpx(x, y, W, dir, 7, 3, 1, 1, palette.cutFace, s)

        -- 左侧受光
        dpx(x, y, W, dir, 8, 10, 1, 4, palette.barkLight, s)
        dpx(x, y, W, dir, 6,  6, 1, 4, palette.barkLight, s)
        dpx(x, y, W, dir, 5,  4, 1, 2, palette.barkLight, s)

        -- 裂纹暗部
        dpx(x, y, W, dir, 12, 10, 1, 4, palette.barkDark, s)
        dpx(x, y, W, dir, 9,  11, 1, 3, palette.barkDark, s)
        dpx(x, y, W, dir, 7,   7, 1, 2, palette.barkDark, s)

        -- 右侧树瘤/断枝
        dpx(x, y, W, dir, 11, 7, 2, 2, palette.bark, s)
        dpx(x, y, W, dir, 13, 7, 1, 2, palette.cutFace, s)

        -- 左上小树杈
        dpx(x, y, W, dir, 6, 5, 1, 2, palette.bark, s)
        dpx(x, y, W, dir, 5, 4, 1, 1, palette.bark, s)
        dpx(x, y, W, dir, 5, 3, 1, 1, palette.cutFace, s)

        -- 中部向右的小短杈
        dpx(x, y, W, dir, 10, 8, 2, 1, palette.bark, s)
        dpx(x, y, W, dir, 12, 8, 1, 1, palette.cutFace, s)

        -- 下方短杈，让造型更枯
        dpx(x, y, W, dir, 9, 12, 1, 2, palette.barkDark, s)
    end
end

function Kumu.drawRandom(rng, x, y, s)
    local dir = rng:random(0, 1) == 0 and -1 or 1
    local style = rng:random(1, 2)
    Kumu.draw(x, y, s, dir, style)
end

return Kumu