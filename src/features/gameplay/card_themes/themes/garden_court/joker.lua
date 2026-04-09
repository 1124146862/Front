--=============================================================================
-- 模块: Joker (小丑牌绘制)
-- 风格: 星露谷物语 (Stardew Valley) / 温馨治愈像素风
-- 特点: 软萌半身像, 治愈系柔和调色板, 背景星光粒子点缀, 严格控制绘制区域
--=============================================================================

local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Joker = {}

-------------------------------------------------------------------------------
--- 1. 温馨治愈系调色板 (Cozy Pixel Palettes)
--- 星露谷风格的核心在于低饱和度、温暖的色调，以及明显的阴影过渡。
-------------------------------------------------------------------------------

-- 普通小丑调色板 (经典的红蓝配色，但更柔和)
local PALETTE_NORMAL = {
    ['.'] = nil,                               -- 透明背景
    ['K'] = { 0.18, 0.15, 0.18, 1 },           -- 深色轮廓线 (更柔和的黑)
    ['W'] = { 1.00, 1.00, 1.00, 1 },           -- 纯白 (用于眼睛高光、牙齿)
    ['s'] = { 0.85, 0.60, 0.45, 1 },           -- 皮肤阴影/轮廓 (温暖的深桃色)
    ['S'] = { 1.00, 0.85, 0.70, 1 },           -- 基础皮肤 (明亮的桃色)
    ['p'] = { 0.95, 0.50, 0.60, 1 },           -- 腮红 (软萌粉色)
    ['E'] = { 0.25, 0.15, 0.10, 1 },           -- 眼睛 (温暖的深棕色)
    ['M'] = { 0.65, 0.25, 0.30, 1 },           -- 嘴巴内部 (浆果红)
    ['R'] = { 0.88, 0.32, 0.35, 1 },           -- 左侧帽子主色 (柔和的番茄红)
    ['r'] = { 0.72, 0.22, 0.25, 1 },           -- 左侧帽子阴影 (深红色)
    ['B'] = { 0.35, 0.65, 0.75, 1 },           -- 右侧帽子主色 (柔和的湖蓝色)
    ['b'] = { 0.20, 0.45, 0.55, 1 },           -- 右侧帽子阴影 (深青色)
    ['Y'] = { 0.95, 0.82, 0.25, 1 },           -- 铃铛主色 (明亮的金色)
    ['y'] = { 0.80, 0.55, 0.15, 1 },           -- 铃铛阴影 (暗金色)
    ['C'] = { 0.98, 0.95, 0.88, 1 },           -- 领口绒毛 (奶油白)
    ['c'] = { 0.88, 0.82, 0.72, 1 },           -- 领口绒毛阴影 (燕麦色)
    ['*'] = { 0.98, 0.90, 0.50, 0.4 }          -- 背景星光 (淡黄半透明)
}

-- 大王调色板 (星露谷秋季/日落色调，温暖的紫罗兰与日落橙)
local PALETTE_BIG = {
    ['.'] = nil,                               
    ['K'] = { 0.15, 0.10, 0.15, 1 },           
    ['W'] = { 1.00, 1.00, 1.00, 1 },           
    ['s'] = { 0.90, 0.65, 0.50, 1 },           
    ['S'] = { 1.00, 0.90, 0.75, 1 },           
    ['p'] = { 0.98, 0.55, 0.65, 1 },           -- 更亮的腮红
    ['E'] = { 0.20, 0.10, 0.15, 1 },           
    ['M'] = { 0.70, 0.20, 0.35, 1 },           
    ['R'] = { 0.80, 0.35, 0.65, 1 },           -- 左侧帽子 (紫罗兰/品红)
    ['r'] = { 0.65, 0.25, 0.50, 1 },           
    ['B'] = { 0.95, 0.60, 0.25, 1 },           -- 右侧帽子 (日落橙)
    ['b'] = { 0.80, 0.45, 0.15, 1 },           
    ['Y'] = { 1.00, 0.90, 0.30, 1 },           
    ['y'] = { 0.85, 0.65, 0.10, 1 },           
    ['C'] = { 1.00, 0.98, 0.95, 1 },           -- 更白的领口绒毛
    ['c'] = { 0.90, 0.85, 0.80, 1 },           
    ['*'] = { 1.00, 0.70, 0.40, 0.5 }          -- 背景星光 (橘红半透明)
}

-------------------------------------------------------------------------------
--- 2. 可爱半身像点阵图 (Cute Bust Sprite Map)
--- 规格: 40 x 40
--- 特点: 萌系大眼, 微笑, 带有毛绒质感的领子, 垂坠感帽子
-------------------------------------------------------------------------------
local CUTE_PORTRAIT = {
    "........................................",
    "........................................",
    "........................................",
    "........................................",
    "..................rrbb..................",
    "................rrRRBBbb................",
    "...............rRRRRBBBBb...............",
    "..............rRRRRRRBBBBBb.............",
    ".............rRRRRRRRBBBBBBb............",
    "............rRRRRRrrrbbbBBBBb...........",
    "............rRRRr.......bBBBb...........",
    "....yyyy....rRRr.........bBBb....yyyy...",
    "...yYYYYy...rRRr.........bBBb...yYYYYy..",
    "...yYYYYy...rRRr.........bBBb...yYYYYy..",
    "...yYYYYy....rr...........bb....yYYYYy..",
    "....yyyy.......ssssssssss.......yyyy....",
    ".............ssSSSSSSSSSSss.............",
    "............sSSSSSSSSSSSSSSs............",
    "............sSSS..EE..EE..SSs...........",
    "............sSSS.EWE..EWE.SSs...........",
    "............sSSS.EEE..EEE.SSs...........",
    "............ssppSSSSSSSSSSppss..........",
    "............sSSSS..MMMM..SSSSs..........",
    "............sSSSSS.MWWM.SSSSSs..........",
    ".............sSSSS.MMMM.SSSSs...........",
    "..............ssssssssssssss............",
    ".........ccccccccccccccccccccc..........",
    "........cCCCCCCCCCCCCCCCCCCCCCc.........",
    ".......cCCCCcccccCCCCCcccccCCCCc........",
    ".......cCCCCc...cCCCCCc...cCCCCc........",
    "........cccc.....ccccc.....cccc.........",
    ".........yy.......yy.......yy...........",
    "........yYYy.....yYYy.....yYYy..........",
    "........yYYy.....yYYy.....yYYy..........",
    ".........yy.......yy.......yy...........",
    "........................................",
    "........................................",
    "........................................",
    "........................................",
    "........................................"
}

-------------------------------------------------------------------------------
--- 3. 辅助绘制系统 (Helper Systems)
-------------------------------------------------------------------------------

-- 单个像素块绘制，向下兼容处理
local function drawPixel(x, y, size, color)
    if not color then return end
    if Utils.drawRect then
        Utils.drawRect(x, y, size, size, color)
    else
        -- 使用稍微放大的圆来模拟像素填充，避免出现网格缝隙
        Utils.drawCircle(x + size * 0.5, y + size * 0.5, size * 0.6, color)
    end
end

-- 背景温馨粒子渲染 (Stardew Ambient Particles)
local function drawCozyBackground(frame, palette, is_big)
    local star_color = palette['*']
    
    -- 手动定义的星光位置(相对比例)，分布在小丑头像周围
    local particles = {
        { x = 0.25, y = 0.15, s = 1.5 },
        { x = 0.75, y = 0.20, s = 2.0 },
        { x = 0.85, y = 0.60, s = 1.2 },
        { x = 0.35, y = 0.85, s = 1.8 },
        { x = 0.65, y = 0.80, s = 1.0 },
    }

    for _, p in ipairs(particles) do
        local px = frame.x + frame.width * p.x
        local py = frame.y + frame.height * p.y
        local radius = frame.width * 0.01 * p.s
        Utils.drawCircle(px, py, radius, star_color)
        
        -- 大王增加十字星芒效果
        if is_big and Utils.drawRect then
            Utils.drawRect(px - radius * 2, py - radius * 0.3, radius * 4, radius * 0.6, star_color)
            Utils.drawRect(px - radius * 0.3, py - radius * 2, radius * 0.6, radius * 4, star_color)
        end
    end
end

-------------------------------------------------------------------------------
--- 4. 主渲染接口 (Main Draw Interface)
-------------------------------------------------------------------------------
function Joker.draw(frame, context)
    local is_big = context.is_big_joker == true
    local palette = is_big and PALETTE_BIG or PALETTE_NORMAL

    -- ==========================================
    -- 第一步: 绘制 JOKER 文本 (完全还原原始代码)
    -- ==========================================
    -- 这部分代码严格保留你最初的参数，以确保引擎中 "J" 的对齐和字距完美无缺
    local main_text_color = is_big and { 0.86, 0.22, 0.22, 1 } or { 0.20, 0.22, 0.26, 1 }
    Utils.drawFittedVerticalLabel("JOKER", frame.x + 3, frame.y + 6, math.max(14, math.floor(frame.width * 0.18)), frame.height - 12, 20, -3, main_text_color)


    -- ==========================================
    -- 第二步: 渲染温馨背景点缀
    -- ==========================================
    drawCozyBackground(frame, palette, is_big)


    -- ==========================================
    -- 第三步: 核心计算与软萌半身像渲染
    -- ==========================================
    local sprite_cols = 40
    local sprite_rows = #CUTE_PORTRAIT

    -- 严格限制图像大小，将其控制在卡牌右下方的安全区域内
    -- 避开左侧文字，且绝对不会超出上方边框
    local max_draw_width = frame.width * 0.60
    local max_draw_height = frame.height * 0.60
    
    local G = math.min(max_draw_width / sprite_cols, max_draw_height / sprite_rows)
    
    -- 坐标定位：向右下方靠拢
    local start_x = (frame.x + frame.width * 0.92) - (sprite_cols * G)
    local start_y = (frame.y + frame.height * 0.92) - (sprite_rows * G)

    -- 逐像素绘制头像
    for row_idx = 1, sprite_rows do
        local row_str = CUTE_PORTRAIT[row_idx]
        for col_idx = 1, sprite_cols do
            local char = row_str:sub(col_idx, col_idx)
            local color = palette[char]
            
            if color then
                local px = start_x + (col_idx - 1) * G
                local py = start_y + (row_idx - 1) * G
                drawPixel(px, py, G, color)
            end
        end
    end
end

return Joker
