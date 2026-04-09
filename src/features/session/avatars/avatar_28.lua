local AvatarSkeleton = require("AvatarSkeleton")
local Avatar28 = { id = "avatar_28" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["H"]  = { 0.15, 0.15, 0.18, 1 },  -- 乌黑的头发
        ["HD"] = { 0.10, 0.10, 0.12, 1 },  -- 头发阴影
        ["R"]  = { 0.88, 0.25, 0.30, 1 },  -- 发带红
        ["C"]  = { 0.35, 0.65, 0.55, 1 },  -- 青绿汉服 (天青色)
        ["N"]  = { 0.90, 0.70, 0.65, 1 },  -- 粉鼻尖
    })

    skel:fillRect(2, 9, 4, 14, "."); skel:fillRect(19, 9, 21, 14, ".")

    -- 头顶的双丫髻 (丸子头)
    skel:fillRect(4, 1, 8, 5, "H")   -- 左发髻
    skel:fillRect(15, 1, 19, 5, "H") -- 右发髻
    
    -- 缠绕发髻的红丝带
    skel:fillRect(4, 4, 8, 4, "R"); skel:fillRect(3, 5, 4, 8, "R") -- 左丝带垂下
    skel:fillRect(15, 4, 19, 4, "R"); skel:fillRect(19, 5, 20, 8, "R") -- 右丝带垂下

    -- 黑发本体与齐整的古风刘海
    skel:fillRect(5, 4, 18, 8, "H")
    skel:fillRect(4, 5, 5, 17, "H"); skel:fillRect(18, 5, 19, 17, "H") -- 两鬓垂发
    skel:fillRect(6, 8, 17, 8, "HD") -- 刘海阴影，显得发量浓密

    -- 少女五官微调
    skel:put(6, 11, "E"); skel:put(17, 11, "E") -- 睫毛
    skel:fillRect(11, 14, 12, 14, "N") -- 鼻子
    skel:fillRect(10, 16, 13, 16, "S") 
    skel:fillRect(11, 16, 12, 16, "M") -- 樱桃小口

    -- 汉服 (青绿色右衽交领)
    skel:fillRect(6, 21, 17, 23, "C")
    skel:fillRect(10, 20, 13, 21, "S") -- 露出的脖子
    skel:put(11, 21, "#"); skel:put(12, 22, "#"); skel:put(13, 23, "#") -- 衣襟边缘

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar28.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar28