-- 文件名: TableBackgroundWinter.lua
local Rock = require("src.core.backgrounds.elements.common_rock")
local Xuehua = require("src.core.backgrounds.elements.snowflake")
local Kumu = require("src.core.backgrounds.elements.common_deadwood")
local MaQue = require("src.core.backgrounds.elements.sparrow")

local TableBackgroundWinter = {
    canvas = nil,
    quad = nil,
    patternSize = 480,
    tileSize = 40,
    scale = 3,
    seed = nil,

    staticEntities = nil, 
    snowflakes = nil,     
    sparrows = nil,       -- 存放麻雀实体
    snowTime = 0,
    _snowRng = nil,

    _lastScreenW = 0,
    _lastScreenH = 0,
}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    snowA      = C(236, 241, 247),
    snowB      = C(228, 235, 244),
    snowC      = C(245, 248, 252),
    snowShadow = C(189, 202, 216),
    snowDark   = C(154, 170, 188),
    ice        = C(199, 223, 241),
    iceLight   = C(226, 240, 251),
    soilCold   = C(118, 110, 103),
    windLine   = C(255, 255, 255),
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function px(x, y, w, h, c, a)
    setColor(c, a)
    love.graphics.rectangle("fill", x, y, w or 1, h or 1)
end

local function gpx(ox, oy, rx, ry, w, h, c, s, a)
    local sx = math.floor(ox + rx * s + 0.5)
    local sy = math.floor(oy + ry * s + 0.5)
    local sw = math.max(1, math.floor((w or 1) * s + 0.5))
    local sh = math.max(1, math.floor((h or 1) * s + 0.5))
    setColor(c, a)
    love.graphics.rectangle("fill", sx, sy, sw, sh)
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

function TableBackgroundWinter:getScaleByY(y)
    local t = clamp(y / math.max(1, self.patternSize - 1), 0, 1)
    return 0.58 + t * 1.38
end

function TableBackgroundWinter:drawSnowBase(rng, ox, oy)
    local ts = self.tileSize

    px(ox, oy, ts, ts, palette.snowA)

    for y = 0, ts - 1 do
        for x = 0, ts - 1 do
            local roll = rng:random(100)
            if roll <= 9 then
                px(ox + x, oy + y, 1, 1, palette.snowB)
            elseif roll <= 15 then
                px(ox + x, oy + y, 1, 1, palette.snowC)
            elseif roll <= 17 then
                px(ox + x, oy + y, 1, 1, palette.snowShadow, 0.45)
            elseif roll == 18 then
                px(ox + x, oy + y, 1, 1, palette.ice, 0.40)
            end
        end
    end

    if chance(rng, 0.18) then
        local x = ox + rng:random(2, ts - 10)
        local y = oy + rng:random(4, ts - 5)
        px(x, y, rng:random(5, 9), 1, palette.windLine, 0.10)
    end

    if chance(rng, 0.12) then
        local x = ox + rng:random(3, ts - 8)
        local y = oy + rng:random(3, ts - 7)
        px(x, y, rng:random(3, 5), rng:random(1, 2), palette.iceLight, 0.10)
    end

    if chance(rng, 0.08) then
        local x = ox + rng:random(4, ts - 9)
        local y = oy + rng:random(4, ts - 8)
        px(x, y, rng:random(3, 4), 1, palette.soilCold, 0.07)
    end
end

function TableBackgroundWinter:addStaticEntity(kind, x, y, s, style, dir)
    self.staticEntities[#self.staticEntities + 1] = {
        kind = kind,
        x = x,
        y = y,
        s = s,
        style = style or 1,
        dir = dir or 1,
    }
end

function TableBackgroundWinter:randomX(rng, approxWidth, s)
    local margin = 8
    local maxX = self.patternSize - math.floor(approxWidth * s) - margin
    if maxX < margin then
        maxX = margin
    end
    return rng:random(margin, maxX)
end

local function drawSnowMound(x, y, s, style)
    style = style or 1

    if style == 1 then
        gpx(x, y, 1, 6, 10, 2, palette.snowShadow, s, 0.18)
        gpx(x, y, 2, 3, 8, 3, palette.snowB, s)
        gpx(x, y, 3, 2, 6, 2, palette.snowC, s)
        gpx(x, y, 4, 1, 3, 1, palette.iceLight, s, 0.55)
    else
        gpx(x, y, 1, 7, 11, 2, palette.snowShadow, s, 0.18)
        gpx(x, y, 2, 4, 9, 3, palette.snowB, s)
        gpx(x, y, 3, 3, 7, 2, palette.snowC, s)
        gpx(x, y, 5, 2, 2, 1, palette.iceLight, s, 0.55)
    end
end

function TableBackgroundWinter:spawnRocks(rng)
    local count = rng:random(14, 22)
    for _ = 1, count do
        local y = rng:random(10, self.patternSize - 32)
        local s = self:getScaleByY(y) * randf(rng, 0.85, 1.18)
        local x = self:randomX(rng, 20, s)
        local style = rng:random(1, 2)
        local dir = rng:random(0, 1) == 0 and -1 or 1
        self:addStaticEntity("rock", x, y, s, style, dir)
    end
end

function TableBackgroundWinter:spawnDeadWood(rng)
    local count = rng:random(9, 15)
    for _ = 1, count do
        local y = rng:random(12, self.patternSize - 30)
        local s = self:getScaleByY(y) * randf(rng, 0.85, 1.15)
        local x = self:randomX(rng, 20, s)
        local style = rng:random(1, 2)
        local dir = rng:random(0, 1) == 0 and -1 or 1
        self:addStaticEntity("kumu", x, y, s, style, dir)
    end
end

function TableBackgroundWinter:spawnSnowMounds(rng)
    local count = rng:random(16, 24)
    for _ = 1, count do
        local y = rng:random(10, self.patternSize - 24)
        local s = self:getScaleByY(y) * randf(rng, 0.72, 1.08)
        local x = self:randomX(rng, 14, s)
        local style = rng:random(1, 2)
        self:addStaticEntity("xuedui", x, y, s, style, 1)
    end
end

function TableBackgroundWinter:drawStaticEntities()
    table.sort(self.staticEntities, function(a, b)
        return a.y < b.y
    end)

    for _, e in ipairs(self.staticEntities) do
        if e.kind == "rock" then
            Rock.draw(e.x, e.y, e.s, e.dir, e.style)
        elseif e.kind == "kumu" then
            Kumu.draw(e.x, e.y, e.s, e.dir, e.style)
        elseif e.kind == "xuedui" then
            drawSnowMound(e.x, e.y, e.s, e.style)
        end
    end
end

function TableBackgroundWinter:rebuildQuad(screenW, screenH)
    local drawW = math.ceil(screenW / self.scale)
    local drawH = math.ceil(screenH / self.scale)
    self.quad = love.graphics.newQuad(0, 0, drawW, drawH, self.patternSize, self.patternSize)
end

function TableBackgroundWinter:getSnowflakeTargetCount(screenW, screenH)
    return clamp(math.floor((screenW * screenH) / 9000), 110, 220)
end

function TableBackgroundWinter:resetSnowflake(f, rng, screenW, screenH, spawnTop)
    local depth = rng:random()

    f.depth = depth
    f.front = depth > 0.62

    f.s = 1.1 + depth * 2.8
    if f.front then
        f.s = f.s + 0.8
    end

    f.x = randf(rng, -40, screenW + 40)
    if spawnTop then
        f.y = randf(rng, -60, -8)
    else
        f.y = randf(rng, -10, screenH + 18)
    end

    f.baseAlpha = randf(rng, 0.34, 0.58) + depth * 0.18
    if f.front then
        f.baseAlpha = f.baseAlpha + 0.08
    end

    f.fallSpeed = randf(rng, 18, 34) + depth * 26
    f.sideBias = randf(rng, -4, 4)
    f.swayAmp = randf(rng, 4, 14) + depth * 10
    f.swaySpeed = randf(rng, 0.45, 1.15)
    f.phase = randf(rng, 0, math.pi * 2)

    f.glintSpeed = randf(rng, 0.20, 0.55)
    f.glintPhase = randf(rng, 0, math.pi * 2)
    f.glintAmp = randf(rng, 0.015, 0.05)

    f.variant = rng:random(1, 3)

    f.fadeInDist = randf(rng, 18, 42)
    f.fadeOutStart = screenH * randf(rng, 0.82, 0.93)
    f.fadeOutDist = randf(rng, 36, 88)
end

function TableBackgroundWinter:spawnSnowflakes(screenW, screenH)
    local rng = self._snowRng or love.math.newRandomGenerator((self.seed or timeSeed()) + 9137)
    local count = self:getSnowflakeTargetCount(screenW, screenH)

    self.snowflakes = {}

    for _ = 1, count do
        local f = {}
        self:resetSnowflake(f, rng, screenW, screenH, false)
        self.snowflakes[#self.snowflakes + 1] = f
    end
end

-- 生成麻雀
function TableBackgroundWinter:spawnSparrows()
    local rng = love.math.newRandomGenerator((self.seed or timeSeed()) + 4096)
    self.sparrows = {}
    
    local count = rng:random(2, 4)
    for _ = 1, count do
        -- 【修改点】：将麻雀的尺寸缩放从 2 提升到了 2.5，让它们大一丢丢
        local actor = MaQue.newActor(rng, 2.5)
        self.sparrows[#self.sparrows + 1] = actor
    end
end

function TableBackgroundWinter:build(options)
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
    self.snowflakes = {}
    self.snowTime = 0
    self._snowRng = love.math.newRandomGenerator(self.seed + 9137)

    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)

    for y = 0, self.patternSize - self.tileSize, self.tileSize do
        for x = 0, self.patternSize - self.tileSize, self.tileSize do
            self:drawSnowBase(rng, x, y)
        end
    end

    self:spawnSnowMounds(rng)
    self:spawnRocks(rng)
    self:spawnDeadWood(rng)

    self:drawStaticEntities()

    for _ = 1, 36 do
        px(
            rng:random(0, self.patternSize - 2),
            rng:random(0, self.patternSize - 2),
            1,
            1,
            palette.iceLight,
            0.18
        )
    end

    love.graphics.setCanvas(oldCanvas)

    local screenW = tonumber(options.screenW) or love.graphics.getWidth()
    local screenH = tonumber(options.screenH) or love.graphics.getHeight()
    self._lastScreenW = screenW
    self._lastScreenH = screenH

    self:rebuildQuad(screenW, screenH)
    self:spawnSnowflakes(screenW, screenH)
    
    self:spawnSparrows()
end

function TableBackgroundWinter:init(options)
    self:build(options)
end

function TableBackgroundWinter:regenerate(options)
    self:build(options or {})
end

function TableBackgroundWinter:resize(screenW, screenH)
    if not self.canvas then
        return
    end

    self._lastScreenW = screenW
    self._lastScreenH = screenH

    self:rebuildQuad(screenW, screenH)
    self:spawnSnowflakes(screenW, screenH)
end

function TableBackgroundWinter:update(dt, screenW, screenH)
    screenW = screenW or love.graphics.getWidth()
    screenH = screenH or love.graphics.getHeight()

    if screenW ~= self._lastScreenW or screenH ~= self._lastScreenH then
        self:resize(screenW, screenH)
    end

    self.snowTime = self.snowTime + dt

    if self.snowflakes then
        local rng = self._snowRng or love.math.newRandomGenerator((self.seed or timeSeed()) + 9137)
        local globalWind = math.sin(self.snowTime * 0.22) * 8 + 5

        for _, f in ipairs(self.snowflakes) do
            local sway = math.sin(self.snowTime * f.swaySpeed + f.phase) * f.swayAmp

            f.x = f.x + (globalWind + f.sideBias + sway) * dt
            f.y = f.y + f.fallSpeed * dt

            local fadeIn = 1
            if f.y < f.fadeInDist then
                fadeIn = clamp((f.y + f.fadeInDist) / math.max(1, f.fadeInDist), 0, 1)
            end

            local fadeOut = 1
            if f.y > f.fadeOutStart then
                fadeOut = clamp(1 - (f.y - f.fadeOutStart) / math.max(1, f.fadeOutDist), 0, 1)
            end

            local glint = 1 + math.sin(self.snowTime * f.glintSpeed + f.glintPhase) * f.glintAmp
            f.alpha = f.baseAlpha * fadeIn * fadeOut * glint

            if f.y > screenH + 80 or f.x < -80 or f.x > screenW + 80 or f.alpha <= 0.01 then
                self:resetSnowflake(f, rng, screenW, screenH, true)
            end
        end
    end
    
    if self.sparrows then
        for _, sparrow in ipairs(self.sparrows) do
            sparrow:update(dt, screenW, screenH)
        end
    end
end

function TableBackgroundWinter:drawSnowflakes()
    if not self.snowflakes then
        return
    end

    for _, f in ipairs(self.snowflakes) do
        if not f.front then
            Xuehua.draw(f.x, f.y, f.s, f.variant, f.alpha, 1.0, false)
        end
    end

    for _, f in ipairs(self.snowflakes) do
        if f.front then
            Xuehua.draw(f.x, f.y, f.s, f.variant, f.alpha, 1.03, true)
        end
    end
end

function TableBackgroundWinter:draw(screenW, screenH)
    if not self.canvas then
        love.graphics.clear(
            palette.snowA[1],
            palette.snowA[2],
            palette.snowA[3],
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
    
    if self.sparrows then
        for _, sparrow in ipairs(self.sparrows) do
            sparrow:draw()
        end
    end

    self:drawSnowflakes()

    love.graphics.setColor(0.95, 0.97, 1.0, 0.035)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    love.graphics.setColor(1, 1, 1, 1)
end

return TableBackgroundWinter
