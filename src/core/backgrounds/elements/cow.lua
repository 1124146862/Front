local Niu = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    body       = C(248, 239, 224), -- 温暖的奶油白
    spot       = C(167, 126, 89),  -- 柔和的奶牛斑块
    dark       = C(111, 85, 61),   -- 蹄子和角
    face       = C(235, 205, 195), -- 稍微粉嫩一点的口鼻区
    blush      = C(255, 160, 175), -- 新增：治愈系腮红
    eye        = C(41, 43, 40),
    shadowSoft = C(42, 62, 34),
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

-- 和小羊一样的无缝绘制算法，根除像素割裂漏色问题
local function dpx(ox, oy, spriteW, dir, rx, ry, w, h, c, s, a)
    local tx
    if dir == 1 then
        tx = rx
    else
        tx = spriteW - rx - (w or 1)
    end

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

-- =========================
-- 侧视图：left / right
-- 加入动画和更大的体型
-- =========================
local function drawSide(x, y, s, dir, isGrazing, isWalking, time)
    -- 吃草点头动画
    local hDy = 0
    if isGrazing then
        hDy = 2 + ((math.sin(time * 5) > 0) and 1 or 0)
    end

    -- 走路抬腿动画
    local l1, l2 = 0, 0
    if isWalking then
        l1 = (math.sin(time * 10) > 0) and 1 or 0
        l2 = (math.sin(time * 10 + math.pi) > 0) and 1 or 0
    end

    -- 牛的画布调宽到 18，比羊的 14 更大，显得身躯更长更宽厚
    local W = 18 

    -- 阴影也相应加长
    dpx(x, y, W, dir, 2, 11, 15, 1, palette.shadowSoft, s, 0.18)

    -- 身体主体 (宽厚感)
    dpx(x, y, W, dir, 2, 3, 11, 6, palette.body, s)
    dpx(x, y, W, dir, 1, 4, 1, 4, palette.body, s) -- 臀部圆润弧度

    -- 花纹 (奶牛斑块稍微大一点)
    dpx(x, y, W, dir, 4, 3, 3, 2, palette.spot, s)
    dpx(x, y, W, dir, 3, 5, 2, 3, palette.spot, s)
    dpx(x, y, W, dir, 9, 6, 3, 3, palette.spot, s)
    dpx(x, y, W, dir, 10, 4, 2, 1, palette.spot, s)

    -- 尾巴 (轻微垂下)
    dpx(x, y, W, dir, 1, 5, 1, 4, palette.dark, s)

    -- 头：单独突出一块，应用偏移
    dpx(x, y, W, dir, 13, 3 + hDy, 3, 5, palette.body, s)
    dpx(x, y, W, dir, 16, 5 + hDy, 2, 3, palette.face, s) -- 宽宽的可爱鼻口

    -- 耳朵和角：应用偏移
    dpx(x, y, W, dir, 13, 2 + hDy, 1, 1, palette.dark, s) -- 小牛角
    dpx(x, y, W, dir, 12, 4 + hDy, 1, 2, palette.dark, s) -- 垂下的耳朵

    -- 眼睛 + 鼻点 + 腮红：应用偏移
    dpx(x, y, W, dir, 15, 4 + hDy, 1, 1, palette.eye, s)
    dpx(x, y, W, dir, 17, 6 + hDy, 1, 1, palette.dark, s) -- 鼻孔
    dpx(x, y, W, dir, 15, 6 + hDy, 1, 1, palette.blush, s) -- 灵魂腮红

    -- 粗壮一点的腿（交替迈步）
    dpx(x, y, W, dir, 3,  9 - l1, 2, 2, palette.dark, s) -- 后腿1 (变粗为宽2)
    dpx(x, y, W, dir, 6,  9 - l2, 1, 2, palette.dark, s) -- 后腿2
    dpx(x, y, W, dir, 10, 9 - l1, 2, 2, palette.dark, s) -- 前腿1 (变粗为宽2)
    dpx(x, y, W, dir, 13, 9 - l2, 1, 2, palette.dark, s) -- 前腿2
end

-- =========================
-- 正面视图：down (重构抗锯齿)
-- =========================
local function drawFront(x, y, s)
    local dir = 1
    local W = 16
    dpx(x, y, W, dir, 3, 11, 10, 1, palette.shadowSoft, s, 0.18)
    dpx(x, y, W, dir, 4, 2, 1, 1, palette.dark, s)
    dpx(x, y, W, dir, 10, 2, 1, 1, palette.dark, s)
    dpx(x, y, W, dir, 4, 3, 7, 7, palette.body, s)
    dpx(x, y, W, dir, 3, 4, 1, 4, palette.body, s)
    dpx(x, y, W, dir, 11, 4, 1, 4, palette.body, s)
    dpx(x, y, W, dir, 5, 4, 2, 2, palette.spot, s)
    dpx(x, y, W, dir, 8, 5, 2, 2, palette.spot, s)
    dpx(x, y, W, dir, 5, 6, 5, 2, palette.face, s)
    dpx(x, y, W, dir, 5, 6, 1, 1, palette.eye, s)
    dpx(x, y, W, dir, 9, 6, 1, 1, palette.eye, s)
    dpx(x, y, W, dir, 6, 7, 2, 1, palette.dark, s)
    dpx(x, y, W, dir, 8, 7, 1, 1, palette.dark, s)
    dpx(x, y, W, dir, 4, 10, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 6, 10, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 9, 10, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 11, 10, 1, 2, palette.dark, s)
end

-- =========================
-- 背面视图：up (重构抗锯齿)
-- =========================
local function drawBack(x, y, s)
    local dir = 1
    local W = 16
    dpx(x, y, W, dir, 3, 11, 10, 1, palette.shadowSoft, s, 0.18)
    dpx(x, y, W, dir, 4, 3, 7, 7, palette.body, s)
    dpx(x, y, W, dir, 3, 4, 1, 4, palette.body, s)
    dpx(x, y, W, dir, 11, 4, 1, 4, palette.body, s)
    dpx(x, y, W, dir, 4, 7, 7, 2, palette.body, s)
    dpx(x, y, W, dir, 5, 4, 2, 2, palette.spot, s)
    dpx(x, y, W, dir, 8, 4, 2, 2, palette.spot, s)
    dpx(x, y, W, dir, 6, 6, 1, 1, palette.spot, s)
    dpx(x, y, W, dir, 7, 2, 1, 3, palette.dark, s)
    dpx(x, y, W, dir, 6, 2, 3, 1, palette.dark, s)
    dpx(x, y, W, dir, 4, 10, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 6, 10, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 9, 10, 1, 2, palette.dark, s)
    dpx(x, y, W, dir, 11, 10, 1, 2, palette.dark, s)
end

-- facing: "left" / "right" / "up" / "down"
function Niu.draw(x, y, s, facing, isGrazing, isWalking, time)
    if facing == -1 then facing = "left" end
    if facing == 1 or facing == nil then facing = "right" end
    time = time or 0

    if facing == "left" then
        drawSide(x, y, s, -1, isGrazing, isWalking, time)
    elseif facing == "right" then
        drawSide(x, y, s, 1, isGrazing, isWalking, time)
    elseif facing == "up" then
        drawBack(x, y, s)
    elseif facing == "down" then
        drawFront(x, y, s)
    else
        drawSide(x, y, s, 1, isGrazing, isWalking, time)
    end
end

-- =========================
-- Actor 逻辑
-- =========================
function Niu.newActor(rng, x, y, s)
    local actor = {
        rng = rng,
        x = x or 0,
        y = y or 0,
        s = s or 1,
        time = 0, -- 新增时间器驱动动画

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

        self.time = self.time + dt
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
        -- 传入行走状态和时间，让小牛动起来
        Niu.draw(self.x, self.y, self.s, self.facing, self.isGrazing, self.state == "walk", self.time)
    end

    actor:_chooseFacing()
    return actor
end

function Niu.drawRandom(rng, x, y, s)
    local facing = (randi(rng, 0, 1) == 0) and "left" or "right"
    Niu.draw(x, y, s, facing, false, false, 0)
end

return Niu