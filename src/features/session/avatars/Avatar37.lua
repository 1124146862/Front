local AvatarSkeleton = require("AvatarSkeleton")
local Avatar37 = { id = "avatar_37" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["D"] = { 0.50, 0.25, 0.40, 1 },  -- 小恶魔紫红色皮肤
        ["#"] = { 0.20, 0.10, 0.15, 1 },  -- 深色轮廓
        ["H"] = { 0.15, 0.15, 0.18, 1 },  -- 恶魔角 (黑灰)
        ["Y"] = { 0.95, 0.85, 0.20, 1 },  -- 闪烁的金色恶魔眼
        ["W"] = { 0.98, 0.98, 0.98, 1 },  -- 尖牙
    })

    -- 擦除原有耳朵，改用尖耳
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")
    
    -- 铺满紫红色的脸蛋
    skel:fillRect(5, 5, 18, 18, "D")

    -- 头顶向后弯曲的恶魔小角
    skel:fillRect(6, 2, 7, 4, "H"); skel:put(8, 4, "H"); skel:put(5, 1, "H")
    skel:fillRect(16, 2, 17, 4, "H"); skel:put(15, 4, "H"); skel:put(18, 1, "H")

    -- 两侧尖尖的精灵/恶魔耳
    skel:fillRect(3, 10, 4, 12, "D"); skel:put(2, 10, "D"); skel:put(1, 9, "D")
    skel:fillRect(19, 10, 20, 12, "D"); skel:put(21, 10, "D"); skel:put(22, 9, "D")

    -- 狡黠的上挑金黄色眼睛
    skel:fillRect(7, 11, 9, 12, "Y"); skel:put(9, 10, "Y")
    skel:fillRect(14, 11, 16, 12, "Y"); skel:put(14, 10, "Y")
    skel:fillRect(8, 11, 8, 12, "#"); skel:fillRect(15, 11, 15, 12, "#") -- 竖瞳

    -- 坏坏的咧嘴笑，漏出一颗小尖牙
    skel:fillRect(10, 15, 14, 15, "#")
    skel:put(9, 14, "#"); skel:put(15, 14, "#")
    skel:put(11, 16, "W") -- 左边的小尖牙

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar37.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar37