local AvatarSkeleton = require("AvatarSkeleton")
local Avatar22 = { id = "avatar_22" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.40, 0.10, 0.10, 1 },  -- 深红勾边
        ["R"]  = { 0.90, 0.20, 0.25, 1 },  -- 山楂红
        ["HL"] = { 0.98, 0.95, 0.95, 0.9}, -- 糖衣高光
        ["S"]  = { 0.80, 0.65, 0.45, 1 },  -- 竹签原木色
        ["N"]  = { 0.20, 0.10, 0.10, 1 },  -- 五官
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 完全擦除骨架

    -- 中心的竹签
    skel:fillRect(11, 1, 12, 23, "S")

    -- 画三颗山楂果 (上、中、下)
    local function drawBerry(yOffset)
        skel:fillRect(8, yOffset, 15, yOffset+5, "R")
        skel:fillRect(9, yOffset-1, 14, yOffset-1, "R")
        skel:fillRect(9, yOffset+6, 14, yOffset+6, "R")
        -- 糖衣高光 (左上角反光)
        skel:fillRect(9, yOffset+1, 10, yOffset+2, "HL")
    end

    drawBerry(2)  -- 顶部
    drawBerry(9)  -- 中部 (带脸)
    drawBerry(16) -- 底部

    -- 在中间的果子上画治愈系笑脸
    skel:fillRect(10, 11, 10, 12, "N") -- 左眼
    skel:fillRect(13, 11, 13, 12, "N") -- 右眼
    skel:put(11, 13, "N"); skel:put(12, 13, "N") -- 小嘴巴

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar22.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar22