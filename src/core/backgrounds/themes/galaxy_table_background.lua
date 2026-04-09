local GalaxyTableBackground = {}
GalaxyTableBackground.displayName = "银河系"
-- ==========================================
-- 内部辅助渲染函数 (自然像素形态)
-- ==========================================

-- 绘制像素星星 (包含核心刺眼星、十字星等)
local function drawPixelStar(x, y, s, variant, alpha, glint, color)
    variant = variant or 1
    alpha = alpha or 1
    s = s or 1
    color = color or {1, 1, 1}

    local u = math.max(1, math.floor(s + 0.5))
    local px = math.floor(x + 0.5)
    local py = math.floor(y + 0.5)

    local r, g, b = color[1], color[2], color[3]
    if glint then
        r = math.min(1, r * 1.1)
        g = math.min(1, g * 1.1)
        b = b * 0.9 
    end

    if variant == 1 then
        -- 微亮单点
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.rectangle("fill", px, py, u, u)
    elseif variant == 2 then
        -- 标准十字星
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.rectangle("fill", px - u, py, u * 3, u)
        love.graphics.rectangle("fill", px, py - u, u, u * 3)
    elseif variant == 3 then
        -- 核心闪耀星
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.rectangle("fill", px - u, py, u * 3, u)
        love.graphics.rectangle("fill", px, py - u, u, u * 3)
        love.graphics.setColor(r, g, b, alpha * 0.5)
        love.graphics.rectangle("fill", px - u, py - u, u, u) 
        love.graphics.rectangle("fill", px + u, py - u, u, u) 
        love.graphics.rectangle("fill", px - u, py + u, u, u) 
        love.graphics.rectangle("fill", px + u, py + u, u, u) 
    else
        -- 耀眼大星 (银河中心专属)
        love.graphics.setColor(1, 1, 1, alpha * 0.9) 
        love.graphics.rectangle("fill", px, py, u, u)
        love.graphics.setColor(r, g, b, alpha * 0.6)
        love.graphics.rectangle("fill", px - u, py, u * 3, u)
        love.graphics.rectangle("fill", px, py - u, u, u * 3)
        love.graphics.setColor(r, g, b, alpha * 0.25)
        love.graphics.rectangle("fill", px - u * 2, py, u * 5, u)
        love.graphics.rectangle("fill", px, py - u * 2, u, u * 5)
    end
end

-- 绘制银河系的星云尘埃 (大面积、低透明度的像素块拼凑叠加)
local function drawPixelDust(x, y, s, alpha, color)
    local u = math.max(1, math.floor(s + 0.5))
    local px = math.floor(x + 0.5)
    local py = math.floor(y + 0.5)
    
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    -- 画一个稍微不规则的十字形或方形拼块来模拟气体云
    love.graphics.rectangle("fill", px - u, py - u, u * 3, u * 3)
    love.graphics.rectangle("fill", px - u*2, py, u * 5, u)
    love.graphics.rectangle("fill", px, py - u*2, u, u * 5)
end

-- ==========================================
-- 背景主题接口
-- ==========================================

function GalaxyTableBackground:init(options)
    self:build(options)
end

local function timeSeed()
    local t = os.time()
    local frac = 0
    if love.timer then
        frac = math.floor(love.timer.getTime() * 100000)
    end
    return t + frac
end

function GalaxyTableBackground:build(options)
    options = options or {}
    self.seed = options.seed or timeSeed()
    local rng = love.math.newRandomGenerator(self.seed)
    
    self.time = 0
    self.bgStarCount = options.bgStarCount or rng:random(60, 96)
    self.armCount = options.armCount or rng:random(2, 3)
    self.coreDensity = options.coreDensity or rng:random(320, 460)
    self.armDensity = options.armDensity or rng:random(680, 920)
    self.tiltY = options.tiltY or (0.28 + rng:random() * 0.12)
    self.rotSpeedFactor = options.rotSpeedFactor or (0.04 + rng:random() * 0.02)
    self.spinOffset = options.spinOffset or math.rad(rng:random(-25, 25))
    
    self.bgStars = {}       -- 深空远景静态星
    self.galaxyDusts = {}   -- 银河气体尘埃
    self.galaxyStars = {}   -- 银河主干恒星
    
    -- 1. 生成深空背景星 (极少量，作为底色衬托)
    for _ = 1, self.bgStarCount do
        table.insert(self.bgStars, {
            rx = rng:random(),
            ry = rng:random(),
            s = rng:random() < 0.8 and 1 or 1.5,
            alpha = rng:random() * 0.3 + 0.1,
            twinkleSpeed = rng:random() * 1.0 + 0.2
        })
    end
    
    -- 2. 生成银河系核心与旋臂 (使用极坐标/对数螺旋分布)
    local armCount = 2 -- 两条主旋臂
    local coreDensity = 400
    local armDensity = 800
    
    -- 银河系配色盘
    local coreColors = { {1, 0.95, 0.8}, {1, 0.85, 0.6}, {1, 1, 0.9} }    -- 暖黄色/白色核心
    local armColors  = { {0.5, 0.7, 1.0}, {0.7, 0.5, 1.0}, {0.4, 0.9, 1.0} } -- 幽蓝/紫/青色悬臂
    local dustColors = { {0.1, 0.2, 0.4}, {0.2, 0.1, 0.3}, {0.05, 0.15, 0.3} } -- 深蓝紫气团

    -- 生成核心区域 (高斯分布)
    for _ = 1, self.coreDensity do
        -- 越靠近中心越密集
        local r = math.abs(rng:random() - rng:random()) * 0.15 
        local theta = rng:random() * math.pi * 2
        local isDust = rng:random() < 0.2
        
        local color = coreColors[rng:random(1, #coreColors)]
        local v = (r < 0.02 and rng:random() > 0.8) and 4 or (rng:random() > 0.8 and 3 or 1)
        
        table.insert(isDust and self.galaxyDusts or self.galaxyStars, {
            r = r,
            theta = theta,
            s = rng:random() * 1.5 + 0.5,
            alpha = isDust and (rng:random() * 0.15 + 0.05) or (rng:random() * 0.8 + 0.2),
            color = isDust and dustColors[rng:random(1, #dustColors)] or color,
            variant = v
        })
    end
    
    -- 生成悬臂区域 (对数螺旋线)
    for i = 1, self.armCount do
        local armOffset = (i - 1) * math.pi
        
        for _ = 1, self.armDensity do
            local lengthT = rng:random() -- 0 到 1
            lengthT = lengthT * lengthT  -- 偏向于靠近核心
            
            -- 对数螺旋角度推算距离
            local angle = lengthT * math.pi * 3 -- 旋臂盘绕 1.5 圈
            local r = 0.05 + 0.45 * lengthT     -- 延伸距离
            
            -- 加上散射噪声，让悬臂边缘自然散开
            local scatter = 0.08 + lengthT * 0.15 -- 越往外越散
            local noiseR = (rng:random() - 0.5) * scatter
            local noiseTheta = (rng:random() - 0.5) * scatter * 2
            
            local finalTheta = armOffset + angle + noiseTheta
            local finalR = math.abs(r + noiseR)
            
            local isDust = rng:random() < 0.4 -- 悬臂有很多气态尘埃
            local isCoreColor = lengthT < 0.2 and rng:random() > 0.5 -- 靠近核心的地方带点暖色
            local color = isCoreColor and coreColors[rng:random(1, #coreColors)] or armColors[rng:random(1, #armColors)]
            
            table.insert(isDust and self.galaxyDusts or self.galaxyStars, {
                r = finalR,
                theta = finalTheta,
                s = rng:random() * 1.5 + 0.5,
                alpha = isDust and (rng:random() * 0.15 + 0.05) or (rng:random() * 0.6 + 0.1),
                color = isDust and dustColors[rng:random(1, #dustColors)] or color,
                variant = rng:random() > 0.9 and 2 or 1
            })
        end
    end
end

function GalaxyTableBackground:regenerate(options)
    self:build(options)
end

function GalaxyTableBackground:resize(screenW, screenH)
end

function GalaxyTableBackground:update(dt)
    self.time = self.time + dt
end

function GalaxyTableBackground:draw(width, height)
    -- 深邃黑底
    love.graphics.clear(0.01, 0.01, 0.02, 1)
    
    -- 1. 绘制深空静态背景星星
    for _, star in ipairs(self.bgStars) do
        local a = star.alpha + math.sin(self.time * star.twinkleSpeed) * 0.2
        a = math.max(0.05, math.min(1, a))
        drawPixelStar(star.rx * width, star.ry * height, star.s, 1, a, false, {0.8, 0.8, 0.9})
    end

    -- 银河系中心坐标
    local cx = width * 0.5
    local cy = height * 0.5
    local scaleRef = math.min(width, height) * 0.9 -- 银河系占屏幕比例
    
    -- 银河系透视倾角 (1为纯平视，0.3为压扁的 3D 透视)
    local tiltX = 1.0
    local tiltY = self.tiltY 
    
    -- 极其缓慢的旋转速度
    local rotSpeed = self.time * self.rotSpeedFactor
        local spinOffset = self.spinOffset -- 鍒濆灞曠ず鍊炬枩瑙掑害

    -- 开启加法混合，让星云和恒星叠加发光
    love.graphics.setBlendMode("add")

    -- 2. 优先绘制底层星云尘埃 (制造发光底座)
    for _, dust in ipairs(self.galaxyDusts) do
        local currentTheta = dust.theta + rotSpeed
        -- 计算投影位置
        local px = cx + math.cos(currentTheta + spinOffset) * dust.r * scaleRef * tiltX
        local py = cy + math.sin(currentTheta + spinOffset) * dust.r * scaleRef * tiltY
        
        drawPixelDust(px, py, dust.s * 2, dust.alpha, dust.color)
    end
    
    -- 3. 绘制星系主体恒星
    for _, star in ipairs(self.galaxyStars) do
        local currentTheta = star.theta + rotSpeed
        
        -- 计算投影位置
        local px = cx + math.cos(currentTheta + spinOffset) * star.r * scaleRef * tiltX
        local py = cy + math.sin(currentTheta + spinOffset) * star.r * scaleRef * tiltY
        
        -- 核心区的星星微微闪烁
        local currentAlpha = star.alpha
        if star.r < 0.1 then
            currentAlpha = currentAlpha + math.sin(self.time * 2.0 + star.theta) * 0.2
        end
        
        drawPixelStar(px, py, star.s, star.variant, currentAlpha, false, star.color)
    end
    
    -- 恢复默认混合模式
    love.graphics.setBlendMode("alpha")
end

return GalaxyTableBackground