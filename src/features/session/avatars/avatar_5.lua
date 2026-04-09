local AvatarSkeleton = require("AvatarSkeleton")

local Avatar5 = {
    id = "avatar_5",
}

local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end

    local skel = AvatarSkeleton.new()

    -- 2. 魔法换色：注入现代高级感的高智清冷调色板
    skel:addColors({
        ["#"]  = { 0.20, 0.18, 0.18, 1 },   -- 更深的碳灰色轮廓，显得精致
        ["S"]  = { 1.00, 0.92, 0.88, 1 },   -- 冷白皮，透亮感
        ["H"]  = { 0.86, 0.82, 0.76, 1 },   -- 高级亚麻灰金发色
        ["HL"] = { 0.96, 0.94, 0.90, 1 },   -- 头发高光 (接近银白)
        ["HD"] = { 0.72, 0.66, 0.62, 1 },   -- 头发阴影 (灰棕色)
        ["A"]  = { 0.95, 0.95, 0.90, 1 },   -- 珍珠发夹的珠光色
        ["C"]  = { 0.22, 0.26, 0.25, 1 },   -- 高级墨绿/深灰高领毛衣
        ["CD"] = { 0.15, 0.18, 0.17, 1 },   -- 毛衣的暗部褶皱
        ["B"]  = { 0.95, 0.60, 0.65, 0.5},  -- 正常的粉色腮红 (修复之前的蓝色中毒腮红!)
        ["N"]  = { 0.90, 0.70, 0.68, 1 },   -- 柔和的粉鼻尖
        ["M"]  = { 0.85, 0.45, 0.48, 1 },   -- 豆沙色口红
    })

    -- 3. 抹除骨架原本的耳朵，准备用长发遮盖
    skel:fillRect(2, 9, 4, 14, ".")
    skel:fillRect(19, 9, 21, 14, ".")

    -- 4. 绘制亚麻色长直发 (更有垂坠感)
    -- 头发外轮廓
    skel:fillRect(7, 1, 16, 1, "#")
    skel:fillRect(5, 2, 6, 2, "#"); skel:fillRect(17, 2, 18, 2, "#")
    skel:fillRect(4, 3, 4, 4, "#"); skel:fillRect(19, 3, 19, 4, "#")
    skel:fillRect(3, 5, 3, 19, "#"); skel:fillRect(20, 5, 20, 19, "#")

    -- 填涂亚麻发色本体
    skel:fillRect(7, 2, 16, 4, "H")  
    skel:fillRect(5, 3, 18, 8, "H")  
    skel:fillRect(4, 5, 5, 19, "H")  -- 左侧长发
    skel:fillRect(18, 5, 19, 19, "H")-- 右侧长发

    -- 5. 法式碎刘海修剪
    -- 漏出额头中心，显得发型透气清爽
    skel:fillRect(10, 7, 13, 9, "S") 
    skel:fillRect(8, 8, 9, 9, "S")   
    -- 额头垂下两缕碎发
    skel:put(11, 7, "H"); skel:put(12, 8, "H") 

    -- 头发的光影塑造 (增加高级的层次感)
    skel:fillRect(8, 3, 11, 3, "HL") -- 头顶的天使光环高光
    skel:put(7, 4, "HL")
    -- 内侧头发阴影，增加脸部的纵深感
    skel:fillRect(4, 9, 5, 19, "HD") 
    skel:fillRect(18, 9, 19, 19, "HD") 
    -- 刘海阴影
    skel:fillRect(6, 8, 7, 9, "HD"); skel:fillRect(14, 8, 17, 9, "HD")

    -- 6. 精致妆容微调
    -- 加长一点眼尾的睫毛，更显清冷
    skel:put(6, 11, "E"); skel:put(17, 11, "E")
    
    -- 正确的微醺腮红
    skel:fillRect(5, 13, 18, 13, "S") -- 擦除原有的底色
    skel:fillRect(6, 13, 7, 13, "B")  
    skel:fillRect(16, 13, 17, 13, "B")

    -- 秀气的小鼻子和豆沙色唇妆
    skel:fillRect(11, 14, 12, 14, "N") 
    skel:fillRect(10, 16, 13, 16, "S") 
    skel:fillRect(11, 16, 12, 16, "M")

    -- 7. 饰品：侧边的珍珠一字夹 (打破单调)
    skel:put(15, 7, "A")
    skel:put(16, 8, "A")
    skel:put(17, 9, "A")

    -- 8. 穿搭：高级质感的高领毛衣
    -- 高领部分完全包裹住脖子
    skel:fillRect(9, 18, 14, 21, "C") 
    skel:fillRect(8, 18, 8, 20, "#"); skel:fillRect(15, 18, 15, 20, "#") -- 领子边缘
    skel:fillRect(9, 18, 14, 18, "CD") -- 领口贴近下巴处的阴影
    
    -- 画上衣躯干
    skel:fillRect(6, 21, 17, 23, "C")
    skel:fillRect(5, 22, 18, 23, "C")
    
    -- 衣服的外轮廓勾边
    skel:fillRect(5, 21, 5, 21, "#"); skel:fillRect(18, 21, 18, 21, "#")
    skel:fillRect(4, 22, 4, 23, "#"); skel:fillRect(19, 22, 19, 23, "#")
    skel:fillRect(9, 21, 14, 21, "CD") -- 锁骨处的衣服织痕细节

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar5.draw(bounds)
    local image = buildImage()
    AvatarSkeleton.drawCentered(image, bounds)
end

return Avatar5