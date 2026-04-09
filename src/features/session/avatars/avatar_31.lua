local AvatarSkeleton = require("AvatarSkeleton")
local Avatar31 = { id = "avatar_31" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["H"]  = { 0.95, 0.95, 0.98, 1 },   -- 须发白色
        ["HD"] = { 0.80, 0.85, 0.90, 1 },   -- 须发阴影
        ["B"]  = { 0.10, 0.10, 0.10, 1 },   -- 眼神深色
        ["R"]  = { 0.20, 0.15, 0.45, 1 },   -- 法师袍深蓝色
        ["Y"]  = { 0.95, 0.80, 0.20, 1 },   -- 法师帽星星黄色
        ["S"]  = { 0.92, 0.72, 0.68, 1 },   -- 老人皮肤颜色
    })

    -- 擦除耳朵，留给头发和帽子
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")

    -- 宽大的深蓝色法师帽
    skel:fillRect(4, 2, 19, 7, "R")
    skel:fillRect(3, 3, 20, 6, "R")
    skel:fillRect(10, 0, 13, 1, "R"); skel:put(11, 1, "R") -- 帽子塔尖

    -- 帽子上的星星装饰
    skel:fillRect(11, 3, 12, 4, "Y"); skel:put(10, 4, "Y"); skel:put(13, 4, "Y")

    -- 遮住脸颊的白色长须发 (瀑布状垂下)
    skel:fillRect(4, 7, 19, 19, "H")  
    skel:fillRect(5, 10, 18, 18, "H")  
    skel:fillRect(6, 13, 17, 17, "H")  

    -- 须发的阴影细节
    skel:fillRect(4, 10, 5, 18, "HD") 
    skel:fillRect(18, 10, 19, 18, "HD") 
    skel:fillRect(11, 14, 12, 18, "HD") -- 鼻子下垂的胡子核心

    -- 睿智的眼神 (眯成线，藏在胡须里)
    skel:fillRect(7, 11, 9, 11, "B")  -- 左眼
    skel:fillRect(14, 11, 16, 11, "B") -- 右眼
    skel:fillRect(10, 12, 13, 12, "S") -- 老人的大鼻子露出一点

    -- 法师袍 (深蓝色领口)
    skel:fillRect(7, 21, 16, 23, "R")
    skel:fillRect(10, 20, 13, 21, "HD") -- 胡子下垂遮住脖子

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar31.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar31