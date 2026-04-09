local AvatarSkeleton = require("AvatarSkeleton")
local Avatar43 = { id = "avatar_43" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["B"] = { 0.55, 0.40, 0.30, 1 },  -- 树懒身体棕色
        ["L"] = { 0.90, 0.85, 0.75, 1 },  -- 树懒脸部浅褐色
        ["D"] = { 0.25, 0.18, 0.15, 1 },  -- 眼罩深棕色
        ["N"] = { 0.10, 0.10, 0.10, 1 },  -- 眼睛/鼻子
        ["#"] = { 0.15, 0.10, 0.10, 1 },  -- 轮廓
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 树懒圆圆的脑袋
    skel:fillRect(5, 4, 18, 19, "B")
    skel:fillRect(6, 3, 17, 3, "#")
    skel:fillRect(4, 5, 4, 18, "#"); skel:fillRect(19, 5, 19, 18, "#")

    -- 脸部的浅色面具区 (面庞)
    skel:fillRect(7, 6, 16, 16, "L")
    skel:fillRect(6, 8, 17, 14, "L")

    -- 标志性的深色眼罩 (向两侧下垂)
    skel:fillRect(5, 9, 10, 12, "D")
    skel:fillRect(13, 9, 18, 12, "D")

    -- 睡眼惺忪的眼睛
    skel:fillRect(8, 10, 9, 10, "N")
    skel:fillRect(14, 10, 15, 10, "N")

    -- 黑鼻子与慢吞吞的微笑
    skel:fillRect(11, 13, 12, 14, "N") -- 鼻子
    skel:put(10, 15, "N"); skel:put(11, 16, "N"); skel:put(12, 16, "N"); skel:put(13, 15, "N") -- 嘴角上扬

    -- 身体
    skel:fillRect(6, 20, 17, 23, "B")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar43.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar43