local AvatarSkeleton = require("AvatarSkeleton")
local Avatar33 = { id = "avatar_33" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.15, 0.10, 0.20, 1 },  -- 深色轮廓
        ["W"]  = { 0.98, 0.98, 0.98, 1 },  -- 纯白的小丑油彩底妆
        ["R"]  = { 0.90, 0.15, 0.25, 1 },  -- 红鼻子/红嘴唇
        ["B"]  = { 0.20, 0.50, 0.85, 1 },  -- 蓝色眼影彩绘
        ["G"]  = { 0.30, 0.75, 0.40, 1 },  -- 绿色头发
        ["P"]  = { 0.70, 0.30, 0.80, 1 },  -- 紫色头发
        ["N"]  = { 0.10, 0.10, 0.10, 1 },  -- 眼睛
    })

    -- 擦除原有耳朵
    skel:fillRect(2, 9, 4, 14, "."); skel:fillRect(19, 9, 21, 14, ".")

    -- 蓬松的左右双色爆炸头
    skel:fillRect(2, 4, 6, 12, "G"); skel:fillRect(3, 3, 7, 13, "G") -- 左侧绿发
    skel:fillRect(17, 4, 21, 12, "P"); skel:fillRect(16, 3, 20, 13, "P") -- 右侧紫发

    -- 铺满白色油彩脸蛋
    skel:fillRect(5, 5, 18, 17, "W")
    skel:fillRect(6, 4, 17, 4, "W")
    skel:fillRect(6, 18, 17, 18, "W")

    -- 夸张的蓝色十字星眼影彩绘
    skel:fillRect(7, 8, 7, 12, "B"); skel:fillRect(6, 10, 8, 10, "B") -- 左眼影
    skel:fillRect(16, 8, 16, 12, "B"); skel:fillRect(15, 10, 17, 10, "B") -- 右眼影

    -- 黑眼睛
    skel:fillRect(7, 10, 7, 10, "N"); skel:fillRect(16, 10, 16, 10, "N")

    -- 标志性的大红鼻子 (突出的圆球)
    skel:fillRect(10, 12, 13, 15, "R")
    skel:fillRect(11, 12, 12, 12, "W") -- 鼻子上的高光

    -- 夸张的红色笑唇
    skel:fillRect(8, 17, 15, 17, "R")
    skel:put(7, 16, "R"); skel:put(16, 16, "R")
    skel:fillRect(10, 18, 13, 18, "W") -- 露出的白牙

    -- 脖子上的小丑拉夫领 (Ruff)
    skel:fillRect(4, 20, 19, 23, "W")
    skel:fillRect(6, 21, 17, 21, "#"); skel:fillRect(8, 22, 15, 22, "#")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar33.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar33