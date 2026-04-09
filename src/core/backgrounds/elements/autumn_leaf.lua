local FallLeaf = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    yellow = C(222, 182, 74),
    orange = C(207, 124, 54),
    brown  = C(135, 86, 47),
    red    = C(156, 74, 50),

    outline   = C(92, 56, 28),
    vein      = C(115, 70, 38),
    stem      = C(98, 64, 34),
    highlight = C(244, 220, 160),
    frontGlow = C(255, 236, 185),
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function mix(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
    }
end

local function darken(c, k)
    return {
        clamp(c[1] * k, 0, 1),
        clamp(c[2] * k, 0, 1),
        clamp(c[3] * k, 0, 1),
    }
end

local function lighten(c, k)
    return mix(c, {1, 1, 1}, k)
end

local function pickColor(i)
    if i == 1 then return palette.yellow end
    if i == 2 then return palette.orange end
    if i == 3 then return palette.brown end
    return palette.red
end

local shapes = {}

-- 🍁 枫叶
shapes[1] = {
     0.00, -1.28,
     0.18, -0.92,
     0.52, -1.02,
     0.42, -0.58,
     0.92, -0.62,
     0.58, -0.16,
     1.06,  0.08,
     0.44,  0.26,
     0.62,  0.86,
     0.16,  0.66,
     0.00,  1.18,
    -0.16,  0.66,
    -0.62,  0.86,
    -0.44,  0.26,
    -1.06,  0.08,
    -0.58, -0.16,
    -0.92, -0.62,
    -0.42, -0.58,
    -0.52, -1.02,
    -0.18, -0.92,
}

-- 🍂 干枯叶
shapes[2] = {
     0.00, -1.22,
     0.38, -0.92,
     0.70, -0.42,
     0.78,  0.08,
     0.56,  0.70,
     0.16,  1.08,
     0.00,  1.18,
    -0.16,  1.08,
    -0.56,  0.70,
    -0.78,  0.08,
    -0.70, -0.42,
    -0.38, -0.92,
}

local highlights = {}

highlights[1] = {
    -0.10, -0.62,
     0.18, -0.82,
     0.30, -0.46,
     0.06, -0.22,
    -0.16, -0.30,
}

highlights[2] = {
    -0.08, -0.70,
     0.18, -0.58,
     0.26, -0.18,
     0.04,  0.02,
    -0.16, -0.16,
}

function FallLeaf.randomVariant()
    return love.math.random(1, 2)
end

function FallLeaf.randomColorIndex()
    return love.math.random(1, 4)
end

-- 这里直接把“更大尺寸 + 更慢速度 + 飘舞参数”都放进叶子实体
function FallLeaf.randomLeafData()
    local variant = FallLeaf.randomVariant()

    local scale
    if love.math.random() < 0.7 then
        scale = 1.15 + love.math.random() * 0.75   -- 大多数偏大
    else
        scale = 0.85 + love.math.random() * 0.35   -- 少量中小叶
    end

    return {
        variant = variant,
        colorIndex = FallLeaf.randomColorIndex(),

        rot = love.math.random() * math.pi * 2,
        scale = scale,

        -- 下落速度：明显降低
        fallSpeed = 10 + love.math.random() * 16,

        -- 横向飘动参数
        driftAmp = 8 + love.math.random() * 18,
        driftFreq = 0.8 + love.math.random() * 1.2,
        driftPhase = love.math.random() * math.pi * 2,

        -- 旋转速度
        spinSpeed = (-0.8 + love.math.random() * 1.6),

        -- 轻微前进漂移
        windBias = -6 + love.math.random() * 12,
    }
end

local function drawStem(variant, alpha)
    setColor(palette.stem, alpha)
    love.graphics.setLineWidth(0.18)

    if variant == 1 then
        love.graphics.line(0, 1.10, 0, 1.58)
    else
        love.graphics.line(0, 1.12, 0, 1.72)
    end
end

local function drawVeins(variant, alpha, front)
    local veinColor = palette.vein
    if front then
        veinColor = lighten(veinColor, 0.08)
    end

    setColor(veinColor, alpha * 0.85)
    love.graphics.setLineWidth(0.12)

    love.graphics.line(0, -0.82, 0, 1.04)

    if variant == 1 then
        love.graphics.line(0, -0.36,  0.52, -0.56)
        love.graphics.line(0, -0.08,  0.68,  0.02)
        love.graphics.line(0,  0.18,  0.38,  0.58)

        love.graphics.line(0, -0.36, -0.52, -0.56)
        love.graphics.line(0, -0.08, -0.68,  0.02)
        love.graphics.line(0,  0.18, -0.38,  0.58)
    else
        love.graphics.line(0, -0.34,  0.42, -0.40)
        love.graphics.line(0,  0.08,  0.36,  0.32)

        love.graphics.line(0, -0.34, -0.42, -0.40)
        love.graphics.line(0,  0.08, -0.36,  0.32)
    end
end

local function drawOutline(poly, alpha, front)
    local oc = palette.outline
    if front then
        oc = mix(oc, palette.frontGlow, 0.22)
    end
    setColor(oc, alpha)
    love.graphics.setLineWidth(0.14)
    love.graphics.polygon("line", poly)
end

local function drawHighlight(variant, alpha, front)
    local a = alpha * (front and 0.34 or 0.22)
    setColor(palette.highlight, a)
    love.graphics.polygon("fill", highlights[variant])
end

function FallLeaf.draw(x, y, s, variant, alpha, rot, colorIndex, front)
    alpha = alpha or 1
    rot = rot or 0
    colorIndex = colorIndex or 1

    if variant == nil then
        variant = FallLeaf.randomVariant()
    end
    if variant ~= 1 and variant ~= 2 then
        variant = 1
    end

    local poly = shapes[variant]
    local main = pickColor(colorIndex)

    if front then
        main = lighten(main, 0.10)
    else
        main = darken(main, 0.96)
    end

    -- 基础尺寸整体再放大一点
    local baseScale = 4.8
    local drawScale = (s or 1) * baseScale

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rot)
    love.graphics.scale(drawScale, drawScale)

    drawStem(variant, alpha * 0.95)

    setColor(main, alpha)
    love.graphics.polygon("fill", poly)

    setColor(darken(main, 0.82), alpha * 0.18)
    love.graphics.polygon("line", poly)

    drawVeins(variant, alpha, front)
    drawHighlight(variant, alpha, front)
    drawOutline(poly, alpha * 0.92, front)

    love.graphics.pop()
end

-- 直接画叶子实体
function FallLeaf.drawLeafEntity(leaf, t, front)
    local swayX = math.sin((t or 0) * leaf.driftFreq + leaf.driftPhase) * leaf.driftAmp
    local rot = (leaf.rot or 0)
        + math.sin((t or 0) * (leaf.driftFreq * 1.35) + leaf.driftPhase) * 0.22

    FallLeaf.draw(
        (leaf.x or 0) + swayX,
        leaf.y or 0,
        leaf.scale or 1,
        leaf.variant or 1,
        leaf.alpha or 1,
        rot,
        leaf.colorIndex or 1,
        front
    )
end

return FallLeaf