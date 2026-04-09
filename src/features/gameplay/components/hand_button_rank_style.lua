local HandButtonRankStyle = {
    w = 64,
    h = 64,
    bg = { 0.96, 0.89, 0.75, 1 },
    border = { 0.40, 0.22, 0.12, 1 },
    iconColor = { 0.25, 0.12, 0.05, 1 },
    shadow = { 0, 0, 0, 0.35 },
    hoverGlow = { 1.00, 0.95, 0.72, 0.18 },
    hoverInner = { 1.00, 0.98, 0.86, 0.22 },
    hoverBorder = { 0.72, 0.46, 0.20, 0.90 },
    shine = { 1.00, 0.97, 0.88, 0.22 },
    pixel = 3,
    hoverGlowExpand = 6,
    hoverLift = 1,
    hoverPulseSpeed = 4.2,
    hoverPulseAmp = 0.20,
    hoverFloatAmp = 0.8,
    hoverWiggleSpeed = 5.0,
    hoverWiggleAngle = 0.06,
    shineSpeed = 2.2,
    shineWidth = 12,
}

local function fillRect(x, y, w, h)
    love.graphics.rectangle("fill", x, y, w, h)
end

local function drawLineRect(x, y, w, h, lw)
    love.graphics.setLineWidth(lw or 1)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setLineWidth(1)
end

local function mix(a, b, t)
    return a + (b - a) * t
end

local function mixColor(c1, c2, t, a_mul)
    return {
        mix(c1[1], c2[1], t),
        mix(c1[2], c2[2], t),
        mix(c1[3], c2[3], t),
        (mix(c1[4] or 1, c2[4] or 1, t)) * (a_mul or 1),
    }
end

local function clamp(v, a, b)
    if v < a then
        return a
    end
    if v > b then
        return b
    end
    return v
end

local function getAnimTime()
    if love.timer and love.timer.getTime then
        return love.timer.getTime()
    end
    return 0
end

local function drawRefreshIcon(ox, oy, ps, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    local cells = {
        { 4, 3 }, { 5, 3 }, { 6, 3 }, { 7, 3 }, { 8, 3 }, { 9, 3 },
        { 4, 4 }, { 5, 4 }, { 6, 4 }, { 7, 4 }, { 8, 4 }, { 9, 4 },
        { 4, 5 }, { 5, 5 },
        { 3, 4 }, { 3, 5 }, { 3, 6 },
        { 9, 2 }, { 10, 2 }, { 11, 2 },
        { 9, 3 }, { 10, 3 }, { 11, 3 }, { 12, 3 },
        { 9, 4 }, { 10, 4 }, { 11, 4 }, { 12, 4 },
        { 9, 5 }, { 10, 5 }, { 11, 5 },
        { 10, 6 },
        { 6, 12 }, { 7, 12 }, { 8, 12 }, { 9, 12 }, { 10, 12 }, { 11, 12 },
        { 6, 11 }, { 7, 11 }, { 8, 11 }, { 9, 11 }, { 10, 11 }, { 11, 11 },
        { 10, 10 }, { 11, 10 },
        { 12, 11 }, { 12, 10 }, { 12, 9 },
        { 4, 13 }, { 5, 13 }, { 6, 13 },
        { 3, 12 }, { 4, 12 }, { 5, 12 }, { 6, 12 },
        { 3, 11 }, { 4, 11 }, { 5, 11 }, { 6, 11 },
        { 4, 10 }, { 5, 10 }, { 6, 10 },
        { 5, 9 },
    }
    for _, cell in ipairs(cells) do
        fillRect(ox + cell[1] * ps, oy + cell[2] * ps, ps, ps)
    end
end

local function drawHoverShine(self, bx, by, bw, bh, hover_t, visible_t, pulse)
    if hover_t <= 0.001 then
        return
    end

    local t = getAnimTime()
    local inner_pad = 3
    local shine_w = self.shineWidth
    local travel = bw - inner_pad * 2 + shine_w * 2
    local phase = (t * self.shineSpeed) % 1
    local shine_x = bx + inner_pad - shine_w + travel * phase

    love.graphics.setScissor(
        math.floor(bx + inner_pad),
        math.floor(by + inner_pad),
        math.floor(math.max(1, bw - inner_pad * 2)),
        math.floor(math.max(1, bh - inner_pad * 2))
    )

    love.graphics.setColor(
        self.shine[1],
        self.shine[2],
        self.shine[3],
        self.shine[4] * hover_t * visible_t * (0.75 + pulse * 0.25)
    )
    fillRect(shine_x, by + 3, shine_w, bh - 6)

    love.graphics.setColor(
        self.shine[1],
        self.shine[2],
        self.shine[3],
        self.shine[4] * 0.45 * hover_t * visible_t
    )
    fillRect(shine_x - shine_w * 0.6, by + 3, shine_w * 0.5, bh - 6)
    fillRect(shine_x + shine_w, by + 3, shine_w * 0.4, bh - 6)

    love.graphics.setScissor()
end

function HandButtonRankStyle:draw(btn, v)
    if not v or v.visibleT <= 0.001 then
        return
    end

    local hover_t = v.hoverT or 0
    local press_t = v.pressT or 0
    local scale = v.scale or 1
    local visible_t = v.visibleT or 1

    local time = getAnimTime()
    local pulse = 0.5 + 0.5 * math.sin(time * self.hoverPulseSpeed)
    local wiggle = math.sin(time * self.hoverWiggleSpeed) * self.hoverWiggleAngle * hover_t
    local float_anim = math.sin(time * (self.hoverPulseSpeed * 0.55)) * self.hoverFloatAmp * hover_t
    local lift_y = -hover_t * self.hoverLift + press_t * 1 - float_anim

    local cx = btn.x + btn.w * 0.5
    local cy = btn.y + btn.h * 0.5 + (v.offsetY or 0) + lift_y
    local bw = btn.w * scale
    local bh = btn.h * scale
    local bx = cx - bw * 0.5
    local by = cy - bh * 0.5

    if hover_t > 0.001 then
        local g_pulse = 1 + pulse * self.hoverPulseAmp
        local g = self.hoverGlowExpand * scale * hover_t * g_pulse
        love.graphics.setColor(
            self.hoverGlow[1],
            self.hoverGlow[2],
            self.hoverGlow[3],
            self.hoverGlow[4] * hover_t * visible_t * (0.85 + pulse * 0.25)
        )
        fillRect(bx - g, by - g, bw + g * 2, bh + g * 2)
        love.graphics.setColor(
            self.hoverGlow[1],
            self.hoverGlow[2],
            self.hoverGlow[3],
            self.hoverGlow[4] * 0.75 * hover_t * visible_t * (0.75 + pulse * 0.20)
        )
        fillRect(bx - g * 0.5, by - g * 0.5, bw + g, bh + g)
    end

    local shadow_dx = 4 - hover_t * 0.6
    local shadow_dy = 4 + (v.shadowDY or 0) - hover_t * 0.5 + press_t * 1.2
    local shadow_alpha = (v.shadowA or self.shadow[4] or 0.35) * visible_t * (1 + hover_t * 0.12)
    love.graphics.setColor(0, 0, 0, shadow_alpha)
    fillRect(bx + shadow_dx, by + shadow_dy, bw, bh)

    local brighten = hover_t * 0.10 - press_t * 0.06 + pulse * hover_t * 0.015
    love.graphics.setColor(
        math.min(1, self.bg[1] + brighten),
        math.min(1, self.bg[2] + brighten),
        math.min(1, self.bg[3] + brighten),
        self.bg[4] * visible_t
    )
    fillRect(bx, by, bw, bh)

    if hover_t > 0.001 then
        local inset = math.max(2, math.floor(3 * scale))
        love.graphics.setColor(
            self.hoverInner[1],
            self.hoverInner[2],
            self.hoverInner[3],
            self.hoverInner[4] * hover_t * visible_t * (0.85 + pulse * 0.20)
        )
        fillRect(bx + inset, by + inset, bw - inset * 2, math.max(2, bh * 0.28))
    end

    drawHoverShine(self, bx, by, bw, bh, hover_t, visible_t, pulse)

    local border_mix = clamp(hover_t * (0.9 + pulse * 0.15), 0, 1)
    local border_color = mixColor(self.border, self.hoverBorder, border_mix, visible_t)
    love.graphics.setColor(border_color)
    drawLineRect(bx, by, bw, bh, 3)

    if hover_t > 0.001 then
        love.graphics.setColor(1, 0.97, 0.88, (0.18 + pulse * 0.06) * hover_t * visible_t)
        drawLineRect(bx + 2, by + 2, bw - 4, bh - 4, 1)
    end

    local ps = self.pixel * scale
    local icon_size = 16 * ps
    local ox = cx - icon_size * 0.5
    local oy = cy - icon_size * 0.5

    love.graphics.push()
    love.graphics.translate(cx, cy + 1 * scale)
    love.graphics.rotate(wiggle)
    love.graphics.translate(-cx, -(cy + 1 * scale))
    drawRefreshIcon(ox, oy + 1 * scale, ps, { 0, 0, 0, (0.16 + hover_t * 0.08 + pulse * hover_t * 0.02) * visible_t })
    love.graphics.pop()

    local icon_brighten = hover_t * 0.08 - press_t * 0.03 + pulse * hover_t * 0.02
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(wiggle)
    love.graphics.translate(-cx, -cy)
    drawRefreshIcon(ox, oy, ps, {
        math.min(1, self.iconColor[1] + icon_brighten),
        math.min(1, self.iconColor[2] + icon_brighten),
        math.min(1, self.iconColor[3] + icon_brighten),
        self.iconColor[4] * visible_t,
    })
    love.graphics.pop()

    if hover_t > 0.001 then
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(wiggle)
        love.graphics.translate(-cx, -cy)
        love.graphics.setColor(1.0, 0.96, 0.84, (0.28 + pulse * 0.10) * hover_t * visible_t)
        fillRect(ox + 5 * ps, oy + 3 * ps, 4 * ps, 1 * ps)
        fillRect(ox + 9 * ps, oy + 4 * ps, 2 * ps, 1 * ps)
        fillRect(ox + 6 * ps, oy + 11 * ps, 4 * ps, 1 * ps)
        love.graphics.pop()
    end
end

return HandButtonRankStyle
