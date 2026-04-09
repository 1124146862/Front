local BlackHoleTableBackground = {}
BlackHoleTableBackground.displayName = "黑洞"

-- ==========================================
-- 内部辅助渲染函数 (像素风)
-- ==========================================

local function drawPixelStar(x, y, s, alpha, color)
    local u = math.max(1, math.floor(s + 0.5))
    local px = math.floor(x + 0.5)
    local py = math.floor(y + 0.5)

    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.rectangle("fill", px, py, u, u)
end

-- 绘制纯黑的“事件视界” (使用像素扫描线拼成一个完美的圆形黑洞)
local function fillPixelEventHorizon(cx, cy, r)
    love.graphics.setColor(0.005, 0.005, 0.008, 1) -- 极致的虚空黑
    local radius = math.floor(r)
    for y = -radius, radius do
        local width = math.floor(math.sqrt(radius * radius - y * y))
        love.graphics.rectangle("fill", cx - width, cy + y, width * 2, 1)
    end
end

-- ==========================================
-- 颜色与物理常数
-- ==========================================

-- 颜色插值 (用于多普勒效应：蓝移/红移)
local function lerpColor(c1, c2, t)
    return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t
    }
end

-- 【调整】更加克制、冷峻的写实系配色
local COLOR_BLUE_SHIFT = {0.85, 0.90, 0.95} -- 幽冷、苍白的微蓝 (迎面)
local COLOR_BASE       = {0.70, 0.50, 0.35} -- 沉稳、暗淡的枯铜金 (基底)
local COLOR_RED_SHIFT  = {0.30, 0.15, 0.10} -- 极度深邃的暗锈红 (远去)

-- ==========================================
-- 背景主题接口
-- ==========================================

local function timeSeed()
    local t = os.time()
    local frac = 0
    if love.timer then
        frac = math.floor(love.timer.getTime() * 100000)
    end
    return t + frac
end

function BlackHoleTableBackground:init(options)
    self:build(options)
end

function BlackHoleTableBackground:build(options)
    options = options or {}
    self.seed = options.seed or timeSeed()
    local rng = love.math.newRandomGenerator(self.seed)
    
    self.time = 0
    
    self.bgStars = {}
    self.bgStarCount = options.bgStarCount or rng:random(30, 44)
    self.diskDensity = options.diskDensity or rng:random(2200, 3000)
    self.photonRingCount = options.photonRingCount or rng:random(520, 720)
    self.eventHorizonScale = options.eventHorizonScale or (0.13 + rng:random() * 0.05)
    self.tiltY = options.tiltY or (0.18 + rng:random() * 0.08)
    self.rotSpeedFactor = options.rotSpeedFactor or (0.04 + rng:random() * 0.02)
    self.pulseAmplitude = options.pulseAmplitude or (0.75 + rng:random() * 0.35)
    self.accretionDisk = {} -- 吸积盘粒子
    self.photonRing = {}    -- 光子环 (黑洞边缘的光环)
    
    -- 1. 生成深空背景星 (极其稀疏和暗淡)
    for _ = 1, self.bgStarCount do
        table.insert(self.bgStars, {
            rx = rng:random(),
            ry = rng:random(),
            s = rng:random() < 0.9 and 1 or 2,
            alpha = rng:random() * 0.15 + 0.05
        })
    end
    
    -- 2. 生成吸积盘 (Accretion Disk)
    for _ = 1, self.diskDensity do
        local distT = rng:random()
        distT = distT * distT * distT 
        
        local r = 1.1 + distT * 3.5 
        local theta = rng:random() * math.pi * 2
        
        -- 【调整】大幅降低基础运转速度，体现巨物缓慢流转感
        local speed = (1.0 / math.sqrt(r)) * (rng:random() * 0.15 + 0.3)
        
        table.insert(self.accretionDisk, {
            r = r,
            theta = theta,
            speed = speed,
            s = rng:random() * 1.2 + 0.8,
            baseAlpha = rng:random() * 0.5 + 0.1,
            noise = rng:random() * math.pi 
        })
    end

    -- 3. 生成光子环
    for _ = 1, self.photonRingCount do
        table.insert(self.photonRing, {
            r = 1.0 + rng:random() * 0.06, 
            theta = rng:random() * math.pi * 2,
            -- 【调整】光子环速度也相应降低
            speed = rng:random() * 0.5 + 0.6, 
            s = rng:random() * 1.2 + 0.8,
            baseAlpha = rng:random() * 0.4 + 0.2
        })
    end
end

function BlackHoleTableBackground:regenerate(options)
    self:build(options)
end

function BlackHoleTableBackground:resize(screenW, screenH)
end

function BlackHoleTableBackground:update(dt)
    self.time = self.time + dt
end

function BlackHoleTableBackground:draw(width, height)
    -- 极度深邃的宇宙底色
    love.graphics.clear(0.005, 0.005, 0.008, 1)
    
    -- 1. 绘制稀疏的背景星空
    love.graphics.setBlendMode("alpha")
    for _, star in ipairs(self.bgStars) do
        drawPixelStar(star.rx * width, star.ry * height, star.s, star.alpha, {0.5, 0.5, 0.6})
    end

    -- 基础排版参数
    local cx = width * 0.5
    local cy = height * 0.5
    local eventHorizonRadius = math.min(width, height) * self.eventHorizonScale
    
    -- 吸积盘透视倾角
    local tiltY = self.tiltY
    -- 【调整】极其缓慢的全局旋转时间轴
    local rotSpeed = self.time * self.rotSpeedFactor

    -- ==== 开始分层渲染黑洞 (核心物理视觉) ====
    love.graphics.setBlendMode("add")

    -- 【第一层】：绘制吸积盘的“后半部分” (位于黑洞后方)
    for _, pt in ipairs(self.accretionDisk) do
        local currentTheta = pt.theta + rotSpeed * pt.speed
        local sinT = math.sin(currentTheta)
        
        -- sinT < 0 代表它正在轨道的后半圈 (屏幕上方)
        if sinT < 0 then
            local px = cx + math.cos(currentTheta) * pt.r * eventHorizonRadius
            local py = cy + sinT * pt.r * eventHorizonRadius * tiltY
            
            -- 【调整】后半圈光线较暗
            local intensity = 0.25 + math.cos(currentTheta) * 0.15
            local a = pt.baseAlpha * intensity
            
            drawPixelStar(px, py, pt.s, a, COLOR_RED_SHIFT)
        end
    end

    -- 【第二层】：绘制事件视界 (纯黑像素圆遮罩，挡住后方的吸积盘)
    love.graphics.setBlendMode("alpha")
    -- 【调整】极其轻微且缓慢的呼吸感，仿佛空间在微微扭曲
    local pulse = math.sin(self.time * 0.5) * self.pulseAmplitude
    fillPixelEventHorizon(cx, cy, eventHorizonRadius + pulse)

    love.graphics.setBlendMode("add")

    -- 【第三层】：绘制光子环 (包裹黑洞边缘的高能光环)
    for _, pt in ipairs(self.photonRing) do
        local currentTheta = pt.theta + rotSpeed * pt.speed
        local cosT = math.cos(currentTheta)
        local shiftFactor = (cosT + 1) * 0.5 
        
        local color = lerpColor(COLOR_BASE, COLOR_BLUE_SHIFT, shiftFactor)
        local px = cx + math.cos(currentTheta) * pt.r * (eventHorizonRadius + pulse)
        local py = cy + math.sin(currentTheta) * pt.r * (eventHorizonRadius + pulse)
        
        -- 【调整】光子环亮度过渡更平滑
        local intensity = 0.6 + cosT * 0.4
        drawPixelStar(px, py, pt.s, pt.baseAlpha * intensity, color)
    end

    -- 【第四层】：绘制吸积盘的“前半部分” (横跨遮挡在黑洞前方)
    for _, pt in ipairs(self.accretionDisk) do
        local currentTheta = pt.theta + rotSpeed * pt.speed
        local sinT = math.sin(currentTheta)
        local cosT = math.cos(currentTheta)
        
        -- sinT >= 0 代表它正在轨道的前半圈 (屏幕下方)
        if sinT >= 0 then
            local px = cx + cosT * pt.r * eventHorizonRadius
            local py = cy + sinT * pt.r * eventHorizonRadius * tiltY
            
            local shiftFactor = (cosT + 1) * 0.5 
            local color = shiftFactor > 0.6 and lerpColor(COLOR_BASE, COLOR_BLUE_SHIFT, (shiftFactor-0.6)/0.4) 
                                             or lerpColor(COLOR_RED_SHIFT, COLOR_BASE, shiftFactor/0.6)
            
            -- 【调整】削弱迎面侧的极度高光，让亮度过渡自然，没有突兀的光斑
            local intensity = 0.5 + cosT * 0.7
            local a = pt.baseAlpha * intensity
            
            -- 【调整】闪烁噪点频率放缓，显得更加安静
            a = a * (0.9 + math.sin(self.time * 1.5 + pt.noise) * 0.1)
            
            drawPixelStar(px, py, pt.s, a, color)
        end
    end

    love.graphics.setBlendMode("alpha")
end

return BlackHoleTableBackground
