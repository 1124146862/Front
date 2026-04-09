local AvatarSkeleton = require("AvatarSkeleton")
local Avatar21 = { id = "avatar_21" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"] = { 0.15, 0.15, 0.15, 1 },  -- 纯黑轮廓
        ["W"] = { 0.98, 0.98, 0.98, 1 },  -- 熊猫白
        ["B"] = { 0.20, 0.20, 0.22, 1 },  -- 熊猫黑
        ["G"] = { 0.45, 0.75, 0.35, 1 },  -- 翠绿竹子
        ["C"] = { 0.95, 0.60, 0.65, 0.6}, -- 微弱腮红
    })

    -- 擦除原本人类耳朵，铺满白脸
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")
    skel:fillRect(4, 4, 19, 18, "W") 

    -- 黑色圆耳朵
    skel:fillRect(3, 2, 7, 6, "B"); skel:fillRect(2, 3, 8, 5, "B")
    skel:fillRect(16, 2, 20, 6, "B"); skel:fillRect(15, 3, 21, 5, "B")

    -- 标志性的八字黑眼圈 (向外下垂)
    skel:fillRect(5, 10, 9, 14, "B")
    skel:fillRect(4, 11, 8, 15, "B")
    skel:fillRect(14, 10, 18, 14, "B")
    skel:fillRect(15, 11, 19, 15, "B")

    -- 眼睛里的高光点 (显得无辜)
    skel:put(7, 11, "W"); skel:put(16, 11, "W")

    -- 小黑鼻子和倒Y嘴巴
    skel:fillRect(11, 14, 12, 14, "B")
    skel:put(10, 16, "B"); skel:put(11, 15, "B"); skel:put(12, 15, "B"); skel:put(13, 16, "B")

    -- 腮红
    skel:fillRect(4, 15, 5, 15, "C"); skel:fillRect(18, 15, 19, 15, "C")

    -- 嘴里咬着的一根翠绿竹子
    skel:fillRect(13, 16, 20, 17, "G")
    skel:fillRect(16, 15, 16, 18, "G") -- 竹节凸起

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar21.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar21