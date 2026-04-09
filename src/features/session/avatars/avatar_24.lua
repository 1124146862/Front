local AvatarSkeleton = require("AvatarSkeleton")
local Avatar24 = { id = "avatar_24" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"] = { 0.20, 0.10, 0.10, 1 },  -- 黑色轮廓
        ["R"] = { 0.88, 0.20, 0.25, 1 },  -- 醒狮红
        ["Y"] = { 0.95, 0.80, 0.20, 1 },  -- 醒狮金/黄
        ["W"] = { 0.98, 0.98, 0.98, 1 },  -- 白绒毛
        ["N"] = { 0.10, 0.10, 0.10, 1 },  -- 黑眼睛
    })

    skel:fillRect(0, 0, 23, 23, ".") -- 擦除骨架

    -- 狮头主体轮廓 (方圆结合)
    skel:fillRect(4, 5, 19, 20, "R")
    
    -- 头顶的独角与白色绒球
    skel:fillRect(11, 2, 12, 5, "Y")
    skel:fillRect(10, 1, 13, 2, "W")

    -- 额头金纹与白色粗眉毛
    skel:fillRect(8, 6, 15, 7, "Y")
    skel:fillRect(4, 9, 10, 11, "W"); skel:fillRect(13, 9, 19, 11, "W")

    -- 大大的铜铃眼
    skel:fillRect(5, 12, 9, 15, "Y")
    skel:fillRect(14, 12, 18, 15, "Y")
    skel:fillRect(6, 13, 8, 14, "N"); skel:put(7, 13, "W") -- 瞳孔
    skel:fillRect(15, 13, 17, 14, "N"); skel:put(16, 13, "W")

    -- 宽阔的白胡须与嘴巴
    skel:fillRect(5, 18, 18, 21, "W")
    skel:fillRect(9, 16, 14, 17, "Y") -- 鼻子部位
    skel:fillRect(8, 19, 15, 19, "#") -- 威武的嘴巴缝

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar24.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar24