-- 文件名: TableBackgroundMaQue.lua
local MaQue = {}

local function C(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

local palette = {
    body   = C(145, 105, 70),  -- 麻雀的深棕色羽毛
    wing   = C(110, 75,  50),  -- 翅膀稍暗
    belly  = C(225, 210, 190), -- 浅色的肚子
    dark   = C(50,  40,  35),  -- 眼睛和脚
    beak   = C(230, 180, 50),  -- 黄色的小嘴
    shadow = C(189, 202, 216), -- 雪地阴影色，融入冬天背景
}

local function setColor(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

-- 无缝抗锯齿像素绘制
local function dpx(ox, oy, spriteW, dir, rx, ry, w, h, c, s, a)
    local tx = (dir == 1) and rx or (spriteW - rx - (w or 1))
    local sx = math.floor(ox + tx * s + 0.5)
    local sy = math.floor(oy + ry * s + 0.5)
    local ex = math.floor(ox + (tx + (w or 1)) * s + 0.5)
    local ey = math.floor(oy + (ry + (h or 1)) * s + 0.5)

    local sw = math.max(1, ex - sx)
    local sh = math.max(1, ey - sy)

    setColor(c, a)
    love.graphics.rectangle("fill", sx, sy, sw, sh)
end

local function randf(rng, a, b)
    return a + (b - a) * rng:random()
end

-- 绘制小麻雀
function MaQue.draw(x, y, s, facing, state, time)
    local dir = (facing == "left") and -1 or 1
    local W = 10 -- 画布宽度

    -- 雪地阴影 (只有在地面才画)
    if state ~= "fly" then
        dpx(x, y, W, dir, 2, 8, 6, 1, palette.shadow, s, 0.4)
    end

    local hDy = 0 
    local bDy = 0 

    if state == "fly" then
        bDy = (math.sin(time * 15) > 0) and -1 or 0
        hDy = bDy
        
        dpx(x, y, W, dir, 1, 4 + bDy, 2, 1, palette.body, s)
        dpx(x, y, W, dir, 3, 3 + bDy, 4, 3, palette.body, s)
        dpx(x, y, W, dir, 3, 6 + bDy, 3, 1, palette.belly, s)
        
        if math.sin(time * 25) > 0 then
            dpx(x, y, W, dir, 4, 1 + bDy, 3, 2, palette.wing, s)
        else
            dpx(x, y, W, dir, 4, 5 + bDy, 3, 2, palette.wing, s)
        end
        
    else
        if state == "peck" then
            hDy = 2 + ((math.sin(time * 10) > 0) and 1 or 0)
        end
        
        dpx(x, y, W, dir, 1, 3, 2, 1, palette.body, s)
        dpx(x, y, W, dir, 2, 4, 1, 1, palette.body, s)
        dpx(x, y, W, dir, 3, 4, 4, 3, palette.body, s)
        dpx(x, y, W, dir, 3, 5, 1, 2, palette.wing, s) 
        dpx(x, y, W, dir, 4, 7, 3, 1, palette.belly, s)
        dpx(x, y, W, dir, 4, 8, 1, 1, palette.dark, s)
        dpx(x, y, W, dir, 6, 8, 1, 1, palette.dark, s)
    end

    -- 头部
    dpx(x, y, W, dir, 6, 3 + hDy, 3, 3, palette.body, s)
    dpx(x, y, W, dir, 7, 5 + hDy, 2, 1, palette.belly, s) 
    dpx(x, y, W, dir, 7, 4 + hDy, 1, 1, palette.dark, s)  
    dpx(x, y, W, dir, 9, 4 + hDy, 1, 1, palette.beak, s)  
end

function MaQue.newActor(rng, s)
    local actor = {
        rng = rng,
        x = -100, y = -100, 
        s = s or 2,
        time = 0,
        facing = "right",
        
        state = "hide", 
        timer = randf(rng, 5.0, 15.0), 
        
        targetX = 0, targetY = 0,
        speed = 120,
        
        actionTimer = 0,
    }

    function actor:update(dt, screenW, screenH)
        self.time = self.time + dt
        
        if self.state == "hide" then
            self.timer = self.timer - dt
            if self.timer <= 0 then
                -- 【修改点】：锁定降落目标在屏幕的上半区 (10% ~ 50% 高度处)
                self.targetX = self.rng:random(50, screenW - 50)
                self.targetY = self.rng:random(math.floor(screenH * 0.1), math.floor(screenH * 0.5))
                
                if self.rng:random() < 0.5 then
                    self.x = -50
                    self.facing = "right"
                else
                    self.x = screenW + 50
                    self.facing = "left"
                end
                self.y = self.targetY - self.rng:random(50, 150) 
                
                self.state = "fly_in"
            end
            return
        end
        
        if self.state == "fly_in" or self.state == "fly_out" then
            local dx = self.targetX - self.x
            local dy = self.targetY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            self.facing = (dx > 0) and "right" or "left"
            
            if dist < self.speed * dt then
                self.x = self.targetX
                self.y = self.targetY
                
                if self.state == "fly_in" then
                    self.state = "idle"
                    self.timer = randf(self.rng, 10.0, 30.0)
                    self.actionTimer = randf(self.rng, 0.5, 2.0)
                else
                    self.state = "hide"
                    self.timer = randf(self.rng, 5.0, 20.0)
                end
            else
                self.x = self.x + (dx / dist) * self.speed * dt
                self.y = self.y + (dy / dist) * self.speed * dt
            end
            return
        end
        
        if self.state == "idle" or self.state == "peck" then
            self.timer = self.timer - dt
            self.actionTimer = self.actionTimer - dt
            
            if self.timer <= 0 then
                self.state = "fly_out"
                self.targetX = (self.rng:random() < 0.5) and -100 or (screenW + 100)
                self.targetY = -50 
                return
            end
            
            if self.actionTimer <= 0 then
                if self.state == "idle" then
                    if self.rng:random() < 0.7 then
                        self.state = "peck"
                        self.actionTimer = randf(self.rng, 1.0, 3.0) 
                    else
                        self.facing = (self.facing == "left") and "right" or "left"
                        self.actionTimer = randf(self.rng, 0.5, 1.5)
                    end
                else
                    self.state = "idle"
                    self.actionTimer = randf(self.rng, 1.0, 2.5)
                end
            end
        end
    end

    function actor:draw()
        if self.state ~= "hide" then
            local drawState = (self.state == "fly_in" or self.state == "fly_out") and "fly" or self.state
            MaQue.draw(self.x, self.y, self.s, self.facing, drawState, self.time)
        end
    end

    return actor
end

return MaQue