local Yang = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    wool       = C(255, 253, 245), -- 更暖、更柔和的羊毛白
    woolLight  = C(255, 255, 255),
    face       = C(245, 210, 200), -- 治愈系微粉肤色
    ear        = C(235, 175, 185), -- 粉嫩的内耳
    blush      = C(255, 160, 175), -- 新增：可爱腮红
    dark       = C(120, 95,  80),  -- 更柔和的深棕色（腿部）
    eye        = C(60,  50,  50),  -- 柔和的深色眼睛
    shadowSoft = C(42,  62,  34),
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

-- 修复割裂问题的绘制函数
local function dpx(ox, oy, spriteW, dir, rx, ry, w, h, c, s, a)
    local tx
    if dir == 1 then
        tx = rx
    else
        tx = spriteW - rx - (w or 1)
    end

    -- 核心修复：分别计算绝对的起始和结束坐标，再相减求宽高
    -- 这样可以彻底消除由于浮点舍入导致的相邻色块间的 1 像素缝隙
    local sx = math.floor(ox + tx * s + 0.5)
    local sy = math.floor(oy + ry * s + 0.5)
    local ex = math.floor(ox + (tx + (w or 1)) * s + 0.5)
    local ey = math.floor(oy + (ry + (h or 1)) * s + 0.5)

    local sw = math.max(1, ex - sx)
    local sh = math.max(1, ey - sy)

    setColor(c, a)
    love.graphics.rectangle("fill", sx, sy, sw, sh)
end

local function rand01(rng)
    if rng and rng.random then
        return rng:random()
    end
    return love.math.random()
end

local function randi(rng, a, b)
    if rng and rng.random then
        return rng:random(a, b)
    end
    return love.math.random(a, b)
end

local function randf(rng, a, b)
    return a + (b - a) * rand01(rng)
end

-- 新增 isWalking 和 time 参数来驱动细节动画
function Yang.draw(x, y, s, facing, isGrazing, isWalking, time)
    local dir = 1
    if facing == "left" or facing == -1 then
        dir = -1
    elseif facing == "right" or facing == 1 then
        dir = 1
    end

    time = time or 0

    -- 动画逻辑计算
    local hDy = 0
    if isGrazing then
        -- 吃草时头低下，且带有轻微的咀嚼点动感
        hDy = 1 + ((math.sin(time * 6) > 0) and 1 or 0)
    end

    local l1, l2 = 0, 0
    if isWalking then
        -- 走路时腿部交替抬起，产生小碎步效果
        l1 = (math.sin(time * 12) > 0) and 1 or 0
        l2 = (math.sin(time * 12 + math.pi) > 0) and 1 or 0
    end

    local W = 14 -- 画布加宽，让羊身变得更圆润蓬松

    -- 阴影
    dpx(x, y, W, dir, 3, 11, 8, 1, palette.shadowSoft, s, 0.30)

    -- 身体（云朵状软萌羊毛）
    dpx(x, y, W, dir, 3, 3,  8, 6, palette.wool, s)
    dpx(x, y, W, dir, 4, 2,  6, 1, palette.wool, s) -- 顶部蓬松
    dpx(x, y, W, dir, 2, 4,  1, 4, palette.wool, s) -- 尾部弧度
    dpx(x, y, W, dir, 11,4,  1, 4, palette.wool, s) -- 颈部弧度

    -- 羊毛高光（增加立体感和软糯感）
    dpx(x, y, W, dir, 4, 3,  2, 1, palette.woolLight, s)
    dpx(x, y, W, dir, 8, 3,  2, 1, palette.woolLight, s)

    -- 腿部（带有 l1, l2 抬腿偏移）
    dpx(x, y, W, dir, 4, 9 - l1, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 6, 9 - l2, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 8, 9 - l1, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 10,9 - l2, 1, 2, palette.dark, s)

    -- 脸部（带有 hDy 吃草偏移）
    dpx(x, y, W, dir, 10, 5 + hDy, 3, 4, palette.face, s)
    dpx(x, y, W, dir, 13, 6 + hDy, 1, 2, palette.face, s) -- 小突出的鼻垫

    -- 眼睛
    dpx(x, y, W, dir, 11, 6 + hDy, 1, 1, palette.eye, s)

    -- 腮红（治愈系灵魂！）
    dpx(x, y, W, dir, 11, 7 + hDy, 1, 1, palette.blush, s)

    -- 耳朵（耷拉下来的垂耳，更显乖巧）
    dpx(x, y, W, dir, 9, 6 + hDy, 1, 2, palette.ear, s)
end

function Yang.drawRandom(rng, x, y, s)
    local dir = (rng and rng.random or love.math.random)(0, 1) == 0 and "left" or "right"
    Yang.draw(x, y, s, dir, false, false, 0)
end

-- =========================
-- Actor 逻辑
-- =========================
function Yang.newActor(rng, x, y, s)
    local actor = {
        rng = rng,
        x = x or 0,
        y = y or 0,
        s = s or 1,
        time = 0, -- 新增内部时间计时器，用于驱动动画

        facing = "right",
        dx = 1,
        dy = 0,

        speed = randf(rng, 0.1, 0.35),
        state = "idle",
        stateTime = randf(rng, 2.0, 5.0),
        
        isGrazing = true,

        idleMin = 3.0,
        idleMax = 7.0,
        walkMin = 1.0,
        walkMax = 3.0,

        turnChance = 0.40,
    }

    function actor:_setFacing(facing)
        self.facing = facing
        if facing == "left" then
            self.dx = -1
        elseif facing == "right" then
            self.dx = 1
        end
    end

    function actor:_chooseFacing()
        if rand01(self.rng) < 0.5 then
            self:_setFacing("left")
        else
            self:_setFacing("right")
        end
    end

    function actor:_chooseNextState()
        if self.state == "walk" then
            if rand01(self.rng) < 0.85 then
                self.state = "idle"
                self.isGrazing = true
                self.stateTime = randf(self.rng, self.idleMin, self.idleMax)
                
                if rand01(self.rng) < self.turnChance then
                    self:_chooseFacing()
                end
            else
                if rand01(self.rng) < 0.3 then
                    self:_chooseFacing()
                end
                self.state = "walk"
                self.isGrazing = false
                self.stateTime = randf(self.rng, self.walkMin, self.walkMax)
                self.speed = randf(self.rng, 0.1, 0.35)
            end
        else
            self:_chooseFacing()
            self.state = "walk"
            self.isGrazing = false
            self.stateTime = randf(self.rng, self.walkMin, self.walkMax)
            self.speed = randf(self.rng, 0.1, 0.35)
        end
    end

    function actor:update(dt, leftBound, rightBound)
        leftBound   = leftBound   or -math.huge
        rightBound  = rightBound  or  math.huge

        self.time = self.time + dt  -- 累加动画时间
        self.stateTime = self.stateTime - dt

        if self.stateTime <= 0 then
            self:_chooseNextState()
        end

        if self.state == "walk" then
            self.x = self.x + self.dx * self.speed * dt
        end

        local bounced = false
        if self.x <= leftBound then
            self.x = leftBound
            self:_setFacing("right")
            bounced = true
        elseif self.x >= rightBound then
            self.x = rightBound
            self:_setFacing("left")
            bounced = true
        end

        if bounced then
            self.state = "walk"
            self.isGrazing = false
            self.stateTime = randf(self.rng, 1.0, 2.5)
            self.speed = randf(self.rng, 0.1, 0.35)
        end
    end

    function actor:draw()
        -- 将内部的行走状态和计时器传递给绘制函数
        Yang.draw(self.x, self.y, self.s, self.facing, self.isGrazing, self.state == "walk", self.time)
    end

    actor:_chooseFacing()
    return actor
end

return Yang