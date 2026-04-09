local AvatarSkeleton = require("AvatarSkeleton")
local Avatar25 = { id = "avatar_25" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["R"]  = { 0.90, 0.20, 0.20, 1 },  -- 灯笼红
        ["HL"] = { 0.95, 0.50, 0.40, 1 },  -- 亮红/灯光透射
        ["Y"]  = { 0.95, 0.75, 0.20, 1 },  -- 金黄色穗子和上下盖
        ["N"]  = { 0.20, 0.10, 0.10, 1 },  -- 眼睛
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 上下金黄盖子
    skel:fillRect(9, 1, 14, 2, "Y")
    skel:fillRect(9, 16, 14, 17, "Y")
    skel:fillRect(11, 0, 12, 1, "N") -- 顶部的挂钩绳子

    -- 灯笼椭圆主体
    skel:fillRect(5, 3, 18, 15, "R")
    skel:fillRect(3, 5, 20, 13, "R")
    
    -- 灯笼内部透出的暖光 (鼓起来的高光)
    skel:fillRect(7, 5, 10, 13, "HL")
    skel:fillRect(5, 7, 12, 11, "HL")

    -- 灯笼的金色竖条纹路
    skel:fillRect(7, 4, 7, 14, "Y")
    skel:fillRect(11, 3, 11, 15, "Y")
    skel:fillRect(16, 4, 16, 14, "Y")

    -- 挂在底下的长流苏
    skel:fillRect(11, 18, 12, 23, "Y")
    skel:put(10, 20, "Y"); skel:put(13, 20, "Y")
    skel:put(10, 22, "Y"); skel:put(13, 22, "Y")

    -- 融入一点可爱的灵魂笑脸
    skel:fillRect(8, 9, 9, 10, "N"); skel:fillRect(14, 9, 15, 10, "N")
    skel:put(11, 11, "N"); skel:put(12, 11, "N")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar25.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar25