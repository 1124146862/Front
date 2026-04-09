local I18n = require("src.core.i18n.i18n")
local Config = require("src.features.session.nickname_generator_config")

local NicknameGenerator = {}
NicknameGenerator.__index = NicknameGenerator

local function utf8Length(text)
    local _, count = string.gsub(text or "", "[^\128-\193]", "")
    return count
end

local function trimToMaxLength(text, max_length)
    local value = tostring(text or "")
    if utf8Length(value) <= max_length then
        return value
    end

    local byte_index = 1
    local char_count = 0
    while byte_index <= #value and char_count < max_length do
        local byte = string.byte(value, byte_index)
        if byte < 0x80 then
            byte_index = byte_index + 1
        elseif byte < 0xE0 then
            byte_index = byte_index + 2
        elseif byte < 0xF0 then
            byte_index = byte_index + 3
        else
            byte_index = byte_index + 4
        end
        char_count = char_count + 1
    end

    return string.sub(value, 1, byte_index - 1)
end

local function resolvePool(locale)
    local pools = Config.pools or {}
    if pools[locale] then
        return pools[locale]
    end

    local normalized = tostring(locale or ""):lower()
    if normalized:sub(1, 2) == "zh" then
        return pools["zh-CN"]
    end
    if normalized:sub(1, 2) == "ja" then
        return pools["ja-JP"]
    end
    if normalized:sub(1, 2) == "ko" then
        return pools["ko-KR"]
    end
    if normalized:sub(1, 2) == "ru" then
        return pools["ru-RU"]
    end

    return pools[Config.default_locale] or pools["en-US"]
end

local function resolveLocale(locale)
    local pools = Config.pools or {}
    if pools[locale] then
        return locale
    end

    local normalized = tostring(locale or ""):lower()
    if normalized:sub(1, 2) == "zh" then
        if normalized:find("tw", 1, true) or normalized:find("hk", 1, true) then
            return pools["zh-TW"] and "zh-TW" or "zh-CN"
        end
        return "zh-CN"
    end
    if normalized:sub(1, 2) == "ja" then
        return "ja-JP"
    end
    if normalized:sub(1, 2) == "ko" then
        return "ko-KR"
    end
    if normalized:sub(1, 2) == "ru" then
        return "ru-RU"
    end
    if normalized:sub(1, 2) == "de" then
        return "de-DE"
    end
    if normalized:sub(1, 2) == "fr" then
        return "fr-FR"
    end
    if normalized:sub(1, 2) == "es" then
        return "es-ES"
    end
    if normalized:sub(1, 2) == "pt" then
        return "pt-BR"
    end
    if normalized:sub(1, 2) == "it" then
        return "it-IT"
    end
    if normalized:sub(1, 2) == "pl" then
        return "pl-PL"
    end

    return Config.default_locale or "en-US"
end

function NicknameGenerator.new()
    return setmetatable({}, NicknameGenerator)
end

function NicknameGenerator:pick(pool)
    return pool[love.math.random(#pool)]
end

function NicknameGenerator:generate(locale)
    local active_locale = locale or I18n:getLocale()
    local mode = love.math.random(4)
    local max_length = tonumber(Config.max_length) or 12
    local resolved_locale = resolveLocale(active_locale)

    if type(Config.generate) == "function" then
        local generated = Config.generate(resolved_locale, love.math.random)
        return trimToMaxLength(generated, max_length)
    end

    local pool = resolvePool(resolved_locale)

    if mode == 1 and #(pool.singles or {}) > 0 then
        return trimToMaxLength(self:pick(pool.singles), max_length)
    end

    local first = self:pick(pool.prefixes or pool.singles)
    local second = self:pick(pool.suffixes or pool.singles)
    local nickname = first .. second

    if mode == 2 then
        nickname = second .. first
    elseif mode == 3 and #(pool.singles or {}) > 0 then
        nickname = first .. self:pick(pool.singles)
    end

    return trimToMaxLength(nickname, max_length)
end

return NicknameGenerator
