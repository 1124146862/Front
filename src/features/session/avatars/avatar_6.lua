local AvatarSkeleton = require("AvatarSkeleton")

local Avatar6 = {
    id = "avatar_6",
}

local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end

    -- 1. 召唤通用骨架
    local skel = AvatarSkeleton.new()

    -- 2. 魔法换色：注入小绵羊的软糯配色
    skel:addColors({
        ["#"]  = { 0.35, 0.25, 0.25, 1 },   -- 温暖的红棕色轮廓
        ["S"]  = { 0.98, 0.85, 0.80, 1 },   -- 绵羊脸部和耳朵的颜色
        ["W"]  = { 0.98, 0.96, 0.92, 1 },   -- 羊毛本色：软糯的奶油白
        ["WD"] = { 0.88, 0.82, 0.78, 1 },   -- 羊毛的阴影色
        ["H"]  = { 0.95, 0.80, 0.40, 1 },   -- 绵羊角的颜色
        ["N"]  = { 0.20, 0.10, 0.10, 1 },   -- 眼睛和鼻子的深色 (略微加深增强对比)
        ["C"]  = { 0.95, 0.60, 0.65, 0.7},  -- 腮红
    })

    -- 3. 擦除人类耳朵，准备重塑脸型
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")
    skel:fillRect(4, 9, 19, 18, "S") 

    -- 4. 绘制头顶蓬松羊毛
    skel:fillRect(5, 2, 18, 8, "W")  
    skel:fillRect(6, 1, 17, 1, "W")
    skel:fillRect(8, 0, 15, 0, "W") 
    skel:fillRect(7, 0, 7, 0, "#"); skel:fillRect(16, 0, 16, 0, "#") 
    
    skel:put(7, 3, "WD"); skel:put(11, 2, "WD"); skel:put(16, 4, "WD")
    skel:put(9, 6, "WD"); skel:put(14, 7, "WD"); skel:put(6, 7, "WD")

    -- 5. 绘制下垂小耳朵
    skel:fillRect(3, 11, 4, 14, "S") 
    skel:put(2, 12, "S"); skel:put(2, 13, "S")
    skel:fillRect(19, 11, 20, 14, "S") 
    skel:put(21, 12, "S"); skel:put(21, 13, "S")
    
    skel:put(2, 11, "#"); skel:put(1, 12, "#"); skel:put(1, 13, "#"); skel:put(2, 14, "#"); skel:put(3, 15, "#"); skel:put(4, 15, "#")
    skel:put(21, 11, "#"); skel:put(22, 12, "#"); skel:put(22, 13, "#"); skel:put(21, 14, "#"); skel:put(20, 15, "#"); skel:put(19, 15, "#")

    -- 6. 盘在脑袋两侧的卷角
    -- 左角
    skel:fillRect(3, 6, 5, 8, "H")
    skel:fillRect(2, 7, 2, 9, "H")
    skel:put(3, 10, "H")
    skel:put(3, 5, "#"); skel:put(4, 5, "#"); skel:put(5, 5, "#"); skel:put(6, 6, "#")
    skel:put(1, 7, "#"); skel:put(1, 8, "#"); skel:put(1, 9, "#"); skel:put(2, 10, "#")
    skel:put(3, 11, "#"); skel:put(4, 10, "#"); skel:put(4, 9, "#")
    
    -- 右角
    skel:fillRect(18, 6, 20, 8, "H")
    skel:fillRect(21, 7, 21, 9, "H")
    skel:put(20, 10, "H")
    skel:put(18, 5, "#"); skel:put(19, 5, "#"); skel:put(20, 5, "#"); skel:put(17, 6, "#")
    skel:put(22, 7, "#"); skel:put(22, 8, "#"); skel:put(22, 9, "#"); skel:put(21, 10, "#")
    skel:put(20, 11, "#"); skel:put(19, 10, "#"); skel:put(19, 9, "#")

    -- ==============================================================================
    -- 7. 绘制脸部五官：【已调整】增强眼神灵动感
    -- ==============================================================================
    
    -- 【新增】淡淡的眉毛阴影，增加眼神聚焦感
    skel:put(6, 11, "WD"); skel:put(17, 11, "WD")

    -- 【修改】眼睛改为2x2方块，更圆润有神 (y轴从12延展到13)
    skel:fillRect(6, 12, 7, 13, "N") -- 左眼本体
    skel:fillRect(16, 12, 17, 13, "N") -- 右眼本体
    
    -- 【修改】高光位置移至外上方 (左眼右上，右眼右上)，经典灵动眼神画法
    skel:put(7, 12, "W"); skel:put(17, 12, "W") 
    
    -- 腮红 (略微下移，配合增大的眼睛)
    skel:fillRect(4, 14, 5, 14, "C")
    skel:fillRect(18, 14, 19, 14, "C")

    -- Y字形三瓣嘴 (保持原样)
    skel:fillRect(11, 14, 12, 14, "N") -- 鼻尖
    skel:fillRect(11, 15, 12, 16, "N") -- 人中下拉
    skel:put(10, 16, "N"); skel:put(13, 16, "N") -- 微微扬起的嘴角
    -- ==============================================================================

    -- 8. 绘制毛茸茸的身体
    skel:fillRect(5, 18, 18, 23, "W")
    skel:fillRect(4, 19, 19, 23, "W")
    skel:fillRect(3, 20, 20, 23, "W")
    
    skel:fillRect(6, 18, 17, 18, "WD")
    skel:put(5, 20, "WD"); skel:put(8, 22, "WD"); skel:put(14, 21, "WD"); skel:put(18, 19, "WD")
    
    skel:fillRect(4, 18, 4, 18, "#"); skel:fillRect(19, 18, 19, 18, "#")
    skel:fillRect(3, 19, 3, 19, "#"); skel:fillRect(20, 19, 20, 19, "#")
    skel:fillRect(2, 20, 2, 23, "#"); skel:fillRect(21, 20, 21, 23, "#")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar6.draw(bounds)
    local image = buildImage()
    AvatarSkeleton.drawCentered(image, bounds)
end

return Avatar6