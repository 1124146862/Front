-- 文件名: AvatarSkeleton.lua
local AvatarSkeleton = {}

function AvatarSkeleton.new()
    local obj = {}
    obj.size = 24

    -- 基础调色板
    obj.palette = {
        ["."] = { 0, 0, 0, 0 },          -- 透明背景
        ["#"] = { 0.15, 0.12, 0.12, 1 }, -- 轮廓线 (深灰色)
        ["S"] = { 0.98, 0.85, 0.74, 1 }, -- 皮肤
        ["E"] = { 0.10, 0.10, 0.12, 1 }, -- 眼睛
        ["W"] = { 1.00, 1.00, 1.00, 1 }, -- 高光/眼白
        ["N"] = { 0.85, 0.65, 0.55, 1 }, -- 鼻子
        ["M"] = { 0.80, 0.40, 0.40, 1 }, -- 嘴巴
        ["C"] = { 0.95, 0.60, 0.65, 0.5},-- 腮红
    }

    -- 初始化网格
    obj.grid = {}
    for y = 1, obj.size do
        obj.grid[y] = {}
        for x = 1, obj.size do
            obj.grid[y][x] = "."
        end
    end

    -- 工具方法：画单点
    function obj:put(x, y, token)
        if y < 0 or y >= self.size or x < 0 or x >= self.size then return end
        self.grid[y + 1][x + 1] = token
    end

    -- 工具方法：画矩形块
    function obj:fillRect(x1, y1, x2, y2, token)
        for y = y1, y2 do
            for x = x1, x2 do
                self:put(x, y, token)
            end
        end
    end

    -- 工具方法：添加专属饰品颜色
    function obj:addColors(newColors)
        for k, v in pairs(newColors) do
            self.palette[k] = v
        end
    end

    -- 初始化绘制基础脸部
    function obj:drawBaseFace()
        -- 1. 基础轮廓
        self:fillRect(8, 3, 15, 3, "#")
        self:fillRect(6, 4, 17, 4, "#")
        self:fillRect(5, 5, 18, 5, "#")
        self:fillRect(4, 6, 19, 16, "#")
        self:fillRect(5, 17, 18, 17, "#")
        self:fillRect(6, 18, 17, 18, "#")
        self:fillRect(8, 19, 15, 19, "#")
        -- 耳朵外轮廓
        self:fillRect(2, 10, 3, 13, "#")
        self:fillRect(20, 10, 21, 13, "#")

        -- 2. 皮肤
        self:fillRect(8, 4, 15, 4, "S")
        self:fillRect(6, 5, 17, 5, "S")
        self:fillRect(5, 6, 18, 16, "S")
        self:fillRect(6, 17, 17, 17, "S")
        self:fillRect(8, 18, 15, 18, "S")
        -- 耳朵内耳
        self:fillRect(3, 11, 4, 12, "S")
        self:fillRect(19, 11, 20, 12, "S")

        -- 3. 五官
        self:fillRect(7, 11, 8, 12, "E")  -- 左眼
        self:fillRect(15, 11, 16, 12, "E") -- 右眼
        self:put(8, 11, "W")               -- 左高光
        self:put(16, 11, "W")              -- 右高光
        self:fillRect(5, 13, 6, 13, "C")   -- 左腮红
        self:fillRect(17, 13, 18, 13, "C") -- 右腮红
        self:fillRect(11, 14, 12, 14, "N") -- 鼻子
        self:fillRect(10, 16, 13, 16, "M") -- 嘴巴
    end

    -- 编译成 love 图像
    function obj:buildImage()
        local image_data = love.image.newImageData(self.size, self.size)
        for y = 1, self.size do
            for x = 1, self.size do
                local color = self.palette[self.grid[y][x]]
                if color then
                    image_data:setPixel(x - 1, y - 1, color[1], color[2], color[3], color[4])
                end
            end
        end
        local img = love.graphics.newImage(image_data)
        img:setFilter("nearest", "nearest")
        return img
    end

    -- 初始化时自动画好基础脸
    obj:drawBaseFace()
    return obj
end

-- 通用的居中渲染逻辑 (所有 Avatar 都可以直接调用)
function AvatarSkeleton.drawCentered(image, bounds)
    local source_size = 24
    local raw_scale = math.min(bounds.w / source_size, bounds.h / source_size)
    local draw_scale = math.max(1, math.floor(raw_scale))
    local draw_w = source_size * draw_scale
    local draw_h = source_size * draw_scale
    local draw_x = bounds.x + math.floor((bounds.w - draw_w) / 2)
    local draw_y = bounds.y + math.floor((bounds.h - draw_h) / 2)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, draw_x, draw_y, 0, draw_scale, draw_scale)
end

return AvatarSkeleton