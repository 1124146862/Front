local Hua = require("src.core.backgrounds.elements.common_flower")
local Cao = require("src.core.backgrounds.elements.common_grass")
local Rock = require("src.core.backgrounds.elements.common_rock")
local Snow = require("src.core.backgrounds.elements.spring_snow_patch")
local Soil = require("src.core.backgrounds.elements.spring_soil_patch")
local Hudie = require("src.core.backgrounds.elements.spring_butterfly")

local TableBackgroundSpring = {
    canvas = nil,
    quad = nil,
    patternSize = 480,
    tileSize = 40,
    scale = 3,
    seed = nil,

    -- ========= 可调参数 =========
    -- 春天：更绿一些，但仍保留湿土和少量残雪
    grassCount = 30,
    flowerCount = 14,
    rockCount = 8,
    snowCount = 3,
    soilCount = 16,

    butterflyCountMin = 5,
    butterflyCountMax = 9,

    staticEntities = nil, -- 草、花、石头、残雪、湿土
    butterflies = nil,    -- 蝴蝶（动态）
}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    -- 底色整体更绿一点
    groundA     = C(144, 142, 103),
    groundB     = C(130, 129, 91),
    groundC     = C(160, 158, 116),
    groundD     = C(116, 115, 79),

    -- 春草更明显
    grassA      = C(126, 172, 96),
    grassB      = C(102, 146, 76),
    grassC      = C(150, 194, 118),
    grassD      = C(182, 216, 146),
    grassShadow = C(76, 108, 58),

    soil        = C(138, 108, 78),
    soilDark    = C(109, 83, 60),

    snow        = C(238, 240, 234),
    snowShadow  = C(199, 204, 194),

    dew         = C(209, 225, 205),
    blossom     = C(249, 234, 241),
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

function TableBackgroundSpring:getBaseScaleByY(y)
    local t = clamp(y / math.max(1, self.patternSize - 1), 0, 1)
    return lerp(0.82, 1.30, t)
end

function TableBackgroundSpring:getPlantScaleByY(y, kind)
    local s = self:getBaseScaleByY(y)

    if kind == "cao" then
        return s * 0.86
    elseif kind == "hua" then
        return s * 0.82
    elseif kind == "soil" then
        return s * 0.80
    elseif kind == "snow" then
        return s * 0.70
    elseif kind == "rock" then
        return s * 0.82
    end

    return s
end

function TableBackgroundSpring:drawGrassBase(rng, ox, oy)
    local ts = self.tileSize

    px(ox, oy, ts, ts, palette.groundA)

    -- 基础噪点：提高绿色占比
    for y = 0, ts - 1 do
        for x = 0, ts - 1 do
            local roll = rng:random(100)

            if roll <= 11 then
                px(ox + x, oy + y, 1, 1, palette.groundB)
            elseif roll <= 20 then
                px(ox + x, oy + y, 1, 1, palette.groundC)
            elseif roll <= 26 then
                px(ox + x, oy + y, 1, 1, palette.groundD)
            elseif roll <= 32 then
                px(ox + x, oy + y, 1, 1, palette.soil, 0.45)
            elseif roll <= 35 then
                px(ox + x, oy + y, 1, 1, palette.soilDark, 0.26)
            elseif roll <= 49 then
                px(ox + x, oy + y, 1, 1, palette.grassA, 0.72)
            elseif roll <= 60 then
                px(ox + x, oy + y, 1, 1, palette.grassB, 0.68)
            elseif roll <= 70 then
                px(ox + x, oy + y, 1, 1, palette.grassC, 0.72)
            elseif roll <= 75 then
                px(ox + x, oy + y, 1, 1, palette.grassD, 0.62)
            elseif roll == 76 then
                px(ox + x, oy + y, 1, 1, palette.grassShadow, 0.50)
            end
        end
    end

    -- 大块不规则返青 1：更常见、更大
    if chance(rng, 0.90) then
        local x = ox + rng:random(0, ts - 17)
        local y = oy + rng:random(0, ts - 13)

        local w1 = rng:random(9, 15)
        local h1 = rng:random(4, 7)
        px(x, y, w1, h1, palette.grassA, 0.38)

        px(
            x + rng:random(1, 3),
            y - 1,
            math.max(3, w1 - rng:random(3, 5)),
            rng:random(2, 3),
            palette.grassC,
            0.28
        )

        px(
            x - 1,
            y + rng:random(1, 2),
            rng:random(3, 6),
            math.max(2, h1 - 2),
            palette.grassB,
            0.24
        )
    end

    -- 大块不规则返青 2
    if chance(rng, 0.72) then
        local x = ox + rng:random(1, ts - 15)
        local y = oy + rng:random(1, ts - 12)

        local w1 = rng:random(8, 13)
        local h1 = rng:random(3, 6)
        px(x, y, w1, h1, palette.grassC, 0.30)

        px(
            x + 1,
            y + 1,
            math.max(2, w1 - 3),
            math.max(1, h1 - 1),
            palette.grassD,
            0.18
        )

        px(
            x + rng:random(0, 2),
            y + h1 - 1,
            rng:random(2, 5),
            1,
            palette.grassB,
            0.24
        )
    end

    -- 第三块小返青斑
    if chance(rng, 0.58) then
        local x = ox + rng:random(2, ts - 11)
        local y = oy + rng:random(2, ts - 9)
        px(
            x,
            y,
            rng:random(4, 8),
            rng:random(2, 4),
            palette.grassD,
            0.16
        )
    end

    -- 湿土块：减少一点
    if chance(rng, 0.30) then
        local x = ox + rng:random(2, ts - 9)
        local y = oy + rng:random(3, ts - 7)
        local w = rng:random(3, 5)
        local h = rng:random(2, 3)

        px(x, y, w, h, palette.soil, 0.24)

        if chance(rng, 0.55) then
            px(x + 1, y + 1, math.max(1, w - 2), 1, palette.soilDark, 0.20)
        end
    end

    -- 少量小残雪：更少
    if chance(rng, 0.05) then
        local x = ox + rng:random(2, ts - 10)
        local y = oy + rng:random(2, ts - 7)
        local w = rng:random(3, 4)
        local h = rng:random(1, 2)

        px(x, y + 1, w, h, palette.snowShadow, 0.18)
        px(x, y, w, h, palette.snow, 0.64)

        if w >= 4 then
            px(x + 1, y, w - 2, 1, palette.dew, 0.34)
        end
    end

    -- 花瓣点
    if chance(rng, 0.07) then
        local pxCount = rng:random(1, 2)
        for _ = 1, pxCount do
            px(
                ox + rng:random(0, ts - 2),
                oy + rng:random(0, ts - 2),
                1, 1,
                palette.blossom,
                0.40
            )
        end
    end
end

function TableBackgroundSpring:addStaticEntity(kind, x, y, s)
    self.staticEntities[#self.staticEntities + 1] = {
        kind = kind,
        x = x,
        y = y,
        s = s,
    }
end

function TableBackgroundSpring:randomX(rng, approxWidth, s)
    local margin = 8
    local maxX = self.patternSize - math.floor(approxWidth * s) - margin
    if maxX < margin then
        maxX = margin
    end
    return rng:random(margin, maxX)
end

function TableBackgroundSpring:spawnFlowers(rng)
    local count = self.flowerCount
    for _ = 1, count do
        local y = rng:random(8, self.patternSize - 34)
        local s = self:getPlantScaleByY(y, "hua") * randf(rng, 0.96, 1.14)
        local x = self:randomX(rng, 22, s)
        self:addStaticEntity("hua", x, y, s)
    end
end

function TableBackgroundSpring:spawnGrass(rng)
    local count = self.grassCount
    for _ = 1, count do
        local y = rng:random(8, self.patternSize - 28)
        local s = self:getPlantScaleByY(y, "cao") * randf(rng, 0.96, 1.18)
        local x = self:randomX(rng, 16, s)
        self:addStaticEntity("cao", x, y, s)
    end
end

function TableBackgroundSpring:spawnRocks(rng)
    local count = self.rockCount
    for _ = 1, count do
        local y = rng:random(10, self.patternSize - 30)
        local s = self:getPlantScaleByY(y, "rock") * randf(rng, 0.88, 1.10)
        local x = self:randomX(rng, 22, s)
        self:addStaticEntity("rock", x, y, s)
    end
end

function TableBackgroundSpring:spawnSnow(rng)
    local count = self.snowCount
    for _ = 1, count do
        local y = rng:random(8, self.patternSize - 24)
        local s = self:getPlantScaleByY(y, "snow") * randf(rng, 0.82, 1.02)
        local x = self:randomX(rng, 20, s)
        self:addStaticEntity("snow", x, y, s)
    end
end

function TableBackgroundSpring:spawnSoil(rng)
    local count = self.soilCount
    for _ = 1, count do
        local y = rng:random(8, self.patternSize - 22)
        local s = self:getPlantScaleByY(y, "soil") * randf(rng, 0.88, 1.10)
        local x = self:randomX(rng, 18, s)
        self:addStaticEntity("soil", x, y, s)
    end
end

function TableBackgroundSpring:spawnButterflies(rng, screenW, screenH)
    self.butterflies = {}

    local count = rng:random(self.butterflyCountMin, self.butterflyCountMax)
    for _ = 1, count do
        local x = rng:random(40, math.max(40, screenW - 40))
        local y = rng:random(50, math.max(50, screenH - 140))
        local s = randf(rng, 1.6, 2.4)

        local actor = Hudie.newActor(rng, x, y, s)
        self.butterflies[#self.butterflies + 1] = actor
    end
end

function TableBackgroundSpring:drawStaticEntities(rng)
    table.sort(self.staticEntities, function(a, b)
        return a.y < b.y
    end)

    for _, e in ipairs(self.staticEntities) do
        if e.kind == "soil" then
            Soil.drawRandom(rng, e.x, e.y, e.s)
        elseif e.kind == "snow" then
            Snow.drawRandom(rng, e.x, e.y, e.s)
        elseif e.kind == "rock" then
            Rock.drawRandom(rng, e.x, e.y, e.s)
        elseif e.kind == "cao" then
            Cao.drawRandom(rng, e.x, e.y, e.s)
        elseif e.kind == "hua" then
            Hua.drawRandom(rng, e.x, e.y, e.s)
        end
    end
end

function TableBackgroundSpring:rebuildQuad(screenW, screenH)
    local drawW = math.ceil(screenW / self.scale)
    local drawH = math.ceil(screenH / self.scale)
    self.quad = love.graphics.newQuad(0, 0, drawW, drawH, self.patternSize, self.patternSize)
end

function TableBackgroundSpring:build(options)
    options = options or {}

    self.patternSize = options.patternSize or self.patternSize
    self.tileSize = options.tileSize or self.tileSize
    self.scale = options.scale or self.scale
    self.seed = options.seed or timeSeed()

    self.grassCount = options.grassCount or self.grassCount
    self.flowerCount = options.flowerCount or self.flowerCount
    self.rockCount = options.rockCount or self.rockCount
    self.snowCount = options.snowCount or self.snowCount
    self.soilCount = options.soilCount or self.soilCount
    self.butterflyCountMin = options.butterflyCountMin or self.butterflyCountMin
    self.butterflyCountMax = options.butterflyCountMax or self.butterflyCountMax

    local rng = love.math.newRandomGenerator(self.seed)

    self.canvas = love.graphics.newCanvas(self.patternSize, self.patternSize)
    self.canvas:setFilter("nearest", "nearest")
    self.canvas:setWrap("repeat", "repeat")

    self.staticEntities = {}
    self.butterflies = {}

    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)

    for y = 0, self.patternSize - self.tileSize, self.tileSize do
        for x = 0, self.patternSize - self.tileSize, self.tileSize do
            self:drawGrassBase(rng, x, y)
        end
    end

    self:spawnSoil(rng)
    self:spawnSnow(rng)
    self:spawnGrass(rng)
    self:spawnFlowers(rng)
    self:spawnRocks(rng)

    self:drawStaticEntities(rng)

    -- 额外点状提亮，也提高绿色占比
    for _ = 1, 54 do
        local roll = rng:random(100)
        local c = palette.groundC
        local a = 0.18

        if roll <= 34 then
            c = palette.grassC
            a = 0.20
        elseif roll <= 56 then
            c = palette.grassA
            a = 0.18
        elseif roll <= 72 then
            c = palette.grassD
            a = 0.14
        elseif roll <= 86 then
            c = palette.soil
            a = 0.14
        end

        px(
            rng:random(0, self.patternSize - 2),
            rng:random(0, self.patternSize - 2),
            1,
            1,
            c,
            a
        )
    end

    love.graphics.setCanvas(oldCanvas)

    local screenW = tonumber(options.screenW) or love.graphics.getWidth()
    local screenH = tonumber(options.screenH) or love.graphics.getHeight()
    self:rebuildQuad(screenW, screenH)
    self:spawnButterflies(rng, screenW, screenH)
end

function TableBackgroundSpring:init(options)
    self:build(options)
end

function TableBackgroundSpring:regenerate(options)
    self:build(options or {})
end

function TableBackgroundSpring:resize(screenW, screenH)
    if not self.canvas then
        return
    end
    self:rebuildQuad(screenW, screenH)
end

function TableBackgroundSpring:update(dt, screenW, screenH)
    if not self.butterflies then
        return
    end

    screenW = screenW or love.graphics.getWidth()
    screenH = screenH or love.graphics.getHeight()

    for _, b in ipairs(self.butterflies) do
        b:update(dt, 12, screenW - 12, 24, screenH - 120)
    end
end

function TableBackgroundSpring:drawButterflies()
    if not self.butterflies then
        return
    end

    for _, b in ipairs(self.butterflies) do
        b:draw()
    end
end

function TableBackgroundSpring:draw(screenW, screenH)
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

    self:drawButterflies()

    love.graphics.setColor(1, 1, 1, 0.03)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    love.graphics.setColor(1, 1, 1, 1)
end

return TableBackgroundSpring
