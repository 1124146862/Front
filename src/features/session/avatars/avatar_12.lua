local AvatarSkeleton = require("AvatarSkeleton")
local Avatar12 = { id = "avatar_12" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.15, 0.35, 0.20, 1 },   -- 深绿边缘
        ["G"]  = { 0.45, 0.80, 0.40, 1 },   -- 青蛙绿
        ["W"]  = { 0.95, 0.98, 0.95, 1 },   -- 白肚皮/眼白
        ["N"]  = { 0.10, 0.10, 0.10, 1 },   -- 黑瞳孔
        ["C"]  = { 0.90, 0.50, 0.55, 0.7},  -- 粉红脸颊
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 青蛙圆滚滚的脸与身体
    skel:fillRect(4, 9, 19, 22, "#")
    skel:fillRect(5, 10, 18, 22, "G")
    skel:fillRect(3, 12, 20, 20, "#")
    skel:fillRect(4, 13, 19, 20, "G")

    -- 突出的两只大眼睛 (Frog Eyes)
    skel:fillRect(4, 3, 10, 9, "#")
    skel:fillRect(5, 4, 9, 8, "G")
    skel:fillRect(13, 3, 19, 9, "#")
    skel:fillRect(14, 4, 18, 8, "G")

    -- 巨大的眼白和瞳孔
    skel:fillRect(6, 5, 8, 7, "W")
    skel:fillRect(15, 5, 17, 7, "W")
    skel:fillRect(7, 6, 8, 7, "N")  -- 瞳孔稍微斗鸡眼更可爱
    skel:fillRect(15, 6, 16, 7, "N")
    skel:put(7, 6, "W"); skel:put(15, 6, "W") -- 灵动高光

    -- 白白的大肚皮
    skel:fillRect(8, 16, 15, 23, "W")
    skel:fillRect(7, 18, 16, 22, "W")

    -- 开心的宽嘴巴
    skel:fillRect(9, 13, 14, 13, "N")
    skel:put(8, 12, "N"); skel:put(15, 12, "N")
    
    -- 腮红
    skel:fillRect(5, 13, 6, 13, "C")
    skel:fillRect(17, 13, 18, 13, "C")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar12.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar12