local AvatarSkeleton = require("AvatarSkeleton")

local Avatar7 = {
    id = "avatar_7",
}

local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end

    -- 1. 召唤通用骨架
    local skel = AvatarSkeleton.new()

    -- 2. 魔法换色：注入焦糖奶牛的专属配色 (无腮红)
    skel:addColors({
        ["#"] = { 0.35, 0.25, 0.20, 1 }, -- 温暖的深咖色轮廓
        ["S"] = { 0.98, 0.95, 0.90, 1 }, -- 奶牛的底色：奶油白
        ["P"] = { 0.75, 0.55, 0.40, 1 }, -- 奶牛的花纹：焦糖棕色
        ["M"] = { 0.95, 0.78, 0.75, 1 }, -- 奶牛的大鼻子/吻部：柔和的浅肉粉色
        ["H"] = { 0.88, 0.82, 0.75, 1 }, -- 小牛角的颜色：骨白色
        ["N"] = { 0.20, 0.15, 0.15, 1 }, -- 眼睛和鼻孔的深咖色
    })

    -- 3. 擦除人类外耳，重置整个脸部底色
    skel:fillRect(2, 9, 4, 14, ".")   -- 清理左侧旧耳朵
    skel:fillRect(19, 9, 21, 14, ".") -- 清理右侧旧耳朵
    skel:fillRect(5, 4, 18, 18, "S")  -- 铺满奶油白底色
    
    -- 补齐被擦掉的脸颊两侧轮廓
    skel:fillRect(4, 6, 4, 16, "#")
    skel:fillRect(19, 6, 19, 16, "#")

    -- 4. 绘制奶牛专属花纹 (焦糖色斑块)
    -- 右眼周围的大斑块
    skel:fillRect(13, 8, 18, 13, "P")
    skel:fillRect(14, 7, 17, 7, "P")
    skel:fillRect(15, 14, 18, 15, "P")
    -- 头顶左侧的小斑块
    skel:fillRect(6, 4, 9, 7, "P")
    skel:fillRect(5, 5, 5, 6, "P")

    -- 5. 绘制奶牛的宽大粉色鼻子 (Muzzle)
    skel:fillRect(8, 13, 15, 17, "M")
    skel:fillRect(9, 12, 14, 12, "M")
    skel:fillRect(9, 18, 14, 18, "M")
    
    -- 画上两个大大的鼻孔
    skel:fillRect(10, 14, 11, 14, "N")
    skel:fillRect(13, 14, 14, 14, "N")
    
    -- 简单的倒 V 字型小嘴巴
    skel:put(11, 16, "N"); skel:put(12, 16, "N")

    -- 6. 绘制眼睛 (无腮红)
    skel:fillRect(7, 10, 8, 11, "N")  -- 左眼
    skel:put(7, 10, "W")              -- 左眼高光
    
    skel:fillRect(15, 10, 16, 11, "N") -- 右眼 (画在焦糖斑块上)
    skel:put(15, 10, "W")              -- 右眼高光

    -- 7. 绘制头顶的短短小牛角
    -- 左角
    skel:fillRect(7, 1, 8, 2, "H")
    skel:put(7, 0, "#"); skel:put(8, 0, "#"); skel:put(6, 1, "#"); skel:put(6, 2, "#"); skel:put(9, 1, "#"); skel:put(9, 2, "#")
    -- 右角
    skel:fillRect(15, 1, 16, 2, "H")
    skel:put(15, 0, "#"); skel:put(16, 0, "#"); skel:put(14, 1, "#"); skel:put(14, 2, "#"); skel:put(17, 1, "#"); skel:put(17, 2, "#")
    
    -- 8. 绘制向两侧平伸/微垂的牛耳朵
    -- 左耳
    skel:fillRect(2, 7, 4, 9, "S")
    skel:fillRect(3, 8, 4, 8, "M") -- 露出一点粉色内耳
    skel:put(2, 6, "#"); skel:put(3, 6, "#"); skel:put(4, 6, "#")
    skel:put(1, 7, "#"); skel:put(1, 8, "#"); skel:put(1, 9, "#")
    skel:put(2, 10, "#"); skel:put(3, 10, "#"); skel:put(4, 10, "#")

    -- 右耳 (右耳也带一点焦糖色花纹)
    skel:fillRect(19, 7, 21, 9, "P")
    skel:fillRect(19, 8, 20, 8, "M") -- 露出一点粉色内耳
    skel:put(19, 6, "#"); skel:put(20, 6, "#"); skel:put(21, 6, "#")
    skel:put(22, 7, "#"); skel:put(22, 8, "#"); skel:put(22, 9, "#")
    skel:put(19, 10, "#"); skel:put(20, 10, "#"); skel:put(21, 10, "#")

    -- 9. 身体部分 (穿一件简约的深棕色背带裤/衣服)
    skel:fillRect(5, 20, 18, 23, "P") -- 衣服底色
    skel:fillRect(9, 20, 14, 21, "S") -- 露出的脖子和一点胸口
    
    -- 肩膀和身体的勾边
    skel:fillRect(4, 20, 4, 23, "#"); skel:fillRect(19, 20, 19, 23, "#")
    skel:fillRect(5, 19, 8, 19, "#"); skel:fillRect(15, 19, 18, 19, "#")
    
    -- 两条深色背带
    skel:fillRect(8, 20, 9, 23, "#")
    skel:fillRect(14, 20, 15, 23, "#")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar7.draw(bounds)
    local image = buildImage()
    AvatarSkeleton.drawCentered(image, bounds)
end

return Avatar7