local AvatarSkeleton = require("AvatarSkeleton")
local Avatar14 = { id = "avatar_14" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"] = { 0.25, 0.10, 0.10, 1 },  -- 深色轮廓
        ["R"] = { 0.88, 0.25, 0.30, 1 },  -- 鲜艳蘑菇红
        ["W"] = { 0.98, 0.95, 0.90, 1 },  -- 蘑菇白点与伞柄
        ["N"] = { 0.15, 0.15, 0.15, 1 },  -- 眼睛
        ["C"] = { 0.95, 0.60, 0.60, 0.6}, -- 脸颊粉晕
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 蘑菇伞盖 (红色部分)
    skel:fillRect(7, 3, 16, 3, "#"); skel:fillRect(4, 4, 19, 4, "#")
    skel:fillRect(2, 5, 21, 11, "#")
    skel:fillRect(7, 4, 16, 4, "R"); skel:fillRect(5, 5, 18, 5, "R")
    skel:fillRect(3, 6, 20, 10, "R")

    -- 伞盖上的白斑点
    skel:fillRect(6, 6, 8, 8, "W")
    skel:fillRect(15, 5, 17, 7, "W")
    skel:fillRect(11, 8, 14, 9, "W")

    -- 蘑菇柄 (白色身体)
    skel:fillRect(7, 11, 16, 21, "#")
    skel:fillRect(8, 11, 15, 20, "W")
    
    -- 蘑菇柄上的笑脸
    skel:fillRect(10, 14, 10, 15, "N") -- 左眼
    skel:fillRect(13, 14, 13, 15, "N") -- 右眼
    skel:fillRect(9, 16, 9, 16, "C")   -- 左腮红
    skel:fillRect(14, 16, 14, 16, "C") -- 右腮红
    skel:put(11, 16, "N"); skel:put(12, 16, "N") -- 小嘴

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar14.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar14