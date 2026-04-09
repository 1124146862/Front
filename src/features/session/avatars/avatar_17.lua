local AvatarSkeleton = require("AvatarSkeleton")
local Avatar17 = { id = "avatar_17" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["P"]  = { 0.40, 0.30, 0.60, 1 },  -- 魔法帽紫色
        ["PD"] = { 0.25, 0.18, 0.40, 1 },  -- 魔法帽暗部
        ["Y"]  = { 0.95, 0.85, 0.25, 1 },  -- 星星装饰的黄色
        ["H"]  = { 0.45, 0.25, 0.15, 1 },  -- 棕色头发
    })

    -- 擦除耳朵
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")

    -- 巨大的紫色巫师帽
    skel:fillRect(2, 7, 21, 9, "P")   -- 宽大的帽檐
    skel:fillRect(1, 8, 22, 9, "PD")  -- 帽檐阴影
    skel:fillRect(5, 5, 18, 6, "P")   -- 帽子主体下半
    skel:fillRect(7, 3, 16, 4, "P")   -- 帽子主体中部
    skel:fillRect(9, 1, 13, 2, "P")   -- 帽子塔尖
    skel:put(14, 2, "P"); skel:put(15, 3, "P") -- 塔尖向右弯折

    -- 帽子上的星星装饰
    skel:fillRect(10, 5, 12, 6, "Y"); skel:put(11, 4, "Y"); skel:put(11, 7, "Y")

    -- 棕色碎发 (从帽子底下漏出来)
    skel:fillRect(4, 10, 5, 16, "H")  -- 左侧头发
    skel:fillRect(18, 10, 19, 16, "H")-- 右侧头发
    skel:fillRect(6, 10, 8, 11, "H")  -- 刘海
    skel:fillRect(15, 10, 17, 11, "H")

    -- 微调表情，显得更加专注
    skel:fillRect(10, 16, 13, 16, "S")
    skel:fillRect(11, 15, 12, 15, "M") -- 抿着小嘴

    -- 魔法长袍 (紫色领子)
    skel:fillRect(6, 21, 17, 23, "P")
    skel:fillRect(10, 21, 13, 23, "PD")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar17.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar17