local AvatarSkeleton = require("AvatarSkeleton")
local Avatar36 = { id = "avatar_36" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["W"]  = { 0.98, 0.98, 0.98, 1 },  -- 蛋白
        ["WD"] = { 0.85, 0.85, 0.85, 1 },  -- 蛋白阴影/煎焦边
        ["Y"]  = { 0.98, 0.75, 0.15, 1 },  -- 蛋黄
        ["HL"] = { 0.98, 0.90, 0.50, 1 },  -- 蛋黄高光
        ["C"]  = { 0.95, 0.50, 0.40, 0.8}, -- 蛋黄红晕
        ["N"]  = { 0.20, 0.10, 0.10, 1 },  -- 眼睛
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 不规则的蛋白摊开形状
    skel:fillRect(6, 6, 18, 18, "W")
    skel:fillRect(4, 8, 20, 16, "W")
    skel:fillRect(7, 4, 15, 20, "W")
    skel:fillRect(2, 10, 22, 14, "W")
    
    -- 蛋白的阴影/立体感
    skel:fillRect(5, 17, 18, 18, "WD")
    skel:put(3, 14, "WD"); skel:put(21, 14, "WD")

    -- 圆润饱满的蛋黄
    skel:fillRect(9, 9, 15, 15, "Y")
    skel:fillRect(10, 8, 14, 16, "Y")

    -- 蛋黄左上角的弧形高光
    skel:fillRect(10, 10, 12, 10, "HL"); skel:put(10, 11, "HL")

    -- 蛋黄里的迷你笑脸
    skel:put(11, 12, "N"); skel:put(13, 12, "N") -- 眼睛
    skel:put(10, 13, "C"); skel:put(14, 13, "C") -- 腮红
    skel:put(12, 14, "N") -- 小张着的嘴巴

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar36.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar36