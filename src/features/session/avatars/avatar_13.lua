local AvatarSkeleton = require("AvatarSkeleton")
local Avatar13 = { id = "avatar_13" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"] = { 0.25, 0.20, 0.25, 1 },  -- 深紫灰色边缘
        ["W"] = { 0.98, 0.98, 0.98, 1 },  -- 白猫本色
        ["P"] = { 0.95, 0.65, 0.70, 1 },  -- 粉色内耳和鼻子
        ["N"] = { 0.15, 0.15, 0.20, 1 },  -- 眼睛
        ["C"] = { 0.95, 0.50, 0.60, 0.5}, -- 脸颊红晕
    })

    -- 擦除原本的耳朵，铺满白脸
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")
    skel:fillRect(4, 9, 19, 18, "W") 
    skel:fillRect(5, 4, 18, 8, "W")

    -- 绘制尖尖的猫耳
    skel:fillRect(4, 2, 7, 5, "W"); skel:put(5, 1, "W"); skel:put(6, 1, "W")
    skel:fillRect(16, 2, 19, 5, "W"); skel:put(17, 1, "W"); skel:put(18, 1, "W")
    -- 内耳粉色
    skel:fillRect(5, 3, 6, 5, "P"); skel:fillRect(17, 3, 18, 5, "P")
    -- 耳朵边缘
    skel:put(5, 0, "#"); skel:put(6, 0, "#"); skel:put(4, 1, "#"); skel:put(7, 1, "#"); skel:put(3, 2, "#")
    skel:put(17, 0, "#"); skel:put(18, 0, "#"); skel:put(16, 1, "#"); skel:put(19, 1, "#"); skel:put(20, 2, "#")

    -- 脸部五官
    skel:fillRect(7, 12, 8, 13, "N"); skel:put(7, 12, "W")  -- 左眼
    skel:fillRect(15, 12, 16, 13, "N"); skel:put(15, 12, "W")-- 右眼
    skel:fillRect(11, 14, 12, 14, "P") -- 粉鼻子
    
    -- 猫咪的 "ω" 嘴巴
    skel:put(10, 15, "N"); skel:put(11, 16, "N"); skel:put(12, 16, "N"); skel:put(13, 15, "N")

    -- 腮红与猫须
    skel:fillRect(5, 14, 6, 14, "C")
    skel:fillRect(17, 14, 18, 14, "C")
    skel:fillRect(2, 13, 4, 13, "#"); skel:fillRect(1, 15, 3, 15, "#") -- 左胡须
    skel:fillRect(19, 13, 21, 13, "#"); skel:fillRect(20, 15, 22, 15, "#")-- 右胡须

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar13.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar13