local AvatarSkeleton = require("AvatarSkeleton")
local Avatar8 = { id = "avatar_8" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.30, 0.10, 0.15, 1 },   -- 深暗红色勾边
        ["R"]  = { 0.90, 0.25, 0.25, 1 },   -- 苹果红
        ["HL"] = { 0.98, 0.55, 0.50, 1 },   -- 苹果高光 (偏粉)
        ["HD"] = { 0.75, 0.15, 0.15, 1 },   -- 苹果暗部
        ["S"]  = { 0.40, 0.20, 0.10, 1 },   -- 树枝深棕色
        ["L"]  = { 0.45, 0.75, 0.35, 1 },   -- 叶子绿色
        ["N"]  = { 0.20, 0.10, 0.10, 1 },   -- 五官
        ["C"]  = { 0.95, 0.45, 0.45, 0.8},  -- 脸颊红晕
    })

    -- 擦除所有默认骨架
    skel:fillRect(0, 0, 23, 23, ".")

    -- 苹果主体外轮廓
    skel:fillRect(6, 4, 17, 4, "#")
    skel:fillRect(4, 5, 19, 5, "#")
    skel:fillRect(3, 6, 20, 18, "#")
    skel:fillRect(4, 19, 19, 19, "#")
    skel:fillRect(6, 20, 17, 20, "#")

    -- 填充红色本体
    skel:fillRect(7, 5, 16, 5, "R")
    skel:fillRect(5, 6, 18, 18, "R")
    skel:fillRect(7, 19, 16, 19, "R")

    -- 苹果凹陷处、高光与阴影
    skel:put(11, 4, "."); skel:put(12, 4, ".") -- 顶部凹陷
    skel:put(11, 5, "#"); skel:put(12, 5, "#") 
    skel:fillRect(6, 7, 9, 9, "HL")            -- 左上角高光
    skel:fillRect(15, 16, 18, 18, "HD")        -- 右下角阴影

    -- 树枝与叶子
    skel:fillRect(11, 2, 12, 4, "S")
    skel:fillRect(13, 1, 16, 2, "L"); skel:put(13, 2, "."); skel:put(14, 1, "L"); skel:put(16, 1, "L")

    -- 治愈系拟人小脸
    skel:fillRect(8, 12, 9, 12, "N")   -- 左眼
    skel:fillRect(14, 12, 15, 12, "N") -- 右眼
    skel:fillRect(6, 13, 7, 13, "C")   -- 左腮红
    skel:fillRect(16, 13, 17, 13, "C") -- 右腮红
    skel:fillRect(11, 14, 12, 14, "N") -- 小嘴巴
    skel:put(10, 13, "N"); skel:put(13, 13, "N") -- 微笑嘴角

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar8.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar8