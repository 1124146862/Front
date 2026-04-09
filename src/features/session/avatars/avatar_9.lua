local AvatarSkeleton = require("AvatarSkeleton")
local Avatar9 = { id = "avatar_9" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.15, 0.18, 0.25, 1 },   -- 深蓝黑边缘
        ["B"]  = { 0.25, 0.32, 0.45, 1 },   -- 企鹅背部的蓝灰色
        ["W"]  = { 0.98, 0.98, 0.98, 1 },   -- 企鹅白肚皮
        ["Y"]  = { 0.95, 0.75, 0.20, 1 },   -- 嫩黄色的喙
        ["S"]  = { 0.85, 0.30, 0.35, 1 },   -- 红色围巾
        ["N"]  = { 0.10, 0.10, 0.10, 1 },   -- 眼睛
        ["C"]  = { 0.95, 0.50, 0.60, 0.6},  -- 脸颊粉晕
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 企鹅圆滚滚的轮廓和深色皮毛
    skel:fillRect(7, 3, 16, 22, "#")
    skel:fillRect(5, 5, 18, 22, "#")
    skel:fillRect(4, 9, 19, 20, "#")
    skel:fillRect(6, 4, 17, 22, "B")
    skel:fillRect(5, 7, 18, 21, "B")

    -- 心形的白色脸部与肚皮
    skel:fillRect(7, 7, 10, 9, "W")  -- 左侧脸白
    skel:fillRect(13, 7, 16, 9, "W") -- 右侧脸白
    skel:fillRect(6, 10, 17, 22, "W")-- 脸蛋下半部连着大肚皮

    -- 眼睛与黄色的喙
    skel:fillRect(8, 10, 9, 11, "N"); skel:put(8, 10, "W")
    skel:fillRect(14, 10, 15, 11, "N"); skel:put(14, 10, "W")
    skel:fillRect(11, 11, 12, 12, "Y") 

    -- 小腮红
    skel:fillRect(6, 12, 7, 12, "C")
    skel:fillRect(16, 12, 17, 12, "C")

    -- 温暖的红围巾
    skel:fillRect(5, 15, 18, 16, "S")
    skel:fillRect(6, 17, 7, 20, "S") -- 垂下的围巾角
    skel:fillRect(4, 15, 4, 16, "#"); skel:fillRect(19, 15, 19, 16, "#") -- 围巾边缘

    -- 两侧拍打的小翅膀(Flipper)
    skel:fillRect(2, 11, 4, 16, "#")
    skel:fillRect(3, 12, 4, 15, "B")
    skel:fillRect(19, 11, 21, 16, "#")
    skel:fillRect(19, 12, 20, 15, "B")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar9.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar9