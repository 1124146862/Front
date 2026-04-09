local AvatarSkeleton = require("AvatarSkeleton")
local Avatar32 = { id = "avatar_32" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"]  = { 0.40, 0.05, 0.10, 1 },   -- 深红勾边
        ["H"]  = { 0.90, 0.20, 0.30, 1 },   -- 像素心红
        ["HL"] = { 0.98, 0.60, 0.65, 1 },   -- 红心高光 (偏粉)
        ["HD"] = { 0.70, 0.10, 0.20, 1 },   -- 红心暗部
        ["A"]  = { 0.95, 0.90, 0.95, 0.7},  -- 治愈柔光 (半透明白紫)
        ["N"]  = { 0.20, 0.10, 0.10, 1 },   -- 五官
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 治愈柔光 aura (最底层，半透明)
    skel:fillRect(5, 5, 18, 18, "A")
    skel:fillRect(3, 7, 20, 16, "A")

    -- 像素心外轮廓
    skel:fillRect(7, 3, 16, 3, "#"); skel:fillRect(4, 4, 19, 4, "#")
    skel:fillRect(2, 5, 21, 11, "#")
    skel:fillRect(3, 12, 20, 12, "#"); skel:fillRect(4, 13, 19, 14, "#")
    skel:fillRect(6, 15, 17, 16, "#"); skel:fillRect(8, 17, 15, 18, "#")
    skel:fillRect(10, 19, 13, 20, "#"); skel:fillRect(11, 21, 12, 21, "#")

    -- 填充红心本体
    skel:fillRect(7, 4, 16, 4, "H"); skel:fillRect(5, 5, 18, 5, "H")
    skel:fillRect(3, 6, 20, 11, "H")
    skel:fillRect(4, 12, 19, 12, "H"); skel:fillRect(5, 13, 18, 14, "H")
    skel:fillRect(7, 15, 16, 16, "H"); skel:fillRect(9, 17, 14, 18, "H")
    skel:fillRect(11, 19, 12, 20, "H")

    -- 红心的凹陷处与光影塑造
    skel:put(11, 3, "."); skel:put(12, 3, ".") -- 顶部凹陷
    skel:put(11, 4, "#"); skel:put(12, 4, "#") 
    skel:fillRect(6, 6, 9, 9, "HL")            -- 左上角高光
    skel:fillRect(14, 15, 17, 18, "HD")        -- 右下角阴影

    -- 红心上的治愈小脸
    skel:fillRect(8, 11, 9, 12, "N"); skel:put(8, 11, "W")  -- 左眼
    skel:fillRect(14, 11, 15, 12, "N"); skel:put(14, 11, "W")-- 右眼
    skel:fillRect(11, 13, 12, 13, "N") -- 小嘴

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar32.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar32
