local AvatarSkeleton = require("AvatarSkeleton")
local Avatar30 = { id = "avatar_30" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["#"] = { 0.25, 0.15, 0.10, 1 },  -- 深褐色边缘
        ["B"] = { 0.50, 0.30, 0.15, 1 },  -- 宝箱木板棕色
        ["Y"] = { 0.95, 0.75, 0.20, 1 },  -- 金色装饰/锁
        ["H"] = { 0.90, 0.20, 0.30, 1 },  -- 内部的红心
        ["N"] = { 0.10, 0.10, 0.10, 1 },  -- 五官
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 宝箱主体 (底部木箱)
    skel:fillRect(4, 10, 19, 21, "#")
    skel:fillRect(5, 11, 18, 20, "B")
    
    -- 宝箱盖子 (顶部圆弧)
    skel:fillRect(5, 4, 18, 9, "#")
    skel:fillRect(6, 5, 17, 8, "B")
    skel:put(11, 4, "B"); skel:put(12, 4, "B") -- 盖顶
    skel:fillRect(11, 9, 12, 9, "#") -- 盖子和箱体的接缝

    -- 金色装饰条 (Crust)
    skel:fillRect(5, 4, 18, 4, "Y"); skel:fillRect(5, 9, 18, 9, "Y")
    skel:fillRect(5, 20, 18, 20, "Y")
    skel:fillRect(5, 11, 5, 19, "Y"); skel:fillRect(18, 11, 18, 19, "Y")

    -- 宝箱正面的金色锁扣 (Lock)
    skel:fillRect(10, 8, 13, 11, "Y")
    skel:fillRect(11, 9, 12, 10, "#") -- 锁孔

    -- 活生生的表情 (画在箱体上)
    skel:fillRect(7, 13, 8, 14, "N"); skel:put(7, 13, "W")
    skel:fillRect(15, 13, 16, 14, "N"); skel:put(15, 13, "W")
    skel:fillRect(11, 16, 12, 16, "N") -- 小嘴

    -- 宝箱内部透出的一颗跳动的红心 (稍微露出一点盖子缝隙)
    skel:fillRect(11, 6, 12, 7, "H") -- 露出一点红心顶
    skel:put(10, 7, "H"); skel:put(13, 7, "H") -- 红心高光
    skel:fillRect(11, 8, 12, 8, "Y") -- 盖缝压住

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar30.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar30