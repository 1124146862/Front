local AvatarSkeleton = require("AvatarSkeleton")
local Avatar38 = { id = "avatar_38" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["B"]  = { 0.35, 0.60, 0.85, 1 },  -- 马克杯蓝色
        ["BD"] = { 0.25, 0.45, 0.65, 1 },  -- 杯子阴影
        ["C"]  = { 0.30, 0.15, 0.10, 1 },  -- 咖啡深褐色
        ["S"]  = { 0.85, 0.90, 0.95, 0.8}, -- 热气 (半透明)
        ["N"]  = { 0.15, 0.20, 0.30, 1 },  -- 杯子上的深蓝色表情
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 杯口边缘 (椭圆)
    skel:fillRect(6, 7, 17, 10, "B")
    skel:fillRect(7, 8, 16, 9, "C") -- 装满的咖啡

    -- 马克杯的圆柱体杯身
    skel:fillRect(6, 10, 17, 21, "B")
    skel:fillRect(7, 21, 16, 21, "BD") -- 杯底阴影
    skel:fillRect(16, 10, 17, 20, "BD")-- 右侧立体阴影

    -- 马克杯的右侧把手 (Handle)
    skel:fillRect(18, 11, 20, 12, "B")
    skel:fillRect(19, 13, 20, 16, "B")
    skel:fillRect(18, 17, 20, 18, "B")

    -- 升腾的白色热气 (S型弯曲)
    skel:fillRect(10, 3, 11, 6, "S")
    skel:put(12, 2, "S"); skel:put(9, 4, "S")
    skel:fillRect(14, 1, 15, 5, "S")
    skel:put(13, 2, "S"); skel:put(16, 4, "S")

    -- 杯身上的安详笑脸
    skel:put(9, 14, "N"); skel:put(13, 14, "N") -- 眼睛
    skel:fillRect(10, 16, 12, 16, "N") -- 嘴巴

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar38.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar38