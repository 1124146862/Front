local AvatarSkeleton = require("AvatarSkeleton")

local Avatar1 = {
    id = "avatar_1",
}

local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end

    -- 1. 创建通用骨架实例 (自带基础头部形状和眼睛)
    local skel = AvatarSkeleton.new()

    -- 2. 魔法换色：覆盖骨架的默认颜色，瞬间变成“治愈系海洋风”
    skel:addColors({
        ["#"] = { 0.22, 0.30, 0.40, 1 }, -- 柔和的深灰蓝轮廓 (替代黑色，更治愈)
        ["S"] = { 0.50, 0.75, 0.88, 1 }, -- 鲨鱼主题色：温暖的婴儿蓝 (覆盖原来的肉色)
        ["W"] = { 0.98, 0.96, 0.92, 1 }, -- 鲨鱼肚子：奶油白
        ["M"] = { 0.90, 0.45, 0.50, 1 }, -- 小嘴巴：柔和的西瓜红
        ["C"] = { 0.95, 0.60, 0.65, 0.7},-- 腮红加深一点点
    })

    -- 3. 擦除人类专属特征
    skel:fillRect(11, 14, 12, 14, "S") -- 抹掉默认的人类鼻子
    skel:fillRect(10, 16, 13, 16, "S") -- 抹掉默认的大嘴巴

    -- 4. 画鲨鱼的奶油白肚皮/吻部 (覆盖在面部下方)
    skel:fillRect(10, 13, 13, 13, "W")
    skel:fillRect(9, 14, 14, 14, "W")
    skel:fillRect(8, 15, 15, 18, "W")
    skel:fillRect(7, 16, 16, 18, "W")

    -- 5. 画一个超级可爱的微张小嘴
    skel:fillRect(11, 15, 12, 15, "M")

    -- 6. 头顶的背鳍 (Dorsal Fin)
    skel:fillRect(11, 1, 12, 2, "S")
    skel:put(10, 2, "S")
    skel:fillRect(10, 3, 12, 3, "S") -- 打通头顶的轮廓线，让鳍和头连在一起
    -- 背鳍的外轮廓
    skel:put(11, 0, "#")
    skel:put(12, 0, "#")
    skel:put(10, 1, "#")
    skel:put(13, 1, "#")
    skel:put(9, 2, "#")
    skel:put(13, 2, "#")

    -- 7. 改造两侧的耳朵，变成下垂的可爱小胸鳍
    -- 清除左耳，画左鳍
    skel:fillRect(2, 10, 3, 13, ".") 
    skel:put(4, 11, "S"); skel:put(4, 12, "S")
    skel:put(3, 11, "S"); skel:put(3, 12, "S"); skel:put(2, 12, "S"); skel:put(1, 12, "S")
    skel:put(3, 10, "#"); skel:put(4, 10, "#")
    skel:put(1, 11, "#"); skel:put(2, 11, "#"); skel:put(0, 12, "#")
    skel:put(1, 13, "#"); skel:put(2, 13, "#"); skel:put(3, 13, "#"); skel:put(4, 13, "#")

    -- 清除右耳，画右鳍
    skel:fillRect(20, 10, 21, 13, ".")
    skel:put(19, 11, "S"); skel:put(19, 12, "S")
    skel:put(20, 11, "S"); skel:put(20, 12, "S"); skel:put(21, 12, "S"); skel:put(22, 12, "S")
    skel:put(19, 10, "#"); skel:put(20, 10, "#")
    skel:put(21, 11, "#"); skel:put(22, 11, "#"); skel:put(23, 12, "#")
    skel:put(19, 13, "#"); skel:put(20, 13, "#"); skel:put(21, 13, "#"); skel:put(22, 13, "#")

    -- 8. 调整腮红位置，让它贴紧眼睛下方，更显萌态
    skel:fillRect(5, 13, 18, 13, "S") -- 清理旧腮红
    skel:fillRect(6, 12, 7, 12, "C")  -- 左新腮红
    skel:fillRect(16, 12, 17, 12, "C")-- 右新腮红

    -- 9. 加一点鲨鱼特有的“腮裂”(脸颊旁边的三道小竖线，这里用两个像素点点缀)
    skel:put(5, 14, "#"); skel:put(5, 16, "#")
    skel:put(18, 14, "#"); skel:put(18, 16, "#")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar1.draw(bounds)
    local image = buildImage()
    -- 直接复用骨架里的居中渲染逻辑
    AvatarSkeleton.drawCentered(image, bounds)
end

return Avatar1
