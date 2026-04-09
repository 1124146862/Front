local AvatarSkeleton = require("AvatarSkeleton")
local Avatar44 = { id = "avatar_44" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.20, 0.25, 0.35, 1 },  -- 玻璃瓶深色边缘
        ["G"]  = { 0.85, 0.90, 0.95, 0.6}, -- 玻璃瓶反光 (半透明白蓝)
        ["P"]  = { 0.90, 0.25, 0.40, 1 },  -- 红色药水
        ["PL"] = { 0.98, 0.55, 0.65, 1 },  -- 药水高光 (亮粉)
        ["C"]  = { 0.70, 0.50, 0.35, 1 },  -- 软木塞
        ["W"]  = { 0.98, 0.98, 0.98, 1 },  -- 纯白高光星星
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 软木塞
    skel:fillRect(10, 1, 13, 3, "C")
    skel:fillRect(9, 0, 14, 0, "#")

    -- 玻璃瓶口和细长的瓶颈
    skel:fillRect(9, 4, 14, 5, "#"); skel:fillRect(10, 4, 13, 4, "G")
    skel:fillRect(10, 6, 13, 9, "G")
    skel:fillRect(9, 6, 9, 9, "#"); skel:fillRect(14, 6, 14, 9, "#")

    -- 浑圆的烧瓶底部轮廓
    skel:fillRect(5, 10, 18, 21, "#")
    skel:fillRect(4, 12, 19, 19, "#")
    skel:fillRect(7, 22, 16, 22, "#")

    -- 玻璃空出的部分
    skel:fillRect(6, 11, 17, 13, "G")

    -- 红色药水液体填充
    skel:fillRect(5, 14, 18, 20, "P")
    skel:fillRect(6, 13, 17, 13, "P")
    skel:fillRect(7, 21, 16, 21, "P")

    -- 药水内部的光影层次
    skel:fillRect(6, 14, 9, 19, "PL") -- 左侧的高光液体
    skel:put(11, 15, "PL"); skel:put(14, 17, "PL") -- 漂浮的气泡

    -- 玻璃瓶表面的大高光
    skel:fillRect(16, 11, 17, 19, "G")
    
    -- 旁边闪烁的魔法星星
    skel:put(4, 5, "W"); skel:put(3, 6, "W"); skel:put(5, 6, "W"); skel:put(4, 7, "W")
    skel:put(19, 9, "W")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar44.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar44