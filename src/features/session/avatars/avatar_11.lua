local AvatarSkeleton = require("AvatarSkeleton")
local Avatar11 = { id = "avatar_11" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["B"]  = { 0.55, 0.35, 0.25, 1 },   -- 棕熊毛色
        ["L"]  = { 0.85, 0.70, 0.55, 1 },   -- 浅色吻部/内耳
        ["N"]  = { 0.15, 0.10, 0.10, 1 },   -- 鼻子/眼睛
    })

    -- 擦除人类耳朵
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")
    
    -- 把脸全部刷成棕色
    skel:fillRect(5, 4, 18, 18, "B")
    skel:fillRect(4, 8, 4, 16, "#")
    skel:fillRect(19, 8, 19, 16, "#")

    -- 绘制头顶的熊耳朵 (圆润大耳)
    skel:fillRect(4, 2, 8, 5, "B")
    skel:fillRect(5, 3, 7, 4, "L") -- 左内耳浅色
    skel:fillRect(15, 2, 19, 5, "B")
    skel:fillRect(16, 3, 18, 4, "L") -- 右内耳浅色
    
    -- 耳朵勾边
    skel:fillRect(5, 1, 7, 1, "#"); skel:put(4, 2, "#"); skel:put(8, 2, "#")
    skel:fillRect(16, 1, 18, 1, "#"); skel:put(15, 2, "#"); skel:put(19, 2, "#")

    -- 宽大的浅色吻部 (Muzzle)
    skel:fillRect(8, 12, 15, 17, "L")
    skel:fillRect(9, 11, 14, 11, "L")

    -- 熊鼻子与睡着的眼睛
    skel:fillRect(10, 12, 13, 13, "N") -- 大黑鼻子
    skel:put(11, 12, "L") -- 鼻子高光
    skel:put(11, 14, "N"); skel:put(12, 14, "N") -- 人中
    skel:put(10, 15, "N"); skel:put(13, 15, "N") -- 呼呼大睡的嘴角
    
    -- 闭着的眼睛 (向下弯的弧线)
    skel:fillRect(6, 11, 8, 11, "N"); skel:put(7, 12, "N")
    skel:fillRect(15, 11, 17, 11, "N"); skel:put(16, 12, "N")

    -- 胖乎乎的身体
    skel:fillRect(5, 19, 18, 23, "B")
    skel:fillRect(4, 19, 4, 23, "#"); skel:fillRect(19, 19, 19, 23, "#")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar11.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar11