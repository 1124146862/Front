local AvatarSkeleton = require("AvatarSkeleton")
local Avatar29 = { id = "avatar_29" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.10, 0.10, 0.15, 1 },   -- 深色机械边缘
        ["G"]  = { 0.30, 0.35, 0.40, 1 },   -- 机械外壳灰蓝
        ["GL"] = { 0.50, 0.55, 0.60, 1 },   -- 外壳高光
        ["E"]  = { 0.10, 0.80, 0.95, 1 },   -- 核心霓虹蓝光 (虹膜)
        ["EL"] = { 0.60, 0.95, 1.00, 1 },   -- 核心最亮点 (瞳孔高光)
        ["S"]  = { 0.05, 0.05, 0.05, 0.5},  -- 底部阴影
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 义眼主体椭圆轮廓
    skel:fillRect(6, 4, 17, 19, "#")
    skel:fillRect(5, 5, 18, 18, "#")
    skel:fillRect(4, 7, 19, 16, "#")
    skel:fillRect(7, 5, 16, 18, "G")
    skel:fillRect(6, 6, 17, 17, "G")
    skel:fillRect(5, 8, 18, 15, "G")

    -- 机械外壳的金属光泽
    skel:fillRect(7, 6, 9, 8, "GL")
    skel:fillRect(14, 14, 16, 16, "GL")

    -- 核心霓虹眼球 (核心光源)
    skel:fillRect(9, 9, 14, 14, "E")
    skel:fillRect(10, 10, 13, 13, "#") -- 瞳孔暗部
    skel:fillRect(11, 11, 12, 12, "EL") -- 最亮高光

    -- 义眼上下方的机械接缝线
    skel:fillRect(8, 7, 15, 7, "#")
    skel:fillRect(8, 16, 15, 16, "#")

    -- 义眼两侧的接口/螺丝
    skel:put(4, 11, "GL"); skel:put(4, 12, "GL")
    skel:put(19, 11, "GL"); skel:put(19, 12, "GL")

    -- 底部漂浮的神秘阴影
    skel:fillRect(8, 20, 15, 21, "S")

    -- 融入一点拟人的小治愈 (核心内的微小笑脸)
    skel:put(11, 11, "E"); skel:put(12, 11, "E") -- 微笑瞳孔
    skel:put(11, 13, "#"); skel:put(12, 13, "#") -- 微笑嘴角

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar29.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar29