local Hua = require("src.core.backgrounds.elements.common_flower")
local Cao = require("src.core.backgrounds.elements.common_grass")
local Niu = require("src.core.backgrounds.elements.cow")
local Yang = require("src.core.backgrounds.elements.sheep")

local TableBackgroundSummer = {
    canvas = nil,
    quad = nil,
    patternSize = 480,
    tileSize = 40,
    scale = 3,
    seed = nil,

    -- ========= 可调参数 =========
    -- 植物数量
    grassCount = 28,
    flowerCount = 40,

    -- 牛羊数量（减少一些）
    cowCount = 2,
    sheepCount = 4,

    -- 动物大小倍率
    cowScaleMul = 3.72,
    sheepScaleMul = 3.52,

    -- 动物移动参数（随机范围加大一些）
    animalMoveRangeMin = 22,
    animalMoveRangeMax = 52,
    animalMoveSpeedMin = 0.30,
    animalMoveSpeedMax = 0.95,

    staticEntities = nil, -- 草、花
    animals = nil,        -- 牛、羊（动态）
}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    grassA      = C(106, 174, 80),
    grassB      = C(89, 154, 66),
    grassC      = C(128, 196, 96),
    grassD      = C(152, 212, 112),
    grassShadow = C(61, 114, 46),
    grassDark   = C(44, 89, 36),
    soil        = C(130, 102, 68),
    blossom     = C(255, 244, 186),
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

-- 不做透视，只做很轻的“越靠下越大”
function TableBackgroundSummer:getBaseScaleByY(y)
    local t = clamp(y / math.max(1, self.patternSize - 1), 0, 1)
    return lerp(0.82, 1.30, t)
end

function TableBackgroundSummer:getPlantScaleByY(y, kind)
    local s = self:getBaseScaleByY(y)

    if kind == "cao" then
        return s * 0.72
    elseif kind == "hua" then
        return s * 0.68
    end

    return s
end

function TableBackgroundSummer:getAnimalScaleByY(y, kind)
    local s = self:getBaseScaleByY(y)

    if kind == "niu" then
        return s * self.cowScaleMul
    elseif kind == "yang" then
        return s * self.sheepScaleMul
    end

    return s
end

function TableBackgroundSummer:drawGrassBase(rng, ox, oy)
    local ts = self.tileSize

    px(ox, oy, ts, ts, palette.grassA)

    for y = 0, ts - 1 do
        for x = 0, ts - 1 do
            local roll = rng:random(100)
            if roll <= 15 then
                px(ox + x, oy + y, 1, 1, palette.grassB)
            elseif roll <= 28 then
                px(ox + x, oy + y, 1, 1, palette.grassC)
            elseif roll <= 35 then
                px(ox + x, oy + y, 1, 1, palette.grassD)
            elseif roll == 36 then
                px(ox + x, oy + y, 1, 1, palette.grassShadow)
            end
        end
    end

    if chance(rng, 0.65) then
        local x = ox + rng:random(3, ts - 12)
        local y = oy + rng:random(3, ts - 10)
        px(x, y, rng:random(5, 9), rng:random(3, 5), palette.grassD, 0.35)
    end

    if chance(rng, 0.22) then
        local x = ox + rng:random(3, ts - 8)
        local y = oy + rng:random(4, ts - 6)
        px(x, y, rng:random(3, 5), rng:random(2, 3), palette.soil, 0.22)
    end

    if chance(rng, 0.25) then
        local pxCount = rng:random(3, 7)
        for _ = 1, pxCount do
            px(
                ox + rng:random(0, ts - 2),
                oy + rng:random(0, ts - 2),
                1, 1,
                palette.blossom,
                0.7
            )
        end
    end
end

function TableBackgroundSummer:addStaticEntity(kind, x, y, s)
    self.staticEntities[#self.staticEntities + 1] = {
        kind = kind,
        x = x,
        y = y,
        s = s,
    }
end

function TableBackgroundSummer:addAnimal(kind, x, y, s, rng)
    local moveRange = rng:random(self.animalMoveRangeMin, self.animalMoveRangeMax)
    local moveSpeed = rng:random() * (self.animalMoveSpeedMax - self.animalMoveSpeedMin) + self.animalMoveSpeedMin

    self.animals[#self.animals + 1] = {
        kind = kind,

        x = x,
        y = y,
        s = s,

        originX = x,
        dir = rng:random(0, 1) == 1 and 1 or -1,
        speed = moveSpeed,
        moveRange = moveRange,

        isGrazing = false,
        pauseT = rng:random() * 3.0,
        walkT = rng:random() * 2.0,

        seed = rng:random(1, 999999),
    }
end

function TableBackgroundSummer:randomX(rng, approxWidth, s)
    local margin = 8
    local maxX = self.patternSize - math.floor(approxWidth * s) - margin
    if maxX < margin then
        maxX = margin
    end
    return rng:random(margin, maxX)
end

function TableBackgroundSummer:spawnFlowers(rng)
    local count = self.flowerCount
    for _ = 1, count do
        local y = rng:random(8, self.patternSize - 34)
        local s = self:getPlantScaleByY(y, "hua")
        local x = self:randomX(rng, 20, s)
        self:addStaticEntity("hua", x, y, s)
    end
end

function TableBackgroundSummer:spawnGrass(rng)
    local count = self.grassCount
    for _ = 1, count do
        local y = rng:random(8, self.patternSize - 28)
        local s = self:getPlantScaleByY(y, "cao")
        local x = self:randomX(rng, 14, s)
        self:addStaticEntity("cao", x, y, s)
    end
end

function TableBackgroundSummer:spawnCows(rng)
    local count = self.cowCount
    for _ = 1, count do
        local y = rng:random(16, self.patternSize - 42)
        local s = self:getAnimalScaleByY(y, "niu")
        local x = self:randomX(rng, 18, s)
        self:addAnimal("niu", x, y, s, rng)
    end
end

function TableBackgroundSummer:spawnSheep(rng)
    local count = self.sheepCount
    for _ = 1, count do
        local y = rng:random(14, self.patternSize - 36)
        local s = self:getAnimalScaleByY(y, "yang")
        local x = self:randomX(rng, 16, s)
        self:addAnimal("yang", x, y, s, rng)
    end
end

function TableBackgroundSummer:drawStaticEntities(rng)
    table.sort(self.staticEntities, function(a, b)
        return a.y < b.y
    end)

    for _, e in ipairs(self.staticEntities) do
        if e.kind == "cao" then
            Cao.drawRandom(rng, e.x, e.y, e.s)
        elseif e.kind == "hua" then
            Hua.drawRandom(rng, e.x, e.y, e.s)
        end
    end
end

function TableBackgroundSummer:sortAnimals()
    table.sort(self.animals, function(a, b)
        return a.y < b.y
    end)
end

function TableBackgroundSummer:rebuildQuad(screenW, screenH)
    local drawW = math.ceil(screenW / self.scale)
    local drawH = math.ceil(screenH / self.scale)
    self.quad = love.graphics.newQuad(0, 0, drawW, drawH, self.patternSize, self.patternSize)
end

function TableBackgroundSummer:build(options)
    options = options or {}

    self.patternSize = options.patternSize or self.patternSize
    self.tileSize = options.tileSize or self.tileSize
    self.scale = options.scale or self.scale
    self.seed = options.seed or timeSeed()

    -- ===== 支持外部传固定密度 =====
    self.grassCount = options.grassCount or self.grassCount
    self.flowerCount = options.flowerCount or self.flowerCount
    self.cowCount = options.cowCount or self.cowCount
    self.sheepCount = options.sheepCount or self.sheepCount

    -- ===== 支持外部传大小 =====
    self.cowScaleMul = options.cowScaleMul or self.cowScaleMul
    self.sheepScaleMul = options.sheepScaleMul or self.sheepScaleMul

    -- ===== 支持外部传移动参数 =====
    self.animalMoveRangeMin = options.animalMoveRangeMin or self.animalMoveRangeMin
    self.animalMoveRangeMax = options.animalMoveRangeMax or self.animalMoveRangeMax
    self.animalMoveSpeedMin = options.animalMoveSpeedMin or self.animalMoveSpeedMin
    self.animalMoveSpeedMax = options.animalMoveSpeedMax or self.animalMoveSpeedMax

    local rng = love.math.newRandomGenerator(self.seed)
    self._animalRng = love.math.newRandomGenerator(self.seed + 31337)

    self.canvas = love.graphics.newCanvas(self.patternSize, self.patternSize)
    self.canvas:setFilter("nearest", "nearest")
    self.canvas:setWrap("repeat", "repeat")

    self.staticEntities = {}
    self.animals = {}

    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)

    for y = 0, self.patternSize - self.tileSize, self.tileSize do
        for x = 0, self.patternSize - self.tileSize, self.tileSize do
            self:drawGrassBase(rng, x, y)
        end
    end

    self:spawnGrass(rng)
    self:spawnFlowers(rng)
    self:spawnCows(rng)
    self:spawnSheep(rng)

    self:drawStaticEntities(rng)

    for _ = 1, 50 do
        px(
            rng:random(0, self.patternSize - 2),
            rng:random(0, self.patternSize - 2),
            1,
            1,
            palette.grassD,
            0.45
        )
    end

    love.graphics.setCanvas(oldCanvas)
    self:rebuildQuad(love.graphics.getWidth(), love.graphics.getHeight())
    self:sortAnimals()
end

function TableBackgroundSummer:init(options)
    self:build(options)
end

function TableBackgroundSummer:regenerate(options)
    self:build(options or {})
end

function TableBackgroundSummer:resize(screenW, screenH)
    if not self.canvas then
        return
    end
    self:rebuildQuad(screenW, screenH)
end

function TableBackgroundSummer:update(dt, screenW, screenH)
    if not self.animals then
        return
    end

    local rng = self._animalRng or love.math.newRandomGenerator((self.seed or timeSeed()) + 31337)
    for _, a in ipairs(self.animals) do
        if a.pauseT and a.pauseT > 0 then
            a.pauseT = a.pauseT - dt
            a.isGrazing = true
        else
            a.isGrazing = false
            a.walkT = a.walkT + dt
            a.x = a.x + a.dir * a.speed * dt

            local minX = a.originX - a.moveRange
            local maxX = a.originX + a.moveRange

            if a.x <= minX then
                a.x = minX
                a.dir = 1
                a.pauseT = rng:random() * 3 + 2
            elseif a.x >= maxX then
                a.x = maxX
                a.dir = -1
                a.pauseT = rng:random() * 3 + 2
            end

            if a.walkT > 2.0 then
                a.walkT = 0
                if rng:random() < 0.35 then
                    a.pauseT = rng:random() * 4 + 2
                end
            end
        end
    end

    self:sortAnimals()
end

function TableBackgroundSummer:drawAnimalShadow(a)
    local sx = a.x
    local sy = a.y + 6 * a.s

    local rx, ry
    if a.kind == "niu" then
        rx = 4.8 * a.s
        ry = 1.8 * a.s
    else
        rx = 4.2 * a.s
        ry = 1.7 * a.s
    end

    love.graphics.setColor(0, 0, 0, 0.10)
    love.graphics.ellipse("fill", sx, sy, rx, ry)
    love.graphics.setColor(1, 1, 1, 1)
end

function TableBackgroundSummer:drawAnimals()
    if not self.animals then
        return
    end

    for _, a in ipairs(self.animals) do
        local drawX = a.x
        local drawY = a.y

        self:drawAnimalShadow(a)

        if a.kind == "niu" then
            Niu.draw(drawX, drawY, a.s, a.dir, a.isGrazing)
        elseif a.kind == "yang" then
            Yang.draw(drawX, drawY, a.s, a.dir, a.isGrazing)
        end
    end
end

function TableBackgroundSummer:draw(screenW, screenH)
    if not self.canvas then
        love.graphics.clear(
            palette.grassA[1],
            palette.grassA[2],
            palette.grassA[3],
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

    self:drawAnimals()

    love.graphics.setColor(1, 1, 1, 0.03)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    love.graphics.setColor(1, 1, 1, 1)
end

return TableBackgroundSummer
