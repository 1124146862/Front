local AvatarSkeleton = require("AvatarSkeleton")
local Avatar26 = { id = "avatar_26" }
local cached_image = nil

local function buildImage()
    if cached_image then return cached_image end
    local skel = AvatarSkeleton.new()

    -- 优化了颜色对比度，让褶皱和五官更清晰
    skel:addColors({
        ["W"]  = { 1.00, 0.98, 0.95, 1 },  -- 白皙的包子皮
        ["D"]  = { 0.88, 0.78, 0.70, 1 },  -- 明显的浅褐色褶皱阴影
        ["S"]  = { 0.85, 0.92, 0.98, 0.7}, -- 半透明浅蓝热气
        ["E"]  = { 0.25, 0.15, 0.15, 1 },  -- 深褐色五官
        ["P"]  = { 0.98, 0.65, 0.70, 1 },  -- 粉嫩腮红
    })

    -- 1. 绘制热腾腾的蒸汽 (可爱的 S 形曲线)
    skel:put(8, 2, "S"); skel:put(9, 1, "S"); skel:put(9, 3, "S"); skel:put(8, 4, "S")
    skel:put(15, 1, "S"); skel:put(14, 2, "S"); skel:put(14, 4, "S"); skel:put(15, 3, "S")

    -- 2. 绘制包子主体形状 (圆润、上窄下宽的经典造型)
    skel:fillRect(10, 6, 13, 6, "W")   -- 顶部收口结
    skel:fillRect(9, 7, 14, 7, "W")    
    skel:fillRect(8, 8, 15, 8, "W")
    skel:fillRect(6, 9, 17, 9, "W")
    skel:fillRect(5, 10, 18, 10, "W")
    skel:fillRect(4, 11, 19, 11, "W")
    skel:fillRect(3, 12, 20, 13, "W")
    skel:fillRect(2, 14, 21, 16, "W")  -- 最宽的胖脸颊区域
    skel:fillRect(3, 17, 20, 17, "W")
    skel:fillRect(5, 18, 18, 18, "W")
    skel:fillRect(7, 19, 16, 19, "W")  -- 平坦的底部

    -- 3. 绘制包子褶皱 (向中心汇聚的线条阴影)
    -- 中心收口处
    skel:fillRect(11, 6, 12, 7, "D")
    
    -- 左侧放射状褶皱
    skel:put(9, 7, "D"); skel:put(8, 8, "D"); skel:put(7, 9, "D"); skel:put(6, 10, "D")
    skel:put(10, 7, "D"); skel:put(9, 8, "D"); skel:put(9, 9, "D")
    
    -- 右侧放射状褶皱
    skel:put(14, 7, "D"); skel:put(15, 8, "D"); skel:put(16, 9, "D"); skel:put(17, 10, "D")
    skel:put(13, 7, "D"); skel:put(14, 8, "D"); skel:put(14, 9, "D")

    -- 4. 绘制治愈系五官
    -- 豆豆眼 + 白色眼神光
    skel:fillRect(6, 13, 7, 14, "E"); skel:put(6, 13, "W")
    skel:fillRect(16, 13, 17, 14, "E"); skel:put(16, 13, "W")
    
    -- 夸张的软萌腮红 (放在脸颊最宽处)
    skel:fillRect(3, 14, 5, 15, "P")
    skel:fillRect(18, 14, 20, 15, "P")

    -- 小巧的嘴巴
    skel:put(11, 15, "E"); skel:put(12, 15, "E")

    cached_image = skel:buildImage()
    return cached_image
end

function Avatar26.draw(bounds)
    AvatarSkeleton.drawCentered(buildImage(), bounds)
end

return Avatar26