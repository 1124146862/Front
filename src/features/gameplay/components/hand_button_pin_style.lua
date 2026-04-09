local HandButtonPinStyle = {
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

    pixel = 2,
    iconThickness = 3,
    headWidthFactor = 4,

    hoverGlowExpand = 6,
    hoverLift = 1,

    hoverPulseSpeed = 4.2,
    hoverPulseAmp = 0.20,
    hoverFloatAmp = 0.8,
    hoverWiggleSpeed = 5.0,
    hoverWiggleAngle = 0.06,
    shineSpeed = 2.2,
    shineWidth = 10,

    hoverTwistSpeed = 3.8,
    hoverTwistAngle = 0.022,
    hoverSkewAmp = 0.045,
    hoverBobX = 0.9,
    hoverBobY = 0.5,
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

local function mixColor(c1, c2, t, aMul)
    return {
        mix(c1[1], c2[1], t),
        mix(c1[2], c2[2], t),
        mix(c1[3], c2[3], t),
        (mix(c1[4] or 1, c2[4] or 1, t)) * (aMul or 1),
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

local function drawPinIcon(cx, cy, ps, thickness, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)

    local halfT = math.floor(thickness / 2)
    local headHalfW = math.floor((thickness * 3.5) / 2)

    local headTop = -8
    local headHeight = math.max(2, thickness - 1)
    fillRect(cx - headHalfW * ps, cy + headTop * ps, (headHalfW * 2 + 1) * ps, headHeight * ps)

    local neckTop = headTop + headHeight
    local neckHeight = 2
    local neckWidth = thickness + 2
    fillRect(cx - math.floor(neckWidth / 2) * ps, cy + neckTop * ps, neckWidth * ps, neckHeight * ps)

    local bodyTop = neckTop + neckHeight
    local bodyHeight = 6
    fillRect(cx - halfT * ps, cy + bodyTop * ps, thickness * ps, bodyHeight * ps)

    local tipTop = bodyTop + bodyHeight
    if thickness > 1 then
        local tipStep1W = thickness - 2
        if tipStep1W < 1 then
            tipStep1W = 1
        end
        fillRect(cx - math.floor(tipStep1W / 2) * ps, cy + tipTop * ps, tipStep1W * ps, 2 * ps)
    end
    fillRect(cx, cy + (tipTop + 2) * ps, 1 * ps, 2 * ps)
end

local function drawHoverShine(self, bx, by, bw, bh, hoverT, visibleT, pulse)
    if hoverT <= 0.001 then
        return
    end

    local t = getAnimTime()
    local innerPad = 3
    local shineW = self.shineWidth
    local travel = bw - innerPad * 2 + shineW * 2
    local phase = (t * self.shineSpeed) % 1
    local shineX = bx + innerPad - shineW + travel * phase

    love.graphics.setScissor(
        math.floor(bx + innerPad),
        math.floor(by + innerPad),
        math.floor(math.max(1, bw - innerPad * 2)),
        math.floor(math.max(1, bh - innerPad * 2))
    )

    love.graphics.setColor(
        self.shine[1],
        self.shine[2],
        self.shine[3],
        self.shine[4] * hoverT * visibleT * (0.75 + pulse * 0.25)
    )
    fillRect(shineX, by + 3, shineW, bh - 6)

    love.graphics.setColor(
        self.shine[1],
        self.shine[2],
        self.shine[3],
        self.shine[4] * 0.45 * hoverT * visibleT
    )
    fillRect(shineX - shineW * 0.6, by + 3, shineW * 0.5, bh - 6)
    fillRect(shineX + shineW, by + 3, shineW * 0.4, bh - 6)

    love.graphics.setScissor()
end

function HandButtonPinStyle:draw(btn, v)
    if not v or v.visibleT <= 0.001 then
        return
    end

    local hoverT = v.hoverT or 0
    local pressT = v.pressT or 0
    local scale = v.scale or 1
    local visibleT = v.visibleT or 1

    local time = getAnimTime()
    local pulse = 0.5 + 0.5 * math.sin(time * self.hoverPulseSpeed)
    local wiggle = math.sin(time * self.hoverWiggleSpeed) * self.hoverWiggleAngle * hoverT
    local twist = math.sin(time * self.hoverTwistSpeed) * self.hoverTwistAngle * hoverT
    local skewPulse = math.sin(time * (self.hoverTwistSpeed * 1.37)) * self.hoverSkewAmp * hoverT
    local bobX = math.sin(time * (self.hoverTwistSpeed * 0.92)) * self.hoverBobX * hoverT
    local bobY = math.cos(time * (self.hoverTwistSpeed * 1.18)) * self.hoverBobY * hoverT
    local floatAnim = math.sin(time * (self.hoverPulseSpeed * 0.55)) * self.hoverFloatAmp * hoverT

    local liftY = -hoverT * self.hoverLift + pressT * 1 - floatAnim + bobY
    local cx = btn.x + btn.w * 0.5 + bobX
    local cy = btn.y + btn.h * 0.5 + (v.offsetY or 0) + liftY

    local bw = btn.w * scale
    local bh = btn.h * scale
    local bx = cx - bw * 0.5
    local by = cy - bh * 0.5

    if hoverT > 0.001 then
        local gPulse = 1 + pulse * self.hoverPulseAmp
        local g = self.hoverGlowExpand * scale * hoverT * gPulse

        love.graphics.setColor(
            self.hoverGlow[1],
            self.hoverGlow[2],
            self.hoverGlow[3],
            self.hoverGlow[4] * hoverT * visibleT * (0.85 + pulse * 0.25)
        )
        fillRect(bx - g, by - g, bw + g * 2, bh + g * 2)

        love.graphics.setColor(
            self.hoverGlow[1],
            self.hoverGlow[2],
            self.hoverGlow[3],
            self.hoverGlow[4] * 0.75 * hoverT * visibleT * (0.75 + pulse * 0.20)
        )
        fillRect(bx - g * 0.5, by - g * 0.5, bw + g, bh + g)
    end

    local shadowDX = 4 - hoverT * 0.6 + bobX * 0.35
    local shadowDY = 4 + (v.shadowDY or 0) - hoverT * 0.5 + pressT * 1.2 - bobY * 0.15
    local shadowAlpha = (v.shadowA or 0.35) * visibleT * (1 + hoverT * 0.12)

    love.graphics.setColor(0, 0, 0, shadowAlpha)
    fillRect(bx + shadowDX, by + shadowDY, bw, bh)

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(twist)
    love.graphics.shear(skewPulse, 0)
    love.graphics.translate(-cx, -cy)

    local brighten = hoverT * 0.10 - pressT * 0.06 + pulse * hoverT * 0.015
    love.graphics.setColor(
        math.min(1, self.bg[1] + brighten),
        math.min(1, self.bg[2] + brighten),
        math.min(1, self.bg[3] + brighten),
        self.bg[4] * visibleT
    )
    fillRect(bx, by, bw, bh)

    if hoverT > 0.001 then
        local inset = math.max(2, math.floor(3 * scale))
        love.graphics.setColor(
            self.hoverInner[1],
            self.hoverInner[2],
            self.hoverInner[3],
            self.hoverInner[4] * hoverT * visibleT * (0.85 + pulse * 0.20)
        )
        fillRect(bx + inset, by + inset, bw - inset * 2, math.max(2, bh * 0.28))
    end

    drawHoverShine(self, bx, by, bw, bh, hoverT, visibleT, pulse)

    local borderMix = clamp(hoverT * (0.9 + pulse * 0.15), 0, 1)
    local borderColor = mixColor(self.border, self.hoverBorder, borderMix, visibleT)
    love.graphics.setColor(borderColor)
    drawLineRect(bx, by, bw, bh, 3)

    if hoverT > 0.001 then
        love.graphics.setColor(1, 0.97, 0.88, (0.18 + pulse * 0.06) * hoverT * visibleT)
        drawLineRect(bx + 2, by + 2, bw - 4, bh - 4, 1)
    end

    love.graphics.pop()

    local currentPS = self.pixel * scale
    love.graphics.push()
    love.graphics.translate(cx, cy + 1 * scale)
    love.graphics.rotate(twist * 0.55 + wiggle)
    love.graphics.translate(-cx, -(cy + 1 * scale))
    drawPinIcon(
        cx,
        cy + 1 * scale,
        currentPS,
        self.iconThickness,
        { 0, 0, 0, (0.16 + hoverT * 0.08 + pulse * hoverT * 0.02) * visibleT }
    )
    love.graphics.pop()

    local iconBrighten = hoverT * 0.08 - pressT * 0.03 + pulse * hoverT * 0.02
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(twist * 0.7 + wiggle)
    love.graphics.translate(-cx, -cy)
    drawPinIcon(
        cx,
        cy,
        currentPS,
        self.iconThickness,
        {
            math.min(1, self.iconColor[1] + iconBrighten),
            math.min(1, self.iconColor[2] + iconBrighten),
            math.min(1, self.iconColor[3] + iconBrighten),
            self.iconColor[4] * visibleT,
        }
    )
    love.graphics.pop()

    if hoverT > 0.001 then
        local ps = currentPS
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(twist * 0.7 + wiggle)
        love.graphics.translate(-cx, -cy)

        love.graphics.setColor(1.0, 0.96, 0.84, (0.28 + pulse * 0.10) * hoverT * visibleT)
        fillRect(cx - 4 * ps, cy - 8 * ps, 3 * ps, 1 * ps)
        fillRect(cx - 1 * ps, cy - 1 * ps, 1 * ps, 3 * ps)

        love.graphics.pop()
    end
end

return HandButtonPinStyle
