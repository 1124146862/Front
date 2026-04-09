local AvatarSkeleton = require("AvatarSkeleton")
local Avatar34 = { id = "avatar_34" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["G"]  = { 0.45, 0.75, 0.45, 1 },  -- 仙人掌绿
        ["GD"] = { 0.25, 0.50, 0.30, 1 },  -- 仙人掌刺和暗部
        ["P"]  = { 0.80, 0.50, 0.35, 1 },  -- 陶土花盆色
        ["PD"] = { 0.60, 0.35, 0.20, 1 },  -- 花盆暗部
        ["R"]  = { 0.95, 0.35, 0.45, 1 },  -- 小红花
        ["N"]  = { 0.15, 0.15, 0.15, 1 },  -- 眼睛
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 陶土花盆
    skel:fillRect(5, 16, 18, 18, "P")  -- 盆沿
    skel:fillRect(6, 19, 17, 23, "P")  -- 盆身
    skel:fillRect(5, 18, 18, 18, "PD") -- 盆沿阴影

    -- 仙人掌主干与分支
    skel:fillRect(8, 7, 15, 15, "G")   -- 主干
    skel:fillRect(4, 9, 7, 12, "G")    -- 左侧小分支
    skel:fillRect(16, 8, 18, 11, "G")  -- 右侧小分支

    -- 仙人掌的刺 (点缀深绿色)
    skel:put(10, 8, "GD"); skel:put(13, 9, "GD"); skel:put(9, 14, "GD"); skel:put(14, 13, "GD")
    skel:put(5, 10, "GD"); skel:put(17, 9, "GD")

    -- 治愈系笑脸
    skel:put(10, 11, "N"); skel:put(13, 11, "N") -- 豆豆眼
    skel:fillRect(11, 12, 12, 12, "N")           -- 嘴巴

    -- 头顶的小红花
    skel:fillRect(12, 4, 14, 6, "R")
    skel:put(13, 5, "W") -- 花心

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar34.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar34