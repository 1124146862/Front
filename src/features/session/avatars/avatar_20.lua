local AvatarSkeleton = require("AvatarSkeleton")
local Avatar20 = { id = "avatar_20" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.20, 0.25, 0.35, 1 },   -- 深蓝灰轮廓
        ["W"]  = { 0.95, 0.95, 0.98, 0.9 }, -- 幽灵本体 (带一点微弱透明度)
        ["WD"] = { 0.80, 0.85, 0.95, 0.9 }, -- 幽灵暗部 (偏蓝)
        ["N"]  = { 0.15, 0.15, 0.20, 1 },   -- 眼睛
        ["M"]  = { 0.90, 0.40, 0.50, 1 },   -- 调皮的小红舌头
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 幽灵圆润的头和身体
    skel:fillRect(6, 3, 17, 20, "#")
    skel:fillRect(5, 5, 18, 18, "#")
    skel:fillRect(7, 4, 16, 20, "W")
    skel:fillRect(6, 6, 17, 18, "W")

    -- 底部波浪裙边 (经典幽灵特征)
    skel:fillRect(7, 21, 8, 22, "W")
    skel:fillRect(11, 21, 12, 22, "W")
    skel:fillRect(15, 21, 16, 22, "W")
    skel:put(9, 20, "."); skel:put(10, 20, "."); skel:put(13, 20, "."); skel:put(14, 20, ".")

    -- 增加一侧蓝灰色阴影，增强漂浮的立体感
    skel:fillRect(15, 6, 16, 18, "WD")

    -- 幽灵的五官
    skel:fillRect(8, 10, 9, 12, "N"); skel:put(8, 10, "W")
    skel:fillRect(14, 10, 15, 12, "N"); skel:put(14, 10, "W")
    
    -- 吐舌头
    skel:fillRect(11, 14, 12, 14, "N") -- 微笑嘴
    skel:fillRect(12, 15, 13, 16, "M") -- 侧边吐出的小舌头

    -- 漂浮的小手
    skel:fillRect(3, 13, 4, 14, "W")
    skel:fillRect(19, 11, 20, 12, "W") -- 右手举高高

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar20.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar20