local AvatarSkeleton = require("AvatarSkeleton")

local Avatar2 = {
    id = "avatar_2",
}

local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end

    -- 1. 调出我们的“造人/造物”骨架
    local skel = AvatarSkeleton.new()

    -- 2. 魔法换色：注入柴犬的灵魂配色
    skel:addColors({
        ["#"] = { 0.35, 0.22, 0.15, 1 }, -- 温暖的深巧克力色轮廓 (比纯黑更治愈)
        ["S"] = { 0.88, 0.55, 0.25, 1 }, -- 柴犬标志性的橘黄毛色
        ["W"] = { 0.98, 0.96, 0.92, 1 }, -- 奶油白 (用于脸颊、豆豆眉、内耳)
        ["N"] = { 0.15, 0.10, 0.10, 1 }, -- 小黑鼻头
        ["M"] = { 0.95, 0.40, 0.45, 1 }, -- 粉嘟嘟的小舌头
        ["G"] = { 0.25, 0.65, 0.40, 1 }, -- 森林绿围巾
        ["GD"]= { 0.15, 0.45, 0.25, 1 }, -- 绿围巾的阴影/边缘
    })

    -- 3. 抹除骨架原本的人类侧边耳朵
    skel:fillRect(2, 10, 3, 13, ".")  -- 清理左外耳
    skel:fillRect(20, 10, 21, 13, ".") -- 清理右外耳
    skel:fillRect(4, 10, 4, 13, "#")  -- 补齐左脸颊边缘线
    skel:fillRect(19, 10, 19, 13, "#") -- 补齐右脸颊边缘线

    -- 4. 在头顶画出柴犬挺拔的“三角小尖耳”
    -- [左耳]
    skel:put(6, 0, "#"); skel:put(7, 0, "#")
    skel:put(5, 1, "#"); skel:put(6, 1, "S"); skel:put(7, 1, "S"); skel:put(8, 1, "#")
    skel:put(4, 2, "#"); skel:put(5, 2, "S"); skel:put(6, 2, "W"); skel:put(7, 2, "S"); skel:put(8, 2, "#")
    skel:put(4, 3, "#"); skel:put(5, 3, "S"); skel:put(6, 3, "W"); skel:put(7, 3, "W"); skel:put(8, 3, "S"); skel:put(9, 3, "#")
    skel:fillRect(5, 4, 8, 4, "S") -- 抹掉头顶原有的边框，让耳朵和头连起来
    
    -- [右耳]
    skel:put(16, 0, "#"); skel:put(17, 0, "#")
    skel:put(15, 1, "#"); skel:put(16, 1, "S"); skel:put(17, 1, "S"); skel:put(18, 1, "#")
    skel:put(15, 2, "#"); skel:put(16, 2, "S"); skel:put(17, 2, "W"); skel:put(18, 2, "S"); skel:put(19, 2, "#")
    skel:put(14, 3, "#"); skel:put(15, 3, "S"); skel:put(16, 3, "W"); skel:put(17, 3, "W"); skel:put(18, 3, "S"); skel:put(19, 3, "#")
    skel:fillRect(15, 4, 18, 4, "S")

    -- 5. 画柴犬的灵魂：白色的胖脸颊和“豆豆眉”
    -- 豆豆眉
    skel:fillRect(7, 7, 8, 8, "W")
    skel:fillRect(15, 7, 16, 8, "W")
    
    -- 大面积白脸颊 (覆盖眼下和嘴巴区域)
    skel:fillRect(10, 11, 13, 12, "W") -- 向上延伸的鼻梁白毛
    skel:fillRect(8, 13, 15, 13, "W")  
    skel:fillRect(6, 14, 17, 14, "W")  
    skel:fillRect(5, 15, 18, 17, "W")  -- 整个下半脸都是白白胖胖的

    -- 6. 重新点缀五官 (适配小狗的脸型)
    skel:fillRect(11, 14, 12, 14, "N") -- 黑色小狗鼻
    skel:put(11, 15, "#"); skel:put(12, 15, "#") -- 倒Y字型的嘴角
    skel:fillRect(11, 16, 12, 17, "M") -- 萌萌地吐出粉色小舌头
    skel:fillRect(11, 18, 12, 18, "#") -- 舌头下边缘

    -- 微调一下腮红，印在白底的毛上会显得十分乖巧
    skel:fillRect(6, 14, 7, 14, "C")
    skel:fillRect(16, 14, 17, 14, "C")

    -- 7. 穿搭时间：一条充满活力的绿色唐草纹风小围巾
    skel:fillRect(5, 18, 18, 19, "G") -- 围巾主体覆盖脖子区域
    skel:put(4, 18, "GD"); skel:put(4, 19, "GD") -- 左边缘阴影
    skel:put(19, 18, "GD"); skel:put(19, 19, "GD") -- 右边缘阴影
    
    -- 围巾打结下垂的小尾巴
    skel:fillRect(14, 20, 16, 21, "G")
    skel:fillRect(13, 20, 13, 21, "GD")
    skel:fillRect(17, 20, 17, 21, "GD")
    skel:fillRect(14, 22, 16, 22, "GD")
    
    -- 围巾上的白色小波点
    skel:put(8, 18, "W"); skel:put(11, 19, "W"); skel:put(15, 18, "W"); skel:put(15, 20, "W")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar2.draw(bounds)
    local image = buildImage()
    AvatarSkeleton.drawCentered(image, bounds)
end

return Avatar2
