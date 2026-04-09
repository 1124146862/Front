local Catalog = {}

Catalog.NONE_MARKER = "__none__"
Catalog.slot_order = { "frame" }

Catalog.slot_keys = {
    frame = "main_menu.wardrobe_slot_frame",
}

Catalog.items = {
    { item_id = "frame_sunrise", slot = "frame", price = 18, title = "朝阳边框", desc = "暖金描边，像晨光一样干净。", animated = false },
    { item_id = "frame_bamboo", slot = "frame", price = 24, title = "竹影边框", desc = "清爽竹节，偏东方气质。", animated = false },
    { item_id = "frame_frost", slot = "frame", price = 22, title = "霜晶边框", desc = "冰蓝晶角，冷感很强。", animated = false },
    { item_id = "frame_ember", slot = "frame", price = 22, title = "余烬边框", desc = "深红描边，边缘带火星。", animated = false },
    { item_id = "frame_ocean", slot = "frame", price = 20, title = "海盐边框", desc = "蓝绿波纹，像海面反光。", animated = false },
    { item_id = "frame_jade", slot = "frame", price = 26, title = "玉润边框", desc = "温润青玉，简洁耐看。", animated = false },
    { item_id = "frame_plum", slot = "frame", price = 20, title = "梅影边框", desc = "紫红小花，边角更柔和。", animated = false },
    { item_id = "frame_rose", slot = "frame", price = 20, title = "玫糖边框", desc = "粉金配色，甜一点。", animated = false },
    { item_id = "frame_grape", slot = "frame", price = 18, title = "葡雾边框", desc = "深紫渐层，偏夜色。", animated = false },
    { item_id = "frame_ink", slot = "frame", price = 16, title = "墨线边框", desc = "黑白极简，轻薄利落。", animated = false },
    { item_id = "frame_cloud", slot = "frame", price = 18, title = "云软边框", desc = "白云卷角，轻盈圆润。", animated = false },
    { item_id = "frame_sakura", slot = "frame", price = 22, title = "樱花边框", desc = "细粉花瓣，明亮柔软。", animated = false },
    { item_id = "frame_bronze", slot = "frame", price = 18, title = "古铜边框", desc = "老铜配色，厚重一点。", animated = false },
    { item_id = "frame_amber", slot = "frame", price = 20, title = "琥珀边框", desc = "蜜金透明感，温暖发亮。", animated = false },
    { item_id = "frame_mint", slot = "frame", price = 18, title = "薄荷边框", desc = "清淡薄荷绿，干净清凉。", animated = false },
    { item_id = "frame_storm", slot = "frame", price = 24, title = "雷霆边框", desc = "冷蓝闪角，带一点锋利感。", animated = false },
    { item_id = "frame_sand", slot = "frame", price = 16, title = "流沙边框", desc = "沙金颗粒，低调耐看。", animated = false },
    { item_id = "frame_lotus", slot = "frame", price = 24, title = "莲光边框", desc = "洋红莲瓣，华丽但不重。", animated = false },
    { item_id = "frame_royal", slot = "frame", price = 28, title = "王庭边框", desc = "紫金双层，仪式感更强。", animated = false },
    { item_id = "frame_pearl", slot = "frame", price = 18, title = "珍珠边框", desc = "奶白珠点，温和百搭。", animated = false },
    { item_id = "frame_aurora", slot = "frame", price = 36, title = "极光边框", desc = "动态流光，在边缘缓慢流动。", animated = true },
    { item_id = "frame_starlight", slot = "frame", price = 38, title = "星辉边框", desc = "动态星点，会轻微闪烁。", animated = true },
    { item_id = "frame_pulse", slot = "frame", price = 34, title = "脉冲边框", desc = "动态呼吸光，节奏很稳。", animated = true },
    { item_id = "frame_festival", slot = "frame", price = 40, title = "庆典边框", desc = "动态彩灯，适合热闹场景。", animated = true },
}

Catalog.items_by_id = {}
Catalog.items_by_slot = {}

for _, item in ipairs(Catalog.items) do
    Catalog.items_by_id[item.item_id] = item
    Catalog.items_by_slot[item.slot] = Catalog.items_by_slot[item.slot] or {}
    Catalog.items_by_slot[item.slot][#Catalog.items_by_slot[item.slot] + 1] = item
end

function Catalog:getItem(item_id)
    return self.items_by_id[item_id]
end

function Catalog:getSlotItems(slot)
    return self.items_by_slot[slot] or {}
end

return Catalog
