local FontManager = {}
FontManager.__index = FontManager
local FontConfig = require("src.core.font_config")
local I18n = require("src.core.i18n.i18n")

FontManager.tokens = FontConfig.tokens

local function loadFont(path, size)
    local ok, font = pcall(love.graphics.newFont, path, size)
    if ok then
        return font
    end

    return love.graphics.newFont(size)
end

local function resolveFontPathForLocale(default_path, locale)
    return FontConfig.resolveLocaleFontPath(
        default_path,
        FontConfig.ui_locale_font_paths,
        locale
    )
end

function FontManager.new(options)
    local self = setmetatable({}, FontManager)

    self.font_path = FontConfig.ui_font_path
    self.tokens = FontConfig.tokens
    self.cache = {}

    return self
end

function FontManager:get(token)
    return self:getForLocale(token, I18n:getLocale())
end

function FontManager:getForLocale(token, locale)
    local key = token
    local size = token

    if type(token) == "string" then
        size = self.tokens[token]
    end

    if type(size) ~= "number" then
        error("Unknown font token: " .. tostring(token))
    end

    local font_path = resolveFontPathForLocale(self.font_path, locale)
    local cache_key = table.concat({
        tostring(font_path),
        tostring(key),
        tostring(size),
    }, "::")

    if not self.cache[cache_key] then
        self.cache[cache_key] = loadFont(font_path, size)
    end

    return self.cache[cache_key]
end

function FontManager:getSize(token)
    return self.tokens[token]
end

function FontManager:listTokens()
    return self.tokens
end

return FontManager
