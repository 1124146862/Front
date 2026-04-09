local AvatarSkeleton = require("AvatarSkeleton")
local Avatar42 = { id = "avatar_42" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["Y"] = { 0.98, 0.85, 0.20, 1 },  -- 太阳金黄主体
        ["O"] = { 0.95, 0.55, 0.15, 1 },  -- 太阳光芒橙色
        ["N"] = { 0.25, 0.15, 0.10, 1 },  -- 暖褐色五官
        ["C"] = { 0.95, 0.45, 0.45, 0.7}, -- 太阳脸颊红晕
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 太阳发散的光芒 (八个方向的橙色射线)
    skel:fillRect(11, 0, 12, 3, "O") -- 上
    skel:fillRect(11, 20, 12, 23, "O")-- 下
    skel:fillRect(0, 11, 3, 12, "O") -- 左
    skel:fillRect(20, 11, 23, 12, "O")-- 右
    
    skel:fillRect(4, 4, 6, 6, "O"); skel:put(3, 3, "O") -- 左上
    skel:fillRect(17, 4, 19, 6, "O"); skel:put(20, 3, "O") -- 右上
    skel:fillRect(4, 17, 6, 19, "O"); skel:put(3, 20, "O") -- 左下
    skel:fillRect(17, 17, 19, 19, "O"); skel:put(20, 20, "O") -- 右下

    -- 太阳圆润的主体
    skel:fillRect(7, 5, 16, 18, "Y")
    skel:fillRect(6, 6, 17, 17, "Y")
    skel:fillRect(5, 8, 18, 15, "Y")

    -- 治愈系笑脸
    skel:fillRect(9, 10, 10, 11, "N"); skel:put(9, 10, "W") -- 左眼
    skel:fillRect(13, 10, 14, 11, "N"); skel:put(13, 10, "W") -- 右眼
    
    skel:fillRect(7, 12, 8, 12, "C") -- 左腮红
    skel:fillRect(15, 12, 16, 12, "C") -- 右腮红

    skel:put(10, 14, "N"); skel:fillRect(11, 15, 12, 15, "N"); skel:put(13, 14, "N") -- 微笑大嘴

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar42.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar42