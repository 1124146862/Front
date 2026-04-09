local CosmosTableBackground = {}
CosmosTableBackground.displayName = "星星"
-- ==========================================
-- 内部辅助渲染函数 (像素风星星)
-- ==========================================
local function drawPixelStar(x, y, s, variant, alpha, glint, color)
    variant = variant or 1
    alpha = alpha or 1
    s = s or 1
    color = color or {1, 1, 1}

    -- 基础像素单位大小
    local u = math.max(1, math.floor(s + 0.5))
    
    -- 坐标对齐
    local px = math.floor(x + 0.5)
    local py = math.floor(y + 0.5)

    -- 处理闪烁颜色变体
    local r, g, b = color[1], color[2], color[3]
    if glint then
        r = math.min(1, r * 1.1)
        g = math.min(1, g * 1.1)
        b = b * 0.9 -- 闪烁时微微变暖/变暗
    end

    -- 绘制基于像素步进的自然星星形态
    if variant == 1 then
        -- 形态 1：微亮星 (1x1像素单点)
        -- 最基础的背景星星
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.rectangle("fill", px, py, u, u)

    elseif variant == 2 then
        -- 形态 2：标准像素十字星 (3x3 grid)
        --  .
        -- .+.
        --  .
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.rectangle("fill", px - u, py, u * 3, u) -- 横
        love.graphics.rectangle("fill", px, py - u, u, u * 3) -- 竖

    elseif variant == 3 then
        -- 形态 3：闪耀大星 (5x5 grid approximation)
        -- 中心核心最亮，边缘像素半透明模拟柔和光晕，看起来不再是硬邦邦的方块
        
        -- 核心 (1.0 alpha)
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.rectangle("fill", px - u, py, u * 3, u)
        love.graphics.rectangle("fill", px, py - u, u, u * 3)
        
        -- 光晕边缘 (0.5 alpha) - 利用透明度拼接出菱形轮廓
        love.graphics.setColor(r, g, b, alpha * 0.5)
        love.graphics.rectangle("fill", px - u, py - u, u, u) -- 左上
        love.graphics.rectangle("fill", px + u, py - u, u, u) -- 右上
        love.graphics.rectangle("fill", px - u, py + u, u, u) -- 左下
        love.graphics.rectangle("fill", px + u, py + u, u, u) -- 右下

    else -- variant == 4 (新增：罕见的大衍射十字星)
        -- 核心（刺眼白/亮色，带轻微叠加）
        love.graphics.setColor(1, 1, 1, alpha * 0.8) -- 核心始终偏白
        love.graphics.rectangle("fill", px, py, u, u)
        
        -- 内层衍射束 (较粗，颜色深)
        love.graphics.setColor(r, g, b, alpha * 0.6)
        love.graphics.rectangle("fill", px - u, py, u * 3, u)
        love.graphics.rectangle("fill", px, py - u, u, u * 3)
        
        -- 外层衍射光束 (较细，极淡，拉长)
        love.graphics.setColor(r, g, b, alpha * 0.25)
        love.graphics.rectangle("fill", px - u * 2, py, u * 5, u)
        love.graphics.rectangle("fill", px, py - u * 2, u, u * 5)
    end
end

-- ==========================================
-- 绘制流星本体与余辉褪色拖尾
-- ==========================================
local function timeSeed()
    local t = os.time()
    local frac = 0
    if love.timer then
        frac = math.floor(love.timer.getTime() * 100000)
    end
    return t + frac
end

local function drawPixelMeteor(m, width, height)
    local u = math.max(1, math.floor(m.s + 0.5))

    -- 1. 绘制残留的拖尾余辉 (划过的地方留在原地渐渐褪去)
    for _, pt in ipairs(m.history) do
        local px = math.floor(pt.rx * width + 0.5)
        local py = math.floor(pt.ry * height + 0.5)
        
        -- 计算生命周期比例 (0~1)，离星星越近(刚产生)越趋近1，越亮
        local t = pt.life / pt.maxLife 
        
        love.graphics.setColor(m.tailColor[1], m.tailColor[2], m.tailColor[3], t * 0.9)
        love.graphics.rectangle("fill", px, py, u, u)
    end

    -- 2. 绘制流星头部本体 (如果它还没飞出画面)
    if not m.dead then
        local px = math.floor(m.rx * width + 0.5)
        local py = math.floor(m.ry * height + 0.5)
        -- 流星头部使用较大的块 (2x2) 以示区分
        love.graphics.setColor(m.headColor[1], m.headColor[2], m.headColor[3], 1)
        love.graphics.rectangle("fill", px, py, u * 2, u * 2)
    end
end

-- ==========================================
-- 标准背景主题接口
-- ==========================================

function CosmosTableBackground:init(options)
    self:build(options)
end

function CosmosTableBackground:build(options)
    options = options or {}
    self.seed = options.seed or timeSeed()
    local rng = love.math.newRandomGenerator(self.seed)
    self._meteorRng = love.math.newRandomGenerator(self.seed + 7919)
    
    self.time = 0
    self.stars = {}
    self.meteors = {}
    self.bgStarCount = options.bgStarCount or rng:random(52, 72)
    self.meteorRate = options.meteorRate or (0.0018 + rng:random() * 0.0012)
    
    for _ = 1, self.bgStarCount do
        local v = 1
        local s_rng = rng:random()
        
        -- 【调整星星形态分布概率，让画面更多样、更自然】
        if s_rng > 0.97 then
            v = 4 -- 罕见的衍射大星
        elseif s_rng > 0.88 then
            v = 3 -- 闪耀大星
        elseif s_rng > 0.65 then
            v = 2 -- 标准像素十字
        else
            v = 1 -- 微亮单点 (最常见，构成背景基底)
        end

        -- 星星严格限制在屏幕上半部分 (最顶端最密集，往下自然过渡消失)
        local startY = rng:random() * rng:random() * 0.45

        local starColor = {1, 1, 1}
        -- 少数星星带颜色点缀
        if rng:random() < 0.10 then 
            local colors = {
                {1.0, 0.85, 0.85}, -- 浅红
                {0.85, 0.92, 1.0}, -- 浅蓝
                {1.0, 0.95, 0.70}  -- 浅金
            }
            starColor = colors[rng:random(1, #colors)]
        end

        table.insert(self.stars, {
            rx = rng:random(), 
            ry = startY, 
            s = rng:random(1, 2),
            variant = v,
            -- 透明度调低一些，让夜空感觉更加幽静遥远
            alpha = rng:random() * 0.5 + 0.1,
            glint = rng:random() > 0.7,
            twinkleSpeed = rng:random() * 1.8 + 0.4,
            color = starColor
        })
    end
end

function CosmosTableBackground:regenerate(options)
    self:build(options)
end

function CosmosTableBackground:resize(screenW, screenH)
end

function CosmosTableBackground:update(dt)
    self.time = self.time + dt
    
    -- 极低概率生成流星
    local rng = self._meteorRng or love.math.newRandomGenerator((self.seed or timeSeed()) + 7919)
    if rng:random() < (self.meteorRate or 0.0025) then 
        local isFast = rng:random() < 0.15 
        
        -- 快流星和慢流星的速度区分
        local rvy = isFast and (rng:random() * 0.8 + 0.9) or (rng:random() * 0.2 + 0.15)
        local rvx = rng:random() * 0.5 - 0.25 
        
        local mHeadColor = {1, 1, 1}
        local mTailColor = {0.8, 0.95, 1}
        if rng:random() < 0.12 then 
            local palettes = {
                { {1.0, 0.95, 0.8}, {1.0, 0.6, 0.2} }, -- 金橙色
                { {0.95, 1.0, 0.95}, {0.3, 0.9, 0.7} }, -- 翠绿
                { {0.95, 0.9, 1.0}, {0.7, 0.4, 1.0} }  -- 幽紫
            }
            local p = palettes[rng:random(1, #palettes)]
            mHeadColor, mTailColor = p[1], p[2]
        end

        table.insert(self.meteors, {
            rx = rng:random() * 1.2 - 0.1, 
            ry = -0.08,                     
            vx = rvx,                       
            vy = rvy,                       
            s = rng:random(1, 2),
            -- 拖尾余辉停留在空中消散所需的时间（秒）
            trailFadeTime = isFast and 0.9 or 1.8, 
            history = {}, -- 记录划过的轨迹粒子
            dead = false, -- 标记流星头是否已经飞出屏幕
            headColor = mHeadColor,
            tailColor = mTailColor
        })
    end
    
    -- 更新所有流星的飞行和拖尾状态
    for i = #self.meteors, 1, -1 do
        local m = self.meteors[i]
        
        -- 1. 更新流星本体飞行逻辑
        if not m.dead then
            local old_rx = m.rx
            local old_ry = m.ry
            
            m.rx = m.rx + m.vx * dt
            m.ry = m.ry + m.vy * dt
            
            -- 在旧位置和新位置之间，每隔微小距离就“洒”下残留的离子轨迹
            local dist = math.sqrt((m.rx - old_rx)^2 + (m.ry - old_ry)^2)
            -- 减小间距以保证高速流星轨迹依然连贯无缝隙
            local steps = math.ceil(dist / 0.0015) 
            
            for s_step = 1, steps do
                local t = s_step / steps
                table.insert(m.history, {
                    rx = old_rx + (m.rx - old_rx) * t,
                    ry = old_ry + (m.ry - old_ry) * t,
                    life = m.trailFadeTime,
                    maxLife = m.trailFadeTime
                })
            end
            
            -- 飞出屏幕，本体死亡，但历史轨迹还要留在空中慢慢消散
            if m.ry > 1.2 or m.rx < -0.3 or m.rx > 1.3 then
                m.dead = true
            end
        end
        
        -- 2. 更新留在空间里的拖尾粒子的生命周期
        for j = #m.history, 1, -1 do
            local pt = m.history[j]
            pt.life = pt.life - dt
            -- 生命周期结束，从空中彻底消散
            if pt.life <= 0 then
                table.remove(m.history, j)
            end
        end
        
        -- 3. 如果流星本体飞出去了，且留在空中的余辉也都消散干净了，才彻底删除这颗流星数据
        if m.dead and #m.history == 0 then
            table.remove(self.meteors, i)
        end
    end
end

function CosmosTableBackground:draw(width, height)
    -- 画底色 (更幽暗深邃的夜空黑)
    love.graphics.clear(0.012, 0.015, 0.03, 1)
    
    -- 遍历渲染星星
    for _, star in ipairs(self.stars) do
        local currentAlpha = star.alpha
        if star.glint then
            currentAlpha = star.alpha + math.sin(self.time * star.twinkleSpeed) * 0.3
            currentAlpha = math.max(0.1, math.min(1, currentAlpha))
        end
        
        drawPixelStar(star.rx * width, star.ry * height, star.s, star.variant, currentAlpha, star.glint, star.color)
    end
    
    -- 遍历渲染流星及残留余辉
    for _, m in ipairs(self.meteors) do
        drawPixelMeteor(m, width, height)
    end
end

return CosmosTableBackground
