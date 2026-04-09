local AvatarSkeleton = require("AvatarSkeleton")
local Avatar18 = { id = "avatar_18" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    -- 定义清晰的颜色，确保 24x24 像素网格下的高 legibility
    skel:addColors({
        ["#"] = { 0.93, 0.84, 0.77, 1 },  -- 背景米色/灰褐色 #EDD5C5
        ["W"] = { 1.00, 1.00, 1.00, 1 },  -- 纯白毛色 #FFFFFF
        ["P"] = { 1.00, 0.71, 0.76, 1 },  -- 粉色内耳/鼻子 #FFB6C1
        ["E"] = { 0.23, 0.16, 0.12, 1 },  -- 深褐色眼睛/嘴部 #3B2A1E
    })

    -- 1. 填充背景
    skel:fillRect(0, 0, 23, 23, "#")

    -- 2. 绘制主体白色毛色 (头部核心)
    -- 注意：我们通过加宽头部区域来强调脸颊，提高 24x24 像素下的可识别性
    skel:fillRect(8, 7, 16, 16, "W") -- 核心
    skel:fillRect(7, 9, 17, 14, "W") -- 脸颊加宽

    -- 3. 绘制白色垂耳 (轮廓)
    -- 左垂耳 (W)
    skel:fillRect(4, 6, 7, 20, "W")
    -- 右垂耳 (W)
    skel:fillRect(17, 6, 20, 20, "W")

    -- 4. 填充粉色内耳 (P)
    -- 左内耳
    skel:fillRect(5, 7, 6, 18, "P")
    -- 右内耳
    skel:fillRect(18, 7, 19, 18, "P")

    -- 5. 绘制面部特征
    -- 眼睛 (深褐色 E，简单明确)
    skel:put(10, 11, "E")
    skel:put(14, 11, "E")

    -- 鼻子 (粉色 P，位于眼睛下方中心)
    skel:put(12, 13, "P")

    -- 清晰的三瓣嘴 (深褐色 E，inverted Y 形，在鼻子正下方)
    skel:put(11, 14, "E")
    skel:put(12, 15, "E")
    skel:put(13, 14, "E")

    -- 将 24x24 的像素艺术构造成最终图像
    cached_image = skel:buildImage()
    return cached_image
end

function Avatar18.draw(bounds)
    -- 外部框架和文字由 AvatarSkeleton 的 drawCentered 处理，
    -- 这里只专注于生成内部可爱的像素艺术。
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end

return Avatar18