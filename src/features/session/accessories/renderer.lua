local Renderer = {}

local function resolveEquipped(accessories)
    if type(accessories) ~= "table" then
        return nil
    end
    if accessories.equipped then
        return accessories.equipped
    end
    return accessories
end

local function copyEquipped(equipped)
    local source = equipped or {}
    return {
        frame = source.frame,
    }
end

local function getTime()
    if love and love.timer and love.timer.getTime then
        return love.timer.getTime()
    end
    return os.clock()
end

local function inset(bounds, amount)
    return {
        x = bounds.x + amount,
        y = bounds.y + amount,
        w = math.max(1, bounds.w - amount * 2),
        h = math.max(1, bounds.h - amount * 2),
    }
end

local function fillRound(bounds, color, radius)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.w, bounds.h, radius or 14, radius or 14)
end

local function lineRound(bounds, color, width, radius)
    love.graphics.setLineWidth(width or 2)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.rectangle("line", bounds.x + 0.5, bounds.y + 0.5, bounds.w - 1, bounds.h - 1, radius or 14, radius or 14)
    love.graphics.setLineWidth(1)
end

local function glowRound(bounds, color, strength, radius)
    local layers = 3
    for index = layers, 1, -1 do
        local alpha = (strength or 0.18) * (index / layers) * 0.45
        love.graphics.setLineWidth(index * 3)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.rectangle("line", bounds.x + 0.5, bounds.y + 0.5, bounds.w - 1, bounds.h - 1, radius or 14, radius or 14)
    end
    love.graphics.setLineWidth(1)
end

local function drawCornerDots(bounds, color, radius, inset_value)
    local pad = inset_value or 10
    local r = radius or 3
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.circle("fill", bounds.x + pad, bounds.y + pad, r)
    love.graphics.circle("fill", bounds.x + bounds.w - pad, bounds.y + pad, r)
    love.graphics.circle("fill", bounds.x + pad, bounds.y + bounds.h - pad, r)
    love.graphics.circle("fill", bounds.x + bounds.w - pad, bounds.y + bounds.h - pad, r)
end

local function drawEdgeDots(bounds, color, count, radius, phase)
    local cx = bounds.x + bounds.w * 0.5
    local cy = bounds.y + bounds.h * 0.5
    local rx = math.max(10, bounds.w * 0.44)
    local ry = math.max(10, bounds.h * 0.44)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    for index = 1, count do
        local angle = ((index - 1) / count) * math.pi * 2 + (phase or 0)
        love.graphics.circle("fill", cx + math.cos(angle) * rx, cy + math.sin(angle) * ry, radius)
    end
end

local function drawBambooNodes(bounds, color)
    local top = bounds.y + 6
    local bottom = bounds.y + bounds.h - 14
    local span = math.max(8, math.floor((bounds.w - 24) / 3))
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    for index = 0, 3 do
        local px = bounds.x + 10 + index * span
        love.graphics.rectangle("fill", px, top, 3, 8)
        love.graphics.rectangle("fill", px, bottom, 3, 8)
    end
end

local function drawPetals(bounds, color, scale)
    local size = scale or 5
    local centers = {
        { bounds.x + 16, bounds.y + 16 },
        { bounds.x + bounds.w - 16, bounds.y + 16 },
        { bounds.x + 16, bounds.y + bounds.h - 16 },
        { bounds.x + bounds.w - 16, bounds.y + bounds.h - 16 },
    }
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    for _, center in ipairs(centers) do
        love.graphics.circle("fill", center[1] - size * 0.6, center[2], size * 0.45)
        love.graphics.circle("fill", center[1] + size * 0.6, center[2], size * 0.45)
        love.graphics.circle("fill", center[1], center[2] - size * 0.6, size * 0.45)
        love.graphics.circle("fill", center[1], center[2] + size * 0.6, size * 0.45)
    end
end

local function drawDashBorder(bounds, color, segment_count)
    local count = segment_count or 10
    local dash_w = math.max(8, math.floor((bounds.w - 22) / count))
    local dash_h = math.max(6, math.floor((bounds.h - 22) / count))
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    for index = 0, count - 1 do
        local top_x = bounds.x + 10 + index * dash_w
        local left_y = bounds.y + 10 + index * dash_h
        love.graphics.rectangle("fill", top_x, bounds.y + 6, math.max(4, dash_w - 4), 3)
        love.graphics.rectangle("fill", top_x, bounds.y + bounds.h - 9, math.max(4, dash_w - 4), 3)
        love.graphics.rectangle("fill", bounds.x + 6, left_y, 3, math.max(4, dash_h - 4))
        love.graphics.rectangle("fill", bounds.x + bounds.w - 9, left_y, 3, math.max(4, dash_h - 4))
    end
end

local function drawWaveCorners(bounds, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    local points = {
        { bounds.x + 10, bounds.y + 14 },
        { bounds.x + 18, bounds.y + 9 },
        { bounds.x + 26, bounds.y + 14 },
        { bounds.x + bounds.w - 26, bounds.y + 14 },
        { bounds.x + bounds.w - 18, bounds.y + 9 },
        { bounds.x + bounds.w - 10, bounds.y + 14 },
        { bounds.x + 10, bounds.y + bounds.h - 14 },
        { bounds.x + 18, bounds.y + bounds.h - 9 },
        { bounds.x + 26, bounds.y + bounds.h - 14 },
        { bounds.x + bounds.w - 26, bounds.y + bounds.h - 14 },
        { bounds.x + bounds.w - 18, bounds.y + bounds.h - 9 },
        { bounds.x + bounds.w - 10, bounds.y + bounds.h - 14 },
    }
    for index = 1, #points, 3 do
        love.graphics.line(
            points[index][1], points[index][2],
            points[index + 1][1], points[index + 1][2],
            points[index + 2][1], points[index + 2][2]
        )
    end
end

local function drawSparkMarks(bounds, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    local spark_points = {
        { bounds.x + 16, bounds.y + 12 },
        { bounds.x + bounds.w - 18, bounds.y + 18 },
        { bounds.x + 20, bounds.y + bounds.h - 20 },
        { bounds.x + bounds.w - 22, bounds.y + bounds.h - 14 },
    }
    for _, point in ipairs(spark_points) do
        love.graphics.line(point[1] - 4, point[2], point[1] + 4, point[2])
        love.graphics.line(point[1], point[2] - 4, point[1], point[2] + 4)
    end
end

local function drawLightningCorners(bounds, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    local function bolt(x, y, mirror)
        local dir = mirror and -1 or 1
        love.graphics.line(
            x, y,
            x + 5 * dir, y + 4,
            x + 1 * dir, y + 9,
            x + 7 * dir, y + 13
        )
    end
    bolt(bounds.x + 14, bounds.y + 12, false)
    bolt(bounds.x + bounds.w - 14, bounds.y + 12, true)
    bolt(bounds.x + 14, bounds.y + bounds.h - 22, false)
    bolt(bounds.x + bounds.w - 14, bounds.y + bounds.h - 22, true)
end

local function drawBulbs(bounds, phase)
    local bulbs = {
        { 0.20, 0.15, { 1.0, 0.44, 0.28, 1 } },
        { 0.50, 0.10, { 1.0, 0.82, 0.30, 1 } },
        { 0.80, 0.15, { 0.42, 0.84, 0.48, 1 } },
        { 0.18, 0.85, { 0.43, 0.67, 0.99, 1 } },
        { 0.50, 0.90, { 0.86, 0.47, 0.98, 1 } },
        { 0.82, 0.85, { 1.0, 0.44, 0.28, 1 } },
    }
    for index, bulb in ipairs(bulbs) do
        local pulse = 0.58 + 0.42 * math.sin(phase + index * 0.8)
        local x = bounds.x + bounds.w * bulb[1]
        local y = bounds.y + bounds.h * bulb[2]
        love.graphics.setColor(bulb[3][1], bulb[3][2], bulb[3][3], 0.30 * pulse)
        love.graphics.circle("fill", x, y, 8 + pulse * 2)
        love.graphics.setColor(bulb[3][1], bulb[3][2], bulb[3][3], 1)
        love.graphics.circle("fill", x, y, 3)
    end
end

local function drawStandard(bounds, theme)
    local radius = theme.radius or 16
    if theme.glow then
        glowRound(bounds, theme.glow, theme.glow_alpha or 0.18, radius)
    end
    lineRound(inset(bounds, theme.outer_inset or 2), theme.outer, theme.outer_width or 4, radius)
    if theme.inner then
        lineRound(inset(bounds, theme.inner_inset or 8), theme.inner, theme.inner_width or 3, math.max(8, radius - 4))
    end
    if theme.corner_dots then
        drawCornerDots(bounds, theme.corner_dots, theme.dot_radius or 3, theme.dot_inset or 11)
    end
    if theme.petals then
        drawPetals(bounds, theme.petals, theme.petal_scale)
    end
    if theme.bamboo then
        drawBambooNodes(bounds, theme.bamboo)
    end
    if theme.dashes then
        drawDashBorder(inset(bounds, 2), theme.dashes, theme.dash_count)
    end
    if theme.waves then
        drawWaveCorners(inset(bounds, 2), theme.waves)
    end
    if theme.sparks then
        drawSparkMarks(bounds, theme.sparks)
    end
    if theme.lightning then
        drawLightningCorners(bounds, theme.lightning)
    end
    if theme.edge_dots then
        drawEdgeDots(bounds, theme.edge_dots, theme.edge_count or 12, theme.edge_radius or 2.5, theme.edge_phase or 0)
    end
end

local FRAME_THEMES = {
    frame_sunrise = {
        outer = { 0.98, 0.71, 0.26, 0.98 },
        inner = { 1.0, 0.88, 0.56, 0.95 },
        glow = { 1.0, 0.77, 0.29, 1 },
    },
    frame_bamboo = {
        outer = { 0.36, 0.67, 0.39, 0.96 },
        inner = { 0.70, 0.88, 0.55, 0.90 },
        bamboo = { 0.52, 0.76, 0.42, 0.92 },
    },
    frame_frost = {
        outer = { 0.52, 0.73, 0.96, 0.96 },
        inner = { 0.82, 0.91, 1.0, 0.96 },
        corner_dots = { 0.90, 0.96, 1.0, 0.92 },
        dot_radius = 2.5,
    },
    frame_ember = {
        outer = { 0.64, 0.20, 0.16, 0.98 },
        inner = { 0.97, 0.54, 0.24, 0.92 },
        sparks = { 1.0, 0.70, 0.32, 0.88 },
        glow = { 0.98, 0.40, 0.22, 1 },
        glow_alpha = 0.14,
    },
    frame_ocean = {
        outer = { 0.20, 0.56, 0.68, 0.98 },
        inner = { 0.44, 0.80, 0.86, 0.90 },
        waves = { 0.72, 0.92, 0.96, 0.84 },
    },
    frame_jade = {
        outer = { 0.30, 0.63, 0.44, 0.98 },
        inner = { 0.73, 0.90, 0.76, 0.94 },
        glow = { 0.48, 0.82, 0.60, 1 },
        glow_alpha = 0.12,
    },
    frame_plum = {
        outer = { 0.63, 0.24, 0.44, 0.98 },
        inner = { 0.90, 0.62, 0.75, 0.92 },
        petals = { 0.92, 0.68, 0.80, 0.84 },
    },
    frame_rose = {
        outer = { 0.90, 0.48, 0.62, 0.98 },
        inner = { 0.99, 0.80, 0.88, 0.94 },
        corner_dots = { 1.0, 0.76, 0.84, 0.92 },
    },
    frame_grape = {
        outer = { 0.45, 0.28, 0.65, 0.98 },
        inner = { 0.74, 0.62, 0.90, 0.92 },
        edge_dots = { 0.82, 0.70, 0.98, 0.76 },
        edge_count = 16,
        edge_radius = 2.2,
    },
    frame_ink = {
        outer = { 0.18, 0.18, 0.18, 0.98 },
        inner = { 0.60, 0.60, 0.60, 0.72 },
        dashes = { 0.18, 0.18, 0.18, 0.88 },
        dash_count = 7,
    },
    frame_cloud = {
        outer = { 0.88, 0.90, 0.94, 0.98 },
        inner = { 0.96, 0.98, 1.0, 0.84 },
        corner_dots = { 1.0, 1.0, 1.0, 0.84 },
        glow = { 0.92, 0.94, 1.0, 1 },
        glow_alpha = 0.16,
    },
    frame_sakura = {
        outer = { 0.92, 0.64, 0.76, 0.98 },
        inner = { 1.0, 0.88, 0.93, 0.94 },
        petals = { 0.98, 0.76, 0.84, 0.88 },
        petal_scale = 4,
    },
    frame_bronze = {
        outer = { 0.60, 0.39, 0.22, 0.98 },
        inner = { 0.84, 0.64, 0.38, 0.92 },
        dashes = { 0.76, 0.56, 0.34, 0.70 },
        dash_count = 8,
    },
    frame_amber = {
        outer = { 0.88, 0.54, 0.18, 0.98 },
        inner = { 0.99, 0.78, 0.40, 0.94 },
        glow = { 1.0, 0.66, 0.26, 1 },
        glow_alpha = 0.16,
    },
    frame_mint = {
        outer = { 0.46, 0.82, 0.72, 0.96 },
        inner = { 0.84, 0.98, 0.94, 0.92 },
        corner_dots = { 0.74, 0.96, 0.88, 0.90 },
    },
    frame_storm = {
        outer = { 0.18, 0.29, 0.58, 0.98 },
        inner = { 0.47, 0.64, 0.96, 0.92 },
        lightning = { 0.80, 0.90, 1.0, 0.94 },
    },
    frame_sand = {
        outer = { 0.72, 0.60, 0.39, 0.98 },
        inner = { 0.90, 0.82, 0.66, 0.92 },
        dashes = { 0.84, 0.72, 0.52, 0.82 },
        dash_count = 9,
    },
    frame_lotus = {
        outer = { 0.72, 0.28, 0.56, 0.98 },
        inner = { 0.95, 0.72, 0.86, 0.92 },
        petals = { 0.98, 0.78, 0.90, 0.86 },
    },
    frame_royal = {
        outer = { 0.38, 0.23, 0.62, 0.98 },
        inner = { 0.98, 0.82, 0.34, 0.92 },
        glow = { 0.86, 0.66, 0.24, 1 },
        glow_alpha = 0.12,
    },
    frame_pearl = {
        outer = { 0.90, 0.88, 0.84, 0.98 },
        inner = { 1.0, 1.0, 1.0, 0.92 },
        edge_dots = { 0.96, 0.96, 0.98, 0.88 },
        edge_count = 14,
        edge_radius = 2.1,
    },
}

local function drawAurora(bounds)
    local t = getTime()
    local pulse = 0.5 + 0.5 * math.sin(t * 1.4)
    local outer = {
        0.34 + 0.18 * pulse,
        0.78,
        0.78 + 0.12 * (1 - pulse),
        0.98,
    }
    local inner = {
        0.80 + 0.12 * (1 - pulse),
        0.96,
        0.70 + 0.16 * pulse,
        0.92,
    }
    drawStandard(bounds, {
        outer = outer,
        inner = inner,
        glow = { 0.48, 0.94, 0.82, 1 },
        glow_alpha = 0.18,
        edge_dots = { 0.92, 0.98, 0.86, 0.44 + 0.24 * pulse },
        edge_count = 12,
        edge_radius = 2.4,
        edge_phase = t * 0.4,
    })
end

local function drawStarlight(bounds)
    local t = getTime()
    local twinkle = 0.58 + 0.42 * math.sin(t * 3.2)
    drawStandard(bounds, {
        outer = { 0.54, 0.66, 0.96, 0.98 },
        inner = { 0.92, 0.95, 1.0, 0.94 },
        glow = { 0.86, 0.90, 1.0, 1 },
        glow_alpha = 0.14 + 0.06 * twinkle,
    })
    drawCornerDots(bounds, { 1.0, 0.98, 0.82, 0.70 + 0.30 * twinkle }, 3.4, 11)
    drawSparkMarks(bounds, { 0.96, 0.96, 1.0, 0.60 + 0.30 * twinkle })
end

local function drawPulse(bounds)
    local t = getTime()
    local pulse = 0.5 + 0.5 * math.sin(t * 2.8)
    drawStandard(bounds, {
        outer = { 0.28, 0.58, 0.98, 0.98 },
        inner = { 0.74, 0.88, 1.0, 0.92 },
        glow = { 0.32, 0.70, 1.0, 1 },
        glow_alpha = 0.10 + 0.12 * pulse,
    })
end

local function drawFestival(bounds)
    local t = getTime()
    drawStandard(bounds, {
        outer = { 0.94, 0.58, 0.24, 0.98 },
        inner = { 1.0, 0.84, 0.44, 0.92 },
        glow = { 1.0, 0.72, 0.30, 1 },
        glow_alpha = 0.12,
    })
    drawBulbs(bounds, t * 3.0)
end

local DRAWERS = {
    frame_aurora = drawAurora,
    frame_starlight = drawStarlight,
    frame_pulse = drawPulse,
    frame_festival = drawFestival,
}

for frame_id, theme in pairs(FRAME_THEMES) do
    DRAWERS[frame_id] = function(bounds)
        drawStandard(bounds, theme)
    end
end

function Renderer.copyEquipped(accessories)
    return copyEquipped(resolveEquipped(accessories))
end

function Renderer.hasFrame(accessories)
    local equipped = resolveEquipped(accessories)
    return type(equipped) == "table" and tostring(equipped.frame or "") ~= ""
end

function Renderer.drawFrame(bounds, frame_id)
    local drawer = DRAWERS[tostring(frame_id or "")]
    if not drawer then
        return
    end
    drawer(bounds)
end

function Renderer.draw(bounds, accessories)
    local equipped = resolveEquipped(accessories)
    if type(equipped) ~= "table" then
        return
    end
    Renderer.drawFrame(bounds, equipped.frame)
end

return Renderer
