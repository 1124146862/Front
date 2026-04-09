local AvatarSkeleton = require("AvatarSkeleton")
local Avatar41 = { id = "avatar_41" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["G"]  = { 0.40, 0.75, 0.45, 1 },  -- 恐龙绿
        ["GD"] = { 0.25, 0.55, 0.35, 1 },  -- 恐龙暗部 (肚子/阴影)
        ["Y"]  = { 0.95, 0.85, 0.20, 1 },  -- 背上的黄色骨板
        ["#"]  = { 0.15, 0.25, 0.15, 1 },  -- 深绿色轮廓线
        ["N"]  = { 0.10, 0.10, 0.10, 1 },  -- 眼睛
        ["C"]  = { 0.95, 0.50, 0.55, 0.6}, -- 腮红
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除默认骨架

    -- 恐龙圆圆的脑袋和大大的后脑勺
    skel:fillRect(5, 4, 16, 17, "G")
    skel:fillRect(6, 3, 15, 3, "#"); skel:fillRect(4, 5, 4, 16, "#") -- 头部轮廓
    skel:fillRect(17, 6, 17, 18, "#")

    -- 宽大的吻部 (向前凸出的大鼻子)
    skel:fillRect(11, 10, 19, 16, "G")
    skel:fillRect(16, 9, 18, 9, "#")
    skel:fillRect(20, 11, 20, 15, "#")

    -- 背上的黄色小骨板 (Spikes)
    skel:fillRect(3, 5, 4, 6, "Y"); skel:put(4, 4, "Y")
    skel:fillRect(3, 9, 4, 10, "Y"); skel:put(4, 8, "Y")
    skel:fillRect(3, 13, 4, 14, "Y"); skel:put(4, 12, "Y")

    -- 恐龙的五官
    skel:fillRect(12, 7, 13, 8, "N"); skel:put(12, 7, "W") -- 大眼睛
    skel:fillRect(17, 11, 18, 11, "N") -- 鼻孔
    skel:put(14, 15, "N"); skel:fillRect(15, 16, 17, 16, "N") -- 憨憨的微笑

    -- 腮红
    skel:fillRect(10, 9, 11, 9, "C")

    -- 身体与小短手
    skel:fillRect(5, 18, 16, 23, "G")
    skel:fillRect(7, 18, 14, 23, "GD") -- 略微深色的肚皮
    skel:fillRect(15, 19, 17, 20, "G") -- 伸出来的小短手

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar41.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar41