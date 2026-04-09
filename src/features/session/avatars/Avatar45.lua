local AvatarSkeleton = require("AvatarSkeleton")
local Avatar45 = { id = "avatar_45" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["O"] = { 0.90, 0.60, 0.25, 1 },  -- 柯基橘黄色
        ["W"] = { 0.98, 0.98, 0.95, 1 },  -- 柯基白毛
        ["P"] = { 0.95, 0.70, 0.75, 1 },  -- 粉色内耳
        ["R"] = { 0.88, 0.25, 0.30, 1 },  -- 红色领巾
        ["#"] = { 0.25, 0.18, 0.15, 1 },  -- 深色轮廓
        ["N"] = { 0.15, 0.15, 0.15, 1 },  -- 眼睛/鼻子
    })

    -- 擦除原本人类耳朵
    skel:fillRect(2, 9, 4, 14, "."); skel:fillRect(19, 9, 21, 14, ".")
    
    -- 铺底色
    skel:fillRect(5, 7, 18, 17, "O")

    -- 柯基标志性的大尖耳 (竖立)
    skel:fillRect(3, 1, 7, 7, "O"); skel:put(4, 0, "#"); skel:put(5, 0, "#") -- 左耳
    skel:fillRect(4, 2, 5, 6, "P") -- 左内耳
    skel:fillRect(16, 1, 20, 7, "O"); skel:put(18, 0, "#"); skel:put(19, 0, "#") -- 右耳
    skel:fillRect(18, 2, 19, 6, "P") -- 右内耳

    -- 脸部中央和下半部分的白色花纹 (白面罩)
    skel:fillRect(10, 6, 13, 11, "W") -- 额头到鼻梁的白条
    skel:fillRect(9, 12, 14, 18, "W") -- 扩大的白脸颊
    skel:fillRect(6, 14, 17, 18, "W") 
    skel:fillRect(5, 15, 18, 17, "W")

    -- 狗狗的明亮大眼
    skel:fillRect(7, 10, 8, 11, "N"); skel:put(7, 10, "W")
    skel:fillRect(15, 10, 16, 11, "N"); skel:put(15, 10, "W")

    -- 黑鼻头和快乐张开的嘴巴
    skel:fillRect(11, 13, 12, 14, "N")
    skel:put(10, 16, "N"); skel:put(13, 16, "N")
    skel:fillRect(11, 17, 12, 17, "R") -- 吐出的红舌头

    -- 脖子上的帅气红领巾
    skel:fillRect(5, 19, 18, 21, "R")
    skel:fillRect(14, 21, 16, 23, "R") -- 垂下的领巾结
    skel:fillRect(4, 19, 4, 20, "#"); skel:fillRect(19, 19, 19, 20, "#")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar45.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar45