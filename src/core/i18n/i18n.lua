local zh_cn = require("src.core.i18n.locales.zh_cn")
local en_us = require("src.core.i18n.locales.en_us")
local zh_tw = require("src.core.i18n.locales.zh_tw")
local ja_jp = require("src.core.i18n.locales.ja_jp")
local ko_kr = require("src.core.i18n.locales.ko_kr")
local de_de = require("src.core.i18n.locales.de_de")
local fr_fr = require("src.core.i18n.locales.fr_fr")
local es_es = require("src.core.i18n.locales.es_es")
local ru_ru = require("src.core.i18n.locales.ru_ru")
local pt_br = require("src.core.i18n.locales.pt_br")
local it_it = require("src.core.i18n.locales.it_it")
local pl_pl = require("src.core.i18n.locales.pl_pl")

local I18n = {
    current_locale = "zh-CN",
    fallback_locale = "zh-CN",
    locales = {
        ["zh-CN"] = zh_cn,
        ["en-US"] = en_us,
        ["zh-TW"] = zh_tw,
        ["ja-JP"] = ja_jp,
        ["ko-KR"] = ko_kr,
        ["de-DE"] = de_de,
        ["fr-FR"] = fr_fr,
        ["es-ES"] = es_es,
        ["ru-RU"] = ru_ru,
        ["pt-BR"] = pt_br,
        ["it-IT"] = it_it,
        ["pl-PL"] = pl_pl,
    },
    ordered_locales = {
        "en-US",
        "zh-CN",
        "zh-TW",
        "ja-JP",
        "ko-KR",
        "de-DE",
        "fr-FR",
        "es-ES",
        "ru-RU",
        "pt-BR",
        "it-IT",
        "pl-PL",
    },
}

local function lookup(source, path)
    local current = source
    for segment in tostring(path):gmatch("[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
    end
    return current
end

local function interpolate(template, params)
    if type(template) ~= "string" or not params then
        return template
    end

    return (template:gsub("{(.-)}", function(key)
        local value = params[key]
        if value == nil then
            return "{" .. key .. "}"
        end
        return tostring(value)
    end))
end

local function buildLocaleFallbackChain(self, locale, extra_fallback_locales)
    local chain = {}
    local seen = {}

    local function push(candidate)
        if not candidate or seen[candidate] or not self.locales[candidate] then
            return
        end
        seen[candidate] = true
        chain[#chain + 1] = candidate
    end

    local active_locale = locale or self.current_locale
    push(active_locale)

    if type(extra_fallback_locales) == "table" then
        for _, candidate in ipairs(extra_fallback_locales) do
            push(candidate)
        end
    else
        local prefix = tostring(active_locale or ""):sub(1, 2):lower()
        if prefix == "zh" then
            push("zh-CN")
            push("en-US")
        else
            push("en-US")
            push(self.fallback_locale)
        end
    end

    push(self.fallback_locale)
    return chain
end

function I18n:setLocale(locale)
    if self.locales[locale] then
        self.current_locale = locale
    end
end

function I18n:getLocale()
    return self.current_locale
end

function I18n:getLocaleLabel(locale)
    local data = self.locales[locale or self.current_locale] or {}
    return (((data or {}).locale or {}).label) or tostring(locale or self.current_locale)
end

function I18n:getLocaleShortLabel(locale)
    local data = self.locales[locale or self.current_locale] or {}
    return (((data or {}).locale or {}).short_label) or self:getLocaleLabel(locale)
end

function I18n:getNextLocale()
    for index, locale in ipairs(self.ordered_locales) do
        if locale == self.current_locale then
            return self.ordered_locales[(index % #self.ordered_locales) + 1]
        end
    end
    return self.ordered_locales[1]
end

function I18n:getOrderedLocales()
    return self.ordered_locales
end

function I18n:getValue(key, options)
    options = options or {}
    local locale_chain = buildLocaleFallbackChain(
        self,
        options.locale,
        options.fallback_locales
    )
    for _, locale in ipairs(locale_chain) do
        local value = lookup(self.locales[locale] or {}, key)
        if value ~= nil then
            return value
        end
    end
    return nil
end

function I18n:t(key, params, options)
    local value = self:getValue(key, options)
    if value == nil then
        return key
    end
    return interpolate(value, params)
end

return I18n
