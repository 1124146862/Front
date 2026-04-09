local AvatarSkeleton = require("AvatarSkeleton")
local Avatar27 = { id = "avatar_27" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    skel:addColors({
        ["Y"] = { 0.95, 0.70, 0.20, 1 },  -- 虎皮黄
        ["R"] = { 0.90, 0.25, 0.25, 1 },  -- 喜庆红
        ["B"] = { 0.15, 0.10, 0.10, 1 },  -- 黑色斑纹
        ["W"] = { 0.98, 0.98, 0.95, 1 },  -- 脸颊白
    })

    skel:fillRect(0, 0, 23, 23, ".") 

    -- 布老虎方正敦实的头部
    skel:fillRect(4, 6, 19, 21, "Y")
    
    -- 两只圆圆的老虎耳朵 (外黄内红)
    skel:fillRect(2, 3, 7, 7, "Y"); skel:fillRect(3, 4, 6, 6, "R")
    skel:fillRect(16, 3, 21, 7, "Y"); skel:fillRect(17, 4, 20, 6, "R")

    -- 额头霸气的“王”字斑纹
    skel:fillRect(11, 7, 12, 11, "B") -- 竖线
    skel:fillRect(9, 7, 14, 7, "B")   -- 上横
    skel:fillRect(10, 9, 13, 9, "B")  -- 中横
    skel:fillRect(8, 11, 15, 11, "B") -- 下横

    -- 布老虎特有的夸张大白眼眶与黑眼珠
    skel:fillRect(5, 12, 9, 15, "W"); skel:fillRect(6, 13, 8, 14, "B")
    skel:fillRect(14, 12, 18, 15, "W"); skel:fillRect(15, 13, 17, 14, "B")

    -- 红色的大鼻子和上扬的嘴角
    skel:fillRect(10, 15, 13, 16, "R")
    skel:put(9, 17, "B"); skel:put(14, 17, "B")
    skel:fillRect(10, 18, 13, 18, "B")

    -- 脸颊两边的三道胡须/黑色斑纹
    skel:fillRect(4, 16, 6, 16, "B"); skel:fillRect(4, 18, 6, 18, "B"); skel:fillRect(4, 20, 6, 20, "B")
    skel:fillRect(17, 16, 19, 16, "B"); skel:fillRect(17, 18, 19, 18, "B"); skel:fillRect(17, 20, 19, 20, "B")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar27.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end
return Avatar27