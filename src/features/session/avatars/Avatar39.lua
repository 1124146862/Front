local AvatarSkeleton = require("AvatarSkeleton")
local Avatar39 = { id = "avatar_39" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["W"]  = { 0.98, 0.98, 0.98, 1 },  -- 雪人白
        ["WD"] = { 0.85, 0.90, 0.95, 1 },  -- 雪人阴影 (略偏冰蓝)
        ["O"]  = { 0.95, 0.50, 0.15, 1 },  -- 胡萝卜橙色
        ["R"]  = { 0.85, 0.25, 0.30, 1 },  -- 帽子/围巾红色
        ["G"]  = { 0.20, 0.60, 0.35, 1 },  -- 帽子/围巾绿色
        ["N"]  = { 0.15, 0.15, 0.15, 1 },  -- 煤炭眼睛
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 雪人圆圆的脑袋
    skel:fillRect(6, 7, 17, 16, "W")
    skel:fillRect(5, 9, 18, 14, "W")
    skel:fillRect(6, 15, 17, 16, "WD") -- 下巴阴影

    -- 胖胖的身体 (下半部分)
    skel:fillRect(4, 18, 19, 23, "W")
    skel:fillRect(3, 20, 20, 23, "W")

    -- 温暖的红绿条纹针织帽
    skel:fillRect(6, 4, 17, 7, "R")
    skel:fillRect(10, 4, 13, 7, "G") -- 绿色条纹
    skel:fillRect(11, 2, 12, 3, "W") -- 帽子顶端的白毛球

    -- 红绿条纹围巾
    skel:fillRect(5, 16, 18, 18, "R")
    skel:fillRect(9, 16, 12, 18, "G")
    skel:fillRect(15, 18, 17, 21, "R") -- 垂下的围巾角

    -- 煤炭眼睛
    skel:fillRect(8, 10, 9, 11, "N"); skel:put(8, 10, "W")
    skel:fillRect(14, 10, 15, 11, "N"); skel:put(14, 10, "W")

    -- 胡萝卜鼻子 (向右突出)
    skel:fillRect(11, 12, 14, 13, "O")
    skel:put(15, 12, "O")

    -- 煤炭微笑嘴巴
    skel:put(9, 14, "N"); skel:put(10, 15, "N"); skel:put(12, 15, "N"); skel:put(13, 14, "N")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar39.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar39