local AvatarSkeleton = require("AvatarSkeleton")
local Avatar15 = { id = "avatar_15" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.45, 0.20, 0.25, 1 }, -- 深紫红色边缘
        ["P"]  = { 0.98, 0.75, 0.80, 1 }, -- 猪猪粉色
        ["PD"] = { 0.88, 0.55, 0.65, 1 }, -- 鼻子和耳朵的深粉色
        ["N"]  = { 0.15, 0.10, 0.10, 1 }, -- 眼睛和鼻孔
    })

    -- 擦除人类耳朵，换成下垂的猪耳朵
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")
    skel:fillRect(4, 9, 19, 18, "P") -- 铺满粉色底色
    skel:fillRect(5, 4, 18, 8, "P")
    
    -- 画猪耳朵 (软塌塌地向两侧下垂)
    skel:fillRect(1, 8, 5, 12, "P"); skel:fillRect(2, 9, 4, 11, "PD")
    skel:fillRect(18, 8, 22, 12, "P"); skel:fillRect(19, 9, 21, 11, "PD")

    -- 猪猪的灵魂：大圆鼻子 (Snout)
    skel:fillRect(9, 13, 14, 17, "PD")
    skel:fillRect(8, 14, 15, 16, "PD")
    skel:fillRect(10, 14, 11, 15, "N") -- 左鼻孔
    skel:fillRect(13, 14, 14, 15, "N") -- 右鼻孔
    skel:fillRect(10, 13, 12, 13, "P") -- 鼻子上的高光反光

    -- 眼睛 (画在鼻子上方两侧)
    skel:fillRect(6, 12, 7, 13, "N"); skel:put(6, 12, "W")
    skel:fillRect(16, 12, 17, 13, "N"); skel:put(16, 12, "W")

    -- 下巴和嘴巴
    skel:fillRect(11, 18, 12, 18, "N") -- 鼻子下方的微笑唇

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar15.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar15