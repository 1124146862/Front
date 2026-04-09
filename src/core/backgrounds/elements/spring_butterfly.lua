local SpringHudie = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    pinkA   = C(244, 174, 208),
    pinkB   = C(226, 128, 186),

    blackA  = C(58, 52, 56),
    blackB  = C(96, 88, 94),

    whiteA  = C(246, 244, 238),
    whiteB  = C(222, 218, 212),

    yellowA = C(240, 214, 106),
    yellowB = C(214, 176, 78),

    body    = C(74, 66, 54),
    shadow  = C(40, 36, 34),
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function dpx(ox, oy, spriteW, dir, rx, ry, w, h, c, s, a)
    local tx
    if dir == 1 then
        tx = rx
    else
        tx = spriteW - rx - (w or 1)
    end

    local sx = math.floor(ox + tx * s + 0.5)
    local sy = math.floor(oy + ry * s + 0.5)
    local sw = math.max(1, math.floor((w or 1) * s + 0.5))
    local sh = math.max(1, math.floor((h or 1) * s + 0.5))

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

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function len2(x, y)
    return math.sqrt(x * x + y * y)
end

local function normalize(x, y)
    local l = len2(x, y)
    if l <= 0.0001 then
        return 0, 0
    end
    return x / l, y / l
end

local function getWingColors(colorType)
    if colorType == "pink" then
        return palette.pinkA, palette.pinkB
    elseif colorType == "black" then
        return palette.blackA, palette.blackB
    elseif colorType == "white" then
        return palette.whiteA, palette.whiteB
    elseif colorType == "yellow" then
        return palette.yellowA, palette.yellowB
    end
    return palette.pinkA, palette.pinkB
end

-- flap: 0=收拢 1=半开 2=张开
function SpringHudie.draw(x, y, s, dir, flap, colorType)
    dir = dir or 1
    flap = flap or 1
    colorType = colorType or "pink"

    local W = 14
    local wingA, wingB = getWingColors(colorType)

    dpx(x, y, W, dir, 4, 10, 5, 1, palette.shadow, s, 0.08)

    -- 身体
    dpx(x, y, W, dir, 6, 5, 1, 4, palette.body, s)
    dpx(x, y, W, dir, 5, 4, 3, 1, palette.body, s)

    -- 触角
    dpx(x, y, W, dir, 5, 3, 1, 1, palette.body, s)
    dpx(x, y, W, dir, 7, 3, 1, 1, palette.body, s)

    if flap == 0 then
        dpx(x, y, W, dir, 4, 5, 2, 3, wingA, s)
        dpx(x, y, W, dir, 3, 6, 1, 2, wingB, s)
        dpx(x, y, W, dir, 7, 5, 2, 3, wingA, s)
        dpx(x, y, W, dir, 9, 6, 1, 2, wingB, s)

    elseif flap == 1 then
        dpx(x, y, W, dir, 3, 4, 3, 3, wingA, s)
        dpx(x, y, W, dir, 2, 6, 2, 2, wingB, s)
        dpx(x, y, W, dir, 7, 4, 3, 3, wingA, s)
        dpx(x, y, W, dir, 10, 6, 2, 2, wingB, s)

    else
        dpx(x, y, W, dir, 2, 4, 4, 3, wingA, s)
        dpx(x, y, W, dir, 1, 6, 3, 2, wingB, s)
        dpx(x, y, W, dir, 7, 4, 4, 3, wingA, s)
        dpx(x, y, W, dir, 10, 6, 3, 2, wingB, s)
    end
end

function SpringHudie.newActor(rng, x, y, s)
    local colorList = {"pink", "black", "white", "yellow"}

    local actor = {
        rng = rng,
        x = x or 0,
        y = y or 0,
        s = s or 1,

        vx = randf(rng, -2.2, 2.2),
        vy = randf(rng, -1.4, 1.4),

        dir = (randi(rng, 0, 1) == 0) and -1 or 1,
        colorType = colorList[randi(rng, 1, #colorList)],

        -- walk=飞行移动，pause=长时间悬停/原地扇翅，rest=更安静停住
        state = "walk", -- walk / pause / rest
        stateTime = randf(rng, 2.6, 4.2),

        flapTimer = randf(rng, 0, 10),
        flapSpeed = randf(rng, 5.0, 7.5),
        flap = 1,

        cruiseSpeed = randf(rng, 5.0, 8.5),
        maxSpeed = randf(rng, 9.0, 14.0),
        accel = randf(rng, 3.0, 5.0),

        noiseTimer = randf(rng, 0, 10),
        noiseSpeed = randf(rng, 0.45, 0.95),
        noiseAmp = randf(rng, 0.8, 2.1),

        bobTimer = randf(rng, 0, 10),
        bobSpeed = randf(rng, 0.8, 1.4),
        bobAmp = randf(rng, 0.5, 1.4),

        targetX = x or 0,
        targetY = y or 0,

        offscreenMargin = randf(rng, 36, 90),

        restX = nil,
        restY = nil,

        pauseFlapMode = "still", -- still / soft
    }

    function actor:_pickTarget(leftBound, rightBound, topBound, bottomBound, allowFar)
        local margin = self.offscreenMargin
        local extra = allowFar and randf(self.rng, 8, 28) or 0

        self.targetX = randf(self.rng, leftBound - margin - extra, rightBound + margin + extra)
        self.targetY = randf(self.rng, topBound - margin - extra, bottomBound + margin + extra)
    end

    function actor:_pickRestPoint(leftBound, rightBound, topBound, bottomBound)
        self.restX = randf(self.rng, leftBound - 8, rightBound + 8)
        self.restY = randf(self.rng, topBound + 8, bottomBound - 8)
    end

    function actor:_enterWalk(leftBound, rightBound, topBound, bottomBound)
        self.state = "walk"
        self.stateTime = randf(self.rng, 2.8, 4.8)
        self:_pickTarget(leftBound, rightBound, topBound, bottomBound, true)
    end

    function actor:_enterPause()
        self.state = "pause"
        self.stateTime = randf(self.rng, 2.0, 4.5)
        self.pauseFlapMode = (rand01(self.rng) < 0.55) and "soft" or "still"
        self.vx = self.vx * 0.25
        self.vy = self.vy * 0.25
    end

    function actor:_enterRest(leftBound, rightBound, topBound, bottomBound)
        self.state = "rest"
        self.stateTime = randf(self.rng, 2.8, 5.5)
        self:_pickRestPoint(leftBound, rightBound, topBound, bottomBound)
        self.vx = self.vx * 0.18
        self.vy = self.vy * 0.18
    end

    function actor:_chooseState(leftBound, rightBound, topBound, bottomBound)
        local r = rand01(self.rng)

        if self.state == "walk" then
            if r < 0.55 then
                self:_enterPause()
            elseif r < 0.78 then
                self:_enterRest(leftBound, rightBound, topBound, bottomBound)
            else
                self:_enterWalk(leftBound, rightBound, topBound, bottomBound)
            end

        elseif self.state == "pause" then
            if r < 0.34 then
                self:_enterRest(leftBound, rightBound, topBound, bottomBound)
            else
                self:_enterWalk(leftBound, rightBound, topBound, bottomBound)
            end

        else
            if r < 0.70 then
                self:_enterWalk(leftBound, rightBound, topBound, bottomBound)
            else
                self:_enterPause()
            end
        end
    end

    function actor:update(dt, leftBound, rightBound, topBound, bottomBound)
        leftBound = leftBound or 0
        rightBound = rightBound or love.graphics.getWidth()
        topBound = topBound or 0
        bottomBound = bottomBound or love.graphics.getHeight()

        self.stateTime = self.stateTime - dt
        self.flapTimer = self.flapTimer + dt * self.flapSpeed
        self.noiseTimer = self.noiseTimer + dt * self.noiseSpeed
        self.bobTimer = self.bobTimer + dt * self.bobSpeed

        if self.stateTime <= 0 then
            self:_chooseState(leftBound, rightBound, topBound, bottomBound)
        end

        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local nx, ny = normalize(dx, dy)

        local noiseX = math.sin(self.noiseTimer * 1.03 + self.s * 2.4) * self.noiseAmp
        local noiseY = math.cos(self.noiseTimer * 0.77 + self.s * 1.9) * (self.noiseAmp * 0.42)
        local bobY = math.sin(self.bobTimer) * self.bobAmp

        if self.state == "walk" then
            local desiredSpeed = self.cruiseSpeed + randf(self.rng, -0.5, 0.8)
            local desiredVX = nx * desiredSpeed + noiseX
            local desiredVY = ny * desiredSpeed * 0.62 + noiseY + bobY

            self.vx = self.vx + (desiredVX - self.vx) * clamp(dt * self.accel * 0.22, 0, 1)
            self.vy = self.vy + (desiredVY - self.vy) * clamp(dt * self.accel * 0.22, 0, 1)

            self.flap = math.floor((math.sin(self.flapTimer) + 1) * 1.49)

        elseif self.state == "pause" then
            local hoverX = math.sin(self.noiseTimer * 0.85) * 0.75
            local hoverY = math.cos(self.noiseTimer * 0.62) * 0.55 + bobY * 0.18

            self.vx = self.vx + (hoverX - self.vx) * clamp(dt * 1.8, 0, 1)
            self.vy = self.vy + (hoverY - self.vy) * clamp(dt * 1.8, 0, 1)

            if self.pauseFlapMode == "soft" then
                local f = math.sin(self.flapTimer * 0.42)
                if f > 0.35 then
                    self.flap = 1
                elseif f < -0.35 then
                    self.flap = 0
                else
                    self.flap = 1
                end
            else
                if rand01(self.rng) < 0.006 then
                    self.flap = 1
                else
                    self.flap = 0
                end
            end

        else
            local restDX = (self.restX or self.x) - self.x
            local restDY = (self.restY or self.y) - self.y

            self.vx = self.vx + restDX * clamp(dt * 0.55, 0, 1)
            self.vy = self.vy + restDY * clamp(dt * 0.55, 0, 1)

            self.vx = self.vx * (1 - clamp(dt * 2.2, 0, 0.80))
            self.vy = self.vy * (1 - clamp(dt * 2.2, 0, 0.80))

            if rand01(self.rng) < 0.010 then
                self.flap = randi(self.rng, 0, 1)
            else
                self.flap = 0
            end
        end

        local speed = len2(self.vx, self.vy)
        if speed > self.maxSpeed then
            local k = self.maxSpeed / speed
            self.vx = self.vx * k
            self.vy = self.vy * k
        end

        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt

        if self.vx < -0.20 then
            self.dir = -1
        elseif self.vx > 0.20 then
            self.dir = 1
        end

        -- 走一段后接长停顿，目标更少切换
        if self.state == "walk" then
            local dist = len2(self.targetX - self.x, self.targetY - self.y)
            if dist < 20 then
                self:_enterPause()
            end
        end

        local hardMargin = self.offscreenMargin + 160
        local tooFar =
            self.x < leftBound - hardMargin or
            self.x > rightBound + hardMargin or
            self.y < topBound - hardMargin or
            self.y > bottomBound + hardMargin

        if tooFar then
            local side = randi(self.rng, 1, 4)
            local enterMargin = self.offscreenMargin + 20

            if side == 1 then
                self.x = leftBound - enterMargin
                self.y = randf(self.rng, topBound - 20, bottomBound + 20)
                self.vx = randf(self.rng, 2.0, 5.0)
                self.vy = randf(self.rng, -2.0, 2.0)
                self.dir = 1
            elseif side == 2 then
                self.x = rightBound + enterMargin
                self.y = randf(self.rng, topBound - 20, bottomBound + 20)
                self.vx = randf(self.rng, -5.0, -2.0)
                self.vy = randf(self.rng, -2.0, 2.0)
                self.dir = -1
            elseif side == 3 then
                self.x = randf(self.rng, leftBound - 20, rightBound + 20)
                self.y = topBound - enterMargin
                self.vx = randf(self.rng, -3.0, 3.0)
                self.vy = randf(self.rng, 2.0, 4.5)
            else
                self.x = randf(self.rng, leftBound - 20, rightBound + 20)
                self.y = bottomBound + enterMargin
                self.vx = randf(self.rng, -3.0, 3.0)
                self.vy = randf(self.rng, -4.5, -2.0)
            end

            self:_enterWalk(leftBound, rightBound, topBound, bottomBound)
        end
    end

    function actor:draw()
        SpringHudie.draw(self.x, self.y, self.s, self.dir, self.flap, self.colorType)
    end

    return actor
end

function SpringHudie.drawRandom(rng, x, y, s)
    local colorList = {"pink", "black", "white", "yellow"}
    local dir = (randi(rng, 0, 1) == 0) and -1 or 1
    local flap = randi(rng, 0, 2)
    local colorType = colorList[randi(rng, 1, #colorList)]
    SpringHudie.draw(x, y, s or 1, dir, flap, colorType)
end

return SpringHudie