local AvatarSkeleton = require("AvatarSkeleton")
local Avatar19 = { id = "avatar_19" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"] = { 0.40, 0.30, 0.10, 1 },  -- 褐色边缘
        ["Y"] = { 0.98, 0.85, 0.20, 1 },  -- 鸭子亮黄
        ["O"] = { 0.95, 0.50, 0.15, 1 },  -- 鸭嘴亮橙
        ["N"] = { 0.10, 0.10, 0.10, 1 },  -- 眼睛
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 鸭子圆圆的头
    skel:fillRect(6, 4, 17, 20, "#")
    skel:fillRect(7, 5, 16, 19, "Y")
    skel:fillRect(5, 7, 18, 17, "Y")
    
    -- 头顶的呆毛 (小羽毛)
    skel:fillRect(11, 2, 12, 4, "Y")
    skel:put(10, 3, "Y"); skel:put(13, 3, "Y")

    -- 鸭子的小黑豆眼
    skel:fillRect(8, 10, 9, 11, "N"); skel:put(8, 10, "W")
    skel:fillRect(14, 10, 15, 11, "N"); skel:put(14, 10, "W")

    -- 宽阔的橙色鸭嘴
    skel:fillRect(8, 13, 15, 16, "O")
    skel:fillRect(7, 14, 16, 15, "O")
    skel:fillRect(9, 15, 14, 15, "#") -- 鸭嘴中间的缝隙

    -- 脸颊粉红
    skel:fillRect(5, 12, 6, 12, "C")
    skel:fillRect(17, 12, 18, 12, "C")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar19.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar19