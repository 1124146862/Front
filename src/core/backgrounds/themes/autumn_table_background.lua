local Rock = require("src.core.backgrounds.elements.autumn_rock")
local Kumu = require("src.core.backgrounds.elements.autumn_deadwood")
local Cao = require("src.core.backgrounds.elements.autumn_grass")
local Hua = require("src.core.backgrounds.elements.autumn_flower")
local FallingLeaf = require("src.core.backgrounds.elements.autumn_leaf")

local TableBackgroundAutumn = {
    canvas = nil,
    quad = nil,
    patternSize = 480,
    tileSize = 40,
    scale = 3,
    seed = nil,

    staticEntities = nil, -- 石头、枯木、枯草、秋花
    leaves = nil,         -- 动态落叶（屏幕空间）
    leafTime = 0,
    _leafRng = nil,

    _lastScreenW = 0,
    _lastScreenH = 0,
}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    groundA    = C(150, 140, 88),
    groundB    = C(136, 124, 77),
    groundC    = C(166, 150, 98),
    groundD    = C(117, 108, 66),
    shadow     = C(87, 68, 49),
    soil       = C(125, 97, 66),
    dry        = C(177, 150, 89),

    leafY      = C(224, 184, 80),
    leafO      = C(202, 125, 59),
    leafR      = C(156, 75, 53),
    leafB      = C(126, 86, 51),

    haze       = C(255, 238, 204),
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function px(x, y, w, h, c, a)
    setColor(c, a)
    love.graphics.rectangle("fill", x, y, w or 1, h or 1)
end

local function chance(rng, p)
    return rng:random() < p
end

local function randf(rng, a, b)
    return a + (b - a) * rng:random()
end

local function timeSeed()
    local t = os.time()
    local frac = 0
    if love.timer then
        frac = math.floor(love.timer.getTime() * 100000)
    end
    return t + frac
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function TableBackgroundAutumn:getScaleByY(y)
    local t = clamp(y / math.max(1, self.patternSize - 1), 0, 1)
    return lerp(0.66, 1.42, t)
end

function TableBackgroundAutumn:drawGroundBase(rng, ox, oy)
    local ts = self.tileSize

    px(ox, oy, ts, ts, palette.groundA)

    for y = 0, ts - 1 do
        for x = 0, ts - 1 do
            local roll = rng:random(100)
            if roll <= 14 then
                px(ox + x, oy + y, 1, 1, palette.groundB)
            elseif roll <= 25 then
                px(ox + x, oy + y, 1, 1, palette.groundC)
            elseif roll <= 31 then
                px(ox + x, oy + y, 1, 1, palette.groundD)
            elseif roll == 32 then
                px(ox + x, oy + y, 1, 1, palette.shadow, 0.28)
            elseif roll == 33 then
                px(ox + x, oy + y, 1, 1, palette.dry, 0.45)
            end
        end
    end

    if chance(rng, 0.24) then
        local x = ox + rng:random(3, ts - 8)
        local y = oy + rng:random(4, ts - 6)
        px(x, y, rng:random(3, 5), rng:random(2, 3), palette.soil, 0.16)
    end

    if chance(rng, 0.22) then
        local x = ox + rng:random(3, ts - 9)
        local y = oy + rng:random(4, ts - 5)
        px(x, y, rng:random(4, 7), 1, palette.dry, 0.16)
    end

    -- 地面零散落叶点
    if chance(rng, 0.28) then
        local leafCount = rng:random(2, 5)
        for _ = 1, leafCount do
            local cRoll = rng:random(1, 4)
            local c = palette.leafY
            if cRoll == 2 then c = palette.leafO end
            if cRoll == 3 then c = palette.leafR end
            if cRoll == 4 then c = palette.leafB end

            px(
                ox + rng:random(0, ts - 2),
                oy + rng:random(0, ts - 2),
                1, 1,
                c,
                0.65
            )
        end
    end
end

function TableBackgroundAutumn:addStaticEntity(kind, x, y, s, style, dir)
    self.staticEntities[#self.staticEntities + 1] = {
        kind = kind,
        x = x,
        y = y,
        s = s,
        style = style or 1,
        dir = dir or 1,
    }
end

function TableBackgroundAutumn:randomX(rng, approxWidth, s)
    local margin = 8
    local maxX = self.patternSize - math.floor(approxWidth * s) - margin
    if maxX < margin then
        maxX = margin
    end
    return rng:random(margin, maxX)
end

function TableBackgroundAutumn:spawnRocks(rng)
    local count = rng:random(14, 22)
    for _ = 1, count do
        local y = rng:random(10, self.patternSize - 32)
        local s = self:getScaleByY(y) * randf(rng, 0.82, 1.18)
        local x = self:randomX(rng, 20, s)
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
        self:addStaticEntity("rock", x, y, s, style, dir)
    end
end

function TableBackgroundAutumn:spawnDeadWood(rng)
    local count = rng:random(8, 13)
    for _ = 1, count do
        local y = rng:random(12, self.patternSize - 30)
        local s = self:getScaleByY(y) * randf(rng, 0.84, 1.14)
        local x = self:randomX(rng, 20, s)
        local style = rng:random(1, 2)
        local dir = rng:random(0, 1) == 0 and -1 or 1
        self:addStaticEntity("kumu", x, y, s, style, dir)
    end
end

function TableBackgroundAutumn:spawnGrass(rng)
    local count = rng:random(26, 38)
    for _ = 1, count do
        local y = rng:random(10, self.patternSize - 24)
        local s = self:getScaleByY(y) * randf(rng, 0.64, 0.95)
        local x = self:randomX(rng, 14, s)
        local style = rng:random(1, 2)
        local dir = rng:random(0, 1) == 0 and -1 or 1
        self:addStaticEntity("cao", x, y, s, style, dir)
    end
end

function TableBackgroundAutumn:spawnFlowers(rng)
    local count = rng:random(18, 28)
    for _ = 1, count do
        local y = rng:random(12, self.patternSize - 26)
        local s = self:getScaleByY(y) * randf(rng, 0.60, 0.88)
        local x = self:randomX(rng, 18, s)
        local style = rng:random(1, 3)
        local dir = rng:random(0, 1) == 0 and -1 or 1
        self:addStaticEntity("hua", x, y, s, style, dir)
    end
end

function TableBackgroundAutumn:drawStaticEntities()
    table.sort(self.staticEntities, function(a, b)
        return a.y < b.y
    end)

    for _, e in ipairs(self.staticEntities) do
        if e.kind == "rock" then
            Rock.draw(e.x, e.y, e.s, e.dir, e.style)
        elseif e.kind == "kumu" then
            Kumu.draw(e.x, e.y, e.s, e.dir, e.style)
        elseif e.kind == "cao" then
            Cao.draw(e.x, e.y, e.s, e.dir, e.style)
        elseif e.kind == "hua" then
            Hua.draw(e.x, e.y, e.s, e.dir, e.style)
        end
    end
end

function TableBackgroundAutumn:rebuildQuad(screenW, screenH)
    local drawW = math.ceil(screenW / self.scale)
    local drawH = math.ceil(screenH / self.scale)
    self.quad = love.graphics.newQuad(0, 0, drawW, drawH, self.patternSize, self.patternSize)
end

-- 动态落叶数量：保持不多
function TableBackgroundAutumn:getLeafTargetCount(screenW, screenH)
    return clamp(math.floor((screenW * screenH) / 70000), 12, 24)
end

function TableBackgroundAutumn:resetLeaf(f, rng, screenW, screenH, spawnTop)
    local depth = rng:random()

    f.depth = depth
    f.front = depth > 0.74

    -- 基础尺寸：整体比上一版更大
    f.s = lerp(0.58, 1.28, depth)

    -- 少量大叶子
    f.big = chance(rng, 0.28)
    if f.big then
        f.s = f.s * randf(rng, 1.18, 1.42)
    end

    -- 前景叶子再稍微大一点
    if f.front then
        f.s = f.s + randf(rng, 0.10, 0.24)
    end

    -- 上限别太离谱
    f.s = clamp(f.s, 0.58, 1.72)

    f.x = randf(rng, -36, screenW + 36)
    if spawnTop then
        f.y = randf(rng, -56, -12)
    else
        f.y = randf(rng, -10, screenH + 16)
    end

    -- 大叶子更明显一点，但不过分
    f.baseAlpha = lerp(0.26, 0.56, depth)
    if f.front then
        f.baseAlpha = f.baseAlpha + 0.05
    end
    if f.big then
        f.baseAlpha = f.baseAlpha + 0.03
    end
    f.baseAlpha = clamp(f.baseAlpha, 0.22, 0.68)

    -- 下落速度：仍然偏慢，大叶略快一点点
    f.fallSpeed = randf(rng, 8.5, 14.5) + depth * 7.5
    if f.big then
        f.fallSpeed = f.fallSpeed + randf(rng, 0.8, 2.0)
    end

    -- 稳定水平漂移
    f.sideBias = randf(rng, -3.6, 3.6)

    -- 摆动：大叶幅度更大一点
    f.swayAmp = randf(rng, 4.8, 10.5) + depth * 5.6
    if f.big then
        f.swayAmp = f.swayAmp + randf(rng, 1.0, 3.0)
    end
    f.swaySpeed = randf(rng, 0.42, 0.92)
    f.phase = randf(rng, 0, math.pi * 2)

    -- 转动：仍然柔和
    f.baseRot = randf(rng, -0.38, 0.38)
    f.rotSwingAmp = randf(rng, 0.10, 0.26) + depth * 0.10
    if f.big then
        f.rotSwingAmp = f.rotSwingAmp + randf(rng, 0.02, 0.06)
    end
    f.rotSwingSpeed = randf(rng, 0.52, 1.10)

    -- 两种叶子
    f.variant = rng:random(1, 2)
    f.colorIndex = rng:random(1, 4)

    f.fadeInDist = randf(rng, 14, 26)
    f.fadeOutStart = screenH * randf(rng, 0.86, 0.95)
    f.fadeOutDist = randf(rng, 42, 84)

    f.alpha = f.baseAlpha
end

function TableBackgroundAutumn:spawnLeaves(screenW, screenH)
    local rng = self._leafRng or love.math.newRandomGenerator((self.seed or timeSeed()) + 5517)
    local count = self:getLeafTargetCount(screenW, screenH)

    self.leaves = {}

    for _ = 1, count do
        local f = {}
        self:resetLeaf(f, rng, screenW, screenH, false)
        self.leaves[#self.leaves + 1] = f
    end
end

function TableBackgroundAutumn:build(options)
    options = options or {}

    self.patternSize = options.patternSize or self.patternSize
    self.tileSize = options.tileSize or self.tileSize
    self.scale = options.scale or self.scale

    self.seed = options.seed or timeSeed()

    local rng = love.math.newRandomGenerator(self.seed)

    self.canvas = love.graphics.newCanvas(self.patternSize, self.patternSize)
    self.canvas:setFilter("nearest", "nearest")
    self.canvas:setWrap("repeat", "repeat")

    self.staticEntities = {}
    self.leaves = {}
    self.leafTime = 0
    self._leafRng = love.math.newRandomGenerator(self.seed + 5517)

    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)

    for y = 0, self.patternSize - self.tileSize, self.tileSize do
        for x = 0, self.patternSize - self.tileSize, self.tileSize do
            self:drawGroundBase(rng, x, y)
        end
    end

    self:spawnRocks(rng)
    self:spawnDeadWood(rng)
    self:spawnGrass(rng)
    self:spawnFlowers(rng)

    self:drawStaticEntities()

    for _ = 1, 42 do
        local roll = rng:random(1, 4)
        local c = palette.leafY
        if roll == 2 then c = palette.leafO end
        if roll == 3 then c = palette.leafR end
        if roll == 4 then c = palette.leafB end

        px(
            rng:random(0, self.patternSize - 2),
            rng:random(0, self.patternSize - 2),
            1,
            1,
            c,
            0.32
        )
    end

    love.graphics.setCanvas(oldCanvas)

    local screenW = tonumber(options.screenW) or love.graphics.getWidth()
    local screenH = tonumber(options.screenH) or love.graphics.getHeight()
    self._lastScreenW = screenW
    self._lastScreenH = screenH

    self:rebuildQuad(screenW, screenH)
    self:spawnLeaves(screenW, screenH)
end

function TableBackgroundAutumn:init(options)
    self:build(options)
end

function TableBackgroundAutumn:regenerate(options)
    self:build(options or {})
end

function TableBackgroundAutumn:resize(screenW, screenH)
    if not self.canvas then
        return
    end

    self._lastScreenW = screenW
    self._lastScreenH = screenH

    self:rebuildQuad(screenW, screenH)
    self:spawnLeaves(screenW, screenH)
end

function TableBackgroundAutumn:update(dt, screenW, screenH)
    if not self.leaves then
        return
    end

    screenW = screenW or love.graphics.getWidth()
    screenH = screenH or love.graphics.getHeight()

    if screenW ~= self._lastScreenW or screenH ~= self._lastScreenH then
        self:resize(screenW, screenH)
    end

    self.leafTime = self.leafTime + dt

    local rng = self._leafRng or love.math.newRandomGenerator((self.seed or timeSeed()) + 5517)

    -- 温和整体风
    local globalWind =
        math.sin(self.leafTime * 0.18) * 2.4 +
        math.sin(self.leafTime * 0.06 + 1.3) * 1.6

    for _, f in ipairs(self.leaves) do
        f.x = f.x + (globalWind + f.sideBias) * dt
        f.y = f.y + f.fallSpeed * dt

        local fadeIn = 1
        if f.y < f.fadeInDist then
            fadeIn = clamp((f.y + f.fadeInDist) / math.max(1, f.fadeInDist), 0, 1)
        end

        local fadeOut = 1
        if f.y > f.fadeOutStart then
            fadeOut = clamp(1 - (f.y - f.fadeOutStart) / math.max(1, f.fadeOutDist), 0, 1)
        end

        f.alpha = f.baseAlpha * fadeIn * fadeOut

        if f.y > screenH + 64 or f.x < -78 or f.x > screenW + 78 or f.alpha <= 0.01 then
            self:resetLeaf(f, rng, screenW, screenH, true)
        end
    end
end

function TableBackgroundAutumn:drawLeaves()
    if not self.leaves then
        return
    end

    for _, f in ipairs(self.leaves) do
        if not f.front then
            local drawX = f.x + math.sin(self.leafTime * f.swaySpeed + f.phase) * f.swayAmp
            local drawRot =
                f.baseRot +
                math.sin(self.leafTime * f.rotSwingSpeed + f.phase * 0.72) * f.rotSwingAmp

            FallingLeaf.draw(
                drawX,
                f.y,
                f.s,
                f.variant,
                f.alpha,
                drawRot,
                f.colorIndex,
                false
            )
        end
    end

    for _, f in ipairs(self.leaves) do
        if f.front then
            local drawX = f.x + math.sin(self.leafTime * f.swaySpeed + f.phase) * f.swayAmp
            local drawRot =
                f.baseRot +
                math.sin(self.leafTime * f.rotSwingSpeed + f.phase * 0.72) * f.rotSwingAmp

            FallingLeaf.draw(
                drawX,
                f.y,
                f.s,
                f.variant,
                f.alpha,
                drawRot,
                f.colorIndex,
                true
            )
        end
    end
end

function TableBackgroundAutumn:draw(screenW, screenH)
    if not self.canvas then
        love.graphics.clear(
            palette.groundA[1],
            palette.groundA[2],
            palette.groundA[3],
            1
        )
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    local tile_w = (self.patternSize or 480) * self.scale
    local tile_h = (self.patternSize or 480) * self.scale
    for y = 0, screenH, tile_h do
        for x = 0, screenW, tile_w do
            love.graphics.draw(self.canvas, x, y, 0, self.scale, self.scale)
        end
    end

    self:drawLeaves()

    love.graphics.setColor(palette.haze[1], palette.haze[2], palette.haze[3], 0.035)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    love.graphics.setColor(1, 1, 1, 1)
end

return TableBackgroundAutumn
