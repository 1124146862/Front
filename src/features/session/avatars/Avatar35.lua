local AvatarSkeleton = require("AvatarSkeleton")
local Avatar35 = { id = "avatar_35" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["D"] = { 0.15, 0.15, 0.18, 1 },  -- 忍者服夜空黑/深蓝
        ["L"] = { 0.25, 0.25, 0.30, 1 },  -- 衣服亮部
        ["R"] = { 0.85, 0.20, 0.25, 1 },  -- 红色头带
        ["S"] = { 0.95, 0.80, 0.70, 1 },  -- 漏出的皮肤
        ["N"] = { 0.05, 0.05, 0.05, 1 },  -- 锐利的眼睛
    })

    -- 蒙面头巾包裹整个头部
    skel:fillRect(4, 2, 19, 18, "D")
    skel:fillRect(5, 1, 18, 1, "D")
    skel:fillRect(6, 2, 10, 4, "L") -- 头部光泽

    -- 红色头带飘逸
    skel:fillRect(4, 6, 19, 8, "R")
    skel:fillRect(20, 7, 22, 8, "R") -- 向右飘出的头带尾巴
    skel:fillRect(21, 9, 22, 10, "R")

    -- 唯一漏出皮肤的眼部区域
    skel:fillRect(7, 10, 16, 13, "S")

    -- 锐利的忍者眼神 (眼角上扬)
    skel:fillRect(8, 11, 10, 11, "N"); skel:put(10, 10, "N") -- 左眼
    skel:fillRect(13, 11, 15, 11, "N"); skel:put(13, 10, "N") -- 右眼
    skel:put(9, 11, "W"); skel:put(14, 11, "W") -- 眼神光

    -- 忍者服身体部分
    skel:fillRect(5, 19, 18, 23, "D")
    skel:fillRect(11, 19, 12, 23, "L") -- 领口交接处的区分线

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar35.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar35