local AvatarSkeleton = require("AvatarSkeleton")
local Avatar40 = { id = "avatar_40" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["O"]  = { 0.90, 0.45, 0.20, 1 },  -- 狐狸橘红色
        ["OD"] = { 0.75, 0.35, 0.15, 1 },  -- 狐狸暗部
        ["W"]  = { 0.98, 0.98, 0.98, 1 },  -- 狐狸白下巴
        ["#"]  = { 0.15, 0.15, 0.18, 1 },  -- 深色耳尖/鼻子
    })

    -- 擦除原本人类耳朵
    skel:fillRect(2, 9, 4, 14, "."); skel:fillRect(19, 9, 21, 14, ".")
    
    -- 铺底色
    skel:fillRect(5, 7, 18, 17, "O")

    -- 狐狸尖尖的大耳朵
    skel:fillRect(3, 2, 7, 7, "O"); skel:put(3, 1, "#"); skel:put(4, 1, "#") -- 左耳
    skel:fillRect(4, 3, 5, 6, "W") -- 左内耳
    skel:fillRect(16, 2, 20, 7, "O"); skel:put(19, 1, "#"); skel:put(20, 1, "#") -- 右耳
    skel:fillRect(18, 3, 19, 6, "W") -- 右内耳

    -- 狐狸特有的倒三角白色下半脸
    skel:fillRect(5, 13, 18, 18, "W")
    skel:fillRect(6, 12, 17, 12, "W")
    skel:fillRect(8, 11, 15, 11, "W")

    -- 狐狸的狭长眼睛 (上挑)
    skel:fillRect(7, 10, 9, 10, "#"); skel:put(6, 9, "#")
    skel:fillRect(14, 10, 16, 10, "#"); skel:put(17, 9, "#")

    -- 小黑鼻头和微笑嘴
    skel:fillRect(11, 13, 12, 13, "#")
    skel:put(10, 15, "#"); skel:fillRect(11, 16, 12, 16, "#"); skel:put(13, 15, "#")

    -- 脖子处的白色绒毛
    skel:fillRect(6, 19, 17, 22, "W")
    skel:fillRect(8, 23, 15, 23, "W")
    skel:put(5, 20, "W"); skel:put(18, 20, "W")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar40.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar40