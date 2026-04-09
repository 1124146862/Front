local AvatarSkeleton = require("AvatarSkeleton")
local Avatar10 = { id = "avatar_10" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["H"]  = { 0.88, 0.90, 0.95, 1 },   -- 银白发色
        ["HD"] = { 0.65, 0.70, 0.80, 1 },   -- 银发阴影
        ["G"]  = { 0.95, 0.65, 0.20, 1 },   -- 护目镜橙色镜片
        ["GF"] = { 0.25, 0.20, 0.20, 1 },   -- 护目镜黑框
        ["C"]  = { 0.35, 0.40, 0.35, 1 },   -- 军绿色夹克
    })

    -- 擦除两侧外耳，留给头发
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")

    -- 狂野的银色碎发 (覆盖在头上)
    skel:fillRect(6, 1, 17, 6, "H")
    skel:fillRect(4, 4, 5, 13, "H")  -- 左侧发鬓
    skel:fillRect(18, 4, 19, 13, "H")-- 右侧发鬓
    
    -- 刘海细节
    skel:fillRect(7, 7, 8, 9, "H"); skel:put(9, 7, "H")
    skel:fillRect(15, 7, 16, 9, "H"); skel:put(14, 7, "H")
    skel:fillRect(7, 8, 8, 10, "HD"); skel:fillRect(15, 8, 16, 10, "HD")

    -- 戴在额头上的飞行员护目镜
    skel:fillRect(5, 3, 18, 5, "GF") -- 宽边框底色
    skel:fillRect(6, 2, 10, 6, "GF") -- 左镜框
    skel:fillRect(13, 2, 17, 6, "GF")-- 右镜框
    skel:fillRect(7, 3, 9, 5, "G")   -- 左橙色镜片
    skel:fillRect(14, 3, 16, 5, "G") -- 右橙色镜片
    skel:put(7, 3, "W"); skel:put(14, 3, "W") -- 镜片反光

    -- 脸部表情 (自信的笑)
    skel:fillRect(10, 16, 13, 16, "S") -- 抹去大嘴
    skel:put(10, 15, "M"); skel:fillRect(11, 16, 13, 16, "M") -- 歪嘴笑

    -- 军绿色夹克
    skel:fillRect(10, 20, 13, 21, "HD") -- 脖子阴影
    skel:fillRect(5, 21, 18, 23, "C")
    skel:fillRect(9, 21, 14, 23, "S") -- 敞开的领口露出内搭
    skel:fillRect(5, 20, 5, 20, "#"); skel:fillRect(18, 20, 18, 20, "#")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar10.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar10