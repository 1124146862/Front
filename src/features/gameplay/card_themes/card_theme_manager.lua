local CardThemeManager = {}
CardThemeManager.__index = CardThemeManager
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")

local THEME_FOLDERS = {
    jade_lacquer = "src.features.gameplay.card_themes.themes.jade_lacquer",
    garden_court = "src.features.gameplay.card_themes.themes.garden_court",
    paper_circus = "src.features.gameplay.card_themes.themes.paper_circus",
    sunset_deco = "src.features.gameplay.card_themes.themes.sunset_deco",
    moonlit_orchid = "src.features.gameplay.card_themes.themes.moonlit_orchid",
}

function CardThemeManager.new()
    return setmetatable({
        cache = {},
    }, CardThemeManager)
end

function CardThemeManager:_getTheme(theme_id)
    local resolved = ThemeCatalog.normalizeThemeId(theme_id)
    if self.cache[resolved] then
        return self.cache[resolved]
    end

    local base = THEME_FOLDERS[resolved]
    local theme = {
        j = require(base .. ".j"),
        q = require(base .. ".q"),
        k = require(base .. ".k"),
        joker = require(base .. ".joker"),
    }
    self.cache[resolved] = theme
    return theme
end

function CardThemeManager:drawFace(theme_id, rank, frame, context)
    local theme = self:_getTheme(theme_id)
    local key = string.lower(tostring(rank or ""))
    local module = theme[key]
    if module and type(module.draw) == "function" then
        module.draw(frame, context or {})
        return true
    end
    return false
end

function CardThemeManager:drawJoker(theme_id, frame, context)
    local theme = self:_getTheme(theme_id)
    local module = theme.joker
    if module and type(module.draw) == "function" then
        module.draw(frame, context or {})
        return true
    end
    return false
end

return CardThemeManager
