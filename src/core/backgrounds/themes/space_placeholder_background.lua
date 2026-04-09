local PlanetaryRingTableBackground = {}

-- ==========================================
-- 内部辅助渲染函数
-- ==========================================

-- 绘制远景像素星星
local function drawPixelStar(x, y, s, alpha, color)
    local u = math.max(1, math.floor(s + 0.5))
    local px = math.floor(x + 0.5)
    local py = math.floor(y + 0.5)
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.rectangle("fill", px, py, u, u)
end

-- 绘制带有光影的冰晶/陨石碎片
local function drawPixelRock(x, y, s, alpha, color)
    local px = math.floor(x + 0.5)
    local py = math.floor(y + 0.5)

    if s <= 1.2 then
        -- 远处的细小冰尘
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.rectangle("fill", px, py, 1, 1)
    elseif s <= 2.5 then
        -- 中等大小的碎冰
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.rectangle("fill", px, py, 2, 2)
        -- 高光 (假设光从左上方照来)
        love.graphics.setColor(1, 1, 1, alpha * 0.7)
        love.graphics.rectangle("fill", px, py, 1, 1) 
    else
        -- 近处的巨大不规则陨石块 (包含基础色、高光、阴影)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.rectangle("fill", px - 1, py - 2, 3, 4)
        love.graphics.rectangle("fill", px - 2, py - 1, 4, 3)
        
        -- 亮部边缘 (向光面)
        love.graphics.setColor(1, 1, 1, alpha * 0.85)
        love.graphics.rectangle("fill", px - 2, py - 1, 1, 2)
        love.graphics.rectangle("fill", px - 1, py - 2, 2, 1)

        -- 暗部边缘 (背光面/阴影)
        love.graphics.setColor(color[1]*0.2, color[2]*0.2, color[3]*0.2, alpha)
        love.graphics.rectangle("fill", px + 1, py + 1, 1, 1)
        love.graphics.rectangle("fill", px, py + 2, 2, 1)
    end
end

-- ==========================================
-- 背景主题接口
-- ==========================================

function PlanetaryRingTableBackground:init(options)
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
function PlanetaryRingTableBackground:build(options)
    options = options or {}
    self.seed = options.seed or timeSeed()
    local rng = love.math.newRandomGenerator(self.seed)
    self._wrapRng = love.math.newRandomGenerator(self.seed + 4271)
    
    self.time = 0
    self.bgStarCount = options.bgStarCount or rng:random(32, 50)
    self.rockCount = options.rockCount or rng:random(240, 360)
    self.eventHorizonScale = options.eventHorizonScale or (0.13 + rng:random() * 0.05)
    self.tiltY = options.tiltY or (0.18 + rng:random() * 0.08)
    self.rotSpeedFactor = options.rotSpeedFactor or (0.04 + rng:random() * 0.02)
    self.stars = {}
    self.rocks = {}
    
    -- 1. 生成宇宙背景星空 (稀疏，缓慢移动)
    for _ = 1, self.bgStarCount do
        table.insert(self.stars, {
            rx = rng:random(),
            ry = rng:random(),
            s = rng:random() < 0.8 and 1 or 2,
            alpha = rng:random() * 0.4 + 0.1,
            twinkle = rng:random() * 1.5 + 0.5
        })
    end
    
    -- 2. 生成视差滚动的星环陨石带
    local rockColors = {
        {0.8, 0.9, 1.0}, -- 纯净冰晶 (淡蓝)
        {0.6, 0.7, 0.8}, -- 脏雪球
        {0.4, 0.45, 0.5},-- 灰色岩石
    }

    local totalRocks = 300
    for _ = 1, self.rockCount do
        local layer = rng:random() 
        local size, speed, alphaBase
        
        -- 分三层，营造强烈的 3D 深度错觉
        if layer > 0.8 then
            -- 近景：大块、稀疏、移动极快
            size = rng:random() * 1.5 + 2.5 
            speed = rng:random() * 0.08 + 0.1
            alphaBase = rng:random() * 0.3 + 0.7
        elseif layer > 0.4 then
            -- 中景：中等大小、移动速度中等
            size = rng:random() * 0.8 + 1.2
            speed = rng:random() * 0.03 + 0.04
            alphaBase = rng:random() * 0.3 + 0.4
        else
            -- 远景：极其细密的冰尘、几乎静止
            size = rng:random() * 0.5 + 0.5
            speed = rng:random() * 0.01 + 0.01
            alphaBase = rng:random() * 0.2 + 0.15
        end
        
        -- 倾斜角度：星环从右上方斜着向左下方流淌
        local vX = -speed
        local vY = speed * 0.25 
        
        table.insert(self.rocks, {
            rx = rng:random(),
            ry = rng:random(),
            vx = vX,
            vy = vY,
            s = size,
            alpha = alphaBase,
            color = rockColors[rng:random(1, #rockColors)]
        })
    end
end

function PlanetaryRingTableBackground:regenerate(options)
    self:build(options)
end

function PlanetaryRingTableBackground:resize(screenW, screenH)
end

function PlanetaryRingTableBackground:update(dt)
    self.time = self.time + dt
    local rng = self._wrapRng or love.math.newRandomGenerator((self.seed or timeSeed()) + 4271)
    
    -- 缓慢平移星星
    for _, star in ipairs(self.stars) do
        star.rx = star.rx - 0.002 * dt
        if star.rx < -0.1 then star.rx = star.rx + 1.2 end
    end
    
    -- 移动星环中的冰晶/陨石
    for _, rock in ipairs(self.rocks) do
        rock.rx = rock.rx + rock.vx * dt
        rock.ry = rock.ry + rock.vy * dt
        
        -- 屏幕外循环 (制造无尽流淌的星环)
        if rock.rx < -0.1 then 
            rock.rx = rock.rx + 1.2 
            rock.ry = rng:random()
        end
        if rock.ry > 1.1 then 
            rock.ry = rock.ry - 1.2 
            rock.rx = rng:random()
        end
    end
end

function PlanetaryRingTableBackground:draw(width, height)
    -- 极地冰冷的宇宙底色
    love.graphics.clear(0.01, 0.02, 0.03, 1)
    
    -- 1. 绘制背景星空
    for _, star in ipairs(self.stars) do
        local a = star.alpha + math.sin(self.time * star.twinkle) * 0.2
        a = math.max(0.05, math.min(1, a))
        drawPixelStar(star.rx * width, star.ry * height, star.s, a, {0.7, 0.8, 1.0})
    end

    -- 2. 绘制左下角巨大的行星轮廓大气层光晕 (暗示庞大巨物)
    love.graphics.setBlendMode("add")
    local planetCenterX = -width * 0.1
    local planetCenterY = height * 1.2
    local maxRadius = math.min(width, height) * 0.8
    
    for i = 1, 15 do
        local r = maxRadius * (i / 15)
        -- 边缘锐利，内部通透的大气层梯度
        local alpha = 0.02 * (1 - (i / 15))
        love.graphics.setColor(0.1, 0.25, 0.4, alpha)
        love.graphics.circle("fill", planetCenterX, planetCenterY, r)
    end
    love.graphics.setBlendMode("alpha")
    
    -- 3. 绘制分层滚动的星环陨石
    for _, rock in ipairs(self.rocks) do
        drawPixelRock(rock.rx * width, rock.ry * height, rock.s, rock.alpha, rock.color)
    end
end

return PlanetaryRingTableBackground
