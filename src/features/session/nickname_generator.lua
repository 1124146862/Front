local NicknameGenerator = {}
NicknameGenerator.__index = NicknameGenerator

local GUANDAN_PREFIXES = {
    "头游", "次游", "末游", "双下", "单下", "进贡", "还贡", "抗贡", "逢配", "级牌",
    "红桃", "黑桃", "方块", "梅花", "大王", "小王", "炸弹", "同花", "顺子", "连对",
    "钢板", "三顺", "对子", "单张", "甩牌", "牌权", "先手", "上游", "下游", "队友",
}

local GUANDAN_SUFFIXES = {
    "牌手", "阿团", "小将", "飞弹", "顺风", "压制", "冲锋", "翻盘", "主攻", "守门",
}

local COMMON_PREFIXES = {
    "青", "白", "云", "风", "星", "月", "木", "山", "川", "海",
    "北", "南", "东", "西", "晨", "夜", "花", "林", "河", "舟",
}

local COMMON_SUFFIXES = {
    "鹿", "舟", "桥", "岚", "禾",
}

local function buildPool(prefixes, suffixes)
    local pool = {}
    for _, prefix in ipairs(prefixes) do
        for _, suffix in ipairs(suffixes) do
            pool[#pool + 1] = prefix .. suffix
        end
    end
    return pool
end

local GUANDAN_POOL = buildPool(GUANDAN_PREFIXES, GUANDAN_SUFFIXES)
local COMMON_POOL = buildPool(COMMON_PREFIXES, COMMON_SUFFIXES)

function NicknameGenerator.new()
    return setmetatable({}, NicknameGenerator)
end

function NicknameGenerator:pick(pool)
    return pool[love.math.random(#pool)]
end

function NicknameGenerator:generate()
    local mode = love.math.random(4)
    local first = self:pick(GUANDAN_POOL)
    if mode == 1 then
        return first
    end

    local second = self:pick(COMMON_POOL)
    if mode == 2 then
        return second .. first
    end

    if mode == 3 then
        return first .. second
    end

    local extra = self:pick(COMMON_POOL)
    return first .. extra
end

return NicknameGenerator
