local AvatarSkeleton = require("AvatarSkeleton")

local Avatar4 = {
    id = "avatar_4",
}

local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end

    -- 1. 召唤通用骨架
    local skel = AvatarSkeleton.new()

    -- 2. 注入水豚专属的焦糖大地配色
    skel:addColors({
        ["#"] = { 0.28, 0.18, 0.12, 1 }, -- 极深焦糖色轮廓 (比纯黑更柔和)
        ["S"] = { 0.78, 0.55, 0.35, 1 }, -- 水豚皮毛色：温暖的焦糖棕
        ["M"] = { 0.85, 0.65, 0.45, 1 }, -- 吻部颜色：略浅一点的奶咖色
        ["N"] = { 0.20, 0.12, 0.08, 1 }, -- 鼻孔和眯眯眼的深褐色
        ["C"] = { 0.95, 0.50, 0.50, 0.6},-- 标志性的微醺腮红
        ["G"] = { 0.45, 0.75, 0.35, 1 }, -- 嘴里叼着的小草颜色（清新绿）
    })

    -- 3. 抹除骨架原本的人类特征 (耳朵和脸颊推平)
    skel:fillRect(2, 10, 3, 13, ".")   -- 清理左外耳
    skel:fillRect(20, 10, 21, 13, ".") -- 清理右外耳
    skel:fillRect(4, 10, 4, 13, "#")   -- 补齐左侧脸颊轮廓
    skel:fillRect(19, 10, 19, 13, "#") -- 补齐右侧脸颊轮廓
    
    -- 填平人类原本的五官，准备画水豚脸
    skel:fillRect(5, 11, 18, 16, "S")

    -- 4. 塑造水豚“方方正正”的大脸盘子
    -- 修复头顶轮廓 (因为不加橘子，需要一个完美圆润的头顶)
    skel:fillRect(7, 3, 16, 3, "#")
    skel:fillRect(6, 4, 17, 4, "#")
    skel:fillRect(7, 4, 16, 4, "S")

    -- 填平下巴，让脸型变得更加钝、更加佛系
    skel:fillRect(5, 17, 18, 17, "S")
    skel:fillRect(6, 18, 17, 18, "S")
    
    -- 画水豚高高在上的小短耳
    skel:fillRect(3, 5, 4, 7, "S"); skel:put(3, 4, "#"); skel:put(2, 5, "#"); skel:put(2, 6, "#")
    skel:fillRect(19, 5, 20, 7, "S"); skel:put(20, 4, "#"); skel:put(21, 5, "#"); skel:put(21, 6, "#")

    -- 5. 画水豚的灵魂五官
    -- 永远睡不醒的水平眯眯眼
    skel:fillRect(6, 10, 8, 10, "N")  -- 左眼
    skel:fillRect(15, 10, 17, 10, "N") -- 右眼

    -- 让人心融化的小腮红
    skel:fillRect(5, 11, 6, 11, "C")
    skel:fillRect(17, 11, 18, 11, "C")

    -- 大大宽宽的浅色吻部 (Muzzle)
    skel:fillRect(9, 13, 14, 18, "M")
    skel:fillRect(10, 12, 13, 12, "M")

    -- 鼻孔与嘴巴 (极简线条)
    skel:fillRect(11, 13, 12, 13, "N") -- 鼻头
    skel:fillRect(11, 14, 12, 15, "N") -- 人中
    skel:put(10, 15, "N"); skel:put(13, 15, "N") -- 微微扬起的神秘微笑

    -- 6. 点睛之笔：嘴里慢吞吞嚼着的一根青草
    skel:put(9, 15, "G")
    skel:put(8, 15, "G")
    skel:put(7, 16, "G")
    skel:put(6, 16, "G")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar4.draw(bounds)
    local image = buildImage()
    AvatarSkeleton.drawCentered(image, bounds)
end

return Avatar4