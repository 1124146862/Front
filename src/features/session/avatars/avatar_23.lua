local AvatarSkeleton = require("AvatarSkeleton")
local Avatar23 = { id = "avatar_23" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["H"]  = { 0.40, 0.70, 0.85, 1 },  -- 水蓝色头发
        ["HD"] = { 0.25, 0.50, 0.65, 1 },  -- 头发阴影
        ["D"]  = { 0.95, 0.55, 0.60, 1 },  -- 珊瑚红龙角
        ["R"]  = { 0.90, 0.25, 0.30, 1 },  -- 额头花钿/朱砂记
        ["C"]  = { 0.95, 0.95, 0.90, 1 },  -- 白色古风交领
    })

    skel:fillRect(2, 9, 4, 14, "."); skel:fillRect(19, 9, 21, 14, ".")

    -- 水蓝长发与齐刘海
    skel:fillRect(5, 3, 18, 9, "H")
    skel:fillRect(4, 5, 5, 20, "H"); skel:fillRect(18, 5, 19, 20, "H")
    skel:fillRect(6, 9, 17, 9, "HD") -- 刘海阴影
    skel:fillRect(10, 8, 13, 9, "S") -- 漏出一点额头中心

    -- 额头中心的红点 (朱砂/花钿)
    skel:fillRect(11, 8, 12, 8, "R")

    -- 晶莹的珊瑚色龙角 (分叉结构)
    skel:fillRect(4, 1, 5, 4, "D"); skel:put(3, 2, "D") -- 左角
    skel:fillRect(18, 1, 19, 4, "D"); skel:put(20, 2, "D")-- 右角

    -- 微调五官
    skel:put(6, 11, "E"); skel:put(17, 11, "E") -- 睫毛
    skel:fillRect(11, 14, 12, 14, "N")
    skel:fillRect(11, 16, 12, 16, "R") -- 红色点唇

    -- 汉服交领 (右衽)
    skel:fillRect(7, 21, 16, 23, "C")
    skel:fillRect(10, 20, 13, 21, "S")
    skel:put(11, 21, "#"); skel:put(12, 22, "#"); skel:put(13, 23, "#") -- 交领的领口线

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar23.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar23