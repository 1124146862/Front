local AvatarSkeleton = require("AvatarSkeleton")

local Avatar3 = {
    id = "avatar_3",
}

local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end

    -- 1. 召唤通用骨架
    local skel = AvatarSkeleton.new()

    -- 2. 魔法换色：注入水豚和橘子的专属配色
    skel:addColors({
        ["#"] = { 0.28, 0.18, 0.12, 1 }, -- 极深焦糖色轮廓 (比纯黑更柔和)
        ["S"] = { 0.78, 0.55, 0.35, 1 }, -- 水豚的皮毛色：温暖的焦糖棕
        ["M"] = { 0.85, 0.65, 0.45, 1 }, -- 水豚的大鼻子/吻部颜色 (略浅一点的棕色)
        ["N"] = { 0.20, 0.12, 0.08, 1 }, -- 鼻孔和眯眯眼的深褐色
        ["O"] = { 0.98, 0.65, 0.15, 1 }, -- 头顶小橘子的亮橙色
        ["L"] = { 0.40, 0.75, 0.30, 1 }, -- 小橘子的绿叶子
        ["C"] = { 0.95, 0.50, 0.50, 0.6},-- 标志性的微醺腮红
    })

    -- 3. 抹除骨架原本的人类特征 (耳朵和脸部全部推平)
    skel:fillRect(2, 10, 3, 13, ".")   -- 清理左外耳
    skel:fillRect(20, 10, 21, 13, ".") -- 清理右外耳
    skel:fillRect(4, 10, 4, 13, "#")   -- 补齐左侧脸颊轮廓
    skel:fillRect(19, 10, 19, 13, "#") -- 补齐右侧脸颊轮廓
    
    -- 把人类的五官全部用皮毛色盖住，准备重新画
    skel:fillRect(5, 11, 18, 16, "S")

    -- 4. 塑造水豚“方方正正”的大脸盘子
    -- 将下巴拉直填满，显得脸更钝、更宽
    skel:fillRect(5, 17, 18, 17, "S")
    skel:fillRect(6, 18, 17, 18, "S")
    
    -- 画水豚小小的、高高在上的耳朵
    skel:fillRect(3, 5, 4, 7, "S"); skel:put(3, 4, "#"); skel:put(2, 5, "#"); skel:put(2, 6, "#")
    skel:fillRect(19, 5, 20, 7, "S"); skel:put(20, 4, "#"); skel:put(21, 5, "#"); skel:put(21, 6, "#")

    -- 5. 画水豚的灵魂五官
    -- 永远睡不醒的眯眯眼 (位于脸部偏上方)
    skel:fillRect(6, 10, 8, 10, "N")  -- 左眼眯成一条线
    skel:fillRect(15, 10, 17, 10, "N") -- 右眼眯成一条线

    -- 让人心融化的小腮红
    skel:fillRect(5, 11, 6, 11, "C")
    skel:fillRect(17, 11, 18, 11, "C")

    -- 大大宽宽的浅色吻部 (Muzzle)
    skel:fillRect(9, 13, 14, 18, "M")
    skel:fillRect(10, 12, 13, 12, "M")

    -- 鼻孔 (极简的Y字型嘴巴)
    skel:fillRect(11, 13, 12, 13, "N") -- 鼻尖
    skel:fillRect(11, 14, 12, 15, "N") -- 往下的人中
    skel:put(10, 15, "N"); skel:put(13, 15, "N") -- 微微扬起的淡定微笑

    -- 6. 点睛之笔：头顶的小橘子
    -- 橘子主体 (压在头顶的轮廓线上，产生“顶着”的视觉效果)
    skel:fillRect(10, 2, 13, 4, "O")
    skel:put(9, 3, "O"); skel:put(14, 3, "O")
    
    -- 橘子的高光
    skel:put(10, 2, "W"); skel:put(11, 2, "W")

    -- 橘子的深色勾边
    skel:fillRect(10, 1, 13, 1, "#") -- 橘子顶
    skel:put(9, 2, "#"); skel:put(8, 3, "#"); skel:put(9, 4, "#") -- 橘子左边缘
    skel:put(14, 2, "#"); skel:put(15, 3, "#"); skel:put(14, 4, "#") -- 橘子右边缘
    
    -- 橘子的小绿叶
    skel:put(12, 1, "L")
    skel:put(13, 0, "L")
    skel:put(14, 0, "L")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar3.draw(bounds)
    local image = buildImage()
    AvatarSkeleton.drawCentered(image, bounds)
end

return Avatar3
