local AvatarSkeleton = require("AvatarSkeleton")
local Avatar16 = { id = "avatar_16" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"] = { 0.25, 0.15, 0.10, 1 },  -- 勾边
        ["C"] = { 0.75, 0.45, 0.20, 1 },  -- 吐司烤焦的边 (Crust)
        ["B"] = { 0.95, 0.85, 0.65, 1 },  -- 吐司面包芯
        ["Y"] = { 0.98, 0.88, 0.30, 1 },  -- 融化的黄油
        ["N"] = { 0.20, 0.10, 0.10, 1 },  -- 眼睛
        ["R"] = { 0.95, 0.50, 0.50, 0.7}, -- 红晕
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 吐司的形状 (上宽下略窄，顶部有两个圆弧)
    skel:fillRect(5, 3, 18, 20, "C")
    skel:fillRect(6, 5, 17, 19, "B")
    
    -- 修饰顶部圆弧
    skel:fillRect(5, 2, 10, 4, "C"); skel:fillRect(6, 3, 9, 4, "B")
    skel:fillRect(13, 2, 18, 4, "C"); skel:fillRect(14, 3, 17, 4, "B")
    skel:put(11, 4, "B"); skel:put(12, 4, "B")

    -- 融化的黄油方块
    skel:fillRect(10, 6, 14, 9, "Y")
    skel:fillRect(13, 10, 14, 11, "Y") -- 往下融化的一滴

    -- 吐司的笑脸
    skel:fillRect(8, 13, 9, 14, "N"); skel:put(8, 13, "W")
    skel:fillRect(14, 13, 15, 14, "N"); skel:put(14, 13, "W")
    skel:fillRect(7, 15, 8, 15, "R")
    skel:fillRect(15, 15, 16, 15, "R")
    skel:put(11, 16, "N"); skel:put(12, 16, "N") -- 小嘴

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar16.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar16